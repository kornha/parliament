const {logger} = require("firebase-functions/v2");
const {
  setContent,
  getContent,
} = require("../common/storage");
const puppeteer = require("puppeteer");
const {
  getPostByXid,
  createPost,
  findCreateEntity,
  updatePost,
  findCreatePlatform,
} = require("../common/database");
const {v5} = require("uuid");
const {Timestamp} = require("firebase-admin/firestore");
const {isoToMillis, getPlatformType,
  retryAsyncFunction} = require("../common/utils");
const {defineSecret} = require("firebase-functions/params");
const {
  publishMessage,
  SHOULD_SCRAPE_FEED,
  SHOULD_PROCESS_LINK,
} = require("../common/pubsub");
const {HttpsError} = require("firebase-functions/v2/https");

const _xHandleKey = defineSecret("X_HANDLE_KEY");
const _xPasswordKey = defineSecret("X_PASSWORD_KEY");
const _xEmailKey = defineSecret("X_EMAIL_KEY");

// User agent for X
// eslint-disable-next-line max-len
const _userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36";

/**
 * REQUIRES 1GB TO RUN!
 * REQUIRES LONGER TIMEOUT
 * Scrapes X feed for new posts and publishes the urls
 * @param {string} feedUrl to start from, if null does not renavigate
 * @return {Promise<void>}
 * */
const scrapeXFeed = async function(feedUrl) {
  logger.info(`Started scraping X feed. ${feedUrl}`);

  const browser = await puppeteer.launch({headless: "new"});
  try {
    const page = await browser.newPage();

    await connectToX(page);

    // Uses async generator to get links
    for await (const link of autoScrollX(page, feedUrl, false, 10000)) {
      await publishMessage(SHOULD_PROCESS_LINK, {link: link});
    }

    logger.info("Finished scraping X feed.");

    return Promise.resolve();
  } catch (error) {
    logger.error("Error in scrapeXFeed:", error);
    throw error;
  } finally {
    await browser.close();
  }
};

/**
 * REQUIRES 1GB TO RUN!
 * Scrapes X for top news feeds
 * @param {string} url the url to scrape from.
 * @param {number} limit the number of feeds to include.
 * Max is ~8 depends on the autoscroll duration
 * @return {Promise<void>}
 * */
const scrapeXTopNews = async function(url = "https://x.com/explore/tabs/news", limit = 1) {
  logger.info("Started scraping top X news.");

  const browser = await puppeteer.launch({headless: "new"});
  try {
    const page = await browser.newPage();

    await connectToX(page);

    // go to top news url https://x.com/explore/tabs/news
    const uniqueEntries = new Set();
    for await (const response of autoScrollX(page, url, true, 6000)) {
      if (response?.data?.timeline?.timeline?.instructions?.length) {
        const entries =
          response.data.timeline.timeline.instructions.find(
              (item) => item.entries,
          )?.entries ?? [];

        // index randomization and sorting, removed for now
        // sort by sortIndex from X
        // entries.sort((a, b) => b.sortIndex - a.sortIndex);
        // const index = 0;
        // const rand = Math.floor(Math.random() * 10);

        for (const entry of entries) {
          // if (index++ != rand) {
          //   continue;
          // }
          if (entry.entryId) {
            if (entry?.entryId == "cursor-bottom") {
              continue;
            }
            if (uniqueEntries.has(entry.entryId)) {
              continue;
            }
            if (limit-- <= 0) {
              break;
            }
            // TODO: we dedup here and not in autoScrollX. Change?
            uniqueEntries.add(entry.entryId);
            const link = `https://x.com/i/trending/${entry.entryId}`;
            logger.info(`Queueing feed: ${link}.`);
            await publishMessage(SHOULD_SCRAPE_FEED, {link: link});
          }
        }
      }
    }

    logger.info("Finished scraping top X news.");

    return Promise.resolve();
  } catch (error) {
    logger.error("Error in scrapeXTopNews:", error);
    throw error;
  } finally {
    await browser.close();
  }
};

