// NOTE! We use v1 here since v2 does not support auth triggers
// https://github.com/firebase/firebase-functions/issues/1383
const functions = require("firebase-functions");
//
const {createUser, updateUser, deleteUser} = require("../common/database");
const {FieldValue} = require("firebase-admin/firestore");
const {authenticate} = require("../common/auth");
const {defaultConfig} = require("../common/functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
// const {computeBias} = require("../ai/bias");


//
// Db triggers
//

exports.onAuthUserCreate = functions.runWith(defaultConfig)
    .auth.user().onCreate((user) => {
      const userDoc = {
        uid: user.uid,
        email: user.email,
        username: null,
        phoneNumber: user.phoneNumber,
        photoURL: user.photoURL,
        elo: 1500,
      };
      return createUser(userDoc);
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


