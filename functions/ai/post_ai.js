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
} = require("../common/database");
const {generateEmbeddings} = require("../common/llm");

const {retryAsyncFunction, isoToMillis} = require("../common/utils");
const {v4} = require("uuid");
const {Timestamp, FieldValue, GeoPoint} = require("firebase-admin/firestore");
const geo = require("geofire-common");
const {findStories, resetStoryVector} = require("./story_ai");
const {findStatements, resetStatementVector} = require("./statement_ai");
// eslint-disable-next-line no-unused-vars
const {publishMessage, POST_SHOULD_FIND_STORIES_AND_STATEMENTS} =
require("../common/pubsub");
const {POST_SHOULD_FIND_STORIES_AND_STATEMENTS_TASK, queueTask} =
require("../common/tasks");

/** FLAGSHIP FUNCTION
 * ***************************************************************
 * Finds/creates stories, find/creates statements, find/creates opinions
 * sets statements to stories, statements to posts, and posts to stories
 *
 * @param {Post} post
 * @return {Promise<void>}
 * ***************************************************************
 * */
const findStoriesAndStatements = async function(post) {
  if (!post) {
    logger.error("Post is null");
    return;
  }

  logger.info(`findStoriesAndStatements for post ${post.pid}`);

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

  // find vector statements
  //

  /**
   * get all neighbor statements P-[2]-C
   * this is a GRAPH search and potentially won't scale with our current db
   */

  const sstatements = (await Promise.all(gstories.map(async (gstory) =>
    gstory.sid ? (await getAllStatementsForStory(gstory.sid)) : [],
  ))).flat();

  // Revearse search all posts from the stories
  const posts = (await Promise.all(gstories.map((gstory) =>
    gstory.sid ? getAllPostsForStory(gstory.sid) : [],
  ))).flat();

  // get all neighbor statements to these posts
  const pstatements = (await Promise.all(posts.map(async (post) =>
  post.pid ? await getAllStatementsForPost(post.pid) : [],
  ))).flat();

  // merge the statements and dedupe
  const statements = _.uniqBy([...sstatements, ...pstatements], "stid");

  const g2stories = await findStatements(post, gstories, statements);

  if (_.isEmpty(g2stories)) {
    logger.warn(`Could not generate stories or statements for post. 
      Orphaned! ${post.pid}`);
    return;
  }

  await Promise.all(g2stories.map(async (gstoryStatement, index) => {
    const sid = gstoryStatement.sid ? gstoryStatement.sid : v4();

    logger.info(`Processing story ${sid} for post ${post.pid}`);

    if (index === 0 && post.sid !== sid) {
      await retryAsyncFunction(() => updatePost(post.pid, {
        sid: sid,
        // updated via callback since the story may not exist yet
        // sids: g2stories.map((gstory) => gstory.sid),
        // stids: order does not matter so we add via callback
      }));
    }

    const location = gstoryStatement.lat && gstoryStatement.long ? {
      geoPoint: new GeoPoint(gstoryStatement.lat, gstoryStatement.long),
      geoHash: geo.geohashForLocation([gstoryStatement.lat,
        gstoryStatement.long]),
    } : null;


    if (gstoryStatement.sid) {
      await retryAsyncFunction(() => updateStory(sid, {
        title: gstoryStatement.title,
        description: gstoryStatement.description,
        headline: gstoryStatement.headline,
        subHeadline: gstoryStatement.subHeadline,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: Timestamp.now().toMillis(),
        pids: FieldValue.arrayUnion(post.pid),
        importance: gstoryStatement.importance ?? 0.0,
        photos: gstoryStatement.photos ?? [],
        ...(location && {location: location}),
        ...(gstoryStatement.happenedAt &&
          {happenedAt: isoToMillis(gstoryStatement.happenedAt)}),
        // updated via callback since the statement may not exist yet
        // stids: FieldValue.arrayUnion(
        //     ...gstoryStatement.statements
        // .map((gstatement) => gstatement.stid)),
      }));
    } else {
      await retryAsyncFunction(() => createStory({
        sid: sid,
        title: gstoryStatement.title,
        headline: gstoryStatement.headline,
        subHeadline: gstoryStatement.subHeadline,
        description: gstoryStatement.description,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: Timestamp.now().toMillis(),
        importance: gstoryStatement.importance ?? 0.0,
        pids: [post.pid],
        photos: gstoryStatement.photos ?? [],
        ...(location && {location: location}),
        ...(gstoryStatement.happenedAt &&
          {happenedAt: isoToMillis(gstoryStatement.happenedAt)}),
        // updated via callback since the statement may not exist
        // stids: gstoryStatement.statements
        // .map((gstatement) => gstatement.stid),
      }));
    }

    // NOTE!: Duplicate logic as in story.js but done here so that later
    // posts find the stories without waiting for a separate update
    await resetStoryVector(sid);

    if (!_.isEmpty(gstoryStatement.statements)) {
      await Promise.all(gstoryStatement.statements.map(async (gstatement) => {
        const stid = gstatement.stid ? gstatement.stid : v4();
        if (gstatement.stid) {
          logger.info("Processing statement " +
             gstatement.stid + " for story " + sid + ", for post " + post.pid);

          await retryAsyncFunction(() => updateStatement(stid, {
            sids: FieldValue.arrayUnion(sid),
            pids: FieldValue.arrayUnion(post.pid), // cause error if deleted?
            eids: FieldValue.arrayUnion(post.eid),
            value: gstatement.value,
            context: gstatement.context,
            type: gstatement.type,
            updatedAt: Timestamp.now().toMillis(),
            statedAt: isoToMillis(gstatement.statedAt),
            // some grade a level horse shit to get around
            // arrayUnion unioning an empty array
            ...(gstatement.pro?.length &&
              {pro: FieldValue.arrayUnion(...gstatement.pro)}),
            ...(gstatement.against?.length &&
              {against: FieldValue.arrayUnion(...gstatement.against)}),
          }));
        } else {
          logger.info("Creating statement " +
            stid + " for story " + sid + ", from post " + post.pid);

          await retryAsyncFunction(() => createStatement({
            stid: stid,
            value: gstatement.value,
            pro: gstatement.pro,
            against: gstatement.against,
            context: gstatement.context,
            type: gstatement.type,
            sids: [sid],
            pids: [post.pid],
            eids: [post.eid],
            statedAt: isoToMillis(gstatement.statedAt),
            updatedAt: Timestamp.now().toMillis(),
            createdAt: Timestamp.now().toMillis(),
          }));
        }

        // save embedding here to avoid race condition
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
        // publishMessage(POST_SHOULD_FIND_STORIES_AND_STATEMENTS,
        // {pid: post.pid});
          queueTask(POST_SHOULD_FIND_STORIES_AND_STATEMENTS_TASK,
              {pid: post.pid});
        });
      }
    }
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
        // publishMessage(POST_SHOULD_FIND_STORIES_AND_STATEMENTS,
        // {pid: post.pid});
        queueTask(POST_SHOULD_FIND_STORIES_AND_STATEMENTS_TASK,
            {pid: post.pid});
      });
    }
  }


  logger.info(`Done findStoriesAndStatements for post ${post.pid}`);

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
  if (post.description) {
    ret.push(post.description);
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
  findStoriesAndStatements,
  resetPostVector,
  getPostEmbeddingStrings,
};
