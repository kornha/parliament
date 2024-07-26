/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig} = require("../common/functions");
const {publishMessage,
  STORY_CHANGED_POSTS,
  STORY_CHANGED_CLAIMS,
  CLAIM_CHANGED_STORIES,
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
exports.onStoryUpdate = functions
    .runWith(defaultConfig) // uses pupetteer and requires 1GB to run
    .firestore
    .document("stories/{sid}")
    .onWrite(async (change) => {
      const before = change.before.data();
      const after = change.after.data();

      if (!before && !after) {
        return Promise.resolve();
      }

      // Executes all matches always!

      const _create = !before && after;
      const _delete = before && !after;
      const _update = before && after;

      if (
        _create && (after.title || after.description) ||
        _delete && (before.title || before.description) ||
        _update &&
        (before.title != after.title ||
           before.description != after.description)) {
        // storyChangedContent
      }

      if (
        _create && !_.isEmpty(after.pids) ||
        _update && !_.isEqual(before.pids, after.pids) ||
        _delete && !_.isEmpty(before.pids)) {
        await publishMessage(STORY_CHANGED_POSTS,
            {before: before, after: after});
      }

      if (
        _create && !_.isEmpty(after.cids) ||
        _update && !_.isEqual(before.cids, after.cids) ||
        _delete && !_.isEmpty(before.cids)) {
        await publishMessage(STORY_CHANGED_CLAIMS,
            {before: before, after: after});
      }

      return Promise.resolve();
    });

/**
 * Called when a story changes its Posts
 * Regenerates the story vector via K means
 * Semi-duplicated logic from findStories
 * @param {string} sid
 * @return {Promise<void>}
 */
exports.onStoryShouldChangeVector = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(STORY_CHANGED_POSTS) // NOTE THE PUBSUB TOPIC
    .onPublish(async (message) => {
      const story = message.json.after;
      if (!story || !story.sid) {
        // noop if deleted
        return Promise.resolve();
      }

      await resetStoryVector(story.sid);

      return Promise.resolve();
    });

/**
 * 'TXN' - called from post.js
 * Updates the stories that this post is part of
 * @param {Post} before
 * @param {Post} after
 */
exports.onPostChangedStories = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(POST_CHANGED_STORIES) // NOTE THE PUBSUB TOPIC
    .onPublish(async (message) => {
      const before = message.json.before;
      const after = message.json.after;
      if (!after) {
        for (const sid of (before.sids || [])) {
          await retryAsyncFunction(() => updateStory(sid, {
            pids: FieldValue.arrayRemove(before.pid),
          },
          5, // skip not found errors
          ));
        }
      } else if (!before) {
        for (const sid of (after.sids || [])) {
          await retryAsyncFunction(() => updateStory(sid, {
            pids: FieldValue.arrayUnion(after.pid),
          },
          5, // skip not found errors
          ));
        }
      } else {
        const removed = (before.sids || [])
            .filter((sid) => !(after.sids || []).includes(sid));
        const added = (after.sids || [])
            .filter((sid) => !(before.sids || []).includes(sid));

        for (const sid of removed) {
          await retryAsyncFunction(() => updateStory(sid, {
            pids: FieldValue.arrayRemove(after.pid),
          },
          5, // skip not found errors
          ));
        }
        for (const sid of added) {
          await retryAsyncFunction(() => updateStory(sid, {
            pids: FieldValue.arrayUnion(after.pid),
          },
          5, // skip not found errors
          ));
        }
      }
      return Promise.resolve();
    });

/**
 * 'TXN' - called from claim.js
 * Updates the claims that this Story is part of
 * @param {Claim} before
 * @param {Claim} after
 */
exports.onClaimChangedStories = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(CLAIM_CHANGED_STORIES) // NOTE THE PUBSUB TOPIC
    .onPublish(async (message) => {
      const before = message.json.before;
      const after = message.json.after;
      if (!after) {
        for (const sid of (before.sids || [])) {
          await retryAsyncFunction(() => updateStory(sid, {
            cids: FieldValue.arrayRemove(before.cid),
          },
          5, // skip not found errors
          ));
        }
      } else if (!before) {
        for (const sid of (after.sids || [])) {
          await retryAsyncFunction(() => updateStory(sid, {
            cids: FieldValue.arrayUnion(after.cid),
          },
          5,
          ));
        }
      } else {
        const removed = (before.sids || [])
            .filter((sid) => !(after.sids || []).includes(sid));
        const added = (after.sids || [])
            .filter((sid) => !(before.sids || []).includes(sid));

        for (const sid of removed) {
          await retryAsyncFunction(() => updateStory(sid, {
            cids: FieldValue.arrayRemove(after.cid),
          },
          5,
          ));
        }
        for (const sid of added) {
          await retryAsyncFunction(() => updateStory(sid, {
            cids: FieldValue.arrayUnion(after.cid),
          },
          5,
          ));
        }
      }
      return Promise.resolve();
    });
