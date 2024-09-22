/* eslint-disable require-jsdoc */
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
const {logger} = require("firebase-functions/v2");
const {getEntity, updateEntity,
  getAllStatementsForEntity,
  getAllEntitiesForStatement,
  updateStatement,
  getStatement,
  getStory,
  updateStory,
  getAllStatementsForStory,
  getPost,
  getAllStatementsForPost,
  updatePost} = require("../common/database");
const {retryAsyncFunction} = require("../common/utils");


// ////////////////////////////////////////////////////////////////////////////
// POST
// ////////////////////////////////////////////////////////////////////////////

/**
 * E2E Logic on Post for setting bias
 * @param {String} pid
 * @return {Promise<void>}
 */
async function onPostShouldChangeBias(pid) {
  const post = await getPost(pid);
  const statements = await getAllStatementsForPost(pid);

  const newBias = calculateAverageBias(statements);

  if (newBias != null && post.bias !== newBias) {
    logger.info(`Updating Post bias: ${pid} ${newBias}`);
    await retryAsyncFunction(() =>
      updatePost(pid, {bias: newBias}, 5));
  }
}

// ////////////////////////////////////////////////////////////////////////////
// STORY
// ////////////////////////////////////////////////////////////////////////////

/**
 * E2E Logic on Story for setting bias
 * @param {String} sid
 * @return {Promise<void>}
 */
async function onStoryShouldChangeBias(sid) {
  const story = await getStory(sid);
  const statements = await getAllStatementsForStory(sid);

  const newBias = calculateAverageBias(statements);

  if (newBias != null && story.bias !== newBias) {
    logger.info(`Updating story bias: ${sid} ${newBias}`);
    await retryAsyncFunction(() =>
      updateStory(sid, {bias: newBias}, 5));
  }
}

// ////////////////////////////////////////////////////////////////////////////
// ENTITY
// ////////////////////////////////////////////////////////////////////////////

/**
 * E2E Logic onEntity for setting bias
 * @param {String} eid
 * @return {Promise<void>}
 */
async function onEntityShouldChangeBias(eid) {
  const entity = await getEntity(eid);

  if (!entity ||
    (entity.adminBias != null &&
    entity.adminBias === entity.bias)) {
    return;
  }

  // If admin has set bias, use that always
  if (entity.adminBias != null) {
    logger.info(`Updating entity bias: ${eid} ${entity.adminBias}`);
    await retryAsyncFunction(() =>
      updateEntity(eid, {bias: entity.adminBias}));
    return;
  }

  const statements = await getAllStatementsForEntity(eid);

  const newBias = calculateAverageBias(statements, entity, true);

  if (newBias != null && entity.bias !== newBias) {
    logger.info(`Updating entity bias: ${eid} ${newBias}`);
    await retryAsyncFunction(() =>
      updateEntity(eid, {bias: newBias}));
  }
}

// ////////////////////////////////////////////////////////////////////////////
// STATEMENT
// ////////////////////////////////////////////////////////////////////////////

/**
 * E2E Logic onStatement for setting bias
 * @param {String} stid
 */
async function onStatementShouldChangeBias(stid) {
  const statement = await getStatement(stid);

  if (!statement ||
    (statement.adminBias != null &&
    statement.adminBias === statement.bias)) {
    return;
  }

  // If admin has set bias, use that always
  if (statement.adminBias != null) {
    logger.info(
        `Updating statement bias: ${stid} ${statement.adminBias}`);
    await retryAsyncFunction(() => updateStatement(stid,
        {bias: statement.adminBias}));
    return;
  }

  const entities = await getAllEntitiesForStatement(stid);

  const newBias = calculateAverageBias(entities, statement, false);

  if (newBias != null && statement.bias !== newBias) {
    logger.info(`Updating statement bias: ${stid} ${newBias}`);
    await retryAsyncFunction(() =>
      updateStatement(stid, {bias: newBias}));
  }

  return;
}

/**
 * Takes in a list of iterables (entities or statements) and returns avg.
 * Accounts for whether the post is pro or against.
 * @param {Object[]} iterable A list of entities or statements.
 * @param {Object|null} target (entity or statement), or null if only avg
 * @param {boolean|null} isEntityTarget entity/statement, or null if only avg
 * @return {number} The bias (angle) of the entity or statement.
 * */
