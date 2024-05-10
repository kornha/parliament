/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig} = require("../common/functions");
const {publishMessage,
  STORY_CHANGED_POSTS,
  STORY_SHOULD_CHANGE_VECTOR,

} = require("../common/pubsub");
const _ = require("lodash");
const {resetStoryVector} = require("../ai/story_ai");
const {getStory, updateStory} = require("../common/database");
const {retryAsyncFunction} = require("../common/utils");
const {FieldValue} = require("firebase-admin/firestore");
const {storyChangedPosts} = require("./post");

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

      // Story changed posts
      if (
        _create && !_.isEmpty(after.pids) ||
        _update && (before.sid != after.sid ||
          !_.isEqual(before.pids, after.pids)) ||
        _delete && !_.isEmpty(before.pids)) {
        // for updating the story vector
        publishMessage(STORY_CHANGED_POSTS, {sid: after?.sid || before?.sid});

        // for updating the post, can probably use the pubsub
        await storyChangedPosts(before, after);
      }

      if (
        _create && (after.title || after.description) ||
        _delete && (before.title || before.description) ||
        _update &&
        (before.title != after.title ||
           before.description != after.description)) {
        // storyChangedContent
      }

      return Promise.resolve();
    });

/**
 * Regenerates the story title, description, and happenedAt
 * Signals to update vector
 *
 * called when a story changes its Posts
 * need to regenerate the story vector and data
 * @param {string} sid
 * @return {Promise<void>}
 */
exports.onStoryChangedPosts = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(STORY_CHANGED_POSTS)
    .onPublish(async (message) => {
      const sid = message.json.sid;
      if (!sid) {
        functions.logger.error(`Invalid sid: ${sid}`);
        return Promise.resolve();
      }

      publishMessage(STORY_SHOULD_CHANGE_VECTOR, {sid: sid});

      const story = await getStory(sid);
      if (!story) {
        functions.logger.error(`Could not fetch story to regenerate: ${sid}`);
        return Promise.resolve();
      }

      return Promise.resolve();
    });

/**
 * called when a story should change its vector
 * eg because it has new posts
 * @param {string} sid
 * @return {Promise<void>}
 */
exports.onStoryShouldChangeVector = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(STORY_SHOULD_CHANGE_VECTOR)
    .onPublish(async (message) => {
      const sid = message.json.sid;
      if (!sid) {
        functions.logger.error(`Invalid sid: ${sid}`);
        return Promise.resolve();
      }
      const story = await getStory(sid);
      if (!story) {
        functions.logger.error(`Could not fetch story to regenerate: ${sid}`);
        return Promise.resolve();
      }

      resetStoryVector(story);

      return Promise.resolve();
    });

/**
 * 'TXN' - called from post.js
 * Updates the stories that this post is part of
 * @param {Post} before
 * @param {Post} after
 */
exports.postChangedStories = function(before, after) {
  if (!after) {
    (before.sids || []).forEach((sid) => {
      retryAsyncFunction(() => updateStory(sid, {
        pids: FieldValue.arrayRemove(before.pid),
      }));
    });
  } else if (!before) {
    (after.sids || []).forEach((sid) => {
      retryAsyncFunction(() => updateStory(sid, {
        pids: FieldValue.arrayUnion(after.pid),
      }));
    });
  } else {
    const removed = (before.sids || [])
        .filter((sid) => !(after.sids || []).includes(sid));
    const added = (after.sids || [])
        .filter((sid) => !(before.sids || []).includes(sid));

    removed.forEach((sid) => {
      retryAsyncFunction(() => updateStory(sid, {
        pids: FieldValue.arrayRemove(after.pid),
      }));
    });
    added.forEach((sid) => {
      retryAsyncFunction(() => updateStory(sid, {
        pids: FieldValue.arrayUnion(after.pid),
      }));
    });
  }
};

/**
 * 'TXN' - called from claim.js
 * Updates the claims that this Story is part of
 * @param {Claim} before
 * @param {Claim} after
 */
exports.claimChangedStories = async function(before, after) {
  if (!after) {
    for (const sid of (before.sids || [])) {
      await retryAsyncFunction(() => updateStory(sid, {
        cids: FieldValue.arrayRemove(before.cid),
      }));
    }
  } else if (!before) {
    for (const sid of (after.sids || [])) {
      await retryAsyncFunction(() => updateStory(sid, {
        cids: FieldValue.arrayUnion(after.cid),
      }));
    }
  } else {
    const removed = (before.sids || [])
        .filter((sid) => !(after.sids || []).includes(sid));
    const added = (after.sids || [])
        .filter((sid) => !(before.sids || []).includes(sid));

    for (const sid of removed) {
      await retryAsyncFunction(() => updateStory(sid, {
        cids: FieldValue.arrayRemove(after.cid),
      }));
    }
    for (const sid of added) {
      await retryAsyncFunction(() => updateStory(sid, {
        cids: FieldValue.arrayUnion(after.cid),
      }));
    }
  }
};
