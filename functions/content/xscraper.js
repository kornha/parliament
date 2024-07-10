const functions = require("firebase-functions");
const {
  setContent,
  getContent} = require("../common/storage");
const puppeteer = require("puppeteer");
const {getPostByXid,
  createPost,
  findCreateEntity,
  updatePost,
} = require("../common/database");
const {v5} = require("uuid");
const {Timestamp} = require("firebase-admin/firestore");
const {isoToMillis} = require("../common/utils");
const {defineSecret} = require("firebase-functions/params");
const {publishMessage, SHOULD_SCRAPE_FEED} = require("../common/pubsub");

const _xHandleKey = defineSecret("X_HANDLE_KEY");
const _xPasswordKey = defineSecret("X_PASSWORD_KEY");
const _xEmailKey = defineSecret("X_EMAIL_KEY");

// need a namespace for X for v5 that is a valid uuid
const _xNamespace = "e962ad23-2f0a-411b-a118-a309d7ee4340";

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
  functions.logger.info(`Started scraping X feed. ${feedUrl}`);

  const browser = await puppeteer.launch({headless: "new"});
  const page = await browser.newPage();

  await connectToX(page);

  if (feedUrl) {
    await page.goto(feedUrl, {waitUntil: "networkidle2"});
    await page.waitForNetworkIdle({idleTime: 1500});
  }

  // Uses async generator to get links
  for await (const link of autoScrollX(page, false)) {
    await processXLinks([link], null);
  }

  functions.logger.info("Finished scraping X feed.");

  await browser.close();

  return Promise.resolve();
};

/**
 * REQUIRES 1GB TO RUN!
 * Scrapes X for top news feeds
 * @param {number} limit the number of feeds to include.
 * Max is ~8 depends on the autoscroll duration
 * @return {Promise<void>}
 * */
const scrapeXTopNews = async function(limit = 1) {
  functions.logger.info("Started scraping top X news.");


  const browser = await puppeteer.launch({headless: "new"});
  const page = await browser.newPage();

  await connectToX(page);

  await page.goto("https://x.com/explore/tabs/news", {waitUntil: "networkidle2"});

  // go to top news url https://x.com/explore/tabs/news
  const uniqueEntries = new Set();
  for await (const response of autoScrollX(page, true, 6000)) {
    // await processXLinks([link], null);
    if (response?.data?.timeline?.timeline?.instructions?.length) {
      const entries = response.data.timeline.timeline.instructions
          .find((item) => item.entries)?.entries ?? [];
      // sort by sortIndex from X
      entries.sort((a, b) => b.sortIndex - a.sortIndex);
      let index = 0;
      const rand = Math.floor(Math.random() * 10);
      for (const entry of entries) {
        if (index++ != rand) {
          continue;
        }
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
          functions.logger.info(`Queueing feed: ${link}.`);
          await publishMessage(SHOULD_SCRAPE_FEED, {link: link});
        }
      }
    }
  }

  functions.logger.info("Finished scraping top X news.");

  await browser.close();

  return Promise.resolve();
};


/**
 * REQUIRES 1GB TO RUN!
 * Connects to X and saves cookies.
 * Logs in if cookies are not sufficient
 * @param {page} page the page instance to connect with
 * */
