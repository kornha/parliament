const {logger} = require("firebase-functions");
const {getStatement,
  getAllEntitiesForStatement,
  updateStatement,
  getAllStatementsForEntity,
  updateEntity,
  getEntity,
  getAllStatementsForStory,
  updateStory,
  getAllStatementsForPost,
  updatePost} = require("../common/database");
const {retryAsyncFunction} = require("../common/utils");

// Parameters
const CORRECT_REWARD = 0.2;
const INCORRECT_PENALTY = -0.6;
const DECAY_FACTOR = 0.95; // Exp. decay (1 = slower decay, 0 = faster decay)
const BASE_CONFIDENCE = 0.5;
const DECIDED_THRESHOLD = 0.9;
const LIKELY_THRESHOLD = 0.75;

// ////////////////////////////////////////////////////////////////////////////
// Post
// ////////////////////////////////////////////////////////////////////////////

/**
 * E2E Logic onPost for setting confidence
 * @param {String} pid
 * @return {Promise<void>}
 * */
async function onPostShouldChangeConfidence(pid) {
  const statements = await getAllStatementsForPost(pid);

  const avgConfidence = calculateAverageConfidence(statements);

  if (avgConfidence != null) {
    logger.info(`Updating Post confidence: ${pid} ${avgConfidence}`);
    // skipping error case where post is deleted, since this throws errors
    await retryAsyncFunction(() =>
      updatePost(pid, {confidence: avgConfidence}, 5));
  }
}


// ////////////////////////////////////////////////////////////////////////////
// Story
// ////////////////////////////////////////////////////////////////////////////

/**
 * E2E Logic onStory for setting confidence
 * @param {String} sid
 * @return {Promise<void>}
 * */
async function onStoryShouldChangeConfidence(sid) {
  const statements = await getAllStatementsForStory(sid);

  const avgConfidence = calculateAverageConfidence(statements);

  if (avgConfidence != null) {
    logger.info(`Updating Story confidence: ${sid} ${avgConfidence}`);
    await retryAsyncFunction(() =>
      updateStory(sid, {confidence: avgConfidence}, 5));
  }
}

// ////////////////////////////////////////////////////////////////////////////
// ENTITY
// ////////////////////////////////////////////////////////////////////////////

/**
 * E2E Logic onEntity for setting confidence
 * @param {String} eid
 * @return {Promise<void>}
 */
async function onEntityShouldChangeConfidence(eid) {
  const entity = await getEntity(eid);

  if (!entity ||
    (entity.adminConfidence != null &&
    entity.adminConfidence === entity.confidence)) {
    return;
  }

  // If admin has set confidence, use that always
  if (entity.adminConfidence != null) {
    logger.info(`Updating Entity confidence: ${eid} ${entity.adminConfidence}`);
    await retryAsyncFunction(() =>
      updateEntity(eid, {confidence: entity.adminConfidence}));
    return;
  }

  const statements = await getAllStatementsForEntity(eid);

  const newConfidence = calculateEntityConfidence(entity, statements);

  if (newConfidence != null && entity.confidence !== newConfidence) {
    logger.info(`Updating entity confidence: ${eid} ${newConfidence}`);
    await retryAsyncFunction(() =>
      updateEntity(eid, {confidence: newConfidence}));
  }
}

/**
 * Calculate the confidence of an entity based on its past statements.
 * Confidence is chance we trust the entity going forward
 * Calculated like a credit score where correct responses are rewarded less
 * than incorrect ones.
 * @param {Entity} entity The entity object.
 * @param {Statement[]} statements The array of statement objects.
 * @return {number} The confidence of the entity.
 */
function calculateEntityConfidence(entity, statements) {
  let totalScore = BASE_CONFIDENCE;
  let count = 0;

  // Loop through statements most recent first
  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];

    if (statement.confidence == null) {
      continue;
    }

    count++;

    // more recent statements are penalized/rewarded more
    const decay = Math.pow(DECAY_FACTOR, i);

    const decidedPro = statement.confidence > DECIDED_THRESHOLD;
    const decidedAgainst = statement.confidence < 1 - DECIDED_THRESHOLD;

    if (!decidedPro && !decidedAgainst) {
      continue;
    }

    let isCorrect = false;
    let isIncorrect = false;

    if (decidedPro) {
      isCorrect = entity.pids.some((pid) => statement.pro.includes(pid));
      isIncorrect = entity.pids.some((pid) => statement.against.includes(pid));
    } else if (decidedAgainst) {
      isCorrect = entity.pids.some((pid) => statement.against.includes(pid));
      isIncorrect = entity.pids.some((pid) => statement.pro.includes(pid));
    }

    // this allows us to weight the confidence equally for distance to 0 or 1
    const adjustedConfidence = Math.abs(statement.confidence - 0.5) * 2;

    if (isCorrect) {
      totalScore +=
        CORRECT_REWARD * (1 - totalScore) * decay * adjustedConfidence;
    } else if (isIncorrect) {
      totalScore +=
        INCORRECT_PENALTY * totalScore * decay * adjustedConfidence;
    }
  }

  if (count === 0) {
    return null;
  }

  return Math.max(0, Math.min(1, totalScore));
}

