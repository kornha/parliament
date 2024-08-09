/* eslint-disable require-jsdoc */

const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {incrementPostMessages} = require("../models/post");
const {reevaluateRoom,
  startDebate, finalizeDebate, getWinningPosition} = require("../ai/debate_ai");
const {isFibonacciNumber} = require("../common/utils");
const {roomTimeIsExpired,
  debateDidTimeOut, incrementDebateTimer} = require("./clock");
const {applyEloScores} = require("../models/user");
const {applyDebateToBias} = require("../ai/bias");
const {defaultConfig} = require("../common/functions");

// Db triggers
exports.onRoomChange = onDocumentWritten(
    {
      document: "rooms/{rid}",
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!after) {
        return Promise.resolve();
      }
      const collectionId = after.parentCollection;
      const parentId = after.parentId;
      const rid = event.params.rid;

      _roomDidChangeWinner(before, after);

      if (after.status === "live" && roomTimeIsExpired(after)) {
        await debateDidTimeOut({rid: rid});
      }

      if (after.eloScore != null && before.eloScore == null) {
        await applyEloScores(after.eloScore);
      }

      if (_messageDidIncrement(before, after)) {
        if (collectionId === "posts") {
          await incrementPostMessages(parentId);
        }

        if (after.status === "live" &&
            after.clock && after.clock.duration && after.clock.increment) {
          await incrementDebateTimer(after);
        }

        if (isFibonacciNumber(after.messageCount) &&
            (after.status === "waiting" || after.status === "live")) {
          await reevaluateRoom(after);
        }
      }

      const roomsWithUser =
      (after.leftUsers.length > 0 ? 1 : 0) +
      (after.rightUsers.length > 0 ? 1 : 0) +
      (after.centerUsers.length > 0 ? 1 : 0) +
      (after.extremeUsers.length > 0 ? 1 : 0);

      if (after.status === "waiting" && roomsWithUser > 1) {
        await startDebate(after);
      } else if (after.status === "judging" && before.status === "live") {
        await finalizeDebate(after);
      } else if ((after.status === "finished" && after.winners === null) ||
      (after.status === "judging" && before.status === "judging")) {
        await finalizeDebate(after);
      }

      return null;
    },
);

// Export Helpers
exports.incrementRoomMessages = function(rid, uid) {
  return getFirestore().collection("rooms").doc(rid).update({
    messageCount: FieldValue.increment(1),
    users: FieldValue.arrayUnion(uid),
  });
};

// Helpers
function _messageDidIncrement(before, after) {
  return after &&
    after.messageCount &&
    after.messageCount > 0 &&
    (!before.messageCount || after.messageCount > before.messageCount);
}

async function _roomDidChangeWinner(before, after) {
  const bPos = getWinningPosition(before).winningPosition;
  const aPos = getWinningPosition(after).winningPosition;
  if (aPos == null && bPos == null ||
    aPos && bPos && aPos.angle === bPos.angle) {
    return;
  }
  if (!bPos && aPos) {
    await applyDebateToBias(after.parentId, aPos, {add: true});
  } else if (bPos && !aPos) {
    await applyDebateToBias(after.parentId, bPos, {add: false});
  } else {
    await applyDebateToBias(after.parentId, bPos, {add: false});
    await applyDebateToBias(after.parentId, aPos, {add: true});
  }
}