const connectToX = async function(page) {
  functions.logger.info("Connecting to X.");

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
    functions.logger.info("No cookies found for X.");
    tryRedirect = false;
  }

  if (tryRedirect) {
    // cannot wait for network idle here as it will hang
    await page.goto("https://x.com/home");
    // wait for redirect
    await page.waitForNetworkIdle({idleTime: 1500});
    if (!page.url().includes("login")) {
      functions.logger.info("Already logged in.");
      return;
    }
  }

  functions.logger.info("Logging in to X.");

  // login
  await page.goto("https://x.com/i/flow/login", {waitUntil: "networkidle0"});
  await page.waitForNetworkIdle({idleTime: 1500});

  // Select the user input
  await page.waitForSelector("[autocomplete=username]");
  await page.type("input[autocomplete=username]", email, {delay: 50});
  // Press the Next button
  await page.evaluate(() => {
    // eslint-disable-next-line no-undef
    const buttons = Array.from(document.querySelectorAll("button"));
    const nextButton =
      buttons.find((button) =>
        button.innerText.trim().toLowerCase() === "next");
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
      const nextButton =
        buttons.find((button) =>
          button.innerText.trim().toLowerCase() === "next");
      if (nextButton) {
        nextButton.click();
      } else {
        console.error("Next button not found.");
      }
    });
    await page.waitForNetworkIdle({idleTime: 1500});
  }
  // ///////////////////////////////////////////////////
  // Select the password input
  await page.waitForSelector("[autocomplete=\"current-password\"]");
  await page.type("[autocomplete=\"current-password\"]", password, {delay: 50});
  // Press the Login button
  await page.evaluate(() => {
    // eslint-disable-next-line no-undef
    const buttons = Array.from(document.querySelectorAll("button"));
    const nextButton =
      buttons.find((button) =>
        button.innerText.trim().toLowerCase() === "log in");
    if (nextButton) {
      nextButton.click();
    } else {
      console.error("Log in button not found.");
    }
  });

  functions.logger.info("Logged in to X.");

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
 * @param {bool} yieldResponses whether to yield responses or links
 * @param {number} maxDuration the maximum duration to scroll
 * @return {AsyncGenerator<string>} with response json or link urls
 */
