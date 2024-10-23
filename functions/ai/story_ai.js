const {logger} = require("firebase-functions/v2");
const {getPostsForStory,
  setVector,
  searchVectors,
  getStory,
  updateStory,
  getAllStatementsForStory} = require("../common/database");
const {generateEmbeddings, generateCompletions} = require("../common/llm");
const {calculateMeanVector, retryAsyncFunction} = require("../common/utils");
const _ = require("lodash");
const {writeTrainingData} = require("./trainer");
const {findStoriesPrompt, findContextPrompt} = require("./prompts");

/** FLAGSHIP FUNCTION
 * ***************************************************************
 * Finds context (headline, subheadline, lead) for stories
 * similar to concepts in post_ai.js
 * @param {Story} story
 * @return {Promise<void>}
 * ***************************************************************
 * */
const onStoryShouldFindContext = async function(story) {
  if (!story) {
    logger.warn("Story is null, not finding context");
    return;
  }

  logger.info(`onStoryShouldFindContext for story ${story.sid}`);

  // sets status, but this cannot be relied on for anything other
  // than single update as it can be overridden by other steps
  if (story.status != "findingContext") {
    await retryAsyncFunction(() => updateStory(story.sid, {
      status: "findingContext",
    }));
  }

  const statements = await getAllStatementsForStory(story.sid);
  if (!statements || statements.length === 0) {
    logger.warn(`Story ${story.sid} does not have statements`);
  }

  const resp = await findContext(story, statements);

  if (resp == null) {
    // we don't change the status here since other posts
    // can yield a contextualization
    return;
  }

  const gstory = resp;

  await retryAsyncFunction(() =>
    updateStory(story.sid, {
      ...(gstory.headline && {headline: gstory.headline}),
      ...(gstory.subHeadline && {subHeadline: gstory.subHeadline}),
      ...(gstory.lede && {lede: gstory.lede}),
      ...(gstory.article && {article: gstory.article}),
      status: "foundContext",
    }),
  );

  logger.info(`Done onPostShouldFindStories for post ${story.sid}`);

  return Promise.resolve();
};

/**
 * ***************************************************************
 * Finds and Creates new stories if new stories are detected
 * Splits and merges stories if needed
 *
 * Searches for nearby stories based on vector distance
 * Uses a Neural second pass to find correct stories for the post
 * @param {Post} post
 * @return {Promise<Gstories,Removed>}
 * ***************************************************************
 */
const findStories = async function(post) {
  if (!post) {
    logger.error("Post is null");
    return;
  }

  // use a retriable with longer backoff since the db is eventually consistent
  const vector = post.vector;
  if (!vector) {
    logger.error(`Post does not have a vector! ${post.pid}`);
    // should we add it here??
    return;
  }

  const candidateStories = await searchVectors(vector, "stories");

  logger.info("Found " +
     candidateStories.length + " candidate stories for post " + post.pid);

  candidateStories.forEach((story, index) => {
    logger.info(`Candidate story ${index + 1}: ${story.sid}`);
  });

  const _prompt = findStoriesPrompt({
    post: post,
    stories: candidateStories,
    training: true,
    includePhotos: true,
  });

  const resp = await generateCompletions({
    messages: _prompt,
    loggingText: "findStories " + post.pid,
  });

  if (!resp || !resp.stories || resp.stories.length === 0) {
    logger.warn(`Cannot find Story for post! ${post.pid}`);
    return null;
  }

  writeTrainingData("findStories", post, candidateStories, null, resp);

  return resp;
};

/**
 * ***************************************************************
 * Finds context (headline, subheadline, lead) for stories based on
 * the statements
 * @param {Story} story
 * @param {Array<Statement>} statements
 * @return {Promise<Gstories,Removed>}
 * ***************************************************************
 */
const findContext = async function(story, statements) {
  if (!story) {
    logger.error("Story is null");
    return;
  }

  const _prompt = findContextPrompt({
    story: story,
    statements: statements,
    training: true,
    includePhotos: true,
  });

  const resp = await generateCompletions({
    messages: _prompt,
    loggingText: "findContext " + story.sid,
  });

  if (!resp || !resp.sid) {
    logger.warn(`Story does not have contextualization! ${story.sid}`);
    return null;
  }

  writeTrainingData("findContext", null, [story], statements, resp);

  return resp;
};


/**
 * K MEANS STREAMING ALGORITHM
 * Updates the story vector
 * @param {String} sid - The story id to update
 * @return {Promise<void>}
 * @async
 * */
const resetStoryVector = async function(sid) {
  if (!sid) {
    logger.error(`Could not fetch story to update vector: 
    ${sid}`);
    return;
  }
  const posts = await getPostsForStory(sid);
  const pids = posts.map((post) => post.pid);
  const vectors = _.isEmpty(pids) ? [] : posts.map((post) => post.vector);
  if (vectors.length > 0) {
    // K MEAN STREAMING ALGORITHM

    const mean = calculateMeanVector(vectors);

    try {
      await setVector(sid, mean, "stories");
      return true;
    } catch (e) {
      logger.error("Error saving Story embeddings", e);
      return false;
    }
  }

  // if no vectors, we default to title/description for the vector
  const story = await getStory(sid);
  const strings = getStoryEmbeddingStrings(story);
  if (strings.length === 0) {
    logger.error(`Could not save Story embeddings, 
    no strings! ${sid}`);
    return;
  }

  try {
    // images will need to be added here if we create them
    const embeddings = await generateEmbeddings(strings);
    await setVector(sid, embeddings, "stories");
    // publishMessage(POST_CHANGED_VECTOR, {pid: post.pid});
    return true;
  } catch (e) {
    logger.error("Error saving post embeddings", e);
    return false;
  }
};

/**
 * @param {Story} story
 * @return {Array}
 * @async
 * */
const getStoryEmbeddingStrings = function(story) {
  const ret = [];
  if (story.title) {
    ret.push(story.title);
  }
  if (story.description) {
    ret.push(story.description);
  }
  return ret;
};

module.exports = {
  findStories,
  onStoryShouldFindContext,
  resetStoryVector,
};

