const functions = require("firebase-functions");
const admin = require("firebase-admin");
const puppeteer = require("puppeteer");

/**
 * Main method for fetching text content.
 * Checks/saves to storage before using browser scraper
 * @param {post} post the post in question.
 */
const getTextContentForPost = async function(post) {
  if (!post.url) return;

  let content = await getTextContentFromStorage(post);
  if (content) return content;

  content = await getTextContentFromBrowser(post);
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
 * Creates/overwrites the content in storage from browser scrape.
 * @param {post} post the post in question.
 */
const setTextContentFromBrowser = async function(post) {
  const content = await getTextContentFromBrowser(post);
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
 * Method from scraping webpage text content with headless browswer
 * @param {post} post the post in question.
 */
const getTextContentFromBrowser = async function(post) {
  const browser = await puppeteer.launch({headless: true});
  const page = (await browser.pages())[0];
  await page.goto(post.url);
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

module.exports = {
  getTextContentForPost,
  getTextContentFromStorage,
  setTextContentFromBrowser,
  setTextContentInStorage,
};
