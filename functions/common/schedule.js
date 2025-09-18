const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defaultConfig} = require("./functions");
const {authenticate} = require("./auth");
const {scrapeFeed} = require("../content/scraper");


/**
 * Called every hour
 * @return {Promise<void>}
 * */
async function onHour() {
  logger.info("Starting hourly trigger...");
  // await scrapeNewsAccounts();
}

/**
 * Called every 30 minutes
 * @return {Promise<void>}
 * */
async function onThirtyMinutes() {
  logger.info("Starting 30 minutes trigger...");
}

/**
 * Called every 15 minutes
 * @return {Promise<void>}
 * */
async function onFifteenMinutes() {
  logger.info("Starting 15 minutes trigger...");
}

/**
 * Called every 5 minutes
 * @return {Promise<void>}
 * */
async function onFiveMinutes() {
  logger.info("Starting 5 minutes trigger...");
  await scrapeFeed("https://x.com", 20);
}

// Export the scheduled function
exports.onHourTrigger = onSchedule("every hour",
    async (event) => {
      await onHour();
    });

exports.onThirtyMinutesTrigger = onSchedule("every 30 minutes",
    async (event) => {
      await onThirtyMinutes();
    });

exports.onFifteenMinutesTrigger = onSchedule("every 15 minutes",
    async (event) => {
      await onFifteenMinutes();
    });

exports.onFiveMinutesTrigger = onSchedule("every 5 minutes",
    async (event) => {
      await onFiveMinutes();
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
      } else if (schedule === "every 30 minutes") {
        await onThirtyMinutes();
      } else if (schedule === "every 15 minutes") {
        await onFifteenMinutes();
      } else if (schedule === "every 5 minutes") {
        await onFiveMinutes();
      } else {
        throw new HttpsError("invalid-argument", "Invalid schedule.");
      }

      return Promise.resolve();
    },
);
