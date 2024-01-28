const admin = require("firebase-admin");
const {onRoomChange, startDebate} = require("./messages/room");
const {onMessageChange} = require("./messages/message");
const {onAuthUserCreate} = require("./models/user");
const {debateDidTimeOutTask, debateDidTimeOut} = require("./ai/debate");
const {TaskQueue} = require( "firebase-admin/functions");
const {onPostCreate, onPostUpdate} = require("./models/post");
const {onVoteBiasChange, onVoteCredibilityChange} = require("./models/vote");
const {generateBiasTraining} = require("./ai/scripts");
const {generateStories} = require("./ai/story_generator");
const {onNewContent} = require("./content/content");

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
  onVoteBiasChange,
  onVoteCredibilityChange,
  onPostCreate,
  onPostUpdate,
  onMessageChange,
  // joinRoom,
  onRoomChange,
  startDebate,
  debateDidTimeOutTask,
  generateStories,
  onNewContent,
  // Scripts
  generateBiasTraining,
};
