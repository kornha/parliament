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
} = require("../common/pubsub");
const _ = require("lodash");
const {resetStoryVector} = require("../ai/story_ai");
const {updateStory, getAllPostsForStory} = require("../common/database");
const {handleChangedRelations,
  calculateAverageStats} = require("../common/utils");

//
// Firestore
//
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
      }

      if (
        (_create && !_.isEmpty(after.stids)) ||
      (_update && !_.isEqual(before.stids, after.stids)) ||
      (_delete && !_.isEmpty(before.stids))
      ) {
        await publishMessage(STORY_CHANGED_STATEMENTS, {before, after});
      }

      return Promise.resolve();
    },
);

//
// PubSub
//

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
// Stats
// ////////////////////////////////////////////////////////////////////////////

exports.onStoryShouldChangeStats = onMessagePublished(
    {
      topic: STORY_SHOULD_CHANGE_STATS,
      ...defaultConfig,
    },
    async (event) => {
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
