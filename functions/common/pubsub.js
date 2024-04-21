const {PubSub} = require("@google-cloud/pubsub");
const functions = require("firebase-functions");

// Instantiates a client
// Must export a function in index.js to be able to use this
const pubsub = new PubSub();
//
const POST_PUBLISHED = "onPostPublished";
//
const POST_CHANGED_VECTOR = "onPostChangedVector";
const STORY_CHANGED_VECTOR = "onStoryChangedVector";
const CLAIM_CHANGED_VECTOR = "onClaimChangedVector";
//
const STORY_CHANGED_POSTS = "onStoryChangedPosts";
const CLAIM_CHANGED_POSTS = "onClaimChangedPosts";
// const STORY_CHANGED_CLAIMS = "onStoryChangedClaims";
const CLAIM_CHANGED_STORIES = "onClaimChangedStories";
//
const STORY_SHOULD_CHANGE_VECTOR = "onStoryShouldChangeVector";
const STORY_SHOULD_CHANGE_CLAIMS = "onStoryShouldChangeClaims";
const CLAIM_SHOULD_CHANGE_CONTEXT = "onClaimShouldChangeContext";

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
  STORY_CHANGED_POSTS,
  CLAIM_CHANGED_POSTS,
  // STORY_CHANGED_CLAIMS,
  CLAIM_SHOULD_CHANGE_CONTEXT,
  CLAIM_CHANGED_STORIES,
  STORY_SHOULD_CHANGE_CLAIMS,
  STORY_SHOULD_CHANGE_VECTOR,
  CLAIM_CHANGED_VECTOR,
  POST_CHANGED_VECTOR,
  STORY_CHANGED_VECTOR,
};
