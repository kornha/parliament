const functions = require("firebase-functions");
const {setVector, getClaim} = require("../common/database");
const {generateEmbeddings, generateCompletions} = require("../common/llm");
const {writeTrainingData} = require("./trainer");
const _ = require("lodash");
const {findClaimsPrompt} = require("./prompts");

const findClaims = async function(post, stories, claims) {
  if (!post || _.isEmpty(stories)) {
    functions.logger.error("Post/Stories is are missing. Cannot find claims");
    return;
  }

  // Note we need not remove the claims already from the post

  const resp =
    await generateCompletions(
        findClaimsPrompt({
          post: post,
          stories: stories,
          claims: claims,
          training: true,
          includePhotos: true,
        }),
        "findClaims " + post.pid,
        true,
    );

  writeTrainingData("findClaims", post, stories, claims, resp);

  return resp.stories;
};


/**
 * Fetches the claim embeddings from OpenAI and saves them to the database
 * returns nothing if there are no qualified claim embeddings
 * publishes a message to the PubSub topic CLAIM_CHANGED_VECTOR
 * @param {String} cid
 * @return {Promise<boolean>}
 */
const resetClaimVector = async function(cid) {
  const claim = await getClaim(cid);
  if (!claim) {
    functions.logger.error(`Claim not found: ${cid}`);
    return false;
  }
  const strings = getClaimEmbeddingStrings(claim);
  if (strings.length === 0) {
    return true;
  }

  const embeddings = await generateEmbeddings(strings);
  return await setVector(claim.cid, embeddings, "claims");
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
  findClaims,
  resetClaimVector,
};
