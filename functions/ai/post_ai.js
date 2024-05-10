const functions = require("firebase-functions");
const _ = require("lodash");

const {
  createClaim,
  updateClaim,
  getAllClaimsForStory,
  getAllPostsForStory,
  getAllClaimsForPost,
  updateStory,
  createStory,
  updatePost,
  setVector,
  searchVectors} = require("../common/database");
const {generateCompletions, generateEmbeddings} = require("../common/llm");

const {findStoriesPrompt, findStoriesAndClaimsPrompt} = require("./prompts");
const {retryAsyncFunction, isoToMillis} = require("../common/utils");
const {v4} = require("uuid");
const {Timestamp, FieldValue} = require("firebase-admin/firestore");


/** FLAGSHIP FUNCTION
 * ***************************************************************
 * Finds/creates stories, find/creates claims
 * sets claims to stories, claims to posts, and posts to stories
 *
 * @param {Post} post
 * @return {Promise<void>}
 * ***************************************************************
 * */
const findStoriesAndClaims = async function(post) {
  if (!post) {
    functions.logger.error("Post is null");
    return;
  }

  functions.logger.info(`Finding stories and claims for post ${post.pid}`);

  // Finds stories based on 2 leg K-mean/Neural search
  const gstories = await findStories(post);

  if (!gstories || gstories.length === 0) {
    functions.logger.warn(`Post does not have a gstory! ${post.pid}`);
    return;
  }

  // get all neighbor claims
  // this is a GRAPH search and potentially won't scare with our current db
  const sclaims = (await Promise.all(gstories.map(async (gstory) =>
  gstory.sid ? (await getAllClaimsForStory(gstory.sid)).map((claim) => ({
    ...claim,
    context: gstory.title + " " + gstory.description,
  })) : [],
  ))).flat();

  // Revearse search all posts from the stories
  const posts = (await Promise.all(gstories.map((gstory) =>
    gstory.sid ? getAllPostsForStory(gstory.sid) : [],
  ))).flat();

  // get all neighbor claims to these posts
  const pclaims = (await Promise.all(posts.map(async (post) =>
  post.pid ? (await getAllClaimsForPost(post.pid)).map((claim) => ({
    ...claim,
    context: post.title + " " + post.description,
  })) : [],
  ))).flat();

  // merge the claims and dedupe
  // this represents all P-[2]-C claims
  const claims = _.uniqBy([...sclaims, ...pclaims], "cid");

  // Note we need not remove the claims already from the post

  const resp =
    await generateCompletions(
        findStoriesAndClaimsPrompt(post, gstories, claims),
        "findStoriesAndClaims " + post.pid);

  const g2stories = resp.stories;

  if (_.isEmpty(g2stories)) {
    functions.logger.warn(`Could not generate stories or claims for post. 
      Orphaned! ${post.pid}`);
    return;
  }

  await Promise.all(g2stories.map(async (gstoryClaim, index) => {
    const sid = gstoryClaim.sid ? gstoryClaim.sid : v4();

    if (gstoryClaim.sid) {
      await retryAsyncFunction(() => updateStory(sid, {
        title: gstoryClaim.title,
        description: gstoryClaim.description,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: Timestamp.now().toMillis(),
        pids: FieldValue.arrayUnion(post.pid),
        importance: gstoryClaim.importance ?? 0.0,
        ...(gstoryClaim.happenedAt &&
          {happenedAt: isoToMillis(gstoryClaim.happenedAt)}),
        // updated via callback since the claim may not exist yet
        // cids: FieldValue.arrayUnion(
        //     ...gstoryClaim.claims.map((gclaim) => gclaim.cid)),
      }));
    } else {
      if (index === 0) {
        await retryAsyncFunction(() => updatePost(post.pid, {
          sid: sid,
        // updated via callback since the story may not exist yet
        // sids: g2stories.map((gstory) => gstory.sid),
        // cids: order does not matter so we add via callback
        }));
      }

      await retryAsyncFunction(() => createStory({
        sid: sid,
        title: gstoryClaim.title,
        description: gstoryClaim.description,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: Timestamp.now().toMillis(),
        importance: gstoryClaim.importance ?? 0.0,
        pids: [post.pid],
        ...(gstoryClaim.happenedAt &&
          {happenedAt: isoToMillis(gstoryClaim.happenedAt)}),
        // updated via callback since the claim may not exist
        // cids: gstoryClaim.claims.map((gclaim) => gclaim.cid),
      }));
    }
    if (!_.isEmpty(gstoryClaim.claims)) {
      await Promise.all(gstoryClaim.claims.map(async (gclaim) => {
        if (gclaim.cid) {
          await retryAsyncFunction(() => updateClaim(gclaim.cid, {
            sids: FieldValue.arrayUnion(sid),
            pids: FieldValue.arrayUnion(post.pid),
            value: gclaim.value,
            updatedAt: Timestamp.now().toMillis(),
            // some grade a level horse shit to get around
            // arrayUnion unioning an empty array
            ...(gclaim.pro?.length &&
              {pro: FieldValue.arrayUnion(...gclaim.pro)}),
            ...(gclaim.against?.length &&
              {against: FieldValue.arrayUnion(...gclaim.against)}),
          }));
        } else {
          await retryAsyncFunction(() => createClaim({
            cid: v4(),
            value: gclaim.value,
            pro: gclaim.pro,
            against: gclaim.against,
            sids: [sid],
            pids: [post.pid],
            updatedAt: Timestamp.now().toMillis(),
            createdAt: Timestamp.now().toMillis(),
          }));
        }
      }));
    }
  }));

  functions.logger.info(`Done find stories and claims for post ${post.pid}`);

  return Promise.resolve();
};

/**
 * ***************************************************************
 * Finds and Creates new stories if new stories are detected
 *
 * Searches for nearby stories based on vector distance
 * Uses a Neural second pass to find correct stories for the post
 * @param {Post} post
 * @return {Promise<void>}
 * ***************************************************************
 */
const findStories = async function(post) {
  if (!post) {
    functions.logger.error("Post is null");
    return;
  }

  // use a retriable with longer backoff since the db is eventually consistent
  const vector = post.vector;
  if (!vector) {
    functions.logger.error(`Post does not have a vector! ${post.pid}`);
    // should we add it here??
    return;
  }

  const stories = await searchVectors(vector, "stories");
  if (!stories || stories.length === 0) {
    // functions.logger.info(`Post does not have a story! ${post.pid}`);
  }
  const resp = await generateCompletions(findStoriesPrompt(post, stories),
      "findStories " + post.pid);

  if (!resp || !resp.stories || resp.stories.length === 0) {
    functions.logger.info(`Post does not have a story! ${post.pid}`);
    return;
  }

  return resp.stories;
};


/**
 * Fetches the post embeddings from OpenAI and saves them to the database
 * returns nothing if there are no qualified post embeddings
 * publishes a message to the PubSub topic POST_CHANGED_VECTOR
 * @param {Post} post
 * @return {Promise<boolean>}
 */
const savePostEmbeddings = async function(post) {
  const strings = getPostEmbeddingStrings(post);
  if (strings.length === 0) {
    return true;
  }

  const embeddings = await generateEmbeddings(strings, post.photoURL);
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
  return ret;
};

module.exports = {
  findStories,
  findStoriesAndClaims,
  savePostEmbeddings,
  getPostEmbeddingStrings,
};
