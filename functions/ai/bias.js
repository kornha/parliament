/* eslint-disable require-jsdoc */
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
const {logger} = require("firebase-functions/v2");
const {getEntity, updateEntity,
  getAllStatementsForEntity,
  getAllEntitiesForStatement,
  updateStatement,
  getStatement} = require("../common/database");
const {retryAsyncFunction} = require("../common/utils");

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

  const newBias = calculateAverageBias(statements);

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

  const newBias = calculateAverageBias(entities);

  if (newBias != null && statement.bias !== newBias) {
    logger.info(`Updating statement bias: ${stid} ${newBias}`);
    await retryAsyncFunction(() =>
      updateStatement(stid, {bias: newBias}));
  }

  return;
}

/**
 * Takes in a list of iterables with bias, and returns the avg bias.
 * @param {Object[]} iterable (entities or statements) with bias
 * @return {number} The bias (angle) of the entity.
 */
function calculateAverageBias(iterable) {
  let x = 0;
  let y = 0;
  let count = 0;

  // Loop through iterable to calculate the average angle
  for (let i = 0; i < iterable.length; i++) {
    const biasObj = iterable[i];

    if (biasObj.bias == null) {
      continue;
    }

    const angleInRadians = (biasObj.bias * Math.PI) / 180;

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

const getDistance = function(currAngle, newAngle) {
  const delta = Math.abs(currAngle - newAngle);
  return Math.min(delta, 360.0 - delta);
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
  onEntityShouldChangeBias,
  onStatementShouldChangeBias,
  applyVoteToBias,
  applyDebateToBias,
  getDirection,
  getDistance,
  addPosition,
};
