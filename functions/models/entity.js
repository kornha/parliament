/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig, gbConfig} = require("../common/functions");
const {getEntityByHandle,
  createEntity, updateEntity} = require("../common/database");
const {v4} = require("uuid");
const {Timestamp} = require("firebase-admin/firestore");
const {retryAsyncFunction} = require("../common/utils");
const {publishMessage,
  ENTITY_SHOULD_CHANGE_IMAGE} = require("../common/pubsub");
const {getEntityImage} = require("../content/scraper");


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
      //   const _update = before && after;

      if (_create && !after.photoURL) {
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
        functions.logger.error("No image found for entity.");
        return;
      }

      await updateEntity(entity.eid, {photoURL: image});

      return Promise.resolve();
    });

//
// helpers
//

/**
 * Finds or creates an entity by handle.
 * @param {string} creatorEntity the creator entity handle.
 * @param {string} sourceType the source type.
 * @return {string} the entity id.
 */
exports.findCreateEntity = async function(creatorEntity, sourceType) {
  if (!creatorEntity) {
    functions.logger.error("No creatorEntity provided.");
    return;
  }

  if (!sourceType) {
    functions.logger.error("No sourceType provided.");
    return;
  }
  // check if first char is @
  // need to see if this is needed for other platforms
  if (creatorEntity[0] == "@" && sourceType == "x") {
    creatorEntity = creatorEntity.slice(1);
  }

  const entity = await retryAsyncFunction(() =>
    getEntityByHandle(creatorEntity), 2, 1000, false);

  if (entity) {
    return entity.eid;
  }

  const eid = v4();
  const newEntity = {
    eid: eid,
    handle: creatorEntity,
    sourceType: sourceType,
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
  };
  await retryAsyncFunction(() => createEntity(newEntity));
  return eid;
};
