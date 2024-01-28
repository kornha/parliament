const functions = require("firebase-functions");

// Function to check if a user is authenticated
exports.authenticate = function(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated",
        "You must be authenticated to make this request.");
  }
};
