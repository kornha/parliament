const functions = require("firebase-functions");
const {getPostsForStory,
  setVector} = require("../common/database");
const {generateEmbeddings} = require("../common/llm");
const {calculateMeanVector} = require("../common/utils");
const {getPostEmbeddingStrings} = require("./post_ai");
const _ = require("lodash");

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
    // images will need to be added here if we create them
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

module.exports = {
  resetStoryVector,
};