function calculateAverageBias(
    iterable,
    target,
    isEntityTarget) {
  let x = 0;
  let y = 0;
  let count = 0;

  // Loop through iterable to calculate the average angle
  for (let i = 0; i < iterable.length; i++) {
    const biasObj = iterable[i];

    if (biasObj.bias == null) {
      continue;
    }

    let pro = false;
    let against = false;

    if (target != null) {
      if (isEntityTarget) {
      // Target is entity: Check if posts are in the pro/against lists
        pro = biasObj.pro?.some((pid) => target.pids.includes(pid)) ?? false;
        against = biasObj.against?.
            some((pid) => target.pids.includes(pid)) ?? false;
      } else {
      // Target is statement: does statement's lists contain the entity's posts
        pro = target.pro?.some((pid) => biasObj.pids.includes(pid)) ?? false;
        against = target.against?.
            some((pid) => biasObj.pids.includes(pid)) ?? false;
      }
    }

    let bias = biasObj.bias;

    // Reverse the bias if it's in the against list
    if (against) {
      bias = (bias + 180) % 360;
    } else if (pro) {
      // do nothing
    }

    const angleInRadians = (bias * Math.PI) / 180;

    // Convert the angle to a vector and accumulate
    x += Math.cos(angleInRadians);
    y += Math.sin(angleInRadians);
    count++;
  }

  // If no valid biases, return null
  if (count === 0) {
    return null;
  }

  // Calculate the average vector direction
  const averageX = x / count;
  const averageY = y / count;

  // Convert the average vector back to an angle
  const averageBias = Math.atan2(averageY, averageX) * (180 / Math.PI);

  // Ensure the angle is in the range [0, 360)
  return (averageBias + 360) % 360;
}

/**
 * Check if a biased changed quadrant. Might want to change to octant.
 * @param {Bias} before The Bias object before the change.
 * @param {Bias} after The Bias object after the change.
 * @return {boolean} Whether the Bias crossed the threshold.
 */
function biasDidCrossThreshold(before, after) {
  if (before == null && after != null ||
      before != null && after == null) {
    return true;
  }
  const q1 = getQuadrant(before.bias);
  const q2 = getQuadrant(after.bias);
  return q1 !== q2;
}

/**
 * Gets the political position quadrant of an angle.
 * @param {number} angle The angle to get the quadrant of.
 * @return {string} The quadrant of the angle or null if invalid.
 */
function getQuadrant(angle) {
  if (angle == null || angle < 0 || angle >= 360) {
    return null;
  }
  const temp = angle % 360;

  if (temp >= 315.0 || temp <= 45.0) {
    return "right";
  } else if (temp >= 135 && temp <= 225) {
    return "left";
  } else if (temp > 45.0 && temp < 135.0) {
    return "center";
  } else {
    return "extreme";
  }
}

const getDistance = function(currAngle, newAngle) {
  const delta = Math.abs(currAngle - newAngle);
  return Math.min(delta, 360.0 - delta);
};

// ////////////////////////////////////////////////////////////////////////////
// Deprecated
// ////////////////////////////////////////////////////////////////////////////

// tests
// console.log(getDirection(0,230)); //clockwise
// console.log(getDirection(270,275)); //counterclockwise
// console.log(getDirection(275,230)); //clockwise
// console.log(getDirection(40,181)); //counterclockwise
// console.log(getDirection(40,280)); //clockwise
// console.log(getDirection(0,180)); //counterclockwise
// console.log(getDirection(180,0)); //clockwise
// console.log(getDirection(272,92)); //counterclockwise
// console.log(getDirection(270,90)); //clockwise
// console.log(getDirection(90,270)); //counterclockwise
const getDirection = function(currAngle, newAngle) {
  // Normalize angles to be in the range [0, 360)
  const angle1 = (currAngle + 360) % 360;
  const angle2 = (newAngle + 360) % 360;

  const angularDistance = (angle2 - angle1 + 360) % 360;

  if (angularDistance == 180) {
    // need this because of JS 0 falsy
    if (angle1 == 0) return "counterclockwise";
    if (angle2 == 0) return "clockwise";
    // no value if on good/bad pole. Breaking case!!
    if (angle1 == 90) return "counterclockwise";
    if (angle1 == 270) return "clockwise";
    // otherwise move to center
    if (angle1 > 90 && angle1 < 270) return "clockwise";
    return "counterclockwise";
  }

  if (angularDistance > 180) return "clockwise";
  else return "counterclockwise";
};


