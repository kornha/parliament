const {onSchedule} = require("firebase-functions/v2/scheduler");
const {publishMessage, SHOULD_SCRAPE_FEED} = require("./pubsub");
const {logger} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defaultConfig} = require("./functions");
const {authenticate} = require("./auth");


/**
 * Called every hour
 * @return {Promise<void>}
 * */
async function onHour() {
  logger.info("Starting hourly trigger...");
  await publishMessage(SHOULD_SCRAPE_FEED, {
    link: "https://x.com/explore/tabs/news",
    metaFeed: true,
  });
}

// Export the scheduled function
exports.onHourTrigger = onSchedule("every hour", async (event) => {
  await onHour();
});

// add onHour cloud callable function
exports.triggerTimeFunction = onCall(
    {
      ...defaultConfig,
    },
    async (request) => {
      authenticate(request);
      const schedule = request.data.schedule;
      if (schedule === "every hour") {
        await onHour();
      } else {
        throw new HttpsError("invalid-argument", "Invalid schedule.");
      }

      return Promise.resolve();
    },
);
