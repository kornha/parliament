/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {defaultConfig} = require("../common/functions");
const {retryAsyncFunction} = require("../common/utils");
const {setClaim, deleteClaim} = require("../common/database");
const {saveClaimEmbeddings} = require("../ai/claim_ai");
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
        await claimChangedStories(before, after);
      }

      if (
        _create && !_.isEmpty(after.pids) ||
        _update && !_.isEqual(before.pids, after.pids) ||
        _delete && !_.isEmpty(before.pids)) {
        await claimChangedPosts(before, after);
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
