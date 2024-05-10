const functions = require("firebase-functions");
const {Timestamp} = require("firebase-admin/firestore");
const _ = require("lodash");

const isLocal = process.env.FUNCTIONS_EMULATOR === "true";
// const isDev = !isLocal &&
//  admin.instanceId().app.options.projectId === "political-think";

const isPerfectSquare = function(x) {
  const s = Math.sqrt(x);
  return s * s === x;
};

const isFibonacciNumber = function(n) {
  if (!n) return false;
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
 * @return {string} the source type of the URL
 */
function urlToSourceType(url) {
  const domain = urlToDomain(url);
  if (domain == "x.com" || domain == "twitter.com") {
    return "x";
  }
  return null;
}

/**
 * @param {string} url - the URL to parse
 * @return {string} the domain of the URL
 */
function urlToDomain(url) {
  if (!url) return;
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
        functions.logger.error(`Attempt ${attempt + 1} failed: ${error}`);
      }
    }
    if (attempt < retries - 1) {
      await new Promise((resolve) => setTimeout(resolve, interval));
    }
  }
  if (showError) {
    functions.logger.error(`Failed after ${retries} attempts`);
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

module.exports = {
  isLocal,
  // isDev,
  urlToDomain,
  urlToSourceType,
  isFibonacciNumber,
  isPerfectSquare,
  getElo,
  retryAsyncFunction,
  calculateMeanVector,
  millisToIso,
  isoToMillis,
};
