/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig} = require("../common/functions");
const {retryAsyncFunction} = require("../common/utils");
const {setClaim, deleteClaim, updateClaim} = require("../common/database");
const {saveClaimEmbeddings} = require("../ai/claim_ai");
const _ = require("lodash");
const {publishMessage, CLAIM_CHANGED_POSTS,
  CLAIM_CHANGED_STORIES,
  POST_CHANGED_CLAIMS,
  STORY_CHANGED_CLAIMS} = require("../common/pubsub");
const {FieldValue} = require("firebase-admin/firestore");

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

      if (
        _create && (after.value || after.context ) ||
        _delete && (before.value || before.context ) ||
        _update &&
        (before.value != after.value || before.context != after.context)) {
        await claimChangedContent(before, after);
      }

      if (
        _create && !_.isEmpty(after.sids) ||
        _update && !_.isEqual(before.sids, after.sids) ||
        _delete && !_.isEmpty(before.sids)) {
        await publishMessage(CLAIM_CHANGED_STORIES,
            {before: before, after: after});
      }

      if (
        _create && !_.isEmpty(after.pids) ||
        _update && !_.isEqual(before.pids, after.pids) ||
        _delete && !_.isEmpty(before.pids)) {
        await publishMessage(CLAIM_CHANGED_POSTS,
            {before: before, after: after});
      }

      return Promise.resolve();
    });


//
// PubSub
//

/**
 * 'TXN'
 * Transactional update to store vector
 * Not done as pubsub because we need access to the before and after
 * @param {Claim} before
 * @param {Claim} after
 */
const claimChangedContent = async function(before, after) {
  if (!after) {
    // delete handled in delete embeddings
    return;
  }
  const save = await saveClaimEmbeddings(after);
  if (!save) {
    functions.logger.error(`Could not save Claim embeddings: ${after.cid}`);
    if (before) {
      return await retryAsyncFunction(() => setClaim(before));
    } else {
      return await retryAsyncFunction(() => deleteClaim(after.cid));
    }
  }
};

//
// posts and stories sync
//

// post changed claims
exports.onPostChangedClaims = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(POST_CHANGED_CLAIMS)
    .onPublish(async (message) => {
      const before = message.json.before;
      const after = message.json.after;
      if (!after) {
        for (const cid of (before.cids || [])) {
          await retryAsyncFunction(() => updateClaim(cid, {
            pids: FieldValue.arrayRemove(before.pid),
            // since its deleted in this case we also remove from pro/against
            // note we only explicitly do the opposite
            pro: FieldValue.arrayRemove(before.pid), // also remove here
            against: FieldValue.arrayRemove(before.pid), // also remove here
          }, 5));
        }
      } else if (!before) {
        for (const cid of (after.cids || [])) {
          await retryAsyncFunction(() => updateClaim(cid, {
            pids: FieldValue.arrayUnion(after.pid),
          }, 5));
        }
      } else {
        const removed = (before.cids || [])
            .filter((cid) => !(after.cids || []).includes(cid));
        const added = (after.cids || [])
            .filter((cid) => !(before.cids || []).includes(cid));

        for (const cid of removed) {
          await retryAsyncFunction(() => updateClaim(cid, {
            pids: FieldValue.arrayRemove(after.pid),
            // since its deleted in this case we also remove from pro/against
            // note we only explicitly do the opposite
            pro: FieldValue.arrayRemove(before.pid), // also remove here
            against: FieldValue.arrayRemove(before.pid), // also remove here
          }, 5));
        }
        for (const cid of added) {
          await retryAsyncFunction(() => updateClaim(cid, {
            pids: FieldValue.arrayUnion(after.pid),
          }, 5));
        }
      }
      return Promise.resolve();
    });

// story changed claims
exports.onStoryChangedClaims = functions
    .runWith(defaultConfig)
    .pubsub
    .topic(STORY_CHANGED_CLAIMS)
    .onPublish(async (message) => {
      const before = message.json.before;
      const after = message.json.after;
      if (!after) {
        for (const cid of (before.cids || [])) {
          await retryAsyncFunction(() => updateClaim(cid, {
            sids: FieldValue.arrayRemove(before.sid),
          }, 5));
        }
      } else if (!before) {
        for (const cid of (after.cids || [])) {
          await retryAsyncFunction(() => updateClaim(cid, {
            sids: FieldValue.arrayUnion(after.sid),
          }, 5));
        }
      } else {
        const removed = (before.cids || [])
            .filter((cid) => !(after.cids || []).includes(cid));
        const added = (after.cids || [])
            .filter((cid) => !(before.cids || []).includes(cid));

        for (const cid of removed) {
          await retryAsyncFunction(() => updateClaim(cid, {
            sids: FieldValue.arrayRemove(after.sid),
          }, 5));
        }
        for (const cid of added) {
          await retryAsyncFunction(() => updateClaim(cid, {
            sids: FieldValue.arrayUnion(after.sid),
          }, 5));
        }
      }
      return Promise.resolve();
    });

