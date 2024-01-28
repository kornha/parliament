/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {generatePostAiFields} = require("../ai/post_ai");
const {createNewRoom} = require("../common/database");
const {FieldValue} = require("firebase-admin/firestore");
const admin = require("firebase-admin");

exports.onPostCreate = functions.firestore
    .document("posts/{pid}")
    .onCreate((change) => {
      generatePostAiFields(change.data());
      createNewRoom(change.data().pid, "post");
    });

exports.onPostUpdate = functions.firestore
    .document("posts/{pid}")
    .onUpdate((change) => {
      const before = change.before.data();
      const after = change.after.data();
      if (before.description != after.description ||
        before.title != after.title) {
        generatePostAiFields(after);
      }
    });

exports.incrementPostMessages = function(pid) {
  return admin.firestore()
      .collection("posts")
      .doc(pid)
      .update({
        messageCount: FieldValue.increment(1),
      });
};