/**
 * REQUIRES 1GB TO RUN!
 * Connects to X and saves cookies.
 * Logs in if cookies are not sufficient
 * @param {page} page the page instance to connect with
 * */
const connectToX = async function(page) {
  logger.info("Connecting to X.");

  const email = _xEmailKey.value();
  const handle = _xHandleKey.value();
  const password = _xPasswordKey.value();

  const cookiePath = "cookies/x.json";

  // REQUIRED FOR TWITTER ELSE IT FORCES LOGIN
  await page.setUserAgent(_userAgent);
  await page.setViewport({width: 1280, height: 720});

  let tryRedirect = false;
  const cookiesString = await getContent(cookiePath);
  if (cookiesString) {
    const cookies = JSON.parse(cookiesString);
    await page.setCookie(...cookies);
    tryRedirect = true;
  } else {
    logger.info("No cookies found for X.");
    tryRedirect = false;
  }

  if (tryRedirect) {
    // cannot wait for network idle here as it will hang
    await page.goto("https://x.com/home");
    await Promise.race([
      page.waitForNavigation({waitUntil: "networkidle2"}),
      page.waitForNetworkIdle(1500),
    ]);
    if (!page.url().includes("login")) {
      logger.info("Already logged in.");
      return;
    }
  }

  logger.info("Logging in to X.");

  // login
  await page.goto("https://x.com/i/flow/login");
  await Promise.race([
    page.waitForNavigation({waitUntil: "networkidle0"}),
    page.waitForNetworkIdle(3000),
  ]);
  await page.waitForNetworkIdle({idleTime: 1500});

  // Select the user input
  await page.waitForSelector("[autocomplete=username]");
  await page.type("input[autocomplete=username]", email, {delay: 50});
  // Press the Next button
  await page.evaluate(() => {
    // eslint-disable-next-line no-undef
    const buttons = Array.from(document.querySelectorAll("button"));
    const nextButton = buttons.find(
        (button) => button.innerText.trim().toLowerCase() === "next",
    );
    if (nextButton) {
      nextButton.click();
    } else {
      console.error("Next button not found.");
    }
  });
  await page.waitForNetworkIdle({idleTime: 1500});
  // ////////////////////////////////////////////////////
  // Sometimes x suspect suspicious activties,
  // so it ask for your handle/phone Number
  const extractedText = await page.$eval("*", (el) => el.innerText);
  if (extractedText.includes("Enter your phone number or username")) {
    await page.waitForSelector("[autocomplete=on]");
    await page.type("input[autocomplete=on]", handle, {delay: 50});
    await page.evaluate(() => {
      // eslint-disable-next-line no-undef
      const buttons = Array.from(document.querySelectorAll("button"));
      const nextButton = buttons.find(
          (button) => button.innerText.trim().toLowerCase() === "next",
      );
      if (nextButton) {
        nextButton.click();
      } else {
        console.error("Next button not found.");
      }
    });
    await page.waitForNetworkIdle({idleTime: 1500});
  }
  // ///////////////////////////////////////////////////
  // if you need to manually log in, put this timeout in here to give you time
  // await page.waitForTimeout(40000);
  // Select the password input
  await page.waitForSelector("[autocomplete=\"current-password\"]");
  await page.type("[autocomplete=\"current-password\"]", password, {delay: 50});
  // Press the Login button
  await page.evaluate(() => {
    // eslint-disable-next-line no-undef
    const buttons = Array.from(document.querySelectorAll("button"));
    const nextButton = buttons.find(
        (button) => button.innerText.trim().toLowerCase() === "log in",
    );
    if (nextButton) {
      nextButton.click();
    } else {
      console.error("Log in button not found.");
    }
  });

  logger.info("Logged in to X.");

  // needed?
  await page.waitForNetworkIdle({idleTime: 1000});

  // save cookies
  const cookies = await page.cookies();
  setContent("cookies/x.json", JSON.stringify(cookies));
};

/**
 * Scrolls an X page yielding links or responses
 * Dedups links, not responses
 * THIS IS AN *ASYNC GENERATOR* FUNCTION,
 * it will yield the links found like a promise.all
 * @param {page} page the page instance to connect with
 * @param {string} url the url to scrape from
 * @param {bool} yieldResponses whether to yield responses or links
 * @param {number} maxDuration the maximum duration to scroll
 * @return {AsyncGenerator<string>} with response json or link urls
 */
