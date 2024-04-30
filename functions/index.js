const admin = require("firebase-admin");
const {onRoomChange, startDebate} = require("./messages/room");
const {onMessageChange} = require("./messages/message");
const {onAuthUserCreate, onAuthUserDelete,
  setUsername} = require("./models/user");
const {TaskQueue} = require( "firebase-admin/functions");
const {onPostUpdate, onPostPublished, onPostPublished2,
  onPostChangedVector} = require("./models/post");
const {onVoteBiasChange, onVoteCredibilityChange} = require("./models/vote");
const {generateBiasTraining} = require("./ai/scripts");
const {onLinkPaste} = require("./content/content");
const {debateDidTimeOut, debateDidTimeOutTask} = require("./messages/clock");
const {onStoryUpdate, onStoryPostsChanged, onStoryChangedPosts,
  onStoryShouldChangeVector, onStoryShouldChangeClaims,
} = require("./models/story");
const {onClaimUpdate, onClaimChangedVector,
  onClaimChangedPosts, onClaimShouldChangeContext} = require("./models/claim");
const {onEntityUpdate,
  onEntityShouldChangeImage} = require("./models/entity");


admin.initializeApp();

// For Local Task Mocking Only
Object.assign(TaskQueue.prototype, {
  enqueue: (data, params) => {
    const end = new Date(params.scheduleTime);
    const now = Date.now();
    const delta = end - now;

    setTimeout(() => {
      debateDidTimeOut(data);
    }, delta);
  },
});

// Used as a dev-time helper to test functions
const functions = require("firebase-functions");

const test = functions.https.onCall(async (data, context) => {
  return {complete: true};
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
  onPostPublished2,
  onPostChangedVector,
  // Story
  onStoryUpdate,
  onStoryPostsChanged,
  onStoryChangedPosts,
  onStoryShouldChangeVector,
  onStoryShouldChangeClaims,
  // Room
  onRoomChange,
  startDebate,
  debateDidTimeOutTask,
  // Entity
  onEntityUpdate,
  onEntityShouldChangeImage,
  // Claim
  onClaimUpdate,
  onClaimChangedVector,
  onClaimChangedPosts,
  onClaimShouldChangeContext,
  //
  onLinkPaste,
  // Scripts
  generateBiasTraining,
  // Dev helper
  test,
};
