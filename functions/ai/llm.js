const {defineSecret} = require("firebase-functions/params");
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const functions = require("firebase-functions");


exports.getOpenApiKey = function() {
  functions.logger.info(`key exists: ${OPENAI_API_KEY.value()}`);

  return OPENAI_API_KEY.value();
};
