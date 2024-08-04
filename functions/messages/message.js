/* eslint-disable require-jsdoc */
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {Timestamp} = require("firebase-admin/firestore");
const {incrementRoomMessages} = require("./room");
const {defaultConfig} = require("../common/functions");
const {logger} = require("firebase-functions");

//
// Db triggers
//

exports.onMessageChange = onDocumentWritten(
    {
      document: "rooms/{rid}/messages/{mid}",
      ...defaultConfig,
    },
    async (event) => {
      const message = event.data.after.data();
      const rid = event.params.rid;

      if (message) {
        if (["delivered", "seen"].includes(message.status)) {
          return null;
        } else {
          await incrementRoomMessages(rid, message.author.id);
          await event.data.after.ref.update({
            status: "delivered",
            createdAt: Timestamp.now().toMillis(),
          });
          logger.info(`Message in room ${rid} updated to delivered.`);
        }
      } else {
        logger.error(`No message data available for room ${rid}`);
        return null;
      }
    },
);