const addPosition = function(currAngle, magnitude, direction) {
  if (direction != "clockwise" && direction != "counterclockwise") {
    logger.error("Invalid direction");
    return;
  }
  const newAngle = direction == "clockwise" ?
      currAngle - magnitude : currAngle + magnitude;

  return (newAngle + 360) % 360;
};

// TODO: could abstract these
const applyVoteToBias = async function(pid, vote, {add = true}) {
  const postRef = admin.firestore().collection("posts").doc(pid);

  try {
    await admin.firestore().runTransaction(async (t) => {
      const doc = await t.get(postRef);

      if (!doc.exists) {
        logger.error(`Post ${pid} does not exist!`);
        return;
      }

      const post = doc.data();
      let newBiasPosVal;

      if (post.voteCountBias == null ||
        post.voteCountBias <= 0 ||
        post.userBias === null) {
        if (!add) {
          logger.error(`Cannot remove vote in ${pid}, empty!`);
          return;
        }
        newBiasPosVal = vote.bias.position.angle;
      } else if (post.voteCountBias == 1 && !add) {
        newBiasPosVal = null;
      } else {
        let direction = getDirection(post.userBias.position.angle,
            vote.bias.position.angle);
        direction = add ? direction :
          direction == "clockwise" ? "counterclockwise" : "clockwise";
        //
        const dist = getDistance(post.userBias.position.angle,
            vote.bias.position.angle);
        const magnitude = dist / (post.voteCountBias + (add ? 1.0 : -1.0));

        //
        newBiasPosVal = addPosition(post.userBias.position.angle, magnitude,
            direction);
      }

      t.update(postRef, {
        userBias: newBiasPosVal !== null ?
        {position: {"angle": newBiasPosVal}} : null,
        voteCountBias: FieldValue.increment(add ? 1 : -1),
      });
    });
  } catch (e) {
    logger.error(e);
  }
};

const applyDebateToBias = async function(pid, winningPosition, {add = true}) {
  const postRef = admin.firestore().collection("posts").doc(pid);

  try {
    await admin.firestore().runTransaction(async (t) => {
      const doc = await t.get(postRef);

      if (!doc.exists) {
        logger.error(`Post ${pid} does not exist!`);
        return;
      }

      const post = doc.data();
      let newBiasPosVal;

      if (post.debateCountBias == null ||
        post.debateCountBias <= 0 ||
        post.debateBias === null) {
        if (!add) {
          logger.error(`Cannot remove debate bias in ${pid}, empty!`);
          return;
        }
        newBiasPosVal = winningPosition.angle;
      } else if (post.debateCountBias == 1 && !add) {
        newBiasPosVal = null;
      } else {
        let direction = getDirection(post.debateBias.position.angle,
            winningPosition.angle);
        direction = add ? direction :
          direction == "clockwise" ? "counterclockwise" : "clockwise";
        //
        const dist = getDistance(post.debateBias.position.angle,
            winningPosition.angle);
        const magnitude = dist / (post.debateCountBias + (add ? 1.0 : -1.0));

        //
        newBiasPosVal = addPosition(post.debateBias.position.angle, magnitude,
            direction);
      }

      t.update(postRef, {
        debateBias: newBiasPosVal !== null ?
        {position: {"angle": newBiasPosVal}} : null,
        debateCountBias: FieldValue.increment(add ? 1 : -1),
      });
    });
  } catch (e) {
    logger.error(e);
  }
};

module.exports = {
  onPostShouldChangeBias,
  onStoryShouldChangeBias,
  onEntityShouldChangeBias,
  onStatementShouldChangeBias,
  applyVoteToBias,
  applyDebateToBias,
  getDirection,
  getDistance,
  addPosition,
  biasDidCrossThreshold,
  calculateAverageBias,
};
