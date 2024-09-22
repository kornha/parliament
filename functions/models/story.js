const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig} = require("../common/functions");
const {
  publishMessage,
  STORY_CHANGED_POSTS,
  STORY_CHANGED_STATEMENTS,
  STATEMENT_CHANGED_STORIES,
  POST_CHANGED_STORIES,
  STORY_SHOULD_CHANGE_STATS,
  STORY_SHOULD_CHANGE_PLATFORMS,
  PLATFORM_CHANGED_STORIES,
  STORY_SHOULD_CHANGE_NEWSWORTHINESS,
  STORY_SHOULD_CHANGE_BIAS,
  STORY_SHOULD_CHANGE_CONFIDENCE,
} = require("../common/pubsub");
const _ = require("lodash");
const {resetStoryVector} = require("../ai/story_ai");
const {updateStory, getAllPostsForStory,
  deleteAttribute} = require("../common/database");
const {handleChangedRelations} = require("../common/utils");
const {logger} = require("firebase-functions/v2");
const {didChangeStats,
  calculateAverageStats,
  onStoryShouldChangeNewsworthiness} = require("../ai/newsworthiness");
const {onStoryShouldChangeBias} = require("../ai/bias");
const {onStoryShouldChangeConfidence} = require("../ai/confidence");


exports.onStoryUpdate = onDocumentWritten(
    {
      document: "stories/{sid}",
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

      if (
        (_create && (after.title || after.description)) ||
        (_delete && (before.title || before.description)) ||
        (_update &&
          (before.title != after.title ||
          before.description != after.description))
      ) {
      // storyChangedContent
      }

      if (
        _create && !_.isEmpty(after.pids) ||
        _update && !_.isEqual(before.pids, after.pids) ||
        _delete && !_.isEmpty(before.pids)
      ) {
        await publishMessage(STORY_CHANGED_POSTS, {before, after});
        await publishMessage(STORY_SHOULD_CHANGE_STATS,
            {sid: after?.sid || before?.sid});

        if (_create && _.isEmpty(after.plids) ||
            _update && _.isEmpty(after.plids)
        ) {
          await publishMessage(STORY_SHOULD_CHANGE_PLATFORMS,
              {sid: after?.sid || before?.sid});
        }
      }

      if (
        (_create && !_.isEmpty(after.stids)) ||
        (_update && !_.isEqual(before.stids, after.stids)) ||
        (_delete && !_.isEmpty(before.stids))
      ) {
        await publishMessage(STORY_CHANGED_STATEMENTS, {before, after});
        await publishMessage(STORY_SHOULD_CHANGE_BIAS,
            {sid: after?.sid || before?.sid});
        await publishMessage(STORY_SHOULD_CHANGE_CONFIDENCE,
            {sid: after?.sid || before?.sid});
      }

      if (didChangeStats(_create, _update, _delete, before, after, true)) {
        await publishMessage(STORY_SHOULD_CHANGE_NEWSWORTHINESS,
            {sid: after?.sid || before?.sid});
      }

      if (
        _create && after.bias ||
        _update && before.bias != after.bias ||
        _delete && before.bias
      ) {
        await publishMessage(STORY_SHOULD_CHANGE_NEWSWORTHINESS,
            {sid: after?.sid || before?.sid});
      }

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// PubSub
// ////////////////////////////////////////////////////////////////////////////

/**
 * Called when a story changes its Posts
 * Regenerates the story vector via K means
 * Semi-duplicated logic from findStories
 * @param {string} sid
 * @return {Promise<void>}
 */
exports.onStoryShouldChangeVector = onMessagePublished(
    {
      topic: STORY_CHANGED_POSTS,
      ...defaultConfig,
    },
    async (event) => {
      const story = event.data.message.json.after;
      if (!story || !story.sid) {
      // noop if deleted
        return Promise.resolve();
      }

      await resetStoryVector(story.sid);

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Confidence
// ////////////////////////////////////////////////////////////////////////////

exports.onStoryShouldChangeConfidence = onMessagePublished(
    {
      topic: STORY_SHOULD_CHANGE_CONFIDENCE,
      ...defaultConfig,
    },
    async (event) => {
      const sid = event.data.message.json.sid;
      if (!sid) {
        return Promise.resolve();
      }
      logger.info(`onStoryShouldChangeConfidence ${sid}`);

      await onStoryShouldChangeConfidence(sid);

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Bias
// ////////////////////////////////////////////////////////////////////////////

exports.onStoryShouldChangeBias = onMessagePublished(
    {
      topic: STORY_SHOULD_CHANGE_BIAS,
      ...defaultConfig,
    },
    async (event) => {
      const sid = event.data.message.json.sid;
      if (!sid) {
        return Promise.resolve();
      }
      logger.info(`onStoryShouldChangeBias ${sid}`);

      await onStoryShouldChangeBias(sid);

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Stats
// ////////////////////////////////////////////////////////////////////////////

exports.onStoryShouldChangeStats = onMessagePublished(
    {
      topic: STORY_SHOULD_CHANGE_STATS,
      ...defaultConfig,
    },
    async (event) => {
      logger.info("onStoryShouldChangeStats");
      const sid = event.data.message.json.sid;
      if (!sid) {
        return Promise.resolve();
      }

      const posts = await getAllPostsForStory(sid);
      if (_.isEmpty(posts)) {
        return Promise.resolve();
      }

      const stats = calculateAverageStats(posts);
      if (_.isEmpty(stats)) {
        return Promise.resolve();
      }

      await updateStory(sid, stats);


      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Platform
// ////////////////////////////////////////////////////////////////////////////

exports.onStoryShouldChangePlatforms = onMessagePublished(
    {
      topic: STORY_SHOULD_CHANGE_PLATFORMS,
      ...defaultConfig,
    },
    async (event) => {
      const sid = event.data.message.json.sid;
      logger.info(`onStoryShouldChangePlatforms ${sid}`);
      if (!sid) {
        return Promise.resolve();
      }

      const posts = await getAllPostsForStory(sid);
      if (_.isEmpty(posts)) {
        logger.warn(`No posts found for story ${sid}`);
        return Promise.resolve();
      }

      const platforms = _.uniq(posts.map((post) => post.plid));
      if (_.isEmpty(platforms)) {
        logger.warn(`No platforms found for story ${sid}`);
        return Promise.resolve();
      }

      await updateStory(sid, {plids: platforms}, 5);

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Newsworthiness
// ////////////////////////////////////////////////////////////////////////////

exports.onStoryShouldChangeNewsworthiness = onMessagePublished(
    {
      topic: STORY_SHOULD_CHANGE_NEWSWORTHINESS,
      ...defaultConfig,
    },
    async (event) => {
      const sid = event.data.message.json.sid;
      if (!sid) {
        return Promise.resolve();
      }
      logger.info(`onStoryShouldChangeNewsworthiness ${sid}`);

      await onStoryShouldChangeNewsworthiness(sid);

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Sync
// ////////////////////////////////////////////////////////////////////////////

/**
 * 'TXN' - called from post.js
 * Updates the stories that this post is part of
 * @param {Post} before
 * @param {Post} after
 */
exports.onPostChangedStories = onMessagePublished(
    {
      topic: POST_CHANGED_STORIES,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;

      // NOTE: When a post is deleted and that post
      // has statements, we don't delete the statements
      // since its expensive to compute if that statement
      // is mentioned by another post.
      await handleChangedRelations(before, after,
          "sids", updateStory, "pid", "pids");
      return Promise.resolve();
    },
);

/**
 * 'TXN' - called from Statement.js
 * Updates the Statements that this Story is part of
 * @param {Statement} before
 * @param {Statement} after
 */
exports.onStatementChangedStories = onMessagePublished(
    {
      topic: STATEMENT_CHANGED_STORIES,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      await handleChangedRelations(before, after,
          "sids", updateStory, "stid", "stids");
      return Promise.resolve();
    },
);

/**
 * 'TXN' - from platform.js
 * Updates the Entities that this Platform is part of
 * @param {Platform} before
 * @param {Platform} after
 */
exports.onPlatformChangedStories = onMessagePublished(
    {
      topic: PLATFORM_CHANGED_STORIES, // Make sure to define this topic
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      if (before && !after) {
        await deleteAttribute("stories",
            "plids", "array-contains", before.plid, true);
      }
      return Promise.resolve();
    },
);

