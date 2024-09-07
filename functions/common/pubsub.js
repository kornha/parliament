const {PubSub} = require("@google-cloud/pubsub");

// Instantiates a client
const pubsub = new PubSub();
const {logger} = require("firebase-functions/v2");

const POST_CHANGED_VECTOR = "onPostChangedVector";
const POST_PUBLISHED = "onPostPublished";
const POST_CHANGED_XID = "onPostChangedXid";
const POST_SHOULD_FIND_STORIES_AND_STATEMENTS =
  "onPostShouldFindStoriesAndStatements";
const STATEMENT_CHANGED_POSTS = "onStatementChangedPosts";
const STORY_CHANGED_POSTS = "onStoryChangedPosts";
const ENTITY_CHANGED_POSTS = "onEntityChangedPosts";

const STORY_CHANGED_VECTOR = "onStoryChangedVector";
const POST_CHANGED_STORIES = "onPostChangedStories";
const STATEMENT_CHANGED_STORIES = "onStatementChangedStories";
const STORY_SHOULD_CHANGE_STATS = "onStoryShouldChangeStats";

const STATEMENT_CHANGED_VECTOR = "onStatementChangedVector";
const STATEMENT_CHANGED_CONTENT = "onStatementChangedContent";
const POST_CHANGED_STATEMENTS = "onPostChangedStatements";
const STORY_CHANGED_STATEMENTS = "onStoryChangedStatements";
const ENTITY_CHANGED_STATEMENTS = "onEntityChangedStatements";
const STATEMENT_SHOULD_CHANGE_CONFIDENCE = "onStatementShouldChangeConfidence";
const STATEMENT_CHANGED_CONFIDENCE = "onStatementChangedConfidence";
const STATEMENT_CHANGED_BIAS = "onStatementChangedBias";
const STATEMENT_SHOULD_CHANGE_BIAS = "onStatementShouldChangeBias";

const ENTITY_SHOULD_CHANGE_IMAGE = "onEntityShouldChangeImage";
const POST_CHANGED_ENTITY = "onPostChangedEntity";
const STATEMENT_CHANGED_ENTITIES = "onStatementChangedEntities";
const ENTITY_CHANGED_CONFIDENCE = "onEntityChangedConfidence";
const ENTITY_SHOULD_CHANGE_CONFIDENCE = "onEntityShouldChangeConfidence";
const ENTITY_CHANGED_BIAS = "onEntityChangedBias";
const ENTITY_SHOULD_CHANGE_BIAS = "onEntityShouldChangeBias";
const ENTITY_SHOULD_CHANGE_STATS = "onEntityShouldChangeStats";

const SHOULD_SCRAPE_FEED = "onShouldScrapeFeed";

/**
 * Publishes a message to a Cloud Pub/Sub Topic.
 * @param {string} topic the topic to publish to.
 * @param {json} json the value to publish.
 */
async function publishMessage(topic, json) {
  try {
    await pubsub.topic(topic).publishMessage({json});
  } catch (error) {
    logger.error(`Error publishing message: ${error}`);
  }
}

module.exports = {
  publishMessage,
  POST_CHANGED_STORIES,
  POST_CHANGED_STATEMENTS,
  POST_PUBLISHED,
  POST_CHANGED_VECTOR,
  POST_CHANGED_XID,
  POST_SHOULD_FIND_STORIES_AND_STATEMENTS,
  POST_CHANGED_ENTITY,
  STORY_CHANGED_POSTS,
  STORY_CHANGED_STATEMENTS,
  STORY_CHANGED_VECTOR,
  STORY_SHOULD_CHANGE_STATS,
  STATEMENT_CHANGED_POSTS,
  STATEMENT_CHANGED_STORIES,
  STATEMENT_CHANGED_VECTOR,
  STATEMENT_CHANGED_CONTENT,
  STATEMENT_SHOULD_CHANGE_CONFIDENCE,
  STATEMENT_CHANGED_CONFIDENCE,
  STATEMENT_CHANGED_BIAS,
  STATEMENT_SHOULD_CHANGE_BIAS,
  ENTITY_SHOULD_CHANGE_IMAGE,
  ENTITY_CHANGED_POSTS,
  ENTITY_CHANGED_STATEMENTS,
  ENTITY_CHANGED_CONFIDENCE,
  ENTITY_SHOULD_CHANGE_CONFIDENCE,
  ENTITY_CHANGED_BIAS,
  ENTITY_SHOULD_CHANGE_BIAS,
  ENTITY_SHOULD_CHANGE_STATS,
  STATEMENT_CHANGED_ENTITIES,
  SHOULD_SCRAPE_FEED,
};
