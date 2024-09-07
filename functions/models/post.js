const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defaultConfig, gbConfig, scrapeConfig} = require("../common/functions");
const {findStoriesAndStatements, resetPostVector} = require("../ai/post_ai");
const {logger} = require("firebase-functions/v2");
const {
  publishMessage,
  POST_PUBLISHED,
  POST_CHANGED_VECTOR,
  POST_CHANGED_XID,
  POST_SHOULD_FIND_STORIES_AND_STATEMENTS,
  STORY_CHANGED_POSTS,
  STATEMENT_CHANGED_POSTS,
  POST_CHANGED_STORIES,
  POST_CHANGED_STATEMENTS,
  POST_CHANGED_ENTITY,
  ENTITY_CHANGED_POSTS,
} = require("../common/pubsub");
const {
  getPost,
  setPost,
  deletePost,
  createNewRoom,
  updatePost,
  getEntity,
  canFindStories,
} = require("../common/database");
const {retryAsyncFunction, handleChangedRelations} = require("../common/utils");
const _ = require("lodash");
const {xupdatePost} = require("../content/xscraper");
const {generateCompletions} = require("../common/llm");
const {generateImageDescriptionPrompt} = require("../ai/prompts");
const {queueTask,
  POST_SHOULD_FIND_STORIES_AND_STATEMENTS_TASK} = require("../common/tasks");
const {onTaskDispatched} = require("firebase-functions/v2/tasks");


//
// Firestore
//
exports.onPostUpdate = onDocumentWritten(
    {
      document: "posts/{pid}",
      ...defaultConfig,
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

      if (_create && after.xid || _update && before.xid != after.xid) {
        await publishMessage(POST_CHANGED_XID,
            {pid: after?.pid || before?.pid});
      }

      if (after && after.status == "published" &&
        (!before || before.status != "published")) {
        await publishMessage(POST_PUBLISHED, {pid: after.pid});
      }

      if (
        _create && after.vector ||
        _delete && before.vector ||
        _update && !_.isEqual(before.vector, after.vector)) {
        await publishMessage(POST_CHANGED_VECTOR,
            {pid: after?.pid || before?.pid});
      }

      // post changed entity
      if (
        _create && after.eid ||
        _update && before.eid != after.eid ||
        _delete && before.eid
      ) {
        await publishMessage(POST_CHANGED_ENTITY,
            {before: before, after: after});
      }

      if (
        _create && (after.title || after.body ||
          after.description || after.photo) ||
        _delete && (before.title || before.body ||
          before.description || before.photo) ||
        _update && (before.description != after.description ||
          before.title != after.title ||
          before.body != after.body || !_.isEqual(before.photo, after.photo))
      ) {
        await postChangedContent(before, after);
      }

      if (
        _create && (after.sid || !_.isEmpty(after.sids)) ||
        _update && (before.sid != after.sid ||
          !_.isEqual(before.sids, after.sids)) ||
        _delete && (before.sid || !_.isEmpty(before.sids))
      ) {
        await publishMessage(POST_CHANGED_STORIES,
            {before: before, after: after});
      }

      if (
        _create && !_.isEmpty(after.stids) ||
        _update && !_.isEqual(before.stids, after.stids) ||
        _delete && !_.isEmpty(before.stids)
      ) {
        await publishMessage(POST_CHANGED_STATEMENTS,
            {before: before, after: after});
      }

      return Promise.resolve();
    },
);

//
// PubSub
//

/**
 * optionally calls findStoriesAndStatements if the post is published beforehand
 * @param {Message} message
 * @return {Promise<void>}
 * */
exports.onPostChangedVector = onMessagePublished(
    {
      topic: POST_CHANGED_VECTOR,
      ...defaultConfig,
    },
    async (event) => {
      const pid = event.data.message.json.pid;
      const post = await getPost(pid);
      if (!post) {
        return Promise.resolve();
      }

      if (post.status == "published" && post.sid == null) {
        const canFind = await canFindStories(pid);
        if (canFind) {
          await queueTask(POST_SHOULD_FIND_STORIES_AND_STATEMENTS_TASK,
              {pid: pid});
        }
      }

      return Promise.resolve();
    },
);

/**
 * creates the room
 * called when a post is published
 * @param {Message} message
 * @return {Promise<void>}
 */
exports.onPostPublished = onMessagePublished(
    {
      topic: POST_PUBLISHED,
      ...defaultConfig,
    },
    async (event) => {
      const pid = event.data.message.json.pid;
      const post = await getPost(pid);

      if (post && post.vector) {
        const canFind = await canFindStories(pid);
        if (canFind) {
          await queueTask(POST_SHOULD_FIND_STORIES_AND_STATEMENTS_TASK,
              {pid: pid});
        }
      }

      await createNewRoom(pid, "posts");

      return Promise.resolve();
    },
);

