const {Timestamp, FieldValue} = require("firebase-admin/firestore");
const _ = require("lodash");
const {logger} = require("firebase-functions/v2");
const axios = require("axios");
const {defineSecret} = require("firebase-functions/params");
const _cloudApiKey = defineSecret("CLOUD_API_KEY");


const isLocal = process.env.FUNCTIONS_EMULATOR === "true";

// //////////////////////////////////////////////////////////////////
// Math
// //////////////////////////////////////////////////////////////////

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

// //////////////////////////////////////////////////////////////////
// Time
// //////////////////////////////////////////////////////////////////

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
// URL
// //////////////////////////////////////////////////////////////////

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

  let domain = (new URL(url)).hostname;

  // Remove 'www.' if it exists
  if (domain.startsWith("www.")) {
    domain = domain.substring(4);
  }

  return domain;
}

// //////////////////////////////////////////////////////////////////
// Retry
// //////////////////////////////////////////////////////////////////

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

// //////////////////////////////////////////////////////////////////
// Error
// //////////////////////////////////////////////////////////////////

/**
 * Checks if an error is due to an invalid image in the prompt.
 * the error messages are hard coded in as per what openai throws
 * @param {Error} e - The error object.
 * @return {boolean} - True if it's an invalid image error, false otherwise.
 */
function isInvalidImageError(e) {
  return e && e.status == 400 && e.code == "invalid_image_url";
}

/**
 * Extracts the invalid image URL from an error message.
 * @param {Error} e - The error object.
 * @return {string} - The URL of the invalid image.
 * */
function extractInvalidImageUrl(e) {
  let errorMessage = "";
  if (e.response && e.response.data && e.response.data.error) {
    errorMessage = e.response.data.error.message || "";
  } else {
    errorMessage = e.message || "";
  }

  // Adjust the regex or parsing logic based on actual error message format
  const urlRegex = /(https?:\/\/[^\s]+)/g;
  const urls = errorMessage.match(urlRegex);
  if (urls && urls.length > 0) {
    let url = urls[0];
    // Remove trailing punctuation
    // eslint-disable-next-line no-useless-escape
    url = url.replace(/[.,!?\"'`]+$/, "");
    return url;
  }
  return null;
}

// //////////////////////////////////////////////////////////////////
// Platform
// //////////////////////////////////////////////////////////////////

/**
 * returns platformType grouping
 * @param {Platform} platform
 * @return {string} type of platform
 */
const getPlatformType = function(platform) {
  if (platform.url == "x.com") {
    return "x";
  } else {
    return "news";
  }
};

// //////////////////////////////////////////////////////////////////
// Content
// //////////////////////////////////////////////////////////////////
/**
   * Gets the status of a post based on its current status and poster.
   * @param {Object} post - The post to get the status for.
   * @param {string} currStatus - The existing status of the post.
   * @return {string} - The status of the post.
   */
function getStatus(post, currStatus) {
  if (post.video && post.video.videoURL) {
    return "unsupported";
  } else if (post.status != "scraping" && post.status != "draft" &&
    currStatus != null) {
    return currStatus;
  } else if (post.poster) {
    return "draft";
  } else {
    return "published";
  }
}

/**
 * Checks if a status is unsupported
 * @param {string} status - the status to check
 * @return {boolean} - True if the status is unsupported, false otherwise.
 * */
function isUnsupportedStatus(status) {
  return status === "unsupported" || status === "noStories";
}

// //////////////////////////////////////////////////////////////////
// Location
// //////////////////////////////////////////////////////////////////

/**
 * @param {number} lat
 * @param {number} long
 * @return {Promise<string|null>}
 */
async function getCountryCode(lat, long) {
  try {
    const response = await axios.get(
        `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${long}&key=${_cloudApiKey.value()}`,
    );
    const country = response.data.results.find((result) =>
      result.types.includes("country"),
    );
    return country ? country.address_components[0].short_name : null;
  } catch (error) {
    logger.error("Error fetching country code:", error);
    return null;
  }
}

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
  getStatus,
  isUnsupportedStatus,
  urlToDomain,
  isFibonacciNumber,
  isPerfectSquare,
  getElo,
  retryAsyncFunction,
  calculateMeanVector,
  millisToIso,
  isoToMillis,
  isInvalidImageError,
  extractInvalidImageUrl,
  getPlatformType,
  handleChangedRelations,
  getCountryCode,
};
