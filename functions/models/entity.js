const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig, scrapeConfig} = require("../common/functions");
const {publishMessage,
  ENTITY_SHOULD_CHANGE_IMAGE,
  POST_CHANGED_ENTITY,
  ENTITY_CHANGED_POSTS,
  ENTITY_CHANGED_STATEMENTS,
  STATEMENT_CHANGED_ENTITIES,
  ENTITY_CHANGED_CONFIDENCE,
  STATEMENT_SHOULD_CHANGE_CONFIDENCE,
  ENTITY_SHOULD_CHANGE_CONFIDENCE,
  ENTITY_SHOULD_CHANGE_BIAS,
  ENTITY_CHANGED_BIAS,
  STATEMENT_SHOULD_CHANGE_BIAS,
  ENTITY_SHOULD_CHANGE_STATS,
} = require("../common/pubsub");
const {logger} = require("firebase-functions/v2");
const {getEntityImage} = require("../content/xscraper");
const {updateEntity, getAllStatementsForEntity,
  getAllPostsForEntity} = require("../common/database");
const {Timestamp} = require("firebase-admin/firestore");
const {handleChangedRelations,
  calculateAverageStats} = require("../common/utils");
const _ = require("lodash");
const {onEntityShouldChangeConfidence} = require("../ai/confidence");
const {onEntityShouldChangeBias} = require("../ai/bias");

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
      const _delete = before && !after;
      const _update = before && after;

      // can revisit if this logic is right
      // for some reason after.handle was null on create
      if (
        _create && !after.photoURL && after.handle ||
        _update && before.handle !== after.handle
      ) {
        publishMessage(ENTITY_SHOULD_CHANGE_IMAGE, after);
      }

      if (
        (_create && !_.isEmpty(after.pids)) ||
        (_update && !_.isEqual(before.pids, after.pids)) ||
        (_delete && !_.isEmpty(before.pids))
      ) {
        await publishMessage(ENTITY_CHANGED_POSTS, {before, after});
        await publishMessage(ENTITY_SHOULD_CHANGE_STATS,
            {eid: after?.eid || before?.eid});
      }

      if (
        (_create && !_.isEmpty(after.stids)) ||
        (_update && !_.isEqual(before.stids, after.stids)) ||
        (_delete && !_.isEmpty(before.stids))
      ) {
        await publishMessage(ENTITY_CHANGED_STATEMENTS,
            {before: before, after: after});
        await publishMessage(ENTITY_SHOULD_CHANGE_CONFIDENCE,
            {eid: after?.eid || before?.eid});
        await publishMessage(ENTITY_SHOULD_CHANGE_BIAS,
            {eid: after?.eid || before?.eid});
      }

      //
      // Confidence and Bias
      //

      if (
        _create && after.confidence ||
        _update && before.confidence !== after.confidence ||
        _delete && before.confidence
      ) {
        await publishMessage(ENTITY_CHANGED_CONFIDENCE,
            {before: before, after: after});
      }

      if (
        _create && after.adminConfidence ||
        _update && before.adminConfidence !== after.adminConfidence ||
        _delete && before.adminConfidence
      ) {
        await publishMessage(ENTITY_SHOULD_CHANGE_CONFIDENCE,
            {eid: after?.eid || before?.eid});
      }

      if (
        _create && after.bias ||
        _update && before.bias !== after.bias ||
        _delete && before.bias
      ) {
        await publishMessage(ENTITY_CHANGED_BIAS,
            {before: before, after: after});
      }

      if (
        _create && after.adminBias ||
        _update && before.adminBias !== after.adminBias ||
        _delete && before.adminBias
      ) {
        await publishMessage(ENTITY_SHOULD_CHANGE_BIAS,
            {eid: after?.eid || before?.eid});
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
      ...scrapeConfig, // currently this heavy config, we get images by scraping
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

// ////////////////////////////////////////////////////////////////////////////
// Confidence
// ////////////////////////////////////////////////////////////////////////////

exports.onEntityShouldChangeConfidence = onMessagePublished(
    {
      topic: ENTITY_SHOULD_CHANGE_CONFIDENCE,
      ...defaultConfig,
    },
    async (event) => {
      const eid = event.data.message.json.eid;
      logger.info(`onEntityShouldChangeConfidence ${eid}`);
      if (!eid) {
        return Promise.resolve();
      }

      await onEntityShouldChangeConfidence(eid);

      return Promise.resolve();
    },
);

exports.onEntityChangedConfidence = onMessagePublished(
    {
      topic: ENTITY_CHANGED_CONFIDENCE,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      logger.info(`onEntityChangedConfidence ${after?.eid || before?.eid}`);
      const eid = after?.eid || before?.eid;
      if (!eid) {
        return Promise.resolve();
      }

      const statements = await getAllStatementsForEntity(eid);
      if (!statements) {
        logger.warn(`No statements found for entity ${eid}`);
        return Promise.resolve();
      }

      for (const statement of statements) {
        if (statement.type == "claim") {
          await publishMessage(STATEMENT_SHOULD_CHANGE_CONFIDENCE,
              {stid: statement.stid});
        }
      }

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Bias
// ////////////////////////////////////////////////////////////////////////////

exports.onEntityShouldChangeBias = onMessagePublished(
    {
      topic: ENTITY_SHOULD_CHANGE_BIAS,
      ...defaultConfig,
    },
    async (event) => {
      const eid = event.data.message.json.eid;
      logger.info(`onEntityShouldChangeBias ${eid}`);
      if (!eid) {
        return Promise.resolve();
      }

      await onEntityShouldChangeBias(eid);

      return Promise.resolve();
    },
);

exports.onEntityChangedBias = onMessagePublished(
    {
      topic: ENTITY_CHANGED_BIAS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      logger.info(`onEntityChangedBias ${after?.eid || before?.eid}`);
      const eid = after?.eid || before?.eid;
      if (!eid) {
        return Promise.resolve();
      }

      const statements = await getAllStatementsForEntity(eid);
      if (!statements) {
        logger.warn(`No statements found for entity ${eid}`);
        return Promise.resolve();
      }

      for (const statement of statements) {
        if (statement.type == "opinion") {
          await publishMessage(STATEMENT_SHOULD_CHANGE_BIAS,
              {stid: statement.stid});
        }
      }

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Stats
// ////////////////////////////////////////////////////////////////////////////

exports.onEntityShouldChangeStats = onMessagePublished(
    {
      topic: ENTITY_SHOULD_CHANGE_STATS,
      ...defaultConfig,
    },
    async (event) => {
      const eid = event.data.message.json.eid;
      logger.info(`onEntityShouldChangeStats ${eid}`);
      if (!eid) {
        return Promise.resolve();
      }

      const posts = await getAllPostsForEntity(eid);
      if (_.isEmpty(posts)) {
        logger.warn(`No posts found for entity ${eid}`);
        return Promise.resolve();
      }

      const stats = calculateAverageStats(posts);
      if (_.isEmpty(stats)) {
        return Promise.resolve();
      }

      logger.info(`Updating entity stats`);
      await updateEntity(eid, stats, 5); // might not exist so skiperror

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Sync
// ////////////////////////////////////////////////////////////////////////////

/**
 * 'TXN' - from Post.js
 * Updates the Entities that this Post is part of
 * @param {Post} before
 * @param {Post} after
 */
exports.onPostChangedEntity = onMessagePublished(
    {
      topic: POST_CHANGED_ENTITY,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;

      // NOTE: When a post is deleted and that post
      // has statements, we don't delete the statements
      // since its expensive to compute if that statement
      // is mentioned by another post.
      await handleChangedRelations(before, after, "eid",
          updateEntity, "pid", "pids", {}, "oneToMany");
      return Promise.resolve();
    },
);

/**
 * 'TXN' - from Statements.js
 * Updates the Entities that this Statement is part of
 * @param {Statement} before
 * @param {Statement} after
 */
exports.onStatementChangedEntities = onMessagePublished(
    {
      topic: STATEMENT_CHANGED_ENTITIES,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      await handleChangedRelations(before, after, "eids",
          updateEntity, "stid", "stids");
      return Promise.resolve();
    },
);
