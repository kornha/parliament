/* eslint-disable no-unused-vars */
const admin = require("firebase-admin");
const {logger} = require("firebase-functions/v2");
const {onRoomChange, startDebate} = require("./messages/room");
const {onMessageChange} = require("./messages/message");
const {onAuthUserCreate,
  onAuthUserDelete,
  setUsername} = require("./models/user");
const {TaskQueue} = require("firebase-admin/functions");
const {
  onPostUpdate, onPostPublished,
  onPostShouldFindStoriesAndClaims,
  onPostChangedXid,
  onPostChangedVector,
  shouldFindStoriesAndClaims,
  onPostShouldFindStoriesAndClaimsTask,
  onStoryChangedPosts,
  onClaimChangedPosts,
} = require("./models/post");
const {onVoteBiasChange, onVoteCredibilityChange} = require("./models/vote");
const {generateBiasTraining} = require("./ai/scripts");
const {onLinkPaste, onScrapeX, onScrapeFeed} = require("./content/content");
const {debateDidTimeOut, debateDidTimeOutTask} = require("./messages/clock");
const {
  onStoryUpdate, onStoryPostsChanged,
  onStoryShouldChangeVector, onStoryShouldChangeClaims,
  onClaimChangedStories,
  onPostChangedStories,
} = require("./models/story");
const {
  onClaimUpdate, onClaimChangedVector,
  onClaimShouldChangeContext,
  onPostChangedClaims,
  onStoryChangedClaims,
} = require("./models/claim");
const {
  onEntityUpdate,
  onEntityShouldChangeImage,
} = require("./models/entity");

admin.initializeApp();

// For Local Task Mocking Only
// cannot use isLocal from utils as its not initialized
if (process.env.FUNCTIONS_EMULATOR === "true") {
  Object.assign(TaskQueue.prototype, {
    enqueue: async (message, params) => {
      if (message.pid) {
        logger.info(
            `local onPostShouldFindStoriesAndClaimsTask: ${message.pid}`);
        await shouldFindStoriesAndClaims(message.pid);
      } else {
        const end = new Date(params.scheduleTime);
        const now = Date.now();
        const delta = end - now;
        setTimeout(() => {
          debateDidTimeOut(message);
        }, delta);
      }
    },
  });
}

// Used as a dev-time helper to test functions
const functions = require("firebase-functions/v2");

const test = functions.https.onCall(async (data, context) => {
  // Your logic here
});

module.exports = {
  onAuthUserCreate,
  onAuthUserDelete,
  setUsername,
  onVoteBiasChange,
  onVoteCredibilityChange,
  // Post
  onPostUpdate,
  onMessageChange,
  onPostPublished,
  onPostShouldFindStoriesAndClaims,
  onPostShouldFindStoriesAndClaimsTask,
  onPostChangedVector,
  onPostChangedXid,
  onStoryChangedPosts,
  onClaimChangedPosts,
  // Story
  onStoryUpdate,
  onStoryPostsChanged,
  onStoryShouldChangeVector,
  onStoryShouldChangeClaims,
  onClaimChangedStories,
  onPostChangedStories,
  // Claim
  onClaimUpdate,
  onClaimChangedVector,
  onClaimShouldChangeContext,
  onStoryChangedClaims,
  onPostChangedClaims,
  // Room
  onRoomChange,
  startDebate,
  debateDidTimeOutTask,
  // Entity
  onEntityUpdate,
  onEntityShouldChangeImage,
  // Content
  onLinkPaste,
  onScrapeX,
  onScrapeFeed,
  // Scripts
  generateBiasTraining,
  // Dev helper
  test,
};
