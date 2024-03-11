const functions = require("firebase-functions");
const {createUser, updateUser, deleteUser} = require("../common/database");
const {FieldValue} = require("firebase-admin/firestore");
const {authenticate} = require("../common/auth");
// const {computeBias} = require("../ai/bias");


//
// Db triggers
//

exports.onAuthUserCreate = functions.auth.user().onCreate((user) => {
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

exports.onAuthUserDelete = functions.auth.user().onDelete((user) => {
  return deleteUser(user.uid);
});

//
// API's
//

// api to setUsername, since we need to check uniqueness
exports.setUsername = functions.https.onCall(async (data, context) => {
  authenticate(context);

  if (!data.username) {
    throw new functions.https.HttpsError(
        "invalid-argument", "No username provided.");
  }
  return updateUser(context.auth.uid, {username: data.username});
});

//
// helpers
//
exports.applyEloScores = async function(eloScore) {
  if (!eloScore || !eloScore.values || eloScore.values.size == 0) {
    return;
  }
  for (const uid in eloScore.values) {
    // some JS BS to check if the key exists
    if (Object.prototype.hasOwnProperty.call(eloScore.values, uid)) {
      const delta = eloScore.values[uid];
      updateUser(uid, {
        elo: FieldValue.increment(delta),
      });
    }
  }
};


