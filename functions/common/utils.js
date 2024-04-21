const functions = require("firebase-functions");
const admin = require("firebase-admin");
const puppeteer = require("puppeteer");
const {Timestamp} = require("firebase-admin/firestore");

const isLocal = process.env.FUNCTIONS_EMULATOR === "true";
const isDev = !isLocal &&
 admin.instanceId().app.options.projectId === "political-think";

/**
 * DEPRECATED!
 * REQUIRES 1GB TO RUN!
 * Main method for fetching text content.
 * Checks/saves to storage before using browser scraper
 * @param {post} post the post in question.
 */
const getTextContentForPost = async function(post) {
  if (!post.url) return;

  let content = await getTextContentFromStorage(post);
  if (content) return content;

  content = await getTextContentFromBrowser(post.url);
  if (content) {
    setTextContentInStorage(post, content);
    return content;
  } else {
    functions.logger.error(
        `Could not fetch content for url: ${post.url}, content: ${content}`);
    return;
  }
};

/**
 * DEPRECATED!
 * REQUIRES 1GB TO RUN!
 * Creates/overwrites the content in storage from browser scrape.
 * @param {post} post the post in question.
 */
const setTextContentFromBrowser = async function(post) {
  const content = await getTextContentFromBrowser(post.url);
  if (content) {
    setTextContentInStorage(post, content);
    return content;
  } else {
    functions.logger.error(
        `Could not fetch content for url: ${post.url}, content: ${content}`);
    return;
  }
};

/**
 * REQUIRES 1GB TO RUN!
 * Method from scraping webpage text content with headless browswer
 * @param {string} url in the post in question.
 */
const getTextContentFromBrowser = async function(url) {
  const browser = await puppeteer.launch({headless: "new"});

  const page = (await browser.pages())[0];
  await page.goto(url);
  const extractedText = await page.$eval("*", (el) => {
    // eslint-disable-next-line no-undef
    const selection = window.getSelection();
    // eslint-disable-next-line no-undef
    const range = document.createRange();
    range.selectNode(el);
    selection.removeAllRanges();
    selection.addRange(range);
    // eslint-disable-next-line no-undef
    return window.getSelection().toString();
  });
  // do we need to await here?
  await browser.close();
  return extractedText;
};

/**
 * REQUIRES 1GB TO RUN (currently)!
 * Method from scraping webpage text content with headless browswer
 * @param {string} url in the post in question.
 * @return {string} with title
 * @return {string} with creator
 * @return {string?} with imageUrl
 */
