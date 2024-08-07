const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions/v2");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig} = require("../common/functions");
const {retryAsyncFunction} = require("../common/utils");
const {setStatement,
  deleteStatement,
  updateStatement} = require("../common/database");
const _ = require("lodash");
const {publishMessage,
  STATEMENT_CHANGED_POSTS, STATEMENT_CHANGED_STORIES,
  POST_CHANGED_STATEMENTS,
  STORY_CHANGED_STATEMENTS} = require("../common/pubsub");
const {FieldValue} = require("firebase-admin/firestore");
const {resetStatementVector} = require("../ai/statement_ai");

//
// Firestore
//
exports.onStatementUpdate = onDocumentWritten(
    {
      document: "statements/{stid}",
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
        await statementChangedContent(before, after);
      }

      if (
        (_create && !_.isEmpty(after.sids)) ||
      (_update && !_.isEqual(before.sids, after.sids)) ||
      (_delete && !_.isEmpty(before.sids))
      ) {
        await publishMessage(STATEMENT_CHANGED_STORIES,
            {before: before, after: after});
      }

      if (
        (_create && !_.isEmpty(after.pids)) ||
      (_update && !_.isEqual(before.pids, after.pids)) ||
      (_delete && !_.isEmpty(before.pids))
      ) {
        await publishMessage(STATEMENT_CHANGED_POSTS,
            {before: before, after: after});
      }

      return Promise.resolve();
    },
);

//
// PubSub
//

const statementChangedContent = async function(before, after) {
  if (!after) {
    // delete handled in delete embeddings
    return;
  }
  const save = await resetStatementVector(after.stid);
  if (!save) {
    logger.error(`Could not save Statement embeddings: ${after.stid}`);
    if (before) {
      return await retryAsyncFunction(() => setStatement(before));
    } else {
      return await retryAsyncFunction(() => deleteStatement(after.stid));
    }
  }
};

//
// posts and stories sync
//

// post changed statements
exports.onPostChangedStatements = onMessagePublished(
    {
      topic: POST_CHANGED_STATEMENTS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      if (!after) {
        for (const stid of before.stids || []) {
          await retryAsyncFunction(() => updateStatement(stid, {
            pids: FieldValue.arrayRemove(before.pid),
            pro: FieldValue.arrayRemove(before.pid), // also remove here
            against: FieldValue.arrayRemove(before.pid), // also remove here
          }, 5));
        }
      } else if (!before) {
        for (const stid of after.stids || []) {
          await retryAsyncFunction(() => updateStatement(stid, {
            pids: FieldValue.arrayUnion(after.pid),
          }, 5));
        }
      } else {
        const removed = (before.stids || [])
            .filter((stid) => !(after.stids || []).includes(stid));
        const added = (after.stids || [])
            .filter((stid) => !(before.stids || []).includes(stid));

        for (const stid of removed) {
          await retryAsyncFunction(() => updateStatement(stid, {
            pids: FieldValue.arrayRemove(after.pid),
            pro: FieldValue.arrayRemove(before.pid), // also remove here
            against: FieldValue.arrayRemove(before.pid), // also remove here
          }, 5));
        }
        for (const stid of added) {
          await retryAsyncFunction(() => updateStatement(stid, {
            pids: FieldValue.arrayUnion(after.pid),
          }, 5));
        }
      }
      return Promise.resolve();
    },
);

// story changed statements
exports.onStoryChangedStatements = onMessagePublished(
    {
      topic: STORY_CHANGED_STATEMENTS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      if (!after) {
        for (const stid of before.stids || []) {
          await retryAsyncFunction(() => updateStatement(stid, {
            sids: FieldValue.arrayRemove(before.sid),
          }, 5));
        }
      } else if (!before) {
        for (const stid of after.stids || []) {
          await retryAsyncFunction(() => updateStatement(stid, {
            sids: FieldValue.arrayUnion(after.sid),
          }, 5));
        }
      } else {
        const removed = (before.stids || [])
            .filter((stid) => !(after.stids || []).includes(stid));
        const added = (after.stids || [])
            .filter((stid) => !(before.stids || []).includes(stid));

        for (const stid of removed) {
          await retryAsyncFunction(() => updateStatement(stid, {
            sids: FieldValue.arrayRemove(after.sid),
          }, 5));
        }
        for (const stid of added) {
          await retryAsyncFunction(() => updateStatement(stid, {
            sids: FieldValue.arrayUnion(after.sid),
          }, 5));
        }
      }
      return Promise.resolve();
    },
);