const autoScrollX = async function* (page,
    yieldResponses = false,
    maxDuration = 11000,
) {
  const startTime = Date.now();
  // eslint-disable-next-line no-undef
  let lastHeight = await page.evaluate(() => document.body.scrollHeight);
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
          return Array.from(items).map((item) =>
            item.href).filter((href) => xRegex.test(href));
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

  for (const link of xLinks) {
    functions.logger.info(`Processing X link: ${link}.`);
    const xid = link.split("/").pop();
    const post = await getPostByXid(xid, "x");
    if (post == null) {
      const handle = link.split("/")[3];
      if (handle == "i" || handle == "@i") {
        // currently not supporting where i is temp handle used by X
        functions.logger.warn("Skipping link: " + link);
        continue;
      }
      const eid = await findCreateEntity(handle, "x");
      if (eid == null) {
        functions.logger.error("Could not find entity for handle: " + handle);
        continue; // Skip to the next iteration if no entity is found
      }
      const post = {
        pid: v5(xid, _xNamespace),
        eid: eid,
        xid: xid,
        url: link,
        poster: poster,
        status: "scraping",
        sourceType: "x",
        createdAt: Timestamp.now().toMillis(),
        updatedAt: Timestamp.now().toMillis(),
      };

      const success = await createPost(post);
      if (success) {
        pids.push(post.pid);
      } else {
        functions.logger.error("Could not create post for xid: " + xid);
      }
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
  const page = await browser.newPage();

  // for video we do it by fetch since scraping directly is hard
  let tweetVideoURL = null; // Initialize the video URL variable
  page.on("request", (request) => {
    if ((request.resourceType() === "media" ||
      request.url().includes(".mp4")) && !tweetVideoURL) {
      tweetVideoURL = request.url();
    }
  });

  // Use the provided sample X URL
  // networkidle0 waits for the page to load entirely
  // eg networkidle2 waits for 2 remaining active items
  await page.goto(url, {waitUntil: "networkidle0"});

  // Finds the tweet text
  // Hack, to be solved with x API
  const tweetTextSelector = "article [data-testid=\"tweetText\"]";

  // Finds the account handle
  // Hack, to be solved with x API
  // in this case needs a div, span at the end. Not sure why.
  const tweetAuthorSelector =
    "article [data-testid=\"User-Name\"] div:nth-of-type(2) div span";

  // Selector for the image within the tweet, based on your structure
  const tweetImageSelector = "[data-testid='tweetPhoto'] img";

  // Selector for the video within the tweet, based on your structure
  // const tweetVideoSelector =
  //   "[data-testid='videoComponent'] video source[type='video/mp4']";


  // Selector for the time of the tweet
  const tweetTimeSelector = "article time[datetime]";

  // this gets the users display name
  // const tweetProfileSelector
  // = "article [data-testid=\"User-Name\"] div span";

  // Extract tweet text and author using the selectors
  const tweetText = await page.evaluate((selector) => {
    // eslint-disable-next-line no-undef
    const element = document.querySelector(selector);
    return element ? element.innerText : null;
  }, tweetTextSelector);

  const tweetAuthor = await page.evaluate((selector) => {
    // eslint-disable-next-line no-undef
    const element = document.querySelector(selector);
    return element && element.innerText && element.innerText[0] == "@" ?
      element.innerText : null;
  }, tweetAuthorSelector);

  // Extract the 'src' attribute of the image
  const tweetPhotoURL = await page.evaluate((selector) => {
    // eslint-disable-next-line no-undef
    const element = document.querySelector(selector);
    return element ? element.src : null;
  }, tweetImageSelector);


  const tweetTime = await page.evaluate((selector) => {
    // eslint-disable-next-line no-undef
    const element = document.querySelector(selector);
    return element ? element.getAttribute("datetime") : null;
  }, tweetTimeSelector);

  // do we need to await here
  await browser.close();

  return {
    title: tweetText,
    creatorEntity: tweetAuthor,
    photoURL: tweetPhotoURL,
    videoURL: tweetVideoURL,
    isoTime: tweetTime,
  };
};

/**
 * REQUIRES 1GB TO RUN!
 * Updates a post with metadata from X
 * @param {Post} post with xid, eid, pid
 * */
const xupdatePost = async function(post) {
  if (!post || !post.xid || !post.eid || !post.url) {
    throw new functions.https
        .HttpsError("invalid-argument", "No post provided.");
  }

  functions.logger.info(`Updating post: ${post.pid} with X metadata.`);

  const xMetaData = await getContentFromX(post.url);
  if (!xMetaData) {
    throw new functions.https
        .HttpsError("invalid-argument",
            "Could not fetch content from " + post.url);
  }

  const time = isoToMillis(xMetaData.isoTime);

  // currently we do not support video
  const supported = xMetaData.videoURL == null;

  if (!supported) {
    functions.logger.warn("Video not supported, skipping post: " + post.pid);
  }

  const _post = {
    // we set to published unless status is in draft
    status: supported ? post.poster ? "draft" : "published" : "unsupported",
    sourceCreatedAt: time,
    updatedAt: Timestamp.now().toMillis(),
    title: xMetaData.title,
    // currently no description pulled from X
    // will change with API change
    // description: metadata.description,

    // don't set the photo at all if its null
    photo: xMetaData.photoURL ? {photoURL: xMetaData.photoURL} : null,
    video: xMetaData.videoURL ? {videoURL: xMetaData.videoURL} : null,
  };

  await updatePost(post.pid, _post);
  functions.logger.info(`Updated post: ${post.pid} with X metadata.`);
};

/**
 * REQUIRES 1GB TO RUN!
 * Method from scraping webpage text content with headless browswer
 * @param {string} handle in the post in question.
 * @param {string} sourceType in the post in question.
 * @return {string} with photoURL
 */
const getEntityImage = async function(handle, sourceType) {
  if (sourceType == "x") {
    return await getEntityImageFromX(handle);
  }

  return Error("Source type not supported.");
};

/**
 * REQUIRES 1GB TO RUN!
 * Fetches entity image from X
 * @param {string} handle in the post in question.
 * @return {string} with photoURL
 * */
const getEntityImageFromX = async function(handle) {
  const browser = await puppeteer.launch({headless: "new"});
  const page = await browser.newPage();

  await page.goto(`https://x.com/${handle}/photo`, {waitUntil: "networkidle0"});

  const imageSelector = "img[alt='Image']";

  const photoURL = await page.evaluate((selector) => {
    // eslint-disable-next-line no-undef
    const element = document.querySelector(selector);
    return element ? element.src : null;
  }, imageSelector);

  // do we need to await here
  await browser.close();

  return photoURL;
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
};