const getTextContentFromX = async function(url) {
  const browser = await puppeteer.launch({headless: "new"});
  const page = await browser.newPage();

  // Use the provided sample X URL
  await page.goto(url, {waitUntil: "networkidle2"});

  // Finds the tweet text
  // Hack, to be solved with twitter API
  const tweetTextSelector = "article [data-testid=\"tweetText\"]";

  // Finds the account handle
  // Hack, to be solved with twitter API
  // in this case needs a div, span at the end. Not sure why.
  const tweetAuthorSelector =
  "article [data-testid=\"User-Name\"] div:nth-of-type(2) div span";

  // Selector for the image within the tweet, based on your structure
  const tweetImageSelector = "[data-testid='tweetPhoto'] img";

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
  const tweetImageUrl = await page.evaluate((selector) => {
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
    creator: tweetAuthor,
    imageUrl: tweetImageUrl,
    isoTime: tweetTime,
  };
};

// ////////////////////////////
// Storage APIs (could be moved)
// ////////////////////////////

/**
  * @param {post} post in question
  * @param {String} content is the text to be saved
  */
const setTextContentInStorage = async function(post, content) {
  const file = admin.storage().bucket().file(`posts/text/${post.pid}.txt`);
  await file.save(content, {
    contentType: "text/plain",
    gzip: true,
  });
};

/**
  * @param {post} post
  * @return {String | null} content text from or null if unavailable
  */
const getTextContentFromStorage = async function(post) {
  console.log(`posts/text/${post.pid}.txt`);
  const file = admin.storage().bucket().file(`posts/text/${post.pid}.txt`);
  const exists = await file.exists();
  if (!exists[0]) return;
  const text = await file.download().then((data) => {
    return data[0].toString();
  });
  return text;
};

const isPerfectSquare = function(x) {
  const s = Math.sqrt(x);
  return s * s === x;
};

const isFibonacciNumber = function(n) {
  if (!n) return false;
  return isPerfectSquare(5 * n * n + 4) || isPerfectSquare(5 * n * n - 4);
};

/**
 * Calculate the probability of player A winning
 * @param {number} eloA - the Elo rating of player A
 * @param {number} eloB - the Elo rating of player B
 * @return {number} the probability of player A winning
 */
function calculateProbability(eloA, eloB) {
  return 1.0 / (1.0 + Math.pow(10, (eloB - eloA) / 400));
}

/**
 * @param {number} eloWinner - the Elo rating of player A
 * @param {number} eloLoser - the Elo rating of player B
 * @param {boolean} didWin - the result of the match for player A, 1, 0 or 0.5
 * @param {number} kFactor - the K-factor for the match
 * @return {number} new rating
 */
function getElo(eloWinner, eloLoser, didWin, kFactor = 32) {
  // Calculate the probability of winning for each player
  const probA = calculateProbability(eloWinner, eloLoser);
  // const probB = calculateProbability(eloLoser, eloWinner);

  // Update ratings
  const newRatingWinner = eloWinner + kFactor * (didWin - probA);
  // const newRatingLoser = eloLoser + kFactor * ((1 - winner) - probB);
  // convert number to integer
  return Math.round(newRatingWinner);
}

/**
 * @param {string} url - the URL to parse
 * @return {string} the domain of the URL
 */
function urlToDomain(url) {
  if (!url) return;
  const domain = (new URL(url)).hostname;
  return domain;
}

/**
 *
 * @param {Function} asyncFn
 * @param {number} retries
 * @param {number} interval
 * @return {Promise<*>}
 */
async function retryAsyncFunction(asyncFn, retries = 3, interval = 1000) {
  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      const result = await asyncFn();
      if (result) return result;
    } catch (error) {
      functions.logger.error(`Attempt ${attempt + 1} failed: ${error}`);
    }
    if (attempt < retries - 1) {
      await new Promise((resolve) => setTimeout(resolve, interval));
    }
  }
  functions.logger.error(`Failed after ${retries} attempts`);
  return false;
}

/**
 *
 * Calculates the mean vector of a list of vectors
 * @param {Array<number[]>} vectors - the list of vectors
 * @return {number[]} the mean vector
 */
function calculateMeanVector(vectors) {
  const meanVector = vectors.reduce((acc, vector) => {
    return acc.map((value, i) => value + vector[i]);
  }, Array(vectors[0].length).fill(0));
  return meanVector.map((value) => value / vectors.length);
}

/**
 * Converts milliseconds to an ISO string
 * @param {number} millis - the milliseconds
 * @return {string} the ISO string
 */
const millisToIso = function(millis) {
  if (!millis) return;
  return new Date(millis).toISOString();
};

/**
 * Converts an ISO string to milliseconds
 * @param {string} iso - the ISO string
 * @return {number} the milliseconds
 */
const isoToMillis = function(iso) {
  if (!iso) return;
  return Timestamp.fromDate(new Date(iso)).toMillis();
};

module.exports = {
  isLocal,
  isDev,
  getTextContentForPost,
  getTextContentFromStorage,
  getTextContentFromBrowser,
  setTextContentFromBrowser,
  setTextContentInStorage,
  urlToDomain,
  isFibonacciNumber,
  isPerfectSquare,
  getElo,
  getTextContentFromX,
  retryAsyncFunction,
  calculateMeanVector,
  millisToIso,
  isoToMillis,
};
