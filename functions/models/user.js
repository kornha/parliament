// NOTE! We use v1 here since v2 does not support auth triggers
// https://github.com/firebase/firebase-functions/issues/1383
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
//
const {createUser, updateUser, deleteUser} = require("../common/database");
const {FieldValue} = require("firebase-admin/firestore");
const {authenticate} = require("../common/auth");
const {defaultConfig} = require("../common/functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
// const {computeBias} = require("../ai/bias");
const {defineSecret} = require("firebase-functions/params");
const _adminEmailKey = defineSecret("ADMIN_EMAIL_KEY");


//
// Db triggers
//

exports.onAuthUserCreate = functions
    .runWith(defaultConfig)
    .auth.user()
    .onCreate(async (user) => {
      const userDoc = {
        uid: user.uid,
        email: user.email,
        username: null,
        phoneNumber: user.phoneNumber,
        photoURL: user.photoURL,
        elo: 1500,
      // Remove the role from Firestore document
      // since we're using custom claims
      // role: "user",
      };

      // Determine the role based on the email
      let role = "user";
      if (user.email === _adminEmailKey.value()) {
        role = "admin";
      }

      // Set custom claims
      await admin.auth().setCustomUserClaims(user.uid, {role: role});

      // Create the user document in Firestore
      await createUser(userDoc);

      // Optional: Force token refresh (in client-side code)
      // Return a success message or perform additional actions if needed
      return null;
    });

exports.onAuthUserDelete = functions.runWith(defaultConfig)
    .auth.user().onDelete((user) => {
      return deleteUser(user.uid);
    });

//
// API's
//

exports.setUsernameV2 = onCall({...defaultConfig},
    async (request) => {
      authenticate(request);

      const data = request.data;
      if (!data.username) {
        throw new HttpsError("invalid-argument", "No username provided.");
      }
      return updateUser(context.auth.uid, {username: data.username});
    },
);

//
// helpers
//

exports.applyEloScores = async function(eloScore) {
  if (!eloScore || !eloScore.values || eloScore.values.size === 0) {
    return;
  }
  for (const uid in eloScore.values) {
    if (Object.prototype.hasOwnProperty.call(eloScore.values, uid)) {
      const delta = eloScore.values[uid];
      updateUser(uid, {
        elo: FieldValue.increment(delta),
      });
    }
  }
};


