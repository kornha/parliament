const {logger} = require("firebase-functions/v2");
const {getPostsForStory,
  setVector,
  searchVectors,
  getStory,
  updateStory,
  getAllStatementsForStory,
  markPhotoAsIncompatible} = require("../common/database");
const {generateEmbeddings, generateCompletions} = require("../common/llm");
const {calculateMeanVector,
  retryAsyncFunction,
  isInvalidImageError, extractInvalidImageUrl} = require("../common/utils");
const _ = require("lodash");
const {writeTrainingData} = require("./trainer");
const {findStoriesPrompt, findContextPrompt} = require("./prompts");
const {storyOutputSchema, contextOutputSchema} = require("./prompt_schemas");
const {processWebLinks} = require("../content/webscraper");
const {MAX_RIPPLE_DEPTH} = require("../common/pubsub");

// Source gathering is scaffolded but switched OFF for now: the first story's
// context pass does not web-search for or ingest additional sources. Flip this
// to re-enable one-hop gathering (the depth budget still applies).
const GATHER_SOURCES = false;

// Max source URLs ingested per single gather (breadth/cost cap of one gather).
// Distinct from MAX_RIPPLE_DEPTH, which caps how many gathers can chain.
const MAX_SOURCE_URLS = 4;

// A Story is an event at a specific time, not a topic — but vector search is
// time-blind, so recurring topics keep surfacing months-old stories as
// candidates and posts accrete onto them forever. Candidates are only
// eligible when the post is within this window of the story's happenedAt
// (the event is recent relative to the post) OR the story's createdAt (the
// escape hatch: coverage began recently — keeps retrospective waves about
// old events clustering instead of spawning one story per post; createdAt is
// immutable, so ongoing drift can't keep a story eligible the way an
// activity-based field would). Boundary over-splits self-heal via merge.
const STORY_TIME_WINDOW_MILLIS = 14 * 24 * 60 * 60 * 1000;

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
    },
    5));
  }

  const statements = await getAllStatementsForStory(story.sid);
  if (!statements || statements.length === 0) {
    logger.warn(`Story ${story.sid} does not have statements`);
  }

  // Recursion gate (depth only): a gathered Story carries a lower budget so
  // gathering goes one hop and dies. Spending a point also self-limits
  // re-gathering the same Story. The AI decides whether it's "thin".
  const d = (story.depth ?? MAX_RIPPLE_DEPTH) - 1;
  const canGather = GATHER_SOURCES && d > 0;

  const resp = await findContext(story, statements, canGather);

  if (resp == null) {
    // we don't change the status here since other posts
    // can yield a contextualization
    return;
  }

  const gcontext = resp;

  await retryAsyncFunction(() =>
    updateStory(story.sid, {
      ...(gcontext.headline && {headline: gcontext.headline}),
      ...(gcontext.subHeadline && {subHeadline: gcontext.subHeadline}),
      ...(gcontext.lede && {lede: gcontext.lede}),
      ...(gcontext.article && {article: gcontext.article}),
      status: "foundContext",
    }),
  );

  // Gather: ingest the AI-surfaced source URLs as real Posts. They re-enter the
  // normal pipeline and cluster into this Story; the math scores them.
  if (canGather && !_.isEmpty(gcontext.sourceUrls)) {
    // Spend a depth point first so concurrent/re-fired context passes can't
    // re-gather this Story (replaces a separate latch).
    await retryAsyncFunction(() => updateStory(story.sid, {depth: d}));
    const pids = await processWebLinks(
        gcontext.sourceUrls.slice(0, MAX_SOURCE_URLS), null, d);
    logger.info(
        `Gathered ${pids.length} posts for story ${story.sid} at depth ${d}`);
  }

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

  // Retrieval is deeper than the prompt: the time lock below discards stale
  // lookalikes, so fetch extra neighbors to keep eligible recent stories from
  // being crowded out of the top slots — but still cap what the LLM sees
  // (each candidate costs prompt tokens AND its photos as input images).
  const CANDIDATE_RETRIEVAL_K = 21;
  const CANDIDATE_PROMPT_K = 7;

  const allCandidates =
    (await searchVectors(vector, "stories", CANDIDATE_RETRIEVAL_K)) ?? [];

  // Time lock (see STORY_TIME_WINDOW_MILLIS): drop topical look-alikes whose
  // event AND coverage start are both far from the post's own timestamp.
  const postAt = post.sourceCreatedAt ?? post.createdAt;
  const eligible = postAt == null ? allCandidates :
    allCandidates.filter((story) => {
      const eventGap = story.happenedAt != null ?
        Math.abs(postAt - story.happenedAt) : Infinity;
      const coverageGap = story.createdAt != null ?
        Math.abs(postAt - story.createdAt) : Infinity;
      // keep stories with no time data at all rather than orphaning them
      if (eventGap === Infinity && coverageGap === Infinity) return true;
      return eventGap <= STORY_TIME_WINDOW_MILLIS ||
        coverageGap <= STORY_TIME_WINDOW_MILLIS;
    });

  // findNearest returns similarity-ordered docs, so this keeps the closest
  // eligible stories.
  const candidateStories = eligible.slice(0, CANDIDATE_PROMPT_K);

  if (eligible.length !== allCandidates.length) {
    logger.info(`Time lock filtered ${
      allCandidates.length - eligible.length} of ${allCandidates.length} ` +
      `candidate stories for post ${post.pid}`);
  }

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

  let resp = null;

  try {
    resp = await retryAsyncFunction(() => {
      return generateCompletions({
        messages: _prompt,
        responseSchema: storyOutputSchema(),
        loggingText: "findStories " + post.pid,
      });
    }, 2);
  } catch (e) {
    // some grade A level BS to unmark invalid images
    if (isInvalidImageError(e)) {
      const url = extractInvalidImageUrl(e);
      const removedPhoto = await markPhotoAsIncompatible(url, [post],
          candidateStories);
      if (removedPhoto) {
        // can retry this method, finite loop
        return await findStories(post);
      }
    }
  }

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
 * @param {boolean} [canGather] enable web search + sourceUrls gathering
 * @return {Promise<Gstories,Removed>}
 * ***************************************************************
 */
const findContext = async function(story, statements, canGather = false) {
  if (!story) {
    logger.error("Story is null");
    return;
  }

  const _prompt = findContextPrompt({
    story: story,
    statements: statements,
    training: true,
    includePhotos: true,
    canGather: canGather,
  });

  const resp = await generateCompletions({
    messages: _prompt,
    responseSchema: contextOutputSchema(),
    loggingText: "findContext " + story.sid,
    // Always on for COMPREHENSION (who people are, what the frame is — the
    // prompt forbids citing the web in prose). Gathering sourceUrls remains
    // separately gated by canGather.
    useWebSearch: true,
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

