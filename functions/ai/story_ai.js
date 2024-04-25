const functions = require("firebase-functions");
const {getPostsForStory, updateStory,
  getAllPostsForStory,
  getAllClaimsForPost,
  setStory,
  setVector} = require("../common/database");
const {Timestamp} = require("firebase-admin/firestore");
const {generateCompletions, generateEmbeddings} = require("../common/llm");
const {calculateMeanVector, isoToMillis} = require("../common/utils");
const {regenerateStoryPrompt, findClaimsForStoryPrompt} = require("./prompts");
const {getPostEmbeddingStrings} = require("./post_ai");
const _ = require("lodash");


/**
 * Fetches all posts that mention this story to generate content
 * @param {Story} story - The story id to regenerate
 * @return {Promise<void>}
 * @async
 * */
const regenerateStory = async function(story) {
  if (!story || !story.sid) {
    functions.logger.error(`Could not fetch story to regenerate: ${story.sid}`);
    return;
  }
  const posts = await getAllPostsForStory(story.sid);
  const [primary, secondary] = posts.reduce(([p, s], post) =>
    post.sid == story.sid ? [[...p, post], s] : [p, [...s, post]], [[], []]);

  const gstory =
    await generateCompletions(regenerateStoryPrompt(story, primary, secondary));

  if (!gstory || !gstory.sid) {
    functions.logger.error(`Could not regenerate story: ${story.sid}`);
    return;
  }

  const {title, description, _createdAt} = gstory;
  let createdAt;
  if (_createdAt) {
    createdAt = isoToMillis(_createdAt);
  }

  if (title == null || description == null) {
    functions.logger.error(`Invalid generation: ${gstory}`);
    return;
  }

  if (title == story.title &&
      description == story.description && createdAt == story.createdAt) {
    functions.logger.info(`No changes to story: ${story.sid}`);
    return;
  }


  updateStory(story.sid, {
    title: title,
    description: description,
    updatedAt: Timestamp.now().toMillis(),
    createdAt: createdAt ?? story.createdAt ?? Timestamp.now().toMillis(),
  });
};

/**
 * K MEANS STREAMING ALGORITHM
 * Updates the story vector
 * @param {Story} story - The story id to update
 * @return {Promise<void>}
 * @async
 * */
const resetStoryVector = async function(story) {
  if (!story || !story.sid) {
    functions.logger.error(`Could not fetch story to update vector: 
    ${story.sid}`);
    return;
  }
  const posts = await getPostsForStory(story.sid);
  const pids = posts.map((post) => post.pid);
  const vectors = _.isEmpty(pids) ? [] : posts.map((post) => post.vector);
  if (vectors.length > 0) {
    // K MEAN STREAMING ALGORITHM

    const mean = calculateMeanVector(vectors);

    try {
      await setVector(story.sid, mean, "stories");
      return true;
    } catch (e) {
      functions.logger.error("Error saving Story embeddings", e);
      return false;
    }
  }

  // if no vectors, we default to title/description for the vector
  const strings = getStoryEmbeddingStrings(story);
  if (strings.length === 0) {
    functions.logger.error(`Could not save Story embeddings, 
    no strings! ${story.sid}`);
    return;
  }

  try {
    const embeddings = await generateEmbeddings(strings);
    await setVector(story.sid, embeddings, "stories");
    // publishMessage(POST_CHANGED_VECTOR, {pid: post.pid});
    return true;
  } catch (e) {
    functions.logger.error("Error saving post embeddings", e);
    return false;
  }
};

/**
 * Currently calls getPostEmbeddingStrings
 * @param {Story} story
 * @return {Array}
 * @async
 * */
const getStoryEmbeddingStrings = function(story) {
  return getPostEmbeddingStrings(story);
};

/**
 * Find claims for a story
 * @param {Story} story
 * @return {Promise<void>}
 * */
const findClaimsForStory = async function(story) {
  if (!story || !story.sid) {
    functions.logger.error(`Could not fetch claims for story: ${story.sid}`);
    return;
  }

  const posts = await getAllPostsForStory(story.sid);
  const claims =
  (await Promise.all(posts.map((post) =>
    getAllClaimsForPost(post.pid)))).flat();

  if (_.isEmpty(claims)) {
    functions.logger.info(`Could not find Claims for Story ${story.sid}`);
    return;
  }

  const gcids =
    await generateCompletions(findClaimsForStoryPrompt(story, claims));

  if (_.isEmpty(gcids.cids)) {
    functions.logger.info(`Could not find Claims for Story ${story.sid}`);
    return;
  }

  setStory(story.sid, {cids: gcids.cids});
  return Promise.resolve();
};

module.exports = {
  regenerateStory,
  resetStoryVector,
  findClaimsForStory,
};

