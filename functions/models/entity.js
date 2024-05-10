/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig, gbConfig} = require("../common/functions");
const {publishMessage,
  ENTITY_SHOULD_CHANGE_IMAGE} = require("../common/pubsub");
const {getEntityImage} = require("../content/xscraper");
const {updateEntity} = require("../common/database");
const {Timestamp} = require("firebase-admin/firestore");

//
// Firestore
//
exports.onEntityUpdate = functions
    .runWith(defaultConfig)
    .firestore
    .document("entities/{eid}")
    .onWrite(async (change) => {
      const before = change.before.data();
      const after = change.after.data();
      if (!before && !after) {
        return Promise.resolve();
      }

      const _create = !before && after;
      //   const _delete = before && !after;
      const _update = before && after;

      // can revisit if this logic is right
      // for some reason after.handle was null on create
      if (_create && !after.photoURL && after.handle ||
        _update && before.handle !== after.handle
      ) {
        publishMessage(ENTITY_SHOULD_CHANGE_IMAGE, after);
      }


      return Promise.resolve();
    });

//
// PubSub
//

/**
 * Sets the entity URL
 * Requires 1GB to run
 * @param {Entity} message the message.
 */
exports.onEntityShouldChangeImage = functions
    .runWith(gbConfig)
    .pubsub
    .topic(ENTITY_SHOULD_CHANGE_IMAGE)
    .onPublish(async (message) => {
      const entity = message.json;
      if (!entity) {
        functions.logger.error("No entity provided.");
        return;
      }

      const image = await getEntityImage(entity.handle, entity.sourceType);
      if (!image) {
        functions.logger.error(`No image found for entity ${entity.handle}, 
          ${entity.sourceType}`);
        return;
      }

      await updateEntity(entity.eid, {
        photoURL: image,
        updatedAt: Timestamp.now().toMillis(),
      });

      return Promise.resolve();
    });


