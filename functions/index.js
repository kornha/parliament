const admin = require("firebase-admin");
const {onRoomChange, startDebate} = require("./messages/room");
const {onMessageChange} = require("./messages/message");
const {onAuthUserCreate, onAuthUserDelete,
  setUsername} = require("./models/user");
const {TaskQueue} = require( "firebase-admin/functions");
const {onPostUpdate, onPostPublished,
  onPostChangedVector} = require("./models/post");
const {onVoteBiasChange, onVoteCredibilityChange} = require("./models/vote");
const {generateBiasTraining} = require("./ai/scripts");
const {onTriggerContent, onLinkPaste} = require("./content/content");
const {debateDidTimeOut, debateDidTimeOutTask} = require("./messages/clock");
const {onStoryUpdate, onStoryPostsChanged, onStoryChangedPosts,
  onStoryShouldChangeVector, onStoryShouldChangeClaims,
} = require("./models/story");
const {onClaimUpdate, onClaimChangedVector,
  onClaimChangedPosts, onClaimShouldChangeContext} = require("./models/claim");


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
  // Story
  onStoryUpdate,
  onStoryPostsChanged,
  onStoryChangedPosts,
  onStoryShouldChangeVector,
  onStoryShouldChangeClaims,
  // Post
  onPostUpdate,
  onMessageChange,
  onPostPublished,
  onPostChangedVector,
  // Room
  // joinRoom,
  onRoomChange,
  startDebate,
  debateDidTimeOutTask,
  // generateStories,
  // Claim
  onClaimUpdate,
  onClaimChangedVector,
  onClaimChangedPosts,
  onClaimShouldChangeContext,
  //
  onTriggerContent,
  onLinkPaste,
  // Scripts
  generateBiasTraining,
  // Dev helper
  test,
};
