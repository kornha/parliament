const {logger} = require("firebase-functions/v2");
const _ = require("lodash");

const {
  createStatement,
  updateStatement,
  getAllStatementsForStory,
  getAllPostsForStory,
  getAllStatementsForPost,
  updateStory,
  createStory,
  updatePost,
  setVector,
  deleteStory,
  getPost,
  getAllPostsForStatement,
  deleteStatement,
  getAllStoriesForPost,
} = require("../common/database");
const {generateEmbeddings} = require("../common/llm");

const {retryAsyncFunction, isoToMillis} = require("../common/utils");
const {v4} = require("uuid");
const {Timestamp, FieldValue, GeoPoint} = require("firebase-admin/firestore");
const geo = require("geofire-common");
const {findStories, resetStoryVector} = require("./story_ai");
const {findStatements, resetStatementVector} = require("./statement_ai");
// eslint-disable-next-line no-unused-vars
const {publishMessage, POST_SHOULD_FIND_STORIES} =
require("../common/pubsub");
const {queueTask, POST_SHOULD_FIND_STORIES_TASK} =
require("../common/tasks");

/** FLAGSHIP FUNCTION
 * ***************************************************************
 * Finds/creates stories
 * sets posts to stories
 *
 * @param {Post} post
 * @return {Promise<void>}
 * ***************************************************************
 * */
const onPostShouldFindStories = async function(post) {
  if (!post) {
    logger.error("Post is null");
    return;
  }

  logger.info(`onPostShouldFindStories for post ${post.pid}`);

  // sets status, but this cannot be relied on for anything other
  // than single update as it can be overridden by other steps
  if (post.status != "findingStories") {
    await retryAsyncFunction(() => updatePost(post.pid, {
      status: "findingStories",
    }));
  }

  // Finds stories based on 2 leg K-mean/Neural search
  const resp = await findStories(post);
  const gstories = resp.stories;
  const removedSids = resp.removedStories;

  if (!gstories || gstories.length === 0) {
    logger.warn(`Post does not have a gstory! ${post.pid}`);
    return;
  }

  logger.info("Found " +
    gstories.length + " stories for post " + post.pid);

  await Promise.all(gstories.map(async (gstory, index) => {
    const sid = gstory.sid ? gstory.sid : v4();

    logger.info(`Processing story ${sid} for post ${post.pid}`);

    // sets the primary SID (deprecated)
    if (index === 0 && post.sid !== sid) {
      await retryAsyncFunction(() => updatePost(post.pid, {
        sid: sid,
        // updated via callback since the story may not exist yet
        // sids: g2stories.map((gstory) => gstory.sid),
        // stids: order does not matter so we add via callback
      }));
    }

    const location = gstory.lat && gstory.long ? {
      geoPoint: new GeoPoint(gstory.lat, gstory.long),
      geoHash: geo.geohashForLocation([gstory.lat,
        gstory.long]),
    } : null;

    const storyData = {
      title: gstory.title,
      description: gstory.description,
      updatedAt: Timestamp.now().toMillis(),
      createdAt: Timestamp.now().toMillis(),
      photos: gstory.photos ?? [],
      ...(location && {location: location}),
      ...(gstory.happenedAt && {happenedAt: isoToMillis(gstory.happenedAt)}),
    };

    if (gstory.sid) {
      await retryAsyncFunction(() =>
        updateStory(sid, {
          ...storyData,
          pids: FieldValue.arrayUnion(post.pid),
        }),
      );
    } else {
      await retryAsyncFunction(() =>
        createStory({
          sid: sid,
          ...storyData,
          status: "draft",
          pids: [post.pid],
        }),
      );
    }

    // NOTE!: Duplicate logic as in story.js but done here so that later
    // posts find the stories without waiting for a separate update
    await resetStoryVector(sid);
  }));

  if (!_.isEmpty(removedSids)) {
    logger.info(`removing sids ${removedSids}`);

    // Revearse search all posts from the stories
    const changedPosts = (await Promise.all(removedSids.map((sid) =>
      getAllPostsForStory(sid),
    ))).flat();

    if (_.isEmpty(changedPosts)) {
      logger.error(`No posts found, 
      not deleting Stories ${removedSids}`);
    } else {
      // delete stories
      await Promise.all(removedSids.map(async (sid) => {
        await retryAsyncFunction(() => deleteStory(sid));
      }));

      logger.info(`Deleted stories ${removedSids}`);

      changedPosts.forEach(async (post) => {
        // publishMessage(POST_SHOULD_FIND_STORIES,
        // {pid: post.pid});
        queueTask(POST_SHOULD_FIND_STORIES_TASK,
            {pid: post.pid});
      });
    }
  }

  await retryAsyncFunction(() => updatePost(post.pid, {
    status: "foundStories",
  }));

  logger.info(`Done onPostShouldFindStories for post ${post.pid}`);

  return Promise.resolve();
};

/** FLAGSHIP FUNCTION
 * ***************************************************************
 * Find/creates statements
 * sets statements to stories
 *
 * @param {Post} post
 * @return {Promise<void>}
 * ***************************************************************
 * */
