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
  deleteStory,
} = require("../common/database");
const {generateEmbeddings} = require("../common/llm");

const {retryAsyncFunction, isoToMillis} = require("../common/utils");
const {v4} = require("uuid");
const {Timestamp, FieldValue, GeoPoint} = require("firebase-admin/firestore");
const geo = require("geofire-common");
const {findStories, resetStoryVector} = require("./story_ai");
const {findClaims} = require("./claim_ai");
// eslint-disable-next-line no-unused-vars
const {publishMessage, POST_SHOULD_FIND_STORIES_AND_CLAIMS} =
require("../common/pubsub");
const {POST_SHOULD_FIND_STORIES_AND_CLAIMS_TASK, queueTask} =
require("../common/tasks");

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

  functions.logger.info(`findStoriesAndClaims for post ${post.pid}`);

  // Finds stories based on 2 leg K-mean/Neural search
  const resp = await findStories(post);
  const gstories = resp.stories;
  const removedSids = resp.removed;

  if (!gstories || gstories.length === 0) {
    functions.logger.warn(`Post does not have a gstory! ${post.pid}`);
    return;
  }

  functions.logger.info("Found " +
    gstories.length + " stories for post " + post.pid);


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

  const g2stories = await findClaims(post, gstories, claims);

  if (_.isEmpty(g2stories)) {
    functions.logger.warn(`Could not generate stories or claims for post. 
      Orphaned! ${post.pid}`);
    return;
  }

  await Promise.all(g2stories.map(async (gstoryClaim, index) => {
    const sid = gstoryClaim.sid ? gstoryClaim.sid : v4();

    functions.logger.info(`Processing story ${sid} for post ${post.pid}`);

    if (index === 0 && post.sid !== sid) {
      await retryAsyncFunction(() => updatePost(post.pid, {
        sid: sid,
        // updated via callback since the story may not exist yet
        // sids: g2stories.map((gstory) => gstory.sid),
        // cids: order does not matter so we add via callback
      }));
    }

    const location = gstoryClaim.lat && gstoryClaim.long ? {
      geoPoint: new GeoPoint(gstoryClaim.lat, gstoryClaim.long),
      geoHash: geo.geohashForLocation([gstoryClaim.lat, gstoryClaim.long]),
    } : null;


    if (gstoryClaim.sid) {
      await retryAsyncFunction(() => updateStory(sid, {
        title: gstoryClaim.title,
        description: gstoryClaim.description,
        headline: gstoryClaim.headline,
        subHeadline: gstoryClaim.subHeadline,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: Timestamp.now().toMillis(),
        pids: FieldValue.arrayUnion(post.pid),
        importance: gstoryClaim.importance ?? 0.0,
        photos: gstoryClaim.photos ?? [],
        ...(location && {location: location}),
        ...(gstoryClaim.happenedAt &&
          {happenedAt: isoToMillis(gstoryClaim.happenedAt)}),
        // updated via callback since the claim may not exist yet
        // cids: FieldValue.arrayUnion(
        //     ...gstoryClaim.claims.map((gclaim) => gclaim.cid)),
      }));
    } else {
      await retryAsyncFunction(() => createStory({
        sid: sid,
        title: gstoryClaim.title,
        headline: gstoryClaim.headline,
        subHeadline: gstoryClaim.subHeadline,
        description: gstoryClaim.description,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: Timestamp.now().toMillis(),
        importance: gstoryClaim.importance ?? 0.0,
        pids: [post.pid],
        photos: gstoryClaim.photos ?? [],
        ...(location && {location: location}),
        ...(gstoryClaim.happenedAt &&
          {happenedAt: isoToMillis(gstoryClaim.happenedAt)}),
        // updated via callback since the claim may not exist
        // cids: gstoryClaim.claims.map((gclaim) => gclaim.cid),
      }));
    }
    // NOTE!: Duplicate logic as in story.js but done here so that later
    // posts find the stories without waiting for a separate update
    await resetStoryVector(sid);

    if (!_.isEmpty(gstoryClaim.claims)) {
      await Promise.all(gstoryClaim.claims.map(async (gclaim) => {
        if (gclaim.cid) {
          functions.logger.info("Processing claim " +
             gclaim.cid + " for story " + sid + ", for post " + post.pid);

          await retryAsyncFunction(() => updateClaim(gclaim.cid, {
            sids: FieldValue.arrayUnion(sid),
            pids: FieldValue.arrayUnion(post.pid),
            value: gclaim.value,
            updatedAt: Timestamp.now().toMillis(),
            claimedAt: isoToMillis(gclaim.claimedAt),
            // some grade a level horse shit to get around
            // arrayUnion unioning an empty array
            ...(gclaim.pro?.length &&
              {pro: FieldValue.arrayUnion(...gclaim.pro)}),
            ...(gclaim.against?.length &&
              {against: FieldValue.arrayUnion(...gclaim.against)}),
          }));
        } else {
          const _cid = v4();

          functions.logger.info("Creating claim " +
            _cid + " for story " + sid + ", from post " + post.pid);

          await retryAsyncFunction(() => createClaim({
            cid: _cid,
            value: gclaim.value,
            pro: gclaim.pro,
            against: gclaim.against,
            sids: [sid],
            pids: [post.pid],
            claimedAt: isoToMillis(gclaim.claimedAt),
            updatedAt: Timestamp.now().toMillis(),
            createdAt: Timestamp.now().toMillis(),
          }));
        }
      }));
    }
  }));

  if (!_.isEmpty(removedSids)) {
    functions.logger.info(`removing sids ${removedSids}`);

    // Revearse search all posts from the stories
    const changedPosts = (await Promise.all(removedSids.map((sid) =>
      getAllPostsForStory(sid),
    ))).flat();

    if (_.isEmpty(changedPosts)) {
      functions.logger.error(`No posts found, 
      not deleting Stories ${removedSids}`);
    } else {
      // delete stories
      await Promise.all(removedSids.map(async (sid) => {
        await retryAsyncFunction(() => deleteStory(sid));
      }));

      functions.logger.info(`Deleted stories ${removedSids}`);

      changedPosts.forEach(async (post) => {
        // publishMessage(POST_SHOULD_FIND_STORIES_AND_CLAIMS, {pid: post.pid});
        queueTask(POST_SHOULD_FIND_STORIES_AND_CLAIMS_TASK, {pid: post.pid});
      });
    }
  }


  functions.logger.info(`Done findStoriesAndClaims for post ${post.pid}`);

  return Promise.resolve();
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
  findStoriesAndClaims,
  savePostEmbeddings,
  getPostEmbeddingStrings,
};
