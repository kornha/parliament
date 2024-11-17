const {scrapeXFeed, isXURL, scrapeXTopNews} = require("./xscraper");
/**
 * REQUIRES 1GB TO RUN!
 * REQUIRES LONGER TIMEOUT
 * Scrapes feed for new posts and publishes the urls
 * @param {string} feedUrl to start from, if null does not renavigate
 * @return {Promise<void>}
 * */
const scrapeFeed = async function(feedUrl) {
  if (isXURL(feedUrl)) {
    await scrapeXFeed(feedUrl);
    return;
  } else {
    throw new Error("Platform not supported for scraping.");
  }
};

/**
 * REQUIRES 1GB TO RUN!
 * REQUIRES LONGER TIMEOUT
 * Scrapes a feed of feeds
 * @param {string} feedUrl - The URL to scrape
 * @return {Promise<void>}
 */
const scrapeMetaFeed = async function(feedUrl) {
  if (isXURL(feedUrl)) {
    // feedUrl is also default for scrapeXTopNews
    await scrapeXTopNews(feedUrl);
    return;
  }
  throw new Error("Not implemented");
};

/**
 * Fetches base platform icon (favicon or similar) from a given URL
 * @param {string} domain - The URL to fetch the base platform image from
 * @return {Promise<string>} - The platform image URL
 */
const getImageFromURL = async function(domain) {
  const _url = `https://www.google.com/s2/favicons?sz=256&domain_url=${domain}`;
  return _url;
};

module.exports = {
  scrapeFeed,
  scrapeMetaFeed,
  getImageFromURL,
};
