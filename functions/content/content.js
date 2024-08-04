const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {logger} = require("firebase-functions/v2");
const {authenticate} = require("../common/auth");
const {gbConfig, gbConfig5Min} = require("../common/functions");
const {urlToSourceType} = require("../common/utils");
const {processXLinks, scrapeXTopNews, scrapeXFeed} = require("./xscraper");
const {SHOULD_SCRAPE_FEED} = require("../common/pubsub");

// ////////////////////////////
// API's
// ////////////////////////////

/**
 * Calls process Link for the given sourceType
 * @param {string} data.link
 * */
const onLinkPaste = onCall(
    {...gbConfig},
    async (request) => {
      authenticate(request);
      const data = request.data;
      if (!data.link) {
        throw new HttpsError("invalid-argument", "No link provided.");
      }

      const sourceType = urlToSourceType(data.link);

      if (!sourceType) {
        throw new HttpsError("invalid-argument", "Platform not supported.");
      }

      let pids = [];
      if (sourceType == "x") {
        pids = await processXLinks([data.link], request.auth.uid);
      } else {
        throw new HttpsError("invalid-argument", "Platform not supported.");
      }

      if (!pids.length) {
        throw new HttpsError("invalid-argument", "No post created.");
      }

      return pids[0];
    },
);

/**
 * Scrapes X feed
 * */
const onScrapeX = onCall(
    {
      ...gbConfig5Min,
    },
    async (request) => {
      authenticate(request);

      // await scrapeXFeed("...");
      await scrapeXTopNews();
      return;
    },
);

/**
 * Pubsub to Scrape X feed
 */
const onScrapeFeed = onMessagePublished(
    {
      ...gbConfig5Min,
      topic: SHOULD_SCRAPE_FEED,
    },
    async (event) => {
      const message = event.data.message;

      if (!message.json.link) {
        logger.error("No link provided.");
        return;
      }

      await scrapeXFeed(message.json.link);

      return;
    },
);

// ////////////////////////////
// Helpers
// ////////////////////////////

module.exports = {
  onLinkPaste,
  onScrapeX,
  onScrapeFeed,
};
