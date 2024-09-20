const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions/v2");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig} = require("../common/functions");
const {retryAsyncFunction, handleChangedRelations} = require("../common/utils");
const {setStatement,
  deleteStatement,
  updateStatement} = require("../common/database");
const _ = require("lodash");
const {publishMessage,
  STATEMENT_CHANGED_POSTS, STATEMENT_CHANGED_STORIES,
  POST_CHANGED_STATEMENTS,
  STORY_CHANGED_STATEMENTS,
  STATEMENT_CHANGED_ENTITIES,
  ENTITY_CHANGED_STATEMENTS,
  STATEMENT_SHOULD_CHANGE_CONFIDENCE,
  STATEMENT_CHANGED_CONFIDENCE,
  ENTITY_SHOULD_CHANGE_CONFIDENCE,
  STATEMENT_CHANGED_BIAS,
  STATEMENT_SHOULD_CHANGE_BIAS,
  ENTITY_SHOULD_CHANGE_BIAS,
  STORY_SHOULD_CHANGE_BIAS,
  POST_SHOULD_CHANGE_BIAS,
  POST_SHOULD_CHANGE_CONFIDENCE,
  STORY_SHOULD_CHANGE_CONFIDENCE} = require("../common/pubsub");
const {FieldValue} = require("firebase-admin/firestore");
const {resetStatementVector} = require("../ai/statement_ai");
const {confidenceDidCrossThreshold,
  onStatementShouldChangeConfidence} = require("../ai/confidence");
const {onStatementShouldChangeBias,
  biasDidCrossThreshold} = require("../ai/bias");

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

      //
      // Confidence
      //

      if (
        (_create && !_.isEmpty(after.eids)) ||
        (_update && !_.isEqual(before.eids, after.eids)) ||
        (_delete && !_.isEmpty(before.eids))
      ) {
        await publishMessage(STATEMENT_CHANGED_ENTITIES,
            {before: before, after: after});

        if ((before ?? after).type == "claim") {
          await publishMessage(STATEMENT_SHOULD_CHANGE_CONFIDENCE,
              {stid: after?.stid || before?.stid});
        } else if ((before ?? after).type == "opinion") {
          await publishMessage(STATEMENT_SHOULD_CHANGE_BIAS,
              {stid: after?.stid || before?.stid});
        }
      }

      if (
        _create && after.confidence ||
        _update && before.confidence != after.confidence ||
        _delete && before.confidence
      ) {
        await publishMessage(STATEMENT_CHANGED_CONFIDENCE,
            {before: before, after: after});
      }

      if (
        _create && after.adminConfidence ||
        _update && before.adminConfidence != after.adminConfidence ||
        _delete && before.adminConfidence
      ) {
        await publishMessage(STATEMENT_SHOULD_CHANGE_CONFIDENCE,
            {stid: after?.stid || before?.stid});
      }

      if (
        _create && after.bias ||
        _update && before.bias != after.bias ||
        _delete && before.bias
      ) {
        await publishMessage(STATEMENT_CHANGED_BIAS,
            {before: before, after: after});
      }

      if (
        _create && after.adminBias ||
        _update && before.adminBias != after.adminBias ||
        _delete && before.adminBias
      ) {
        await publishMessage(STATEMENT_SHOULD_CHANGE_BIAS,
            {stid: after?.stid || before?.stid});
      }

      //
      //

      if (
        (_create && (after.value || after.context)) ||
        (_delete && (before.value || before.context)) ||
        (_update &&
        (before.value != after.value || before.context != after.context))
      ) {
        await statementChangedContent(before, after);
      }

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// CONFIDENCE
// ////////////////////////////////////////////////////////////////////////////

