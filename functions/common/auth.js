const {HttpsError} = require("firebase-functions/v2/https");

// Function to check if a user is authenticated
exports.authenticate = function(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated",
        "You must be authenticated to make this request.");
  }
};
