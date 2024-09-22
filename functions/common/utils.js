const {Timestamp, FieldValue} = require("firebase-admin/firestore");
const _ = require("lodash");
const {logger} = require("firebase-functions/v2");

const isLocal = process.env.FUNCTIONS_EMULATOR === "true";

const isPerfectSquare = function(x) {
  const s = Math.sqrt(x);
  return s * s === x;
};

const isFibonacciNumber = function(n) {
  if (n == null) return false;
  return isPerfectSquare(5 * n * n + 4) || isPerfectSquare(5 * n * n - 4);
};

/**
 * Calculate the probability of player A winning
 * @param {number} eloA - the Elo rating of player A
 * @param {number} eloB - the Elo rating of player B
 * @return {number} the probability of player A winning
 */
function calculateProbability(eloA, eloB) {
  return 1.0 / (1.0 + Math.pow(10, (eloB - eloA) / 400));
}

/**
 * @param {number} eloWinner - the Elo rating of player A
 * @param {number} eloLoser - the Elo rating of player B
 * @param {boolean} didWin - the result of the match for player A, 1, 0 or 0.5
 * @param {number} kFactor - the K-factor for the match
 * @return {number} new rating
 */
function getElo(eloWinner, eloLoser, didWin, kFactor = 32) {
  // Calculate the probability of winning for each player
  const probA = calculateProbability(eloWinner, eloLoser);
  // const probB = calculateProbability(eloLoser, eloWinner);

  // Update ratings
  const newRatingWinner = eloWinner + kFactor * (didWin - probA);
  // const newRatingLoser = eloLoser + kFactor * ((1 - winner) - probB);
  // convert number to integer
  return Math.round(newRatingWinner);
}

/**
 * @param {string} url - the URL to parse
 * @return {string} the domain of the URL
 */
function urlToDomain(url) {
  if (!url) return;

  // Add a default scheme if the URL doesn't contain one
  if (!/^https?:\/\//i.test(url)) {
    url = "https://" + url;
  }

  const domain = (new URL(url)).hostname;
  return domain;
}

/**
 *
 * @param {Function} asyncFn
 * @param {number} retries
 * @param {number} interval
 * @param {boolean} showError
 * @return {Promise<*>}
 */
async function retryAsyncFunction(
    asyncFn,
    retries = 3,
    interval = 1000,
    showError = true,
) {
  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      const result = await asyncFn();
      if (result) return result;
    } catch (error) {
      if (showError) {
        logger.error(`Attempt ${attempt + 1} failed: ${error}`);
      }
    }
    if (attempt < retries - 1) {
      await new Promise((resolve) => setTimeout(resolve, interval));
    }
  }
  if (showError) {
    logger.error(`Failed after ${retries} attempts`);
  }
  return false;
}

/**
 *
 * Calculates the mean vector of a list of vectors
 * @param {Array<number[]> | VectorValue} vectors - the list of vectors
 * @return {number[]} the mean vector
 */
function calculateMeanVector(vectors) {
  if (_.isEmpty(vectors)) return null;
  if (!_.isArray(vectors[0])) {
    vectors = vectors.map((vector) => vector.toArray());
  }
  const meanVector = vectors.reduce((acc, vector) => {
    return acc.map((value, i) => value + vector[i]);
  }, Array(vectors[0].length).fill(0));
  return meanVector.map((value) => value / vectors.length);
}

/**
 * Converts milliseconds to an ISO string
 * @param {number} millis - the milliseconds
 * @return {string} the ISO string
 */
const millisToIso = function(millis) {
  if (!millis) return;
  return new Date(millis).toISOString();
};

/**
 * Converts an ISO string to milliseconds
 * @param {string} iso - the ISO string
 * @return {number} the milliseconds
 */
const isoToMillis = function(iso) {
  if (!iso) return;
  return Timestamp.fromDate(new Date(iso)).toMillis();
};


// //////////////////////////////////////////////////////////////////
// Sync
// //////////////////////////////////////////////////////////////////

