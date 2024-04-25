/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig} = require("../common/functions");
const {retryAsyncFunction} = require("../common/utils");
const {FieldValue} = require("firebase-admin/firestore");
const {updateClaim} = require("../common/database");
const {saveClaimEmbeddings} = require("../ai/claim_ai");
const {CLAIM_CHANGED_VECTOR} = require("../common/pubsub");
const _ = require("lodash");
const {claimChangedPosts} = require("./post");
const {claimChangedStories} = require("./story");

//
// Firestore
//
exports.onClaimUpdate = functions
    .runWith(defaultConfig) // uses pupetteer and requires 1GB to run
    .firestore
    .document("claims/{cid}")
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
        onClaimCreate(after);
      }

      if (_delete) {
        onClaimDelete(before);
      }

      if (_update) {
        // onClaimUpdate(before, after);
      }

      if (
        _create && (after.value || after.context ) ||
        _delete && (before.value || before.context ) ||
        _update &&
        (before.value != after.value || before.context != after.context)) {
        claimChangedContent(before, after);
      }

      // // claim changed posts
      // if (
      //   _create && !_.isEmpty(after.pids) ||
      //   _update && !_.isEqual(before.pids, after.pids) ||
      //   _delete && !_.isEmpty(before.pids)) {
      //   // collect delta pids
      //   const removed = (before.pids || [])
      //       .filter((pid) => !(after?.pids || []).includes(pid));
      //   const added = (after?.pids || [])
      //       .filter((pid) => !(before?.pids || []).includes(pid));
      //   const deltas = (before?.pids || [])
      //       .concat(after?.pids || [])
      //       .filter((pid) => !removed.includes(pid) || !added.includes(pid));

      //   const cid = after ? after.cid : before.cid;

      //   publishMessage(CLAIM_CHANGED_POSTS, {cid: cid, pids: deltas});
      // }

      if (
        _create && !_.isEmpty(after.sids) ||
        _update && !_.isEqual(before.sids, after.sids) ||
        _delete && !_.isEmpty(before.sids)) {
        claimChangedStories(before, after);
      }

      if (
        _create && !_.isEmpty(after.pids) ||
        _update && !_.isEqual(before.pids, after.pids) ||
        _delete && !_.isEmpty(before.pids)) {
        claimChangedPosts(before, after);
      }

      return Promise.resolve();
    });


//
// PubSub
//

/**
 * Signals to the Story that there might be a nearby claim
 * @param {string} message.cid
 * @param {string[]} message.pids
 * @return {Promise<void>}
 * */
// exports.onClaimChangedPosts = functions
//     .runWith(defaultConfig)
//     .pubsub
//     .topic(CLAIM_CHANGED_POSTS)
//     .onPublish(async (message) => {
// const cid = message.json.cid;
// const pids = message.json.pids;
// if (!cid || !pids || pids.length === 0) {
//   functions.logger.error(`Invalid precondition: ${cid} ${pids}`);
//   return Promise.resolve();
// }

// const stories =
//  (await Promise.all(pids.map((pid) => getAllStoriesForPost(pid)))).flat();

// if (_.isEmpty(stories)) {
//   functions.logger.info(`Claim created before stories: ${cid} ${pids}`);
//   return Promise.resolve();
// }

// stories.forEach((story) => {
//   publishMessage(STORY_SHOULD_CHANGE_CLAIMS, {sid: story.sid});
// });

//   return Promise.resolve();
// });

/**
 * Claim should change context
 * called when there's a new story for claim
 * @param {string} message.cid
 * @return {Promise<void>}
 * */
// exports.onClaimShouldChangeContext = functions
//     .runWith(defaultConfig)
//     .pubsub
//     .topic(CLAIM_SHOULD_CHANGE_CONTEXT)
//     .onPublish(async (message) => {
//       const cid = message.json.cid;
//       if (!cid) {
//         functions.logger.error(`Invalid cid: ${cid}`);
//         return Promise.resolve();
//       }

