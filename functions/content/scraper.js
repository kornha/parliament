const {scrapeXFeed, isXURL} = require("./xscraper");
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
  getImageFromURL,
};
