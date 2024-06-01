/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig, gbConfig} = require("../common/functions");
const {
  savePostEmbeddings, findStoriesAndClaims} = require("../ai/post_ai");
const {publishMessage, POST_PUBLISHED,
  POST_CHANGED_VECTOR,
  POST_CHANGED_XID,
  POST_SHOULD_FIND_STORIES_AND_CLAIMS,
} = require("../common/pubsub");
const {getPost, setPost, deletePost,
  createNewRoom,
  updatePost, getEntity, canFindStories,
} = require("../common/database");
const {retryAsyncFunction} = require("../common/utils");
const _ = require("lodash");
const {FieldValue} = require("firebase-admin/firestore");
const {xupdatePost} = require("../content/xscraper");
const {generateCompletions} = require("../common/llm");
const {generateImageDescriptionPrompt} = require("../ai/prompts");


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

      if (_create && after.xid ||
        _delete && before.xid ||
        _update && before.xid != after.xid) {
        await publishMessage(POST_CHANGED_XID,
            {pid: after?.pid || before?.pid});
      }

      if (after && after.status == "published" &&
      (!before || before.status != "published")) {
        await publishMessage(POST_PUBLISHED, {pid: after.pid});
      }

      if (
        _create && after.sid ||
        _update && (before.sid != after.sid ||
          !_.isEqual(before.sids, after.sids)) ||
        _delete && before.sid) {
        // postChangedStories
      }

      if (
        _create && !_.isEmpty(after.cids) ||
        _update && !_.isEqual(before.cids, after.cids) ||
        _delete && !_.isEmpty(before.cids)) {
        // postChangedClaims
      }

      if (_create && after.vector ||
        _delete && before.vector ||
        _update && !_.isEqual(before.vector, after.vector)) {
        await publishMessage(POST_CHANGED_VECTOR,
            {pid: after?.pid || before?.pid});
      }

      if (
        _create && (after.title || after.body ||
           after.description || after.photo) ||
        _delete && (before.title || before.body ||
           before.description || before.photo) ||
        _update &&
        (before.description != after.description ||
        before.title != after.title ||
        before.body != after.body ||
        !_.isEqual(before.photo, after.photo))) {
        await postChangedContent(before, after);
      }

      return Promise.resolve();
    });

//
// PubSub
//

/**
 * optionally calls findStoriesAndClaims if the post is published beforehand
 * @param {Message} message
 * @return {Promise<void>}
 * */
exports.onPostChangedVector = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(POST_CHANGED_VECTOR)
    .onPublish(async (message) => {
      const pid = message.json.pid;
      const post = await getPost(pid);
      if (!post) {
        return Promise.resolve();
      }

      if (post.status == "published" && post.sid == null) {
        await publishMessage(POST_SHOULD_FIND_STORIES_AND_CLAIMS, {pid: pid});
      }

      return Promise.resolve();
    });

/**
 * creates the room
 * called when a post is published
 * @param {Message} message
 * @return {Promise<void>}
 */
exports.onPostPublished = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(POST_PUBLISHED)
    .onPublish(async (message) => {
      const pid = message.json.pid;
      const post = await getPost(pid);

      if (post && post.vector) {
        await publishMessage(POST_SHOULD_FIND_STORIES_AND_CLAIMS, {pid: pid});
      }

      await createNewRoom(pid, "posts");

      return Promise.resolve();
    });

exports.onPostShouldFindStoriesAndClaims = functions
    .runWith(gbConfig)
    .pubsub
    .topic(POST_SHOULD_FIND_STORIES_AND_CLAIMS)
    .onPublish(async (message) => {
      const pid = message.json.pid;

      const canFind = await canFindStories(pid);
      if (!canFind) {
        return Promise.resolve();
      }

      const post = await getPost(pid);
      await findStoriesAndClaims(post);

      await updatePost(pid, {status: "found"});

      return Promise.resolve();
    });

exports.onPostChangedXid = functions
    .runWith(gbConfig)
    .pubsub
    .topic(POST_CHANGED_XID)
    .onPublish(async (message) => {
      functions.logger.info(`onPostChangedXid: ${message.json.pid}`);

      const pid = message.json.pid;
      const post = await getPost(pid);

      if (!post || !post.xid || !post.sourceType || !post.eid) {
        return Promise.resolve();
      }
      const entity = await getEntity(post.eid);
      if (!entity) {
        return Promise.resolve();
      }

      if (post.sourceType == "x") {
        await xupdatePost(post);
      } else {
        functions.logger.error(`Unsupported source type: ${post.sourceType}`);
        return Promise.resolve();
      }

      return Promise.resolve();
    });

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

  // we generate description when the urls changed (and no description is set)
  // NOTE: we don't save embeddings as we will next update (assuming no error)
  // will not work for delete
  if (before?.photo?.photoURL != after?.photo?.photoURL &&
    after.photo?.photoURL &&
    !after.photo?.description) {
    const resp = await generateCompletions(
        generateImageDescriptionPrompt(after.photo.photoURL),
        after.pid + " photoURL",
        true,
    );
    if (!resp?.description) {
      functions.logger.error("Error generating image description");
      // in this case we save embeddings cz there's no image
    } else {
      await retryAsyncFunction(() => updatePost(after.pid, {
        "photo.description": resp.description,
      }));
      // in this case we return
      return;
    }
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
 * Updates the stories that this Post is part of
 * @param {Story} before
 * @param {Story} after
 */
exports.storyChangedPosts = async function(before, after) {
  if (!after) {
    for (const pid of (before.pids || [])) {
      await retryAsyncFunction(() => updatePost(pid, {
        sids: FieldValue.arrayRemove(before.sid),
      }));
    }
  } else if (!before) {
    for (const pid of (after.pids || [])) {
      await retryAsyncFunction(() => updatePost(pid, {
        sids: FieldValue.arrayUnion(after.sid),
      }));
    }
  } else {
    const removed = (before.pids || [])
        .filter((pid) => !(after.pids || []).includes(pid));
    const added = (after.pids || [])
        .filter((pid) => !(before.pids || []).includes(pid));

    for (const pid of removed) {
      await retryAsyncFunction(() => updatePost(pid, {
        sids: FieldValue.arrayRemove(after.sid),
      }));
    }
    for (const pid of added) {
      await retryAsyncFunction(() => updatePost(pid, {
        sids: FieldValue.arrayUnion(after.sid),
      }));
    }
  }
};

/**
 * 'TXN' - called from claim.js
 * Updates the claims that this Post is part of
 * @param {Claim} before
 * @param {Claim} after
 */
exports.claimChangedPosts = async function(before, after) {
  if (!after) {
    for (const pid of (before.pids || [])) {
      await retryAsyncFunction(() => updatePost(pid, {
        cids: FieldValue.arrayRemove(before.cid),
      }));
    }
  } else if (!before) {
    for (const pid of (after.pids || [])) {
      await retryAsyncFunction(() => updatePost(pid, {
        cids: FieldValue.arrayUnion(after.cid),
      }));
    }
  } else {
    const removed = (before.pids || [])
        .filter((pid) => !(after.pids || []).includes(pid));
    const added = (after.pids || [])
        .filter((pid) => !(before.pids || []).includes(pid));

    for (const pid of removed) {
      await retryAsyncFunction(() => updatePost(pid, {
        cids: FieldValue.arrayRemove(after.cid),
      }));
    }
    for (const pid of added) {
      await retryAsyncFunction(() => updatePost(pid, {
        cids: FieldValue.arrayUnion(after.cid),
      }));
    }
  }
};
