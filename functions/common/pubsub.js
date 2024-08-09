const {PubSub} = require("@google-cloud/pubsub");

// Instantiates a client
const pubsub = new PubSub();
const {logger} = require("firebase-functions/v2");

const POST_CHANGED_VECTOR = "onPostChangedVector";
const POST_PUBLISHED = "onPostPublished";
const POST_CHANGED_XID = "onPostChangedXid";
const POST_SHOULD_FIND_STORIES_AND_STATEMENTS =
  "onPostShouldFindStoriesAndStatements";
const POST_CHANGED_ENTITY = "onPostChangedEntity";
const STATEMENT_CHANGED_POSTS = "onStatementChangedPosts";
const STORY_CHANGED_POSTS = "onStoryChangedPosts";

const STORY_CHANGED_VECTOR = "onStoryChangedVector";
const POST_CHANGED_STORIES = "onPostChangedStories";
const STATEMENT_CHANGED_STORIES = "onStatementChangedStories";

const STATEMENT_CHANGED_VECTOR = "onStatementChangedVector";
const STATEMENT_CHANGED_CONTENT = "onStatementChangedContent";
const POST_CHANGED_STATEMENTS = "onPostChangedStatements";
const STORY_CHANGED_STATEMENTS = "onStoryChangedStatements";

const ENTITY_SHOULD_CHANGE_IMAGE = "onEntityShouldChangeImage";
const ENTITY_CHANGED_POSTS = "onEntityChangedPosts";

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
  STATEMENT_CHANGED_POSTS,
  STATEMENT_CHANGED_STORIES,
  STATEMENT_CHANGED_VECTOR,
  STATEMENT_CHANGED_CONTENT,
  ENTITY_SHOULD_CHANGE_IMAGE,
  ENTITY_CHANGED_POSTS,
  SHOULD_SCRAPE_FEED,
};
