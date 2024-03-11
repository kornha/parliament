const admin = require("firebase-admin");
const {onRoomChange, startDebate} = require("./messages/room");
const {onMessageChange} = require("./messages/message");
const {onAuthUserCreate, onAuthUserDelete,
  setUsername} = require("./models/user");
const {TaskQueue} = require( "firebase-admin/functions");
const {onPostUpdate} = require("./models/post");
const {onVoteBiasChange, onVoteCredibilityChange} = require("./models/vote");
const {generateBiasTraining} = require("./ai/scripts");
const {onTriggerContent, onLinkPaste} = require("./content/content");
const {debateDidTimeOut, debateDidTimeOutTask} = require("./messages/clock");

// const {generateStories} = require("./ai/story_generator");

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

module.exports = {
  onAuthUserCreate,
  onAuthUserDelete,
  setUsername,
  onVoteBiasChange,
  onVoteCredibilityChange,
  // onPostCreate,
  onPostUpdate,
  onMessageChange,
  // joinRoom,
  onRoomChange,
  startDebate,
  debateDidTimeOutTask,
  // generateStories,
  onTriggerContent,
  onLinkPaste,
  // Scripts
  generateBiasTraining,
};
