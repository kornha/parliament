/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig, gbConfig} = require("../common/functions");
const {
  savePostEmbeddings, findStoriesAndClaims} = require("../ai/post_ai");
const {publishMessage, POST_PUBLISHED,
  POST_CHANGED_VECTOR} = require("../common/pubsub");
const {getPost, setPost, deletePost,
  createNewRoom,
  updatePost} = require("../common/database");
const {retryAsyncFunction} = require("../common/utils");
const _ = require("lodash");
const {FieldValue} = require("firebase-admin/firestore");


//
// Firestore
//
exports.onPostUpdate = functions
    .runWith(defaultConfig) // uses pupetteer and requires 1GB to run
    .firestore
    .document("posts/{pid}")
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
        onPostCreate(after);
      }

      if (_delete) {
        onPostDelete(before);
      }

      if (after && after.status == "published" &&
      (!before || before.status != "published")) {
        publishMessage(POST_PUBLISHED, {pid: after.pid});
      }

      if (
        _create && after.sid ||
        _update && (before.sid != after.sid ||
          !_.isEqual(before.sids, after.sids)) ||
        _delete && before.sid) {
        // postChangedStories(before, after);
      }

      if (
        _create && !_.isEmpty(after.cids) ||
        _update && !_.isEqual(before.cids, after.cids) ||
        _delete && !_.isEmpty(before.cids)) {
        // postChangedClaims(before, after);
      }

      if (
        _create && (after.title || after.body || after.description) ||
        _delete && (before.title || before.body || before.description) ||
        _update &&
        (before.description != after.description ||
        before.title != after.title ||
        before.body != after.body)) {
        postChangedContent(before, after);
      }

      return Promise.resolve();
    });

//
// PubSub
//

/**
 * called when a post is published
 * need to find stories and claims
 * uses GB config because heavy ops
 */
exports.onPostPublished = functions
    .runWith(gbConfig)
    .pubsub
    .topic(POST_PUBLISHED)
    .onPublish(async (message) => {
      const pid = message.json.pid;
      const post = await getPost(pid);
      createNewRoom(pid, "posts");

      findStoriesAndClaims(post);

      return Promise.resolve();
    });

exports.onPostChangedVector = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(POST_CHANGED_VECTOR)
    .onPublish(async (message) => {
      // const pid = message.json.pid;
    });

//
// Events. Recall that multiple may get triggered for a single update!
// no need to retrigger each other below.
//

const onPostCreate = function(post) {
  return Promise.resolve();
};

const onPostDelete = function(post) {
  return Promise.resolve();
};

/**
 * TXN
 * Transactional update to store vector
 * Not done as pubsub because we need access to the before and after
 * @param {Post} before
 * @param {Post} after
 */
const postChangedContent = async function(before, after) {
  if (!after) {
    // delete handled in delete embeddings
    return;
  }
  const save = await savePostEmbeddings(after);
  if (!save) {
    functions.logger.error(`Could not save post embeddings: ${after.pid}`);
    if (before) {
      return await retryAsyncFunction(() => setPost(before));
    } else {
      return await retryAsyncFunction(() => deletePost(after.pid));
    }
  }
};

/**
 * 'TXN' - called from story.js
 * Updates the stories that this post is part of
 * @param {Story} before
 * @param {Story} after
 * @return {Promise<void>}
 * @async
 * */
exports.storyChangedPosts = async function(before, after) {
  if (!after) {
    (before.pids || []).forEach((pid) => {
      retryAsyncFunction(() => updatePost(pid, {
        sids: FieldValue.arrayRemove(before.sid),
      }));
    });
  } else if (!before) {
    (after.pids || []).forEach((pid) => {
      retryAsyncFunction(() => updatePost(pid, {
        sids: FieldValue.arrayUnion(after.sid),
      }));
    });
  } else {
    const removed = (before.pids || [])
        .filter((pid) => !(after.pids || []).includes(pid));
    const added = (after.pids || [])
        .filter((pid) => !(before.pids || []).includes(pid));

    removed.forEach((pid) => {
      retryAsyncFunction(() => updatePost(pid, {
        sids: FieldValue.arrayRemove(after.sid),
      }));
    });
    added.forEach((pid) => {
      retryAsyncFunction(() => updatePost(pid, {
        sids: FieldValue.arrayUnion(after.sid),
      }));
    });
  }
};

/**
 * 'TXN' - called from claim.js
 * Updates the claims that this Post is part of
 * @param {Claim} before
 * @param {Claim} after
 */
exports.claimChangedPosts = function(before, after) {
  if (!after) {
    (before.pids || []).forEach((pid) => {
      retryAsyncFunction(() => updatePost(pid, {
        cids: FieldValue.arrayRemove(before.cid),
      }));
    });
  } else if (!before) {
    (after.pids || []).forEach((pid) => {
      retryAsyncFunction(() => updatePost(pid, {
        cids: FieldValue.arrayUnion(after.cid),
      }));
    });
  } else {
    const removed = (before.pids || [])
        .filter((pid) => !(after.pids || []).includes(pid));
    const added = (after.pids || [])
        .filter((pid) => !(before.pids || []).includes(pid));

    removed.forEach((pid) => {
      retryAsyncFunction(() => updatePost(pid, {
        cids: FieldValue.arrayRemove(after.cid),
      }));
    });
    added.forEach((pid) => {
      retryAsyncFunction(() => updatePost(pid, {
        cids: FieldValue.arrayUnion(after.cid),
      }));
    });
  }
};

