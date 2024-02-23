/* eslint-disable max-len */
/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const {OpenAI} = require("openai");
const {getMessages, getDBDocument, setRoom, updateRoom, getUsers} = require("../common/database");
const {Timestamp} = require("firebase-admin/firestore");
const {queueDebateTimer, getEnd} = require("../messages/clock");
const {getElo} = require("../common/utils");

// /////////////////////////////////////////
// debate controls
// /////////////////////////////////////////


const reevaluateRoom = async function(room) {
  if (room.status == "finished") {
    functions.logger.info(`Room ${room.rid} already finished`);
    return;
  }

  functions.logger.info(`Reevaluating room ${room.rid}`);

  const end = getEnd(room);

  const messages = await getMessages(room.rid, end);
  const parent = await getDBDocument(room.parentId, room.parentCollection);

  if (!messages || !parent) {
    throw new Error(`Could not reevaluate room ${room.rid}`);
  }

  const isPost = room.parentCollection !== "messages";

  let sourceDomain = "n/a";

  if (parent.url) {
    const url = new URL(parent.url);
    if (url.hostname) {
      sourceDomain = url.hostname;
    }
  }

  // If the author is making a comment that cannot be grouped,
  // you need not group the author at all and simply return -1.0.
  // But use this sparingly and only for non-sequtir comments.

  // ${isPost ? "BODY:" + parent.body + "\n" : ""}
  // Omitted for size but need a way to give this context to LLM
  // probably using RAG

  const prompt =
  `Here is a ${isPost ? "post" : "parent message"}:"\n"
   START OF ${isPost ? "POST" : "PARENT MESSAGE"}:"\n"
   ${isPost ? "TITLE:" + parent.title + "\n": "TEXT" + parent.text + "\n"}
   ${isPost ? "DESCRIPTION:" + parent.description + "\n" : ""}
   ${isPost ? "SOURCE DOMAIN:" + sourceDomain + "\n" : ""}

   END OF ${isPost ? "POST" : "PARENT MESSAGE"}

   You will be given a list of child messages commonting on the above. 
   For each child message, you will be give the text of the message, 
   the ID of the message author, and, if available, 
   the grouping to which the message author belongs.
   There are 4 groupings, 0.0, 180.0, 90.0, and 270.0,
   (and -1.0 meaning no grouping).
   0.0 represents right-wings, 180.0 represents left-wing, 90.0 is centrist,
   and 270.0 is extremist. Think of the spectrum as a circle, where
   extreme left and extreme right converge.

   The goal is to group message authors into 1,2,3,4 position groupings. 
   They may already be grouped by ai already, but you can change their group.

   If two users are on the same side of the political spectrum of a debate,
   you can group them together, 
   eg, if both are liberal they would both be grouped in the position 180.0.

   If there are two overall positions in the debate, 
   try and group them as left and right, so positions 180.0 and 0.0.
   If there are three positions, try and group them as left,
   center, and right, so positions 180.0, 90.0, and 0.0. 
   If there are four positions, 
   then group them as left, right, center, and extreme, 
   so positions 180.0, 0.0, 90.0, and 270.0. Don't create more than 4 groups.
   If messages are BOTH entirely non-political whatsoever, 
   AND also entirely non-related to the subject matter,
   then you can group them as -1.0, which indicates no group. 
   A comment that appears non-political but is related to the subject matter, or is argumentative, 
   should NOT be grouped as -1.0, and instead eagerly found a group.
   To reiterate; we want to group even loosely political or argumentative messages.

   SCORING:
   In addition to grouping the users, we want to assign a score to each user. The score is between 0.0-1.0,
   and reflect how good that user is at arguing their position. Note that for the same group, 
   users can have different scores.

   Scores across all users should add up to 1.0. 
   Eg., if there are two users their scores can bt 0.3 and 0.7, or 0.4 and 0.6, etc.
   0.0 is a valid score and also the starting/default score. 
   1.0 would represent complete and utter perfection versus a bad argument in the debate.
   When the debate is judged, the scores will be used to determine the winning group. 
   The group with the highest score wins (or ties).

   Your output should be a JSON list, with each author id appearing once, listing their position and score.
   {positions:[{id: author uuid passed in, position: 0.0-270.0 or -1.0, score:0.0-1.0}]}

   Here are the child messages, ordered by most recent.
   Note authors can appear multiple times in the list (since they may have written multiple messages), 
   but in your output they should only appear once.

   ${messages.map((message) => {
    return "AUTHOR: " + message.author.id + "\n   " +
    "TEXT: " + message.text + "\n   " +
    "CURRENT POSITION: " + (
        room.leftUsers.includes(message.author.id) ? "180.0" :
        room.rightUsers.includes(message.author.id) ? "0.0" :
        room.centerUsers.includes(message.author.id) ? "90.0" :
        room.extremeUsers.includes(message.author.id) ? "270.0" :
        "-1.0"
    );
  }).join("\n   ")};
  `;

  const completion = await new OpenAI().chat.completions.create({
    messages: [
      {
        role: "system",
        content: `You are a machine that only returns and replies with valid, 
        iterable RFC8259 compliant JSON in your responses`,
      },
      {
        role: "user", content: prompt,
      },
    ],
    model: "gpt-4-1106-preview",
    response_format: {"type": "json_object"},
  });
  try {
    const decision = JSON.parse(completion.choices[0].message.content);
    const positions = decision.positions;
    await _handleReevaluation(room, positions);
    functions.logger.info(`Reevaluating of room ${room.rid} complete`);
  } catch (e) {
    functions.logger.error(`Invalid decision: ${e}`);
    functions.logger.error(completion);
    return;
  }
};

