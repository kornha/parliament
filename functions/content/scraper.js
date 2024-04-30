const functions = require("firebase-functions");
const {getTextContentFromStorage,
  setTextContentInStorage} = require("../common/storage");
const puppeteer = require("puppeteer");


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
  // networkidle0 waits for the page to load entirely
  // eg networkidle2 waits for 2 remaining active items
  await page.goto(url, {waitUntil: "networkidle0"});

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
    creatorEntity: tweetAuthor,
    imageUrl: tweetImageUrl,
    isoTime: tweetTime,
  };
};

const getEntityImageFromX = async function(handle) {
  const browser = await puppeteer.launch({headless: "new"});
  const page = await browser.newPage();

  await page.goto(`https://twitter.com/${handle}/photo`, {waitUntil: "networkidle0"});

  const imageSelector = "img[alt='Image']";

  const imageUrl = await page.evaluate((selector) => {
    // eslint-disable-next-line no-undef
    const element = document.querySelector(selector);
    return element ? element.src : null;
  }, imageSelector);

  // do we need to await here
  await browser.close();

  return imageUrl;
};

/**
 * REQUIRES 1GB TO RUN!
 * Method from scraping webpage text content with headless browswer
 * @param {string} handle in the post in question.
 * @param {string} sourceType in the post in question.
 * @return {string} with imageUrl
 */
const getEntityImage = async function(handle, sourceType) {
  if (sourceType == "x") {
    return await getEntityImageFromX(handle);
  }

  return Error("Source type not supported.");
};


// /////////////////////////////////////////////////////
// DEPRECATED
// /////////////////////////////////////////////////////

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

module.exports = {
  getTextContentFromX,
  //
  getEntityImageFromX,
  getEntityImage,
  //
  getTextContentForPost,
  setTextContentFromBrowser,
  getTextContentFromBrowser,
};