const onPostShouldFindStatements = async function(post) {
  if (!post) {
    logger.error("Post is null");
    return;
  }

  logger.info(`onPostShouldFindStatements for post ${post.pid}`);

  // sets status, but this cannot be relied on for anything other
  // than single update as it can be overridden by other steps
  if (post.status != "findingStatements") {
    await retryAsyncFunction(() => updatePost(post.pid, {
      status: "findingStatements",
    }));
  }

  const stories = await getAllStoriesForPost(post.pid);

  if (!stories || stories.length === 0) {
    logger.warn(`Post ${post.pid} has no story, cannot find statements`);
    return;
  }

  // find vector statements

  /**
   * get all neighbor statements P-[2]-C
   * this is a GRAPH search and potentially won't scale with our current db
   */

  const sstatements = (await Promise.all(stories.map(async (story) =>
    story.sid ? (await getAllStatementsForStory(story.sid)) : [],
  ))).flat();

  // Revearse search all posts from the stories
  const posts = (await Promise.all(stories.map((story) =>
    story.sid ? getAllPostsForStory(story.sid) : [],
  ))).flat();

  // get all neighbor statements to these posts
  const pstatements = (await Promise.all(posts.map(async (post) =>
    post.pid ? await getAllStatementsForPost(post.pid) : [],
  ))).flat();

  // merge the statements and dedupe
  const statements = _.uniqBy([...sstatements, ...pstatements], "stid");

  const g2stories = await findStatements(post, stories, statements);

  if (_.isEmpty(g2stories)) {
    logger.warn(`Could not generate statements for post. 
      Orphaned! ${post.pid}`);
    return;
  }

  await Promise.all(g2stories.map(async (gstoryStatement, index) => {
    const sid = gstoryStatement.sid ? gstoryStatement.sid : v4();

    logger.info(`Processing g2story ${sid} for post ${post.pid}`);

    if (!_.isEmpty(gstoryStatement.statements)) {
      await Promise.all(gstoryStatement.statements.map(async (gstatement) => {
        const stid = gstatement.stid ? gstatement.stid : v4();
        const statementData = {
          value: gstatement.value,
          context: gstatement.context,
          type: gstatement.type,
          updatedAt: Timestamp.now().toMillis(),
          statedAt: isoToMillis(gstatement.statedAt),
          sids: FieldValue.arrayUnion(sid),
          pids: FieldValue.arrayUnion(post.pid),
          eids: FieldValue.arrayUnion(post.eid),
          ...(gstatement.side === "pro" &&
              {pro: FieldValue.arrayUnion(post.pid)}),
          ...(gstatement.side === "against" &&
              {against: FieldValue.arrayUnion(post.pid)}),
        };

        if (gstatement.stid) {
          logger.info("Processing statement " +
            gstatement.stid + " for story " + sid + ", for post " + post.pid);

          await retryAsyncFunction(() => updateStatement(stid, statementData));
        } else {
          logger.info("Creating statement " +
            stid + " for story " + sid + ", from post " + post.pid);

          await retryAsyncFunction(() =>
            createStatement({
              stid: stid,
              ...statementData,
              createdAt: Timestamp.now().toMillis(),
              pro: gstatement.side === "pro" ? [post.pid] : [],
              against: gstatement.side === "against" ? [post.pid] : [],
            }),
          );
        }

        // Update statement vector for search indexing
        await resetStatementVector(stid);
      }));
    }

    // handle removed statements
    if (!_.isEmpty(gstoryStatement.removedStatements)) {
      // get all posts that will be affected by the removal
      const changedPosts = (await Promise.all(gstoryStatement.removedStatements
          .map((stid) => getAllPostsForStatement(stid),
          ))).flat();

      if (_.isEmpty(changedPosts)) {
        logger.error(`No posts found, 
        not deleting Statements ${gstoryStatement.removedStatements}`);
      } else {
        // delete statements
        await Promise.all(gstoryStatement.removedStatements
            .map(async (stid) => {
              await retryAsyncFunction(() => deleteStatement(stid));
            }));

        logger.info(`Deleted statements ${gstoryStatement.removedStatements}`);

        changedPosts.forEach(async (post) => {
        // publishMessage(POST_SHOULD_FIND_STORIES,
        // {pid: post.pid});
          queueTask(POST_SHOULD_FIND_STORIES_TASK,
              {pid: post.pid});
        });
      }
    }
  }));

  await retryAsyncFunction(() => updatePost(post.pid, {
    status: "foundStatements",
  }));

  logger.info(`Done onPostShouldFindStatements for post ${post.pid}`);

  return Promise.resolve();
};

/**
 * Fetches the post embeddings from OpenAI and saves them to the database
 * returns nothing if there are no qualified post embeddings
 * publishes a message to the PubSub topic POST_CHANGED_VECTOR
 * @param {String} pid
 * @return {Promise<boolean>}
 */
const resetPostVector = async function(pid) {
  const post = await getPost(pid);
  if (!post) {
    logger.error(`Post not found: ${pid}`);
    return false;
  }
  const strings = getPostEmbeddingStrings(post);
  if (strings.length === 0) {
    return true;
  }

  const embeddings = await generateEmbeddings(strings);
  return await setVector(post.pid, embeddings, "posts");
};

/**
 * Fetches the strings to embed for a post
 * @param {Post} post
 * @return {string[]}
 */
const getPostEmbeddingStrings = function(post) {
  const ret = [];
  if (post.title) {
    ret.push(post.title);
  }
  if (post.body) {
    ret.push(post.body);
  }
  if (post.photo?.description) {
    ret.push(post.photo.description);
  }
  return ret;
};

module.exports = {
  onPostShouldFindStories,
  onPostShouldFindStatements,
  resetPostVector,
  getPostEmbeddingStrings,
};