exports.onStatementShouldChangeConfidence = onMessagePublished(
    {
      topic: STATEMENT_SHOULD_CHANGE_CONFIDENCE,
      ...defaultConfig,
    },
    async (event) => {
      const stid = event.data.message.json.stid;
      logger.info("onStatementShouldChangeConfidence stid: ", stid);

      if (!stid) {
        return Promise.resolve();
      }

      // compute new confidence via algorithm
      await onStatementShouldChangeConfidence(stid);

      return Promise.resolve();
    },
);

exports.onStatementChangedConfidence = onMessagePublished(
    {
      topic: STATEMENT_CHANGED_CONFIDENCE,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      logger.info("onStatementChangedConfidence stid: ",
          after?.stid || before?.stid);

      if (!confidenceDidCrossThreshold(before, after)) {
        return Promise.resolve();
      }

      const eids = after?.eids ?? before?.eids;
      for (const eid of eids) {
        await publishMessage(ENTITY_SHOULD_CHANGE_CONFIDENCE, {eid: eid});
      }

      const pids = after?.pids ?? before?.pids;
      for (const pid of pids) {
        await publishMessage(POST_SHOULD_CHANGE_CONFIDENCE, {pid: pid});
      }

      const sids = after?.sids ?? before?.sids;
      for (const sid of sids) {
        await publishMessage(STORY_SHOULD_CHANGE_CONFIDENCE, {sid: sid});
      }

      // TODO: also inform the story to update its description

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// Bias
// ////////////////////////////////////////////////////////////////////////////

exports.onStatementShouldChangeBias = onMessagePublished(
    {
      topic: STATEMENT_SHOULD_CHANGE_BIAS,
      ...defaultConfig,
    },
    async (event) => {
      const stid = event.data.message.json.stid;
      logger.info("onStatementShouldChangeBias stid: ", stid);
      if (!stid) {
        return Promise.resolve();
      }

      // compute new Bias via algorithm
      await onStatementShouldChangeBias(stid);

      return Promise.resolve();
    },
);

exports.onStatementChangedBias = onMessagePublished(
    {
      topic: STATEMENT_CHANGED_BIAS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      logger.info("onStatementChangedBias stid: ", after?.stid || before?.stid);
      if (!biasDidCrossThreshold(before, after)) {
        return Promise.resolve();
      }

      const eids = after?.eids ?? before?.eids;
      for (const eid of eids) {
        await publishMessage(ENTITY_SHOULD_CHANGE_BIAS, {eid: eid});
      }

      const pids = after?.pids ?? before?.pids;
      for (const pid of pids) {
        await publishMessage(POST_SHOULD_CHANGE_BIAS, {pid: pid});
      }

      const sids = after?.sids ?? before?.sids;
      for (const sid of sids) {
        await publishMessage(STORY_SHOULD_CHANGE_BIAS, {sid: sid});
      }

      // TODO: also inform the story to update its description

      return Promise.resolve();
    },
);

// ////////////////////////////////////////////////////////////////////////////
// CONTENT
// ////////////////////////////////////////////////////////////////////////////

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

// ////////////////////////////////////////////////////////////////////////////
// Sync
// ////////////////////////////////////////////////////////////////////////////

exports.onPostChangedStatements = onMessagePublished(
    {
      topic: POST_CHANGED_STATEMENTS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      await handleChangedRelations(
          before,
          after,
          "stids",
          updateStatement,
          "pid",
          "pids",
          {
            pro: FieldValue.arrayRemove(before?.pid || after?.pid),
            against: FieldValue.arrayRemove(before?.pid || after?.pid),
          },
      );
      return Promise.resolve();
    },
);

exports.onStoryChangedStatements = onMessagePublished(
    {
      topic: STORY_CHANGED_STATEMENTS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      await handleChangedRelations(before,
          after, "stids", updateStatement, "sid", "sids");
      return Promise.resolve();
    },
);

exports.onEntityChangedStatements = onMessagePublished(
    {
      topic: ENTITY_CHANGED_STATEMENTS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      await handleChangedRelations(before,
          after, "stids", updateStatement, "eid", "eids");
      return Promise.resolve();
    },
);