/**
 * triggers fetching the post
 * called when a post changed external id
 * @param {Message} message
 * @return {Promise<void>}
 */
exports.onPostChangedXid = onMessagePublished(
    {
      topic: POST_CHANGED_XID,
      ...scrapeConfig,
    },
    async (event) => {
      logger.info(`onPostChangedXid: ${event.data.message.json.pid}`);

      const pid = event.data.message.json.pid;
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
        logger.error(`Unsupported source type: ${post.sourceType}`);
        return Promise.resolve();
      }

      return Promise.resolve();
    },
);

/**
 * TXN
 * Transactional update to store vector
 * Not done as pubsub because we need access to the before and after
 * @param {Post} before
 * @param {Post} after
 */
const postChangedContent = async function(before, after) {
  if (!after) {
    return;
  }

  if (before?.photo?.photoURL != after?.photo?.photoURL &&
     after.photo?.photoURL && !after.photo?.description) {
    const resp = await generateCompletions(
        generateImageDescriptionPrompt(after.photo.photoURL),
        after.pid + " photoURL",
        true,
    );
    if (!resp?.description) {
      logger.error("Error generating image description");
    } else {
      await retryAsyncFunction(() => updatePost(after.pid, {
        "photo.description": resp.description,
      }));
      return;
    }
  }

  const save = await resetPostVector(after.pid);
  if (!save) {
    logger.error(`Could not save post embeddings: ${after.pid}`);
    if (before) {
      return await retryAsyncFunction(() => setPost(before));
    } else {
      return await retryAsyncFunction(() => deletePost(after.pid));
    }
  }
};

//
// FIND STORIES AND STATEMENTS
//

exports.onPostShouldFindStoriesAndStatementsTask = onTaskDispatched(
    {
      retryConfig: {
        maxAttempts: 2,
      },
      rateLimits: {
        maxConcurrentDispatches: 1,
      },
      ...gbConfig,
    },
    async (event) => {
      logger.info(
          `onPostShouldFindStoriesAndStatementsTask: ${event.data.pid}`);
      const pid = event.data.pid;
      await _shouldFindStoriesAndStatements(pid);
      return Promise.resolve();
    },
);

/**
 * Finds stories and statements for a post
 * @param {Message} message
 * @return {Promise<void>}
 * */
exports.onPostShouldFindStoriesAndStatements = onMessagePublished(
    {
      topic: POST_SHOULD_FIND_STORIES_AND_STATEMENTS,
      ...gbConfig,
    },
    async (event) => {
      logger.info(`onPostShouldFindStoriesAndStatementsPubsub: 
        ${event.data.message.json.pid}`);
      const pid = event.data.message.json.pid;
      await _shouldFindStoriesAndStatements(pid);
      return Promise.resolve();
    },
);

const _shouldFindStoriesAndStatements = async function(pid) {
  const post = await getPost(pid);
  await findStoriesAndStatements(post);

  await updatePost(pid, {status: "found"});

  return Promise.resolve();
};
exports.shouldFindStoriesAndStatements = _shouldFindStoriesAndStatements;

//
// Story/Statement sync
//

/**
 * 'TXN' - called from story.js
 * Updates the stories that this Post is part of
 * @param {Story} before
 * @param {Story} after
 */
exports.onStoryChangedPosts = onMessagePublished(
    {
      topic: STORY_CHANGED_POSTS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      await handleChangedRelations(before, after,
          "pids", updatePost, "sid", "sids");
      await handleChangedRelations(before, after,
          "pids", updatePost, "sid", "sid", {}, "manyToOne");
      return Promise.resolve();
    },
);

/**
 * 'TXN' - called from Statement.js
 * Updates the Statements that this Post is part of
 * @param {Statement} before
 * @param {Statement} after
 */
exports.onStatementChangedPosts = onMessagePublished(
    {
      topic: STATEMENT_CHANGED_POSTS,
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      await handleChangedRelations(before,
          after, "pids", updatePost, "stid", "stids");
      return Promise.resolve();
    },
);

/**
 * 'TXN' - called from Entity.js
 * Updates the Entity that this Post is part of
 * @param {Entity} before
 * @param {Entity} after
 */
exports.onEntityChangedPosts = onMessagePublished(
    {
      topic: ENTITY_CHANGED_POSTS, // Make sure to define this topic
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.message.json.before;
      const after = event.data.message.json.after;
      await handleChangedRelations(before, after,
          "pids", updatePost, "eid", "eid", {}, "manyToOne");
      return Promise.resolve();
    },
);