const autoScrollX = async function* (
    page,
    url,
    yieldResponses = false,
    maxDuration = 10000,
) {
  const uniqueLinksSeen = new Set();
  const responses = [];

  if (yieldResponses) {
    page.on("response", async (response) => {
      try {
        const headers = response.headers();

        if (headers["content-type"]) {
          const contentType = headers["content-type"];

          if (contentType.includes("application/json")) {
            const responseBody = await response.json();
            responses.push(responseBody);
          }
        }
      } catch (error) {
        console.error("Error getting response body:", error);
      }
    });
  }

  await page.goto(url);
  await page.waitForTimeout(4000);

  const startTime = Date.now();
  // eslint-disable-next-line no-undef
  let lastHeight = await page.evaluate(() => document.body.scrollHeight);

  while (Date.now() - startTime < maxDuration) {
    // eslint-disable-next-line no-undef
    await page.evaluate(() => window.scrollBy(0, window.innerHeight / 1.25));

    // eslint-disable-next-line no-undef
    const newHeight = await page.evaluate(() => document.body.scrollHeight);

    if (newHeight > lastHeight) {
      lastHeight = newHeight;

      if (!yieldResponses) {
        // Fetch links and ensure they are fully
        // loaded by checking the absence of placeholders
        const links = await page.evaluate(() => {
          // eslint-disable-next-line no-undef
          const items = document.querySelectorAll("article [role='link']");
          const xRegex = /^https:\/\/x\.com\/\w+\/status\/\d+$/;
          return Array.from(items)
              .map((item) => item.href)
              .filter((href) => xRegex.test(href));
        });

        // Filter out any duplicates seen in this session
        const newLinks = links.filter((link) => !uniqueLinksSeen.has(link));
        newLinks.forEach((link) => uniqueLinksSeen.add(link));

        // Yield each new link found that does not include placeholders
        for (const link of newLinks) {
          yield link;
        }
      }
    } else {
      // If no new height is detected, wait before the next scroll attempt
      await page.waitForTimeout(2000);
    }
  }
  if (yieldResponses && responses.length > 0) {
    for (const responseBody of responses) {
      yield responseBody;
    }
    responses.length = 0; // Clear responses array
  }
};

/**
 * goes through the links and creates an entity and post if not found
 * by adding XID, acts as "pubsub" publisher for new links
 * @param {Array<string>} xLinks
 * @param {string} poster uid to apply if posted by user
 * @return {Promise<Array<string>>} with pids
 * */
const processXLinks = async function(xLinks, poster = null) {
  const pids = [];
  // move into loop for multi-platforms
  // took out to avoid db call for each link
  const platform = await findCreatePlatform("x.com");

  for (const link of xLinks) {
    logger.info(`Processing X link: ${link}.`);
    const xid = link.split("/").pop();
    const post = await getPostByXid(xid, platform.plid);
    if (post == null) {
      const handle = link.split("/")[3];
      if (handle == "i" || handle == "@i") {
        // currently not supporting where i is temp handle used by X
        logger.warn("Skipping link: " + link);
        continue;
      }
      const entity = await findCreateEntity(handle, platform);
      if (entity.eid == null) {
        logger.error("Could not find entity for handle: " + handle);
        continue; // Skip to the next iteration if no entity is found
      }
      const post = {
        pid: v5(xid, platform.plid),
        eid: entity.eid,
        xid: xid,
        url: link,
        poster: poster,
        status: "scraping",
        plid: platform.plid,
        createdAt: Timestamp.now().toMillis(),
        updatedAt: Timestamp.now().toMillis(),
      };

      const success = await createPost(post);
      if (success) {
        pids.push(post.pid);
      } else {
        logger.error("Could not create post for xid: " + xid);
      }
    } else {
      logger.info("Post already exists for xid: " + xid);
      await xupdatePost(post);
      pids.push(post.pid);
    }
  }

  return pids;
};

