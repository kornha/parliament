const {PubSub} = require("@google-cloud/pubsub");

// Instantiates a client
const pubsub = new PubSub();
const {logger} = require("firebase-functions/v2");

const POST_CHANGED_VECTOR = "onPostChangedVector";
const POST_PUBLISHED = "onPostPublished";
const POST_CHANGED_XID = "onPostChangedXid";
const POST_SHOULD_FIND_STORIES ="onPostShouldFindStories";
const STATEMENT_CHANGED_POSTS = "onStatementChangedPosts";
const STORY_CHANGED_POSTS = "onStoryChangedPosts";
const ENTITY_CHANGED_POSTS = "onEntityChangedPosts";
const PLATFORM_CHANGED_POSTS = "onPlatformChangedPosts";
const POST_CHANGED_STATS = "onPostChangedStats";
const POST_SHOULD_CHANGE_BIAS = "onPostShouldChangeBias";
const POST_SHOULD_CHANGE_CONFIDENCE = "onPostShouldChangeConfidence";
const POST_SHOULD_CHANGE_VIRALITY = "onPostShouldChangeVirality";
const POST_CHANGED_VIRALITY = "onPostChangedVirality";

const STORY_CHANGED_VECTOR = "onStoryChangedVector";
const POST_CHANGED_STORIES = "onPostChangedStories";
const STATEMENT_CHANGED_STORIES = "onStatementChangedStories";
const STORY_SHOULD_CHANGE_STATS = "onStoryShouldChangeStats";
const STORY_SHOULD_CHANGE_PLATFORMS = "onStoryShouldChangePlatforms";
const PLATFORM_CHANGED_STORIES = "onPlatformChangedStories";
const STORY_SHOULD_CHANGE_NEWSWORTHINESS = "onStoryShouldChangeNewsworthiness";
const STORY_SHOULD_CHANGE_CONFIDENCE = "onStoryShouldChangeConfidence";
const STORY_SHOULD_CHANGE_BIAS = "onStoryShouldChangeBias";
const STORY_CHANGED_CONFIDENCE = "onStoryChangedConfidence";
const STORY_CHANGED_BIAS = "onStoryChangedBias";
const STORY_SHOULD_CHANGED_SCALED_HAPPENED_AT =
 "onStoryShouldChangeScaledHappenedAt";

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
const ENTITY_CHANGED_STATS = "onEntityChangedStats";
const ENTITY_SHOULD_CHANGE_PLATFORM = "onEntityShouldChangePlatform";
const PLATFORM_CHANGED_ENTITIES = "onPlatformChangedEntities";

const PLATFORM_SHOULD_CHANGE_IMAGE = "onPlatformShouldChangeImage";
const PLATFORM_SHOULD_CHANGE_STATS = "onPlatformShouldChangeStats";
const PLATFORM_CHANGED_STATS = "onPlatformChangedStats";

const SHOULD_SCRAPE_FEED = "onShouldScrapeFeed";
const SHOULD_PROCESS_LINK = "onShouldProcessLink";

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
  POST_SHOULD_FIND_STORIES,
  POST_CHANGED_ENTITY,
  POST_CHANGED_STATS,
  POST_SHOULD_CHANGE_BIAS,
  POST_SHOULD_CHANGE_CONFIDENCE,
  POST_SHOULD_CHANGE_VIRALITY,
  POST_CHANGED_VIRALITY,
  STORY_CHANGED_POSTS,
  STORY_CHANGED_STATEMENTS,
  STORY_CHANGED_VECTOR,
  STORY_SHOULD_CHANGE_STATS,
  STORY_SHOULD_CHANGE_PLATFORMS,
  STORY_SHOULD_CHANGE_NEWSWORTHINESS,
  STORY_SHOULD_CHANGE_CONFIDENCE,
  STORY_SHOULD_CHANGE_BIAS,
  STORY_CHANGED_CONFIDENCE,
  STORY_CHANGED_BIAS,
  STORY_SHOULD_CHANGED_SCALED_HAPPENED_AT,
  STATEMENT_CHANGED_POSTS,
  STATEMENT_CHANGED_STORIES,
  STATEMENT_CHANGED_VECTOR,
  STATEMENT_CHANGED_CONTENT,
  STATEMENT_SHOULD_CHANGE_CONFIDENCE,
  STATEMENT_CHANGED_CONFIDENCE,
  STATEMENT_CHANGED_BIAS,
  STATEMENT_SHOULD_CHANGE_BIAS,
  STATEMENT_CHANGED_ENTITIES,
  ENTITY_SHOULD_CHANGE_IMAGE,
  ENTITY_CHANGED_POSTS,
  ENTITY_CHANGED_STATEMENTS,
  ENTITY_CHANGED_CONFIDENCE,
  ENTITY_SHOULD_CHANGE_CONFIDENCE,
  ENTITY_CHANGED_BIAS,
  ENTITY_SHOULD_CHANGE_BIAS,
  ENTITY_SHOULD_CHANGE_STATS,
  ENTITY_CHANGED_STATS,
  ENTITY_SHOULD_CHANGE_PLATFORM,
  PLATFORM_CHANGED_ENTITIES,
  PLATFORM_CHANGED_POSTS,
  PLATFORM_SHOULD_CHANGE_IMAGE,
  PLATFORM_SHOULD_CHANGE_STATS,
  PLATFORM_CHANGED_STATS,
  PLATFORM_CHANGED_STORIES,
  SHOULD_SCRAPE_FEED,
  SHOULD_PROCESS_LINK,
};
