const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defaultConfig} = require("./functions");
const {authenticate} = require("./auth");
const {scrapeNewsAccounts} = require("../content/content");


/**
 * Called every hour
 * @return {Promise<void>}
 * */
async function onHour() {
  logger.info("Starting hourly trigger...");
  await scrapeNewsAccounts();
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
      } else {
        throw new HttpsError("invalid-argument", "Invalid schedule.");
      }

      return Promise.resolve();
    },
);
