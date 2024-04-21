// const _ = require("lodash");

const {CLAIM_INDEX, saveStrings} = require("../common/vector_database");
const functions = require("firebase-functions");


/**
 * Fetches the claim embeddings from OpenAI and saves them to the database
 * returns nothing if there are no qualified claim embeddings
 * publishes a message to the PubSub topic CLAIM_CHANGED_VECTOR
 * @param {Claim} claim
 * @return {Promise<boolean>}
 */
const saveClaimEmbeddings = async function(claim) {
  const strings = getClaimEmbeddingStrings(claim);
  if (strings.length === 0) {
    return true;
  }

  try {
    await saveStrings(claim.cid, strings, CLAIM_INDEX);
    // publishMessage(CLAIM_CHANGED_VECTOR, {cid: claim.cid});
    return true;
  } catch (e) {
    functions.logger.error("Error saving claim embeddings", e);
    return false;
  }
};

/**
 * Fetches the strings to embed for a claim
 * Note: context is first
 * @param {Claim} claim
 * @return {string[]}
 */
const getClaimEmbeddingStrings = function(claim) {
  const ret = [];
  if (claim.context) {
    ret.push(claim.context);
  }
  if (claim.value) {
    ret.push(claim.value);
  }
  return ret;
};


module.exports = {
  saveClaimEmbeddings,
};
