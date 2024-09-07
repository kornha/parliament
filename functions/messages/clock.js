/* eslint-disable require-jsdoc */

const {onTaskDispatched} = require("firebase-functions/v2/tasks");
const {getFunctions} = require("firebase-admin/functions");
const {Timestamp, FieldValue} = require("firebase-admin/firestore");
const {getRoom, updateRoom} = require("../common/database");
const {defaultConfig} = require("../common/functions");
const {logger} = require("firebase-functions/v2");

// Task Queue handler for debateDidTimeOutTask
exports.debateDidTimeOutTask = onTaskDispatched(
    {
      retryConfig: {
        maxAttempts: 5,
        minBackoffSeconds: 30,
      },
      rateLimits: {
        maxConcurrentDispatches: 12,
      },
      ...defaultConfig,
    },
    async (data) => {
      await debateDidTimeOut(data);
    },
);

const debateDidTimeOut = async function(data) {
  if (!data.rid) {
    logger.error(`Room ${data.rid} timed out with no rid`);
    return;
  }

  const room = await getRoom(data.rid);
  if (!room) {
    logger.error(`Room ${data.rid} not found`);
    return;
  }

  if (roomTimeIsActive(room)) {
    logger.info(`Room not timed out. Queueing new time ${room.rid}`);
    await queueDebateTimer(room, room.clock.start + room.clock.duration * 1000);
    return;
  }

  logger.info(`Room ${data.rid} debateDidTimeOut`);
  await updateRoom(data.rid, {
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
        dispatchDeadlineSeconds: 60, // 1 minute
        uri: targetUri,
      },
  );
  logger.info("Enqueued task");
}

async function incrementDebateTimer(room) {
  if (!room || !room.clock ||
    !room.clock.start || !room.clock.duration || !room.clock.increment) {
    logger.error(`Cannot increment clock for ${room.rid}`);
    return;
  }

  await updateRoom(room.rid, {
    "clock.duration": FieldValue.increment(room.clock.increment),
  });
}

async function _getFunctionUrl(name, _location = "us-central1") {
  return `https://127.0.0.1:5001/political-think/us-central1/${name}`;
  // Uncomment and adjust the following lines if needed for production
  // const gAuth = new GoogleAuth({
  //   scopes: "https://www.googleapis.com/auth/cloud-platform",
  // });
  // const projectId = await gAuth.getProjectId();
  // const url = `https://cloudfunctions.googleapis.com/v2/projects/${projectId}/locations/${_location}/functions/${name}`;
  // const client = await gAuth.getClient();
  // const res = await client.request({ url });
  // const uri = res.data?.serviceConfig?.uri;
  // if (!uri) {
  //   throw new Error(`Unable to retrieve URI for function at ${url}`);
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

module.exports = {
  debateDidTimeOut,
  getEnd,
  roomTimeIsActive,
  roomTimeIsExpired,
  queueDebateTimer,
  incrementDebateTimer,
};
