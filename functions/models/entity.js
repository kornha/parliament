const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig, gbConfig} = require("../common/functions");
const {publishMessage,
  ENTITY_SHOULD_CHANGE_IMAGE} = require("../common/pubsub");
const {logger} = require("firebase-functions/v2");
const {getEntityImage} = require("../content/xscraper");
const {updateEntity} = require("../common/database");
const {Timestamp} = require("firebase-admin/firestore");

//
// Firestore
//
exports.onEntityUpdate = onDocumentWritten(
    {
      document: "entities/{eid}",
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
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
    },
);

//
// PubSub
//

/**
 * Sets the entity URL
 * Requires 1GB to run
 * @param {Entity} message the message.
 */
exports.onEntityShouldChangeImage = onMessagePublished(
    {
      topic: ENTITY_SHOULD_CHANGE_IMAGE,
      ...gbConfig,
    },
    async (event) => {
      const entity = event.data.message.json;
      if (!entity) {
        logger.error("No entity provided.");
        return;
      }

      const image = await getEntityImage(entity.handle, entity.sourceType);
      if (!image) {
        logger.error(`No image found for entity ${entity.handle}, 
          ${entity.sourceType}`);
        return;
      }

      await updateEntity(entity.eid, {
        photoURL: image,
        updatedAt: Timestamp.now().toMillis(),
      });

      return Promise.resolve();
    },
);
