/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const {incrementMessages} = require("./rooms");
const {Timestamp} = require("firebase-admin/firestore");


//
// Db triggers
//

exports.onMessageChange = functions.firestore
    .document("messages/{messageId}")
    .onWrite((change) => {
      const message = change.after.data();
      if (message) {
        if (["delivered", "seen"].includes(message.status)) {
          return null;
        } else {
          incrementMessages(message.roomId);
          return change.after.ref.update({
            status: "delivered",
            // this is technically overwriting local set timestamp
            createdAt: Timestamp.now().toMillis(),
          });
        }
      } else {
        return null;
      }
    });