/**
 * REQUIRES 1GB TO RUN (currently)!
 * Method from scraping webpage text content with headless browswer
 * @param {string} url in the post in question.
 * @return {string} with title
 * @return {string} with creator
 * @return {string?} with photoURL
 */
const getContentFromX = async function(url) {
  const browser = await puppeteer.launch({headless: "new"});
  try {
    const page = await browser.newPage();

    // Variables to store extracted data
    let tweetVideoURL = null;
    let tweetPhotoURL = null;
    let tweetText = null;
    let tweetAuthor = null;
    let tweetTime = null;
    let tweetLikes = null;
    let tweetReposts = null;
    let tweetBookmarks = null;
    let tweetViews = null;
    let tweetReplies = null;

    // Set up a promise to capture media URLs
    const mediaPromise = new Promise((resolve) => {
      page.on("request", (request) => {
        const requestUrl = request.url();
        if (
          (request.resourceType() === "media" ||
            requestUrl.includes(".mp4")) &&
          !tweetVideoURL
        ) {
          tweetVideoURL = requestUrl;
          resolve();
        }
        if (
          request.resourceType() === "image" &&
          requestUrl.includes("media") &&
          !tweetPhotoURL
        ) {
          tweetPhotoURL = requestUrl;
          resolve();
        }
      });
    });

    // Set up a promise to capture tweet data
    const tweetDataPromise = new Promise((resolve) => {
      page.on("response", async (response) => {
        const responseUrl = response.url();

        // Skip preflight requests or responses without content
        if (response.request().method() === "OPTIONS" ||
         response.status() === 204) {
          return;
        }

        // We are only interested in the specific GraphQL response
        if (
          responseUrl.includes("graphql") &&
          responseUrl.includes("TweetResultByRestId")
        ) {
          try {
            const headers = response.headers();
            if (
              headers["content-type"] &&
              headers["content-type"].includes("application/json")
            ) {
              const responseBody = await response.json();
              const tweetResult = responseBody?.data?.tweetResult?.result;

              if (!tweetResult) {
                console.error("No tweet result found in the response.");
                resolve(); // Resolve to avoid hanging
                return;
              }

              let tweetData;
              if (tweetResult.__typename === "Tweet") {
                tweetData = tweetResult;
              } else if (
                tweetResult.__typename === "TweetWithVisibilityResults"
              ) {
                tweetData = tweetResult.tweet;
              } else {
                console.error(
                    `Unhandled tweet result type: ${tweetResult.__typename}`,
                );
                resolve(); // Resolve to avoid hanging
                return;
              }

              // Extract the tweet details
              tweetText = tweetData.legacy.full_text;
              tweetAuthor = tweetData.core.user_results.result.legacy.name;
              tweetTime = tweetData.legacy.created_at;
              tweetReplies = tweetData.legacy.reply_count;
              tweetReposts = tweetData.legacy.retweet_count;
              tweetLikes = tweetData.legacy.favorite_count;
              tweetBookmarks = tweetData.legacy.bookmark_count;
              tweetViews = parseInt(tweetData.views?.count || "0", 10);

              resolve();
            }
          } catch (error) {
            if (error.message.
                includes("Could not load body for this request")) {
              // Suppress the specific error
              console.warn("Skipped a response without a body.");
            } else {
              console.error("Error parsing tweet data:", error);
            }
            resolve(); // Resolve to avoid hanging
          }
        }
      });
    });

    // Navigate to the tweet URL
    await page.goto(url);

    // Wait for both promises or timeout after 5 seconds
    await Promise.race([
      Promise.all([tweetDataPromise, mediaPromise]),
      new Promise((resolve) => setTimeout(resolve, 8000)),
    ]);

    // return null if any null values
    if (!tweetText || !tweetAuthor || !tweetTime) {
      return null;
    }

    return {
      title: tweetText,
      creatorEntity: tweetAuthor,
      photoURL: tweetPhotoURL,
      videoURL: tweetVideoURL,
      isoTime: tweetTime,
      replies: tweetReplies,
      reposts: tweetReposts,
      likes: tweetLikes,
      bookmarks: tweetBookmarks,
      views: tweetViews,
    };
  } catch (error) {
    logger.error(`Error in getContentFromX url: ${url}, error`, error);
    return null;
  } finally {
    await browser.close();
  }
};


