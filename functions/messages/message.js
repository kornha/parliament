/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const {incrementRoomMessages} = require("./room");
const {Timestamp} = require("firebase-admin/firestore");

//
// Db triggers
//

exports.onMessageChange = functions.firestore
    .document("/{collectionId}/{parentId}/rooms/{rid}/messages/{mid}")
    .onWrite((change, context) => {
      const message = change.after.data();
      const collectionId = context.params.collectionId;
      const parentId = context.params.parentId;
      const rid = context.params.rid;
      if (message) {
        if (["delivered", "seen"].includes(message.status)) {
          return null;
        } else {
          incrementRoomMessages(rid, parentId, collectionId);
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

