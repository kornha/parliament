const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {logger} = require("firebase-functions/v2");
const {authenticate} = require("../common/auth");
const {scrapeConfig} = require("../common/functions");
const {SHOULD_SCRAPE_FEED} = require("../common/pubsub");
const {findCreatePlatform} = require("../common/database");
const {scrapeFeed} = require("./scraper");
const {getPlatformType} = require("../common/utils");
const {processLinks, processItems} = require("./contentProcessor");
const {scrapeXTopNews} = require("./xscraper");
const {getTopNewsPosts} = require("./news");

// ////////////////////////////
// API's
// ////////////////////////////

/**
 * Calls process Link for the given platform
 * @param {string} data.link
 * */
const onLinkPaste = onCall(
    {
      ...scrapeConfig,
    },
    async (request) => {
      authenticate(request);
      const data = request.data;
      if (!data.link) {
        throw new HttpsError("invalid-argument", "No link provided.");
      }

      const platform = await findCreatePlatform(data.link);

      const platformType = getPlatformType(platform);

      const pids = await processLinks([data.link],
          platformType, request.auth.uid);

      if (!pids.length) {
        throw new HttpsError("invalid-argument", "No post created.");
      }

      return pids[0];
    },
);

/**
 * Scrapes X feed
 * */
const fetchNews = onCall(
    {
      ...scrapeConfig,
    },
    async (request) => {
      authenticate(request);
      const platformType = request.data.platformType;
      if (platformType === "x") {
        await scrapeXTopNews();
        return {message: "Top news scraping initiated for X platform."};
      } else if (platformType === "news") {
        // For News, fetch articles and process them
        const topPosts = await getTopNewsPosts(5);
        const pids = await processItems(topPosts, platformType);
        return pids;
      } else {
        throw new Error(`Unsupported platform type: ${platformType}`);
      }
    },
);

/**
 * Pubsub to process a link
 * called typically from scraping environments
 */
const onShouldProcessLink = onMessagePublished(
    {
      ...scrapeConfig,
      topic: "onShouldProcessLink",
    },
    async (event) => {
      const message = event.data.message;

      if (!message.json.link) {
        logger.error("No link provided.");
        return;
      }

      const platform = await findCreatePlatform(message.json.link);

      const platformType = getPlatformType(platform);

      await processLinks([message.json.link],
          platformType, message.json.poster);

      return;
    },
);

/**
 * Pubsub to Scrape X feed
 */
const onScrapeFeed = onMessagePublished(
    {
      ...scrapeConfig,
      topic: SHOULD_SCRAPE_FEED,
    },
    async (event) => {
      const message = event.data.message;

      if (!message.json.link) {
        logger.error("No link provided.");
        return;
      }

      await scrapeFeed(message.json.link);

      return;
    },
);

// ////////////////////////////
// Helpers
// ////////////////////////////

module.exports = {
  onLinkPaste,
  fetchNews,
  onScrapeFeed,
  onShouldProcessLink,
};
