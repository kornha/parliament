/* eslint-disable no-unused-vars */
const admin = require("firebase-admin");
const {logger} = require("firebase-functions/v2");
const {onRoomChange, startDebate} = require("./messages/room");
const {onMessageChange} = require("./messages/message");
const {onAuthUserCreate,
  onAuthUserDelete,
  setUsername} = require("./models/user");
const {TaskQueue} = require("firebase-admin/functions");
const {POST_SHOULD_FIND_STORIES_TASK,
  POST_SHOULD_FIND_STATEMENTS_TASK,
  STORY_SHOULD_FIND_CONTEXT_TASK} = require("./common/tasks");
const {
  onPostUpdate, onPostPublished,
  onPostShouldFindStories,
  onPostChangedXid,
  onPostChangedVector,
  onPostShouldFindStoriesTask,
  onStoryChangedPosts,
  onStatementChangedPosts,
  onEntityChangedPosts,
  onPostChangedStats,
  onPlatformChangedPosts,
  onPostShouldChangeBias,
  onPostShouldChangeConfidence,
  onPostShouldFindStatementsTask,
  shouldFindStories,
  shouldFindStatements,
} = require("./models/post");
const {
  onStoryUpdate, onStoryPostsChanged,
  onStoryShouldChangeVector, onStoryShouldChangeStatements,
  onStatementChangedStories,
  onPostChangedStories,
  onStoryShouldChangeStats,
  onPlatformChangedStories,
  onStoryShouldChangePlatforms,
  onStoryShouldChangeNewsworthiness,
  onStoryShouldChangeBias,
  onStoryShouldChangeConfidence,
  onStoryShouldChangeScaledHappenedAt,
  shouldFindContext,
  onStoryShouldFindContextTask,
} = require("./models/story");
const {onVoteBiasChange, onVoteCredibilityChange} = require("./models/vote");
const {generateBiasTraining} = require("./ai/scripts");
const {onLinkPaste, fetchNews,
  onScrapeFeed, onShouldProcessLink} = require("./content/content");
const {debateDidTimeOut, debateDidTimeOutTask} = require("./messages/clock");
const {
  onStatementUpdate, onStatementChangedVector,
  onStatementShouldChangeContext,
  onPostChangedStatements,
  onStoryChangedStatements,
  onEntityChangedStatements,
  onStatementShouldChangeConfidence,
  onStatementChangedConfidence,
  onStatementChangedBias,
  onStatementShouldChangeBias,
} = require("./models/statement");
const {
  onEntityUpdate,
  onEntityShouldChangeImage,
  onPostChangedEntity,
  onStatementChangedEntities,
  onEntityChangedConfidence,
  onEntityShouldChangeConfidence,
  onEntityShouldChangeBias,
  onEntityChangedBias,
  onEntityShouldChangeStats,
  onPlatformChangedEntities,
} = require("./models/entity");
const {onPlatformUpdate,
  onPlatformShouldChangeImage,
  onPlatformShouldChangeStats,
  onPlatformChangedStats} = require("./models/platform");
const {onHourTrigger, triggerTimeFunction,
  onFifteenMinutesTrigger} = require("./common/schedule");


admin.initializeApp();

// For Local Task Mocking Only
// cannot use isLocal from utils as its not initialized
if (process.env.FUNCTIONS_EMULATOR === "true") {
  // Needed for mocking cloud tasks which we use for scheduled messages
  Object.assign(TaskQueue.prototype, {
    enqueue: async (message, params) => {
      if (message.task == POST_SHOULD_FIND_STORIES_TASK) {
        logger.info(
            `local onPostShouldFindStoriesTask: ${message.pid}`);
        await shouldFindStories(message.pid);
      } else if (message.task == POST_SHOULD_FIND_STATEMENTS_TASK) {
        logger.info(
            `local onPostShouldFindStatementsTask: ${message.pid}`);
        await shouldFindStatements(message.pid);
      } else if (message.task == STORY_SHOULD_FIND_CONTEXT_TASK) {
        logger.info(
            `local onStoryShouldFindContextTask: ${message.sid}`);
        await shouldFindContext(message.sid);
        //
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
  onPostShouldFindStories,
  onPostShouldFindStoriesTask,
  onPostShouldFindStatementsTask,
  onPostChangedVector,
  onPostChangedXid,
  onStoryChangedPosts,
  onStatementChangedPosts,
  onEntityChangedPosts,
  onPostChangedStats,
  onPlatformChangedPosts,
  onPostShouldChangeBias,
  onPostShouldChangeConfidence,
  // Story
  onStoryUpdate,
  onStoryPostsChanged,
  onStoryShouldChangeVector,
  onStoryShouldChangeStatements,
  onStatementChangedStories,
  onPostChangedStories,
  onStoryShouldChangeStats,
  onPlatformChangedStories,
  onStoryShouldChangePlatforms,
  onStoryShouldChangeNewsworthiness,
  onStoryShouldChangeBias,
  onStoryShouldChangeConfidence,
  onStoryShouldChangeScaledHappenedAt,
  onStoryShouldFindContextTask,
  // Statement
  onStatementUpdate,
  onStatementChangedVector,
  onStatementShouldChangeContext,
  onStoryChangedStatements,
  onPostChangedStatements,
  onEntityChangedStatements,
  onStatementShouldChangeConfidence,
  onStatementChangedConfidence,
  onStatementChangedBias,
  onStatementShouldChangeBias,
  // Room
  onRoomChange,
  startDebate,
  debateDidTimeOutTask,
  // Entity
  onEntityUpdate,
  onEntityShouldChangeImage,
  onPostChangedEntity,
  onStatementChangedEntities,
  onEntityChangedConfidence,
  onEntityShouldChangeConfidence,
  onEntityShouldChangeBias,
  onEntityChangedBias,
  onEntityShouldChangeStats,
  onPlatformChangedEntities,
  // Platform
  onPlatformUpdate,
  onPlatformShouldChangeImage,
  onPlatformShouldChangeStats,
  onPlatformChangedStats,
  // Content
  onLinkPaste,
  fetchNews,
  onScrapeFeed,
  onShouldProcessLink,
  //
  onHourTrigger,
  onFifteenMinutesTrigger,
  triggerTimeFunction,
  // Scripts
  generateBiasTraining,
  // Dev helper
  test,
};