// ////////////////////////////////////////////////////////////////////////////
// STATEMENT
// ////////////////////////////////////////////////////////////////////////////

/**
 * E2E Logic onStatement for setting confidence
 * @param {String} stid
 */
async function onStatementShouldChangeConfidence(stid) {
  const statement = await getStatement(stid);

  if (!statement ||
    (statement.adminConfidence != null &&
    statement.adminConfidence === statement.confidence)) {
    return;
  }

  // If admin has set confidence, use that always
  if (statement.adminConfidence != null) {
    logger.info(
        `Updating statement confidence: ${stid} ${statement.adminConfidence}`);
    await retryAsyncFunction(() => updateStatement(stid,
        {confidence: statement.adminConfidence}));
    return;
  }

  const entities = await getAllEntitiesForStatement(stid);

  const newConfidence = calculateStatementConfidence(statement, entities);

  if (newConfidence != null && statement.confidence !== newConfidence) {
    logger.info(`Updating statement confidence: ${stid} ${newConfidence}`);
    await retryAsyncFunction(() =>
      updateStatement(stid, {confidence: newConfidence}));
  }

  return;
}

/**
 * Calculate the confidence of a statement based on its entities.
 * Uses margin-from-0.5 weighting so near-neutral entities contribute little,
 * but always returns a number (falls back to 0.5 if no signal).
 *
 * @param {Statement} statement
 * @param {Entity[]} entities
 * @return {number} Confidence in [0,1]
 */
function calculateStatementConfidence(statement, entities) {
  if (!entities || entities.length === 0) return 0.5; // no evidence → neutral

  const GAMMA = 2.5; // steeper -> 0.55–0.65 counts much less

  let weightedSum = 0;
  let totalWeight = 0;

  for (const entity of entities) {
    const e = entity?.confidence;
    if (e == null) continue;

    const pro =
      statement.pro?.some((pid) => entity.pids?.includes(pid)) ?? false;
    const against =
      statement.against?.some((pid) => entity.pids?.includes(pid)) ?? false;

    if (!pro && !against) continue;

    // weight = distance from 0.5 in either direction
    const margin = Math.abs(e - 0.5) / 0.5; // 0 at 0.5, 1 at 0 or 1
    const w = Math.pow(margin, GAMMA);

    // effective confidence: flip only value, not weight
    const eff = pro ? e : (against ? (1 - e) : null);
    if (eff == null) continue;

    weightedSum += w * eff;
    totalWeight += w;
  }

  // if no non-neutral weights, just return 0.5
  if (totalWeight === 0) return 0.5;

  const newConfidence = weightedSum / totalWeight;
  return Math.max(0, Math.min(1, newConfidence));
}


/**
 * Check if a statement crossed the confidence threshold.
 * @param {Statement} before The statement object before the change.
 * @param {Statement} after The statement object after the change.
 * @return {boolean} Whether the statement crossed the threshold.
 */
function confidenceDidCrossThreshold(before, after) {
  const beforeConfidence = before?.confidence ?? BASE_CONFIDENCE;
  const afterConfidence = after?.confidence ?? BASE_CONFIDENCE;

  // 1) Dislodging from / returning to BASE_CONFIDENCE
  if (
    (beforeConfidence === BASE_CONFIDENCE &&
       afterConfidence !== BASE_CONFIDENCE) ||
    (afterConfidence === BASE_CONFIDENCE &&
       beforeConfidence !== BASE_CONFIDENCE)
  ) {
    return true;
  }

  /**
   * @param {number} confidence The statement object after the change
   * @return {number} The confidence state.
   */
  function getConfidenceState(confidence) {
    if (confidence < 1 - DECIDED_THRESHOLD) {
      // negative decided
      return -2;
    } else if (confidence < 1 - LIKELY_THRESHOLD) {
      // negative likely
      return -1;
    } else if (confidence > DECIDED_THRESHOLD) {
      // positive decided
      return 2;
    } else if (confidence >= LIKELY_THRESHOLD) {
      // positive likely
      return 1;
    } else {
      // neutral
      return 0;
    }
  }

  const beforeState = getConfidenceState(beforeConfidence);
  const afterState = getConfidenceState(afterConfidence);

  return beforeState !== afterState;
}


// ////////////////////////////////////////////////////////////////////////////
// Generic
// ////////////////////////////////////////////////////////////////////////////
/**
 * Calculate the average confidence of an iterable
 * @param {Object[]} iterable The array of objects
 * @return {number|null} The average confidence
 * */
function calculateAverageConfidence(iterable) {
  if (iterable.length === 0) {
    return null;
  }

  let totalConfidence = 0;
  let count = 0;

  for (const item of iterable) {
    if (item.confidence != null) {
      totalConfidence += item.confidence;
      count++;
    }
  }

  if (count === 0) {
    return null;
  }

  return totalConfidence / count;
}


module.exports = {
  confidenceDidCrossThreshold,
  onPostShouldChangeConfidence,
  onStoryShouldChangeConfidence,
  onEntityShouldChangeConfidence,
  calculateEntityConfidence,
  onStatementShouldChangeConfidence,
  calculateStatementConfidence,
};
