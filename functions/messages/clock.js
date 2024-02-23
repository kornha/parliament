/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {getFunctions} = require("firebase-admin/functions");
const {Timestamp, FieldValue} = require("firebase-admin/firestore");
const {getRoom, updateRoom} = require("../common/database");

// /////////////////////////////////////////
// timer
// /////////////////////////////////////////

exports.debateDidTimeOutTask = functions.tasks.taskQueue({
  retryConfig: {
    maxAttempts: 5,
    minBackoffSeconds: 30,
  },
  rateLimits: {
    maxConcurrentDispatches: 12,
  },
}).onDispatch(async (data) => {
  this.debateDidTimeOut(data);
});

const debateDidTimeOut = async function(data) {
  if (!data.rid) {
    functions.logger.error(`Room ${data.rid} timed out with no rid`);
    return;
  }

  const room = await getRoom(data.rid);
  if (!room) {
    functions.logger.error(`Room ${data.rid} not found`);
    return;
  }

  if (roomTimeIsActive(room)) {
    functions.logger.info(`Room not timed out. Queueing new time ${room.rid}`);
    queueDebateTimer(room, room.clock.start + room.clock.duration * 1000);
    return;
  }

  functions.logger.info(`Room ${data.rid} debateDidTimeOut`);
  updateRoom(data.rid, {
    status: "judging",
  });
};

async function queueDebateTimer(room, time) {
  const queue = getFunctions().taskQueue("debateDidTimeOut");
  const targetUri = await _getFunctionUrl("debateDidTimeOut");

  await queue.enqueue(
      {
        rid: room.rid,
      },
      {
        scheduleTime: new Date(time),
        dispatchDeadlineSeconds: 60, // 5 minutes
        uri: targetUri,
      });
  console.log("Enqueued task");
}

async function incrementDebateTimer(room) {
  if (!room || !room.clock || !room.clock.start || !room.clock.duration ||
    !room.clock.increment) {
    functions.logger.error(`Cannot increment clock for ${room.rid}`);
    return;
  }

  updateRoom(room.rid, {
    "clock.duration": FieldValue.increment(room.clock.increment),
  });
}

async function _getFunctionUrl(name, _location = "us-central1") {
  return `https://127.0.0.1:5001/political-think/us-central1/${name}`;
  // https://127.0.0.1:5001/political-think/us-central1/debateDidTimeOut
  // if (!auth) {
  //     auth = new GoogleAuth({
  //         scopes: "https://www.googleapis.com/auth/cloud-platform",
  //     });
  // }
  // const projectId = await auth.getProjectId();
  // const url = "https://cloudfunctions.googleapis.com/v2beta/" +
  //     `projects/${projectId}/locations/${location}/functions/${name}`;

  // const client = await auth.getClient();
  // const res = await client.request({ url });
  // const uri = res.data?.serviceConfig?.uri;
  // if (!uri) {
  //     throw new Error(`Unable to retreive uri for function at ${url}`);
  // }
  // return uri;
}

function roomTimeIsActive(room) {
  const end = getEnd(room);
  if (end && end > Timestamp.now().toMillis()) {
    return true;
  }

  return false;
}

function roomTimeIsExpired(room) {
  const end = getEnd(room);
  if (end && end < Timestamp.now().toMillis()) {
    return true;
  }

  return false;
}

function getEnd(room) {
  let end = null;
  if (room.clock && room.clock.start && room.clock.duration) {
    end = room.clock.start + room.clock.duration * 1000;
  }
  return end;
}


module.exports = exports = {
  debateDidTimeOut,
  getEnd,
  roomTimeIsActive,
  roomTimeIsExpired,
  queueDebateTimer,
  incrementDebateTimer,
};
