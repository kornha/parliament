const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.onAuthUserCreate = functions.auth.user().onCreate((user) => {
  const userDoc = {
    uid: user.uid,
    email: user.email,
    username: null,
    phoneNumber: user.phoneNumber,
    photoURL: user.photoURL,
  };
  return admin
      .firestore()
      .collection("users")
      .doc(user.uid)
      .set(userDoc)
      .then((writeResult) => {
        functions.logger.info("User Created result:", writeResult);
        return;
      })
      .catch((err) => {
        functions.logger.error(err);
        return;
      });
});