//       return Promise.resolve();
//     });

/**
 * Claim changed vector
 * We have 2 ways to handle this; by Claim Vector -> Story or
 * by Claim -> Post -> Story. We will do the latter for now.
 * This assumes that a Claim cannot be part of a Story
 * if the post is not part of the Story
 * Since we are not doing it by Claim Vector -> Story, we will return noop here
 * @param {string} message.cid
 * @return {Promise<void>}
 */
exports.onClaimChangedVector = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(CLAIM_CHANGED_VECTOR)
    .onPublish(async (message) => {
      const cid = message.json.cid;
      if (!cid) {
        functions.logger.error(`Invalid cid: ${cid}`);
        return Promise.resolve();
      }

      return Promise.resolve();
    });


//
// Events. Recall that multiple may get triggered for a single update!
// no need to retrigger each other below.
//

/**
 * 'TXN' - called from post.js
 * Updates the stories that this post is part of
 * @param {Post} before
 * @param {Post} after
 */
exports.postChangedClaims = function(before, after) {
  if (!after) {
    (before.cids || []).forEach((cid) => {
      retryAsyncFunction(() => updateClaim(cid, {
        pids: FieldValue.arrayRemove(before.pid),
      }));
    });
  } else if (!before) {
    (after.cids || []).forEach((cid) => {
      retryAsyncFunction(() => updateClaim(cid, {
        pids: FieldValue.arrayUnion(after.pid),
      }));
    });
  } else {
    const removed = (before.cids || [])
        .filter((cid) => !(after.cids || []).includes(cid));
    const added = (after.cids || [])
        .filter((cid) => !(before.cids || []).includes(cid));

    removed.forEach((cid) => {
      retryAsyncFunction(() => updateClaim(cid, {
        pids: FieldValue.arrayRemove(after.pid),
      }));
    });
    added.forEach((cid) => {
      retryAsyncFunction(() => updateClaim(cid, {
        pids: FieldValue.arrayUnion(after.pid),
      }));
    });
  }
};

/**
 * 'TXN' - called from story.js
 * Updates the stories that this Story is part of
 * @param {Story} before
 * @param {Story} after
 */
exports.storyChangedClaims = function(before, after) {
  if (!after) {
    (before.cids || []).forEach((cid) => {
      retryAsyncFunction(() => updateClaim(cid, {
        sids: FieldValue.arrayRemove(before.sid),
      }));
    });
  } else if (!before) {
    (after.cids || []).forEach((cid) => {
      retryAsyncFunction(() => updateClaim(cid, {
        sids: FieldValue.arrayUnion(after.sid),
      }));
    });
  } else {
    const removed = (before.cids || [])
        .filter((cid) => !(after.cids || []).includes(cid));
    const added = (after.cids || [])
        .filter((cid) => !(before.cids || []).includes(cid));

    removed.forEach((cid) => {
      retryAsyncFunction(() => updateClaim(cid, {
        sids: FieldValue.arrayRemove(after.sid),
      }));
    });
    added.forEach((cid) => {
      retryAsyncFunction(() => updateClaim(cid, {
        sids: FieldValue.arrayUnion(after.sid),
      }));
    });
  }
};

/**
 * Claim created
 * @param {Claim} claim
 */
function onClaimCreate(claim) {
}

/**
 * Claim deleted
 * @param {Claim} claim
 * @return {Promise<void>}
 */
function onClaimDelete(claim) {
  return Promise.resolve();
}

/**
 * 'TXN'
 * Transactional update to store vector
 * Not done as pubsub because we need access to the before and after
 * @param {Post} before
 * @param {Post} after
 */
const claimChangedContent = async function(before, after) {
  if (!after) {
    // delete handled in delete embeddings
    return;
  }

  // retry?
  saveClaimEmbeddings(after);
};
