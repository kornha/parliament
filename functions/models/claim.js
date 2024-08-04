const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions/v2");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig} = require("../common/functions");
const {retryAsyncFunction} = require("../common/utils");
const {setClaim, deleteClaim, updateClaim} = require("../common/database");
const _ = require("lodash");
const {publishMessage,
  CLAIM_CHANGED_POSTS, CLAIM_CHANGED_STORIES,
  POST_CHANGED_CLAIMS, STORY_CHANGED_CLAIMS} = require("../common/pubsub");
const {FieldValue} = require("firebase-admin/firestore");
const {resetClaimVector} = require("../ai/claim_ai");

//
// Firestore
//
exports.onClaimUpdate = onDocumentWritten(
    {
      document: "claims/{cid}",
      ...defaultConfig, // uses pupetteer and requires 1GB to run
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
        (_create && (after.value || after.context)) ||
      (_delete && (before.value || before.context)) ||
      (_update &&
      (before.value != after.value || before.context != after.context))
      ) {
        await claimChangedContent(before, after);
      }

      if (
        (_create && !_.isEmpty(after.sids)) ||
      (_update && !_.isEqual(before.sids, after.sids)) ||
      (_delete && !_.isEmpty(before.sids))
      ) {
        await publishMessage(CLAIM_CHANGED_STORIES,
            {before: before, after: after});
      }

      if (
        (_create && !_.isEmpty(after.pids)) ||
      (_update && !_.isEqual(before.pids, after.pids)) ||
      (_delete && !_.isEmpty(before.pids))
      ) {
        await publishMessage(CLAIM_CHANGED_POSTS,
            {before: before, after: after});
      }

      return Promise.resolve();
    },
);

//
// PubSub
//

const claimChangedContent = async function(before, after) {
  if (!after) {
    // delete handled in delete embeddings
    return;
  }
  const save = await resetClaimVector(after.cid);
  if (!save) {
    logger.error(`Could not save Claim embeddings: ${after.cid}`);
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
exports.onPostChangedClaims = onMessagePublished(
    {
      topic: POST_CHANGED_CLAIMS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      if (!after) {
        for (const cid of before.cids || []) {
          await retryAsyncFunction(() => updateClaim(cid, {
            pids: FieldValue.arrayRemove(before.pid),
            pro: FieldValue.arrayRemove(before.pid), // also remove here
            against: FieldValue.arrayRemove(before.pid), // also remove here
          }, 5));
        }
      } else if (!before) {
        for (const cid of after.cids || []) {
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
    },
);

// story changed claims
exports.onStoryChangedClaims = onMessagePublished(
    {
      topic: STORY_CHANGED_CLAIMS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      if (!after) {
        for (const cid of before.cids || []) {
          await retryAsyncFunction(() => updateClaim(cid, {
            sids: FieldValue.arrayRemove(before.sid),
          }, 5));
        }
      } else if (!before) {
        for (const cid of after.cids || []) {
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
    },
);
