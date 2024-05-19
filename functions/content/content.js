const functions = require("firebase-functions");
const {authenticate} = require("../common/auth");
const {gbConfig, gbConfig5Min} = require("../common/functions");
const {urlToSourceType} = require("../common/utils");
const {processXLinks, scrapeXFeed} = require("./xscraper");
// ////////////////////////////
// API's
// ////////////////////////////

/**
 * calls process Link for the given sourceType
 * @param {string} data.link
 * */
const onLinkPaste = functions.runWith(gbConfig)
    .https.onCall(async (data, context) => {
      authenticate(context);
      if (!data.link) {
        throw new functions.https
            .HttpsError("invalid-argument", "No link provided.");
      }

      const sourceType = urlToSourceType(data.link);

      if (!sourceType) {
        throw new functions.https
            .HttpsError("invalid-argument", "Platform not supported.");
      }

      let pids = [];
      if (sourceType == "x") {
        pids = await processXLinks([data.link], context.auth.uid);
      } else {
        throw new functions.https
            .HttpsError("invalid-argument", "Platform not supported.");
      }

      if (!pids.length) {
        throw new functions.https
            .HttpsError("invalid-argument", "No post created.");
      }

      return Promise.resolve(pids[0]);
    });

/**
 * Scrapes X feed
 * */
const onScrapeX = functions.runWith(gbConfig5Min)
    .https.onCall(async (data, context) => {
      await scrapeXFeed();
      return Promise.resolve();
    });


// ////////////////////////////
// Helpers
// ////////////////////////////

module.exports = {
  onLinkPaste,
  onScrapeX,
};