/**
 * Handles changed relations between two objects
 * Eg., if a Post has sids, and a Story has pids, when the Post is updated
 * this function will update the Story's pids, and vice versa.
 * Ignores errors if the object to update does not exist.
 * Note that we only remove for extraUpdates, adding is done directly
 * @param {Object} before - the object before the change
 * @param {Object} after - the object after the change
 * @param {string} field - the field containing the relations
 * @param {Function} updateFn - the function to update the related object
 * @param {string} idKey - the key of the related object
 * @param {string} relatedKey - the key of the related field
 * @param {Object} extraUpdates - extra updates to apply to the related object.
 * @param {boolean} relationType - if the relation is one-to-many
 * @return {Promise<void>}
 * */
const handleChangedRelations = async (
    before,
    after,
    field,
    updateFn,
    idKey,
    relatedKey,
    extraUpdates = {},
    relationType = "manyToMany") => {
  if (relationType === "oneToMany") {
    // await handleChangedRelations(before, after, "eid",
    //     updateEntity, "pid", "pids", {}, "oneToMany");
    if (!after) {
      await retryAsyncFunction(() => updateFn(before[field], {
        [relatedKey]: FieldValue.arrayRemove(before[idKey]),
        ...extraUpdates,
      }, 5));
    } else if (!before) {
      await retryAsyncFunction(() => updateFn(after[field], {
        [relatedKey]: FieldValue.arrayUnion(after[idKey]),
      }, 5));
    } else {
      const removed = before[field];
      const added = after[field];
      if (removed !== added) {
        if (removed) {
          await retryAsyncFunction(() => updateFn(removed, {
            [relatedKey]: FieldValue.arrayRemove(before[idKey]),
            ...extraUpdates,
          }, 5));
        }
        if (added) {
          await retryAsyncFunction(() => updateFn(added, {
            [relatedKey]: FieldValue.arrayUnion(after[idKey]),
          }, 5));
        }
      }
    }
  } else if (relationType === "manyToOne") {
    // await handleChangedRelations(before, after,
    // "pids", updatePost, "eid", "eid", {}, "manyToOne");
    if (!after) {
      for (const id of before[field] || []) {
        await retryAsyncFunction(() => updateFn(id, {
          [relatedKey]: FieldValue.delete(),
          ...extraUpdates,
        }, 5));
      }
    } else if (!before) {
      for (const id of after[field] || []) {
        await retryAsyncFunction(() => updateFn(id, {
          [relatedKey]: after[idKey],
        }, 5));
      }
    } else {
      const removed = (before[field] || [])
          .filter((id) => !(after[field] || []).includes(id));
      const added = (after[field] || [])
          .filter((id) => !(before[field] || []).includes(id));

      for (const id of removed) {
        await retryAsyncFunction(() => updateFn(id, {
          [relatedKey]: FieldValue.delete(),
          ...extraUpdates,
        }, 5));
      }
      for (const id of added) {
        await retryAsyncFunction(() => updateFn(id, {
          [relatedKey]: after[idKey],
        }, 5));
      }
    }
  } else if (relationType === "manyToMany") {
    if (!after) {
      for (const id of before[field] || []) {
        await retryAsyncFunction(() => updateFn(id, {
          [relatedKey]: FieldValue.arrayRemove(before[idKey]),
          ...extraUpdates,
        }, 5));
      }
    } else if (!before) {
      for (const id of after[field] || []) {
        await retryAsyncFunction(() => updateFn(id, {
          [relatedKey]: FieldValue.arrayUnion(after[idKey]),
        }, 5));
      }
    } else {
      const removed = (before[field] || [])
          .filter((id) => !(after[field] || []).includes(id));
      const added = (after[field] || [])
          .filter((id) => !(before[field] || []).includes(id));

      for (const id of removed) {
        await retryAsyncFunction(() => updateFn(id, {
          [relatedKey]: FieldValue.arrayRemove(before[idKey]),
          ...extraUpdates,
        }, 5));
      }
      for (const id of added) {
        await retryAsyncFunction(() => updateFn(id, {
          [relatedKey]: FieldValue.arrayUnion(after[idKey]),
        }, 5));
      }
    }
  }

  return Promise.resolve();
};


module.exports = {
  isLocal,
  urlToDomain,
  isFibonacciNumber,
  isPerfectSquare,
  getElo,
  retryAsyncFunction,
  calculateMeanVector,
  millisToIso,
  isoToMillis,
  handleChangedRelations,
};