const _handleReevaluation = async function(room, positions) {
  // groups
  const leftUsers = room.leftUsers;
  const rightUsers = room.rightUsers;
  const centerUsers = room.centerUsers;
  const extremeUsers = room.extremeUsers;
  const scoreValues = {};

  positions.forEach((position) => {
    if (position.position != -1.0) {
      // remove user from all groups if they are in one
      if (leftUsers.indexOf(position.id) !== -1) {
        leftUsers.splice(leftUsers.indexOf(position.id), 1);
      }
      if (rightUsers.indexOf(position.id) !== -1) {
        rightUsers.splice(rightUsers.indexOf(position.id), 1);
      }
      if (centerUsers.indexOf(position.id) !== -1) {
        centerUsers.splice(centerUsers.indexOf(position.id), 1);
      }
      if (extremeUsers.indexOf(position.id) !== -1) {
        extremeUsers.splice(extremeUsers.indexOf(position.id), 1);
      }
      if (position.position == 180.0) {
        leftUsers.push(position.id);
      } else if (position.position == 0.0) {
        rightUsers.push(position.id);
      } else if (position.position == 90.0) {
        centerUsers.push(position.id);
      } else if (position.position == 270.0) {
        extremeUsers.push(position.id);
      }
    }
    scoreValues[position.id] = position.score;
  });

  await setRoom(room.rid, {
    leftUsers: leftUsers,
    rightUsers: rightUsers,
    centerUsers: centerUsers,
    extremeUsers: extremeUsers,
    score: {
      values: scoreValues,
      updatedAt: Timestamp.now().toMillis(),
    },
  });
};

const startDebate = async function(room) {
  const now = Timestamp.now().toMillis();

  // DEBATE DURATION...
  const duration = 30.0;
  // Increment is not solved yet!
  const increment = 5.0;

  if (updateRoom(room.rid, {
    status: "live",
    clock: {start: now, duration: duration, increment: increment},
  })) {
    queueDebateTimer(room, now + (duration * 1000));
    functions.logger.info(`Starting debate for ${room.rid}`);
  } else {
    functions.logger.error(`Cannot start debate for room ${room.rid}`);
  }
};

const finalizeDebate = async function(room) {
  functions.logger.info(`Finalizing debate for ${room.rid}`);
  if (room.score != null &&
    room.score.updatedAt > (room.clock.start + room.clock.duration * 1000)) {
    functions.logger.info(`Debate ${room.rid} already evaluated after time`);
  } else {
    await reevaluateRoom(room);
  }
  await scoreDebate(room);
};

