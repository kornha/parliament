const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig, mediumConfig, scrapeConfig} =
  require("../common/functions");
const {publishMessage, publishRipple,
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
  ENTITY_SHOULD_CHANGE_PLATFORM,
  PLATFORM_CHANGED_ENTITIES,
  ENTITY_CHANGED_STATS,
  POST_SHOULD_CHANGE_VIRALITY,
} = require("../common/pubsub");
const {logger} = require("firebase-functions/v2");
const {getEntityImage} = require("../content/xscraper");
const {updateEntity, getAllStatementsForEntity,
  getAllPostsForEntity,
  getPlatform,
  deleteAttribute,
  getEntity,
  getAverages} = require("../common/database");
const {Timestamp} = require("firebase-admin/firestore");
const {handleChangedRelations,
  getSocialScore, movedBeyond, STATS_REFRESH_MS} = require("../common/utils");
const _ = require("lodash");
const {onEntityShouldChangeConfidence,
  confidenceDidCrossThreshold} = require("../ai/confidence");
const {onEntityShouldChangeBias,
  biasDidCrossThreshold, getDistance} = require("../ai/bias");

// Ripple damping: an entity value recompute rebroadcasts to every statement
// of the entity, so sub-epsilon wiggles multiply into hundreds of statement
// recomputes. Only meaningful moves (or threshold crossings) propagate.
const CONFIDENCE_RIPPLE_EPS = 0.01;
const BIAS_RIPPLE_EPS_DEGREES = 2;
const {didChangeStats} = require("../ai/newsworthiness");

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
        await publishMessage(ENTITY_SHOULD_CHANGE_IMAGE, after);
      }

      if (
        (_create && !_.isEmpty(after.pids)) ||
        (_update && !_.isEqual(before.pids, after.pids)) ||
        (_delete && !_.isEmpty(before.pids))
      ) {
        await publishMessage(ENTITY_CHANGED_POSTS, {before, after});
        await publishMessage(ENTITY_SHOULD_CHANGE_STATS,
            {eid: after?.eid || before?.eid});

        if (_create && !after.plid || _update && !after.plid) {
          await publishMessage(ENTITY_SHOULD_CHANGE_PLATFORM,
              {eid: after?.eid || before?.eid});
        }
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
        // forward the persisted ripple depth so the guard survives this
        // document-trigger boundary (see confidence.js confidenceDepth)
        await publishMessage(ENTITY_CHANGED_CONFIDENCE,
            {before: before, after: after, depth: after?.confidenceDepth});
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

      // stats

      if (didChangeStats(_create, _update, _delete, before, after, true)) {
        await publishMessage(ENTITY_CHANGED_STATS,
            {plid: after?.plid || before?.plid});
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

      const platform = await getPlatform(entity.plid);
      if (!platform) {
        logger.error(`No platform found for entity ${entity.handle}`);
        return;
      }

      // Not all entities have images
      const image = await getEntityImage(entity.handle, platform);

      if (image) {
        await updateEntity(entity.eid, {
          photoURL: image,
          updatedAt: Timestamp.now().toMillis(),
        });
      }

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Confidence
// ////////////////////////////////////////////////////////////////////////////

exports.onEntityShouldChangeConfidence = onMessagePublished(
    {
      topic: ENTITY_SHOULD_CHANGE_CONFIDENCE,
      ...mediumConfig,
    },
    async (event) => {
      const {eid, depth} = event.data.message.json;
      logger.info(`onEntityShouldChangeConfidence ${eid} depth: ${depth}`);
      if (!eid) {
        return Promise.resolve();
      }

      await onEntityShouldChangeConfidence(eid, depth);

      return Promise.resolve();
    },
);

exports.onEntityChangedConfidence = onMessagePublished(
    {
      topic: ENTITY_CHANGED_CONFIDENCE,
      ...mediumConfig, // reads all statements of the entity
    },
    async (event) => {
      const {before, after, depth} = event.data.message.json;
      logger.info(`onEntityChangedConfidence ${after?.eid || before?.eid}` +
          ` depth: ${depth}`);
      const eid = after?.eid || before?.eid;
      if (!eid) {
        return Promise.resolve();
      }

      if (!confidenceDidCrossThreshold(before, after) &&
        !movedBeyond(before?.confidence, after?.confidence,
            CONFIDENCE_RIPPLE_EPS)) {
        return Promise.resolve();
      }

      const statements = await getAllStatementsForEntity(eid);
      if (!statements) {
        logger.warn(`No statements found for entity ${eid}`);
        return Promise.resolve();
      }

      for (const statement of statements) {
        if (statement.type == "claim") {
          await publishRipple(STATEMENT_SHOULD_CHANGE_CONFIDENCE,
              {stid: statement.stid}, depth);
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
      ...mediumConfig,
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
      ...mediumConfig, // reads all statements of the entity
    },
    async (event) => {
      const {before, after, depth} = event.data.message.json;
      logger.info(`onEntityChangedBias ${after?.eid || before?.eid}` +
          ` depth: ${depth}`);
      const eid = after?.eid || before?.eid;
      if (!eid) {
        return Promise.resolve();
      }

      const biasMoved = before?.bias != null && after?.bias != null &&
        getDistance(before.bias, after.bias) >= BIAS_RIPPLE_EPS_DEGREES;
      if (!biasDidCrossThreshold(before, after) && !biasMoved) {
        return Promise.resolve();
      }

      const statements = await getAllStatementsForEntity(eid);
      if (!statements) {
        logger.warn(`No statements found for entity ${eid}`);
        return Promise.resolve();
      }

      for (const statement of statements) {
        if (statement.type == "opinion") {
          await publishRipple(STATEMENT_SHOULD_CHANGE_BIAS,
              {stid: statement.stid}, depth);
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
      if (!eid) {
        return Promise.resolve();
      }
      logger.info(`onEntityShouldChangeStats ${eid}`);


      const entity = await getEntity(eid);
      if (!entity) {
        logger.warn(`No entity found for ${eid}`);
        return Promise.resolve();
      }

      const now = Timestamp.now().toMillis();
      if (now - (entity.lastStatsAt ?? 0) < STATS_REFRESH_MS) {
        return Promise.resolve();
      }

      // Claim the window before the aggregation so concurrent messages
      // skip instead of double-computing.
      await updateEntity(eid, {lastStatsAt: now}, 5);

      const stats = await getAverages("posts", "eid", eid,
          ["likes", "reposts", "replies", "bookmarks", "views"]);
      // can be {} if no stats in child posts
      if (stats != null && !_.isEmpty(stats)) {
        // do this here since getAverages is limited to 5
        stats.avgSocialScore = getSocialScore({
          likes: stats.avgLikes,
          reposts: stats.avgReposts,
          replies: stats.avgReplies,
          bookmarks: stats.avgBookmarks,
          views: stats.avgViews,
        });
        await updateEntity(eid, stats, 5); // might not exist so skiperror
      }

      return Promise.resolve();
    });

exports.onEntityChangedStats = onMessagePublished(
    {
      topic: ENTITY_CHANGED_STATS,
      ...defaultConfig, // fetches at most 20 posts (see below)
    },
    async (event) => {
      const eid = event.data.message.json.eid;
      if (!eid) {
        return Promise.resolve();
      }
      logger.info(`onEntityChangedStats: ${eid}`);

      // technically this is not a prerequisite for a post changing virality
      // however since the post virality needs to update
      // this is a useful cadence to do so
      // this also double triggers with entity stats
      const posts = await getAllPostsForEntity(eid, null, 20);
      if (_.isEmpty(posts)) {
        logger.warn(`No posts for entity ${eid}`);
        return Promise.resolve();
      }

      for (const post of posts) {
        await publishMessage(POST_SHOULD_CHANGE_VIRALITY,
            {pid: post.pid});
      }

      return Promise.resolve();
    });

// ////////////////////////////////////////////////////////////////////////////
// Platform
// ////////////////////////////////////////////////////////////////////////////

exports.onEntityShouldChangePlatform = onMessagePublished(
    {
      topic: ENTITY_SHOULD_CHANGE_PLATFORM,
      ...defaultConfig,
    },
    async (event) => {
      const eid = event.data.message.json.eid;
      logger.info(`onEntityShouldChangePlatform ${eid}`);
      if (!eid) {
        return Promise.resolve();
      }

      const posts = await getAllPostsForEntity(eid, null, 25);
      if (_.isEmpty(posts)) {
        logger.warn(`No posts found for entity ${eid}`);
        return Promise.resolve();
      }

      const platforms = _.uniq(posts.map((post) => post.plid));
      if (_.isEmpty(platforms)) {
        logger.warn(`No platforms found for entity ${eid}`);
        return Promise.resolve();
      }

      if (platforms.length > 1) {
        logger.warn(`Multiple platforms found for entity ${eid}`);
      }

      const plid = platforms[0];

      await updateEntity(eid, {plid: plid}, 5); // might not exist so skiperror

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

/**
 * 'TXN' - from platform.js
 * Updates the Entities that this Platform is part of
 * @param {Platform} before
 * @param {Platform} after
 */
exports.onPlatformChangedEntities = onMessagePublished(
    {
      topic: PLATFORM_CHANGED_ENTITIES, // Make sure to define this topic
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      if (before && !after) {
        await deleteAttribute("entities", "plid", "==", before.plid);
      }
      return Promise.resolve();
    },
);
