const admin = require("firebase-admin");
const {joinRoom, onRoomChange, startDebate} = require("./rooms");
const {onMessageChange} = require("./messages");
const {createUserFunction} = require("./users");
const {debateDidTimeOutTask, debateDidTimeOut} = require("./debate");
const {TaskQueue} = require( "firebase-admin/functions");

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
  joinRoom,
  onRoomChange,
  startDebate,
  debateDidTimeOutTask,
  onMessageChange,
  createUserFunction,
};
