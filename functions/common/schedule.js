const {onSchedule} = require("firebase-functions/v2/scheduler");
const {publishMessage, SHOULD_SCRAPE_FEED} = require("./pubsub");
const logger = require("firebase-functions/logger");

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

exports.onHour = onHour;
