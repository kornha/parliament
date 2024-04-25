const functions = require("firebase-functions");
const _ = require("lodash");

const {setPost,
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

const {findStoriesPrompt,
  findClaimsPrompt, findStoriesAndClaimsPrompt} = require("./prompts");
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
  const gstories = await findStories(post);

  const sclaims = (await Promise.all(gstories.map(async (gstory) =>
  gstory.sid ? (await getAllClaimsForStory(gstory.sid)).map((claim) => ({
    ...claim,
    context: gstory.title + " " + gstory.description,
  })) : [],
  ))).flat();

  const posts = (await Promise.all(gstories.map((gstory) =>
    gstory.sid ? getAllPostsForStory(gstory.sid) : [],
  ))).flat();

  const pclaims = (await Promise.all(posts.map(async (post) =>
  post.pid ? (await getAllClaimsForPost(post.pid)).map((claim) => ({
    ...claim,
    context: post.title + " " + post.description,
  })) : [],
  ))).flat();

  // merge the claims and dedupe
  const claims = _.uniqBy([...sclaims, ...pclaims], "cid");

  // Note we need not remove the claims already from the post

  // const mergedStories
  const resp =
    await generateCompletions(
        findStoriesAndClaimsPrompt(post, gstories, claims));

  const stories = resp.stories;

  let i = 0; // need I since we set post on first iteration
  for (const gstoryClaim of stories) {
    const sid = gstoryClaim.sid ? gstoryClaim.sid : v4();

    if (i === 0) {
      await retryAsyncFunction(() => updatePost(post.pid, {
        sid: sid,
        // updated via callback since the story may not exist yet
        // sids: stories.map((gstory) => gstory.sid),
        // cids: order does not matter so we add via callback
      }));
    }

    if (gstoryClaim.sid) {
      await retryAsyncFunction(() => updateStory(gstoryClaim.sid, {
        title: gstoryClaim.title,
        description: gstoryClaim.description,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: isoToMillis(gstoryClaim.createdAt),
        pids: FieldValue.arrayUnion(post.pid),
        // updated via callback since the claim may not exist yet
        // cids: FieldValue.arrayUnion(
        //     ...gstoryClaim.claims.map((gclaim) => gclaim.cid)),
      }));
    } else {
      await retryAsyncFunction(() => createStory({
        sid: sid,
        title: gstoryClaim.title,
        description: gstoryClaim.description,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: isoToMillis(gstoryClaim.createdAt),
        pids: [post.pid],
        // updated via callback since the claim may not exist
        // cids: gstoryClaim.claims.map((gclaim) => gclaim.cid),
      }));
    }
    if (!_.isEmpty(gstoryClaim.claims)) {
      gstoryClaim.claims.forEach((gclaim) => {
        if (gclaim.cid) {
          retryAsyncFunction(() => updateClaim(gclaim.cid, {
            sids: FieldValue.arrayUnion(sid),
            pids: FieldValue.arrayUnion(post.pid),
            against: FieldValue.arrayUnion(...gclaim.pro),
            pro: FieldValue.arrayUnion(...gclaim.pro),
            value: gclaim.value,
            updatedAt: Timestamp.now().toMillis(),
          }));
        } else {
          retryAsyncFunction(() => createClaim({
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
      });
    }
    i++;
  }

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

  const resp = await generateCompletions(findStoriesPrompt(post, stories));

  if (!resp || !resp.stories || resp.stories.length === 0) {
    functions.logger.info(`Post does not have a story! ${post.pid}`);
    return;
  }

  return resp.stories;
  // const sids = [];

  // for (const gstory of resp.stories) {
  //   if (gstory.sid) {
  //     sids.push(gstory.sid);
  //   } else {
  //     const sid = v4();
  //     // TODO: Ugly, change
  //     const createdAt = gstory.createdAt != null ?
  //      isoToMillis(gstory.createdAt) : Timestamp.now().toMillis();
  //     const saved = await retryAsyncFunction(() => createStory({
  //       sid: sid,
  //       title: gstory.title,
  //       description: gstory.description,
  //       updatedAt: createdAt,
  //       createdAt: createdAt,
  //     }));
  //     if (saved) sids.push(sid);
  //   }
  // }

  // if (sids.length === 0) {
  //   functions.logger.error(`Could not generate stories for post.
  //    Orphaned! ${post.pid}`);
  //   return;
  // }

  // setPost(post.pid, {sid: sids[0], sids: sids});
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
  return ret;
};

//
// Deprecated
//

/**
 * ***************************************************************
 * Creates new claims if new claims are detected
 * Sets the Claims for the Post
 *
 * Searches for nearby claims based on vector distance
 * Uses a Neural second pass to find correct claims for the post
 * @param {Post} post
 * @return {Promise<void>}
 * ***************************************************************
 */
const findClaims = async function(post) {
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


  const claims = await searchVectors(vector, "claims");

  const resp = await generateCompletions(findClaimsPrompt(post, claims));

  if (!resp || !resp.claims || resp.claims.length === 0) {
    functions.logger.info(`Post does not have a claim! ${post.pid}`);
    return;
  }

  const cids = [];
  for (const gclaim of resp.claims) {
    if (gclaim.cid) {
      cids.push(gclaim.cid);
      // NOTE! we update this separately from the claim pids
      // Since we have reference to the pro/against here
      if (!_.isEmpty(gclaim.pro) || !_.isEmpty(gclaim.against)) {
        retryAsyncFunction(() => updateClaim(gclaim.cid, {
          pro: FieldValue.arrayUnion(gclaim.pro),
          against: FieldValue.arrayUnion(gclaim.against),
        }));
      }
    } else {
      const cid = v4();
      const saved = await retryAsyncFunction(() => createClaim({
        cid: cid,
        value: gclaim.value,
        context: gclaim.context,
        pro: gclaim.pro,
        against: gclaim.against,
        updatedAt: Timestamp.now().toMillis(),
        createdAt: Timestamp.now().toMillis(),
      }));
      if (saved) cids.push(cid);
    }
  }

  if (cids.length === 0) {
    // Warn since a post may not have claims
    functions.logger.warn(`Could not generate Claims for Post ${post.pid}`);
    return;
  }
  retryAsyncFunction(() => setPost(post.pid, {cids: cids}));
};


module.exports = {
  findStories,
  findClaims,
  findStoriesAndClaims,
  savePostEmbeddings,
  getPostEmbeddingStrings,
};