/**
 * REQUIRES 1GB TO RUN!
 * Updates a post with metadata from X
 * @param {Post} post with xid, eid, pid
 * */
const xupdatePost = async function(post) {
  if (!post || !post.xid || !post.eid || !post.url) {
    throw new HttpsError("invalid-argument", "No post provided.");
  }

  logger.info(`Updating Post: ${post.pid} with X metadata.`);

  // retries
  const xMetaData = await retryAsyncFunction(() =>
    getContentFromX(post.url), 2);
  if (!xMetaData) {
    // firebase doesn't log the httpsError as an error
    logger.error("Could not fetch content from " + post.url);
    await updatePost(post.pid, {status: "errored"});
    throw new HttpsError(
        "invalid-argument",
        "Could not fetch content from " + post.url,
    );
  }

  const time = isoToMillis(xMetaData.isoTime);

  // currently we do not support video
  const supported = xMetaData.videoURL == null;

  // if the post already exists (eg., not scraping, draft, and not null), keep
  // if the post has a poster, set to draft
  // otherwise, if created from backend, set to published
  const status =
    post.status != "scraping" && post.status != "draft" && post.status != null ?
      post.status :
      !supported ?
      "unsupported" :
      post.poster ?
      "draft" :
      "published";

  const _post = {
    // we set to published unless status is in draft
    status: status,
    sourceCreatedAt: time,
    updatedAt: Timestamp.now().toMillis(),
    title: xMetaData.title,
    // currently no description pulled from X
    // will change with API change
    // description: metadata.description,

    // don't set the photo at all if its null
    photo: xMetaData.photoURL ? {photoURL: xMetaData.photoURL} : null,
    video: xMetaData.videoURL ? {videoURL: xMetaData.videoURL} : null,
    replies: xMetaData.replies,
    reposts: xMetaData.reposts,
    likes: xMetaData.likes,
    bookmarks: xMetaData.bookmarks,
    views: xMetaData.views,
  };

  await updatePost(post.pid, _post);
  logger.info(`Updated post: ${post.pid} with X metadata.`);
};

/**
 * REQUIRES 1GB TO RUN!
 * Method from scraping webpage text content with headless browser
 * @param {string} handle in the post in question.
 * @param {Platform} platform in the post in question.
 * @return {string} with photoURL
 */
const getEntityImage = async function(handle, platform) {
  const platformType = getPlatformType(platform);
  if (platformType == "x") {
    return await getEntityImageFromX(handle);
  }

  logger.info(`Entity image unsupported for: ${platformType}`);

  return null;
};

/**
 * REQUIRES 1GB TO RUN!
 * Fetches entity image from X
 * @param {string} handle in the post in question.
 * @return {string} with photoURL
 * */
const getEntityImageFromX = async function(handle) {
  const browser = await puppeteer.launch({headless: "new"});
  try {
    const page = await browser.newPage();

    let photoURL = null;
    page.on("request", (request) => {
      const url = request.url();
      if (
        request.resourceType() === "image" &&
        url.includes("profile_images")
      ) {
        photoURL = url;
      }
    });

    await page.goto(`https://x.com/${handle}/photo`, {
      waitUntil: "networkidle0",
    });

    return photoURL;
  } catch (error) {
    logger.error("Error in getEntityImageFromX:", error);
    throw error;
  } finally {
    await browser.close();
  }
};

/**
 * Checks if the URL is from X
 * @param {string} url
 * @return {bool} if the URL is from X
 * */
const isXURL = function(url) {
  return url && (url.includes("x.com") || url.includes("twitter.com"));
};

module.exports = {
  xupdatePost,
  scrapeXFeed,
  scrapeXTopNews,
  processXLinks,
  //
  getContentFromX,
  //
  getEntityImageFromX,
  getEntityImage,
  //
  isXURL,
};
