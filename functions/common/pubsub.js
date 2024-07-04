const {PubSub} = require("@google-cloud/pubsub");
const functions = require("firebase-functions");

// Instantiates a client
// Must export a function in index.js to be able to use this
const pubsub = new PubSub();
//
const POST_PUBLISHED = "onPostPublished";
const POST_CHANGED_VECTOR = "onPostChangedVector";
const POST_CHANGED_XID = "onPostChangedXid";
const POST_SHOULD_FIND_STORIES_AND_CLAIMS = "onPostShouldFindStoriesAndClaims";
//
const STORY_CHANGED_VECTOR = "onStoryChangedVector";
const STORY_CHANGED_POSTS = "onStoryChangedPosts";
const STORY_SHOULD_CHANGE_VECTOR = "onStoryShouldChangeVector";
const STORY_SHOULD_CHANGE_CLAIMS = "onStoryShouldChangeClaims";
//
const CLAIM_CHANGED_POSTS = "onClaimChangedPosts";
const CLAIM_CHANGED_STORIES = "onClaimChangedStories";
const CLAIM_CHANGED_VECTOR = "onClaimChangedVector";
const CLAIM_CHANGED_CONTENT = "onClaimChangedContent";
//
const ENTITY_SHOULD_CHANGE_IMAGE = "onEntityShouldChangeImage";
//
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
    functions.logger.error(`Error publishing message: ${error}`);
  }
}

module.exports = {
  publishMessage,
  POST_PUBLISHED,
  POST_CHANGED_VECTOR,
  POST_CHANGED_XID,
  POST_SHOULD_FIND_STORIES_AND_CLAIMS,
  //
  STORY_CHANGED_POSTS,
  STORY_SHOULD_CHANGE_CLAIMS,
  STORY_SHOULD_CHANGE_VECTOR,
  STORY_CHANGED_VECTOR,
  //
  CLAIM_CHANGED_POSTS,
  CLAIM_CHANGED_STORIES,
  CLAIM_CHANGED_VECTOR,
  CLAIM_CHANGED_CONTENT,
  //
  ENTITY_SHOULD_CHANGE_IMAGE,
  //
  SHOULD_SCRAPE_FEED,
};