const scoreDebate = async function(room) {
  functions.logger.info(`Scoring debate for ${room.rid}`);

  if (room.winningPosition != null && room.winners != null) {
    functions.logger.info(`Debate ${room.rid} already finalized`);
    // return;
  }

  const leftScore = room.leftUsers
      .map((uid) => room.score.values[uid] || 0)
      .reduce((acc, value) => acc + value, 0);
  const rightScore = room.rightUsers
      .map((uid) => room.score.values[uid] || 0)
      .reduce((acc, value) => acc + value, 0);
  const centerScore = room.centerUsers
      .map((uid) => room.score.values[uid] || 0)
      .reduce((acc, value) => acc + value, 0);
  const extremeScore = room.extremeUsers
      .map((uid) => room.score.values[uid] || 0)
      .reduce((acc, value) => acc + value, 0);

  functions.logger.info(`Debate ${room.rid} scored`);
  functions.logger.info(`Left: ${leftScore}, Right: ${rightScore}, Center: ${centerScore}, Extreme: ${extremeScore}`);

  let winningPositionAngle = null;
  let winners = [];
  if (leftScore > rightScore && leftScore > centerScore && leftScore > extremeScore) {
    winningPositionAngle = 180.0;
    winners = room.leftUsers;
  } else if (rightScore > leftScore && rightScore > centerScore && rightScore > extremeScore) {
    winningPositionAngle = 0.0;
    winners = room.rightUsers;
  } else if (centerScore > leftScore && centerScore > rightScore && centerScore > extremeScore) {
    winningPositionAngle = 90.0;
    winners = room.centerUsers;
  } else if (extremeScore > leftScore && extremeScore > rightScore && extremeScore > centerScore) {
    winningPositionAngle = 270.0;
    winners = room.extremeUsers;
  }
  const winningPosition = winningPositionAngle != null ? {angle: winningPositionAngle} : null;
  const eloScores = await calculateEloDelta(room, winners);
  // atomic operation
  await setRoom(room.rid, {
    //
    winningPosition: winningPosition,
    winners: winners,
    eloScore: {
      values: eloScores,
      updatedAt: Timestamp.now().toMillis(),
    },
    //
    status: "finished",
  });
};

const calculateEloDelta = async function(room, winners) {
  functions.logger.info(`Calculating elo for ${room.rid}`);
  const isDraw = winners.length == 0;
  const eloScores = {};

  // get users in one of the rooms
  // get users where left or right etc are not empty
  const players = room.users.filter((uid) => {
    return room.leftUsers.indexOf(uid) !== -1 ||
    room.rightUsers.indexOf(uid) !== -1 ||
    room.centerUsers.indexOf(uid) !== -1 ||
    room.extremeUsers.indexOf(uid) !== -1;
  });

  // get elos for each player
  const playerUsers = await getUsers(players);
  if (!playerUsers) {
    functions.logger.error(`Elo failed: Could not get users for ${room.rid}`);
    return;
  }

  // if there is winner and loser we want to get each average
  // else if draw we get overall avg
  let eloWinnerAvg = 0.0;
  let eloLoserAvg = 0.0;
  let eloAvg = 0.0;

  if (isDraw) {
    const sum = playerUsers.reduce((acc, user) => acc + user.elo, 0);
    eloAvg = sum / playerUsers.length;
  } else {
    const winnerSum = winners.reduce((acc, uid) => {
      const userElo = playerUsers.find((user) => user.uid === uid).elo || 0;
      return acc + userElo;
    }, 0);
    eloWinnerAvg = winnerSum / winners.length;

    const loserSum = playerUsers.reduce((acc, user) => {
      if (!winners.includes(user.uid)) {
        acc += user.elo;
      }
      return acc;
    }, 0);
    eloLoserAvg = loserSum / (playerUsers.length - winners.length);
  }

  // calculate new elo
  for (const user of playerUsers) {
    let newElo = 0;
    if (isDraw) {
      newElo = getElo(user.elo, eloAvg, 0.5);
    } else if (winners.indexOf(user.uid) !== -1) {
      newElo = getElo(user.elo, eloLoserAvg, 1);
    } else {
      newElo = getElo(user.elo, eloWinnerAvg, 0);
    }
    eloScores[user.uid] = newElo - user.elo;
  }
  functions.logger.info(`Elo for ${room.rid} calculated, ${JSON.stringify(eloScores)}`);
  return eloScores;
};

module.exports = exports = {
  reevaluateRoom,
  finalizeDebate,
  startDebate,
};
