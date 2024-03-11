/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
const {incrementPostMessages} = require("../models/post");
const {reevaluateRoom, startDebate, finalizeDebate, getWinningPosition} =
require("../ai/debate_ai");
const {isFibonacciNumber} = require("../common/utils");
const {roomTimeIsExpired,
  debateDidTimeOut, incrementDebateTimer} = require("./clock");
const {applyEloScores} = require("../models/user");
const {applyDebateToBias} = require("../ai/bias");

//
// Db triggers
//

exports.onRoomChange = functions.firestore
    .document("rooms/{rid}")
    .onWrite(async (change, context) => {
      if (!change.after.exists) {
        return Promise.resolve();
      }
      const before = change.before.data();
      const after = change.after.data();
      const collectionId = after.parentCollection;
      const parentId = after.parentId;
      const rid = context.params.rid;

      _roomDidChangeWinner(before, after);

      // if our timer messed up...
      if (after.status == "live" && roomTimeIsExpired(after)) {
        debateDidTimeOut({rid: rid});
      }

      // if elo scores were added
      // TODO: make this txn in the future with room finish
      if (after.eloScore != null && before.eloScore == null) {
        applyEloScores(after.eloScore);
      }

      // if message incremented
      // increment post message count
      // update timer increment
      // possibly reevaluate room
      if (_messageDidIncrement(before, after)) {
        // post messages versus room messages
        // we have different counts since 1 post can have many rooms
        if (collectionId === "posts") {
          incrementPostMessages(parentId);
        }

        // if the room is not timed out, we want to increase timer
        if (after.status == "live" && after.clock &&
        after.clock.duration && after.clock.increment) {
          incrementDebateTimer(after);
        }

        // handle reevaluation, does not change status
        if (isFibonacciNumber(after.messageCount) &&
        (after.status == "waiting" || after.status == "live")) {
          reevaluateRoom(after);
        }
      }

      // if/else on debate status
      const roomsWithUser =
        (after.leftUsers.length > 0 ? 1 : 0) +
        (after.rightUsers.length > 0 ? 1 : 0) +
        (after.centerUsers.length > 0 ? 1 : 0) +
        (after.extremeUsers.length > 0 ? 1 : 0);

      // waiting to live
      // task manager sets live to judging
      // on judging we then finalize the debate and set to final
      if (after.status == "waiting" && roomsWithUser > 1) {
        startDebate(after); // live-judging set by timer
      } else if (after.status == "judging" && before.status == "live") {
        finalizeDebate(after);
      } else if (after.status == "finished" && after.winners === null ||
      after.status == "judging" && before.status == "judging") {
        // SANITY CHECK
        // we dont check for winning position since if thats null
        // its a draw
        finalizeDebate(after);
      }

      return Promise.resolve();
    });

//
// Export Helpers
//
exports.incrementRoomMessages = function(rid, uid) {
  return admin.firestore()
      .collection("rooms")
      .doc(rid)
      .update({
        messageCount: FieldValue.increment(1),
        users: FieldValue.arrayUnion(uid),
      });
};

//
// Helpers
//

function _messageDidIncrement(before, after) {
  return after &&
        after.messageCount &&
        after.messageCount > 0 &&
         (!before.messageCount ||
          after.messageCount > before.messageCount);
}

async function _roomDidChangeWinner(before, after) {
  const bPos = getWinningPosition(before).winningPosition;
  const aPos = getWinningPosition(after).winningPosition;
  if (aPos == null && bPos == null ||
    aPos && bPos && aPos.angle == bPos.angle) {
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

