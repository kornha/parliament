const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig} = require("../common/functions");
const {
  publishMessage,
  STORY_CHANGED_POSTS,
  STORY_CHANGED_STATEMENTS,
  STATEMENT_CHANGED_STORIES,
  POST_CHANGED_STORIES,
} = require("../common/pubsub");
const _ = require("lodash");
const {resetStoryVector} = require("../ai/story_ai");
const {updateStory} = require("../common/database");
const {retryAsyncFunction} = require("../common/utils");
const {FieldValue} = require("firebase-admin/firestore");

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
      if (!after) {
        for (const sid of (before.sids || [])) {
          await retryAsyncFunction(() => updateStory(sid, {
            pids: FieldValue.arrayRemove(before.pid),
          }, 5)); // skip not found errors
        }
      } else if (!before) {
        for (const sid of (after.sids || [])) {
          await retryAsyncFunction(() => updateStory(sid, {
            pids: FieldValue.arrayUnion(after.pid),
          }, 5)); // skip not found errors
        }
      } else {
        const removed = (before.sids || [])
            .filter((sid) => !(after.sids || []).includes(sid));
        const added = (after.sids || [])
            .filter((sid) => !(before.sids || []).includes(sid));

        for (const sid of removed) {
          await retryAsyncFunction(() => updateStory(sid, {
            pids: FieldValue.arrayRemove(after.pid),
          }, 5)); // skip not found errors
        }
        for (const sid of added) {
          await retryAsyncFunction(() => updateStory(sid, {
            pids: FieldValue.arrayUnion(after.pid),
          }, 5)); // skip not found errors
        }
      }
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
      if (!after) {
        for (const sid of (before.sids || [])) {
          await retryAsyncFunction(() => updateStory(sid, {
            stids: FieldValue.arrayRemove(before.stid),
          }, 5)); // skip not found errors
        }
      } else if (!before) {
        for (const sid of (after.sids || [])) {
          await retryAsyncFunction(() => updateStory(sid, {
            stids: FieldValue.arrayUnion(after.stid),
          }, 5)); // skip not found errors
        }
      } else {
        const removed = (before.sids || [])
            .filter((sid) => !(after.sids || []).includes(sid));
        const added = (after.sids || [])
            .filter((sid) => !(before.sids || []).includes(sid));

        for (const sid of removed) {
          await retryAsyncFunction(() => updateStory(sid, {
            stids: FieldValue.arrayRemove(after.stid),
          }, 5)); // skip not found errors
        }
        for (const sid of added) {
          await retryAsyncFunction(() => updateStory(sid, {
            stids: FieldValue.arrayUnion(after.stid),
          }, 5)); // skip not found errors
        }
      }
      return Promise.resolve();
    },
);
