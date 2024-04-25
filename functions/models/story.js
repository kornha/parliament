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

      if (_create) {
        onStoryCreate(after);
      }

      if (_delete) {
        onStoryDelete(before);
      }

      // Story changed posts
      if (
        _create && !_.isEmpty(after.pids) ||
        _update && (before.sid != after.sid ||
          !_.isEqual(before.pids, after.pids)) ||
        _delete && !_.isEmpty(before.pids)) {
        // for updating the post, can probably use the pubsub
        storyChangedPosts(before, after);

        // for updating the story vector
        const sid = after ? after.sid : before.sid;
        publishMessage(STORY_CHANGED_POSTS, {sid: sid});
      }

      // story changed posts
      if (
        _create && after.pids ||
        _update && !_.isEqual(before.pids, after.pids) ||
        _delete && before.pids) {
        //
      }

      if (
        _create && !_.isEmpty(after.cids) ||
        _update && !_.isEqual(before.cids, after.cids) ||
        _delete && !_.isEmpty(before.cids)) {
        // storyChangedClaims(before, after);
      }

      // story changed content
      if (
        _create && (after.title || after.description) ||
        _delete && (before.title || before.description) ||
        _update &&
        (before.title != after.title ||
           before.description != after.description)) {
        storyChangedContent(before, after);
      }

      return Promise.resolve();
    });

//
// PubSub
//

/**
 * Regenerates the story title, description, and createdAt
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

      // regenerateStory(story);

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
 * Finds the claims for a story
 * Currently triggered when claims change posts
 *
 * called when a story should change its claims
 * eg the claim has entered the Story's radar (in this case claim changed posts)
 * @param {string} sid
 * @return {Promise<void>}
 */
// exports.onStoryShouldChangeClaims = functions
//     .runWith(defaultConfig)
//     .pubsub
//     .topic(STORY_SHOULD_CHANGE_CLAIMS)
//     .onPublish(async (message) => {
//       const sid = message.json.sid;
//       if (!sid) {
//         functions.logger.error(`Invalid sid: ${sid}`);
//         return Promise.resolve();
//       }
//       const story = await getStory(sid);
//       if (!story) {
//         functions.logger.
// error(`Could not fetch story to regenerate: ${sid}`);
//         return Promise.resolve();
//       }

//       findClaimsForStory(story);

//       return Promise.resolve();
//     });


//
// Events. Recall that multiple may get triggered for a single update!
// no need to retrigger each other below.
//

/**
 * called when a story is created
 * note that we set the vector here
 * since a story can be created from the find story (post)
 * @param {Story} story
 * @return {Promise<void>}
 */
const onStoryCreate = async function(story) {
  if (!story || !story.sid) {
    functions.logger.error(`Could not fetch story to regenerate: ${story.sid}`);
    return;
  }

  // need to remove the story from claim and post

  // is this needed since we assign post to story after its created?
  // publishMessage(STORY_SHOULD_CHANGE_VECTOR, {sid: story.sid});

  return Promise.resolve();
};

/**
 * called when a story is deleted
 * @param {Story} story
 * @return {Promise<void>}
 */
const onStoryDelete = async function(story) {
  return Promise.resolve();
};

const storyChangedContent = function(before, after) {
  if (!after) {
    return;
  }
  // publishMessage(STORY_SHOULD_CHANGE_CLAIMS, {sid: after.sid});
};

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
exports.claimChangedStories = function(before, after) {
  if (!after) {
    (before.sids || []).forEach((sid) => {
      retryAsyncFunction(() => updateStory(sid, {
        cids: FieldValue.arrayRemove(before.cid),
      }));
    });
  } else if (!before) {
    (after.sids || []).forEach((sid) => {
      retryAsyncFunction(() => updateStory(sid, {
        cids: FieldValue.arrayUnion(after.cid),
      }));
    });
  } else {
    const removed = (before.sids || [])
        .filter((sid) => !(after.sids || []).includes(sid));
    const added = (after.sids || [])
        .filter((sid) => !(before.sids || []).includes(sid));

    removed.forEach((sid) => {
      retryAsyncFunction(() => updateStory(sid, {
        cids: FieldValue.arrayRemove(after.cid),
      }));
    });
    added.forEach((sid) => {
      retryAsyncFunction(() => updateStory(sid, {
        cids: FieldValue.arrayUnion(after.cid),
      }));
    });
  }
};

