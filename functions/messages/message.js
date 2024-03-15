/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const {incrementRoomMessages} = require("./room");
const {Timestamp} = require("firebase-admin/firestore");
const {defaultConfig} = require("../common/functions");

//
// Db triggers
//

exports.onMessageChange = functions.runWith(defaultConfig)
    .firestore
    .document("rooms/{rid}/messages/{mid}")
    .onWrite((change, context) => {
      const message = change.after.data();
      const rid = context.params.rid;
      if (message) {
        if (["delivered", "seen"].includes(message.status)) {
          return null;
        } else {
          incrementRoomMessages(rid, message.author.id);
          return change.after.ref.update({
            status: "delivered",
            // this is technically overwriting local set timestamp
            // can use updatedAt instead
            // but need to change DB..
            // for now keeping createdAt as the source of truth
            createdAt: Timestamp.now().toMillis(),
          });
        }
      } else {
        return null;
      }
    });

