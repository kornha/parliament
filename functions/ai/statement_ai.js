const functions = require("firebase-functions");
const {setVector, getStatement,
  markPhotoAsIncompatible} = require("../common/database");
const {generateEmbeddings, generateCompletions} = require("../common/llm");
const {writeTrainingData} = require("./trainer");
const {findStatementsPrompt} = require("./prompts");
const {logger} = require("firebase-functions/v2");
const {isInvalidImageError,
  extractInvalidImageUrl} = require("../common/utils");

const findStatements = async function(post, statements) {
  if (!post) {
    functions.logger.error("Post is missing. Cannot find statements");
    return;
  }

  // Note we need not remove the statements already from the post
  const prompt = findStatementsPrompt({
    post: post,
    statements: statements,
    training: true,
    includePhotos: true,
  });

  let resp = null;


  try {
    resp =
    await generateCompletions({
      messages: prompt,
      loggingText: "findStatements " + post.pid,
    });
  } catch (e) {
    // some grade A level BS to unmark invalid images
    if (isInvalidImageError(e)) {
      const url = extractInvalidImageUrl(e);
      const removedPhoto = await markPhotoAsIncompatible(url, [post], []);
      if (removedPhoto) {
        // can retry this method, finite loop
        return await findStatements(post, statements);
      }
    }
  }

  // might be OK as not all posts have statements
  if (!resp || !resp.statements || resp.statements.length === 0) {
    logger.warn(`Cannot find Statements for post! ${post.pid}`);
    return null;
  }

  writeTrainingData("findStatements", post, null, statements, resp);

  return resp;
};


/**
 * Fetches the statement embeddings from OpenAI and saves them to the database
 * returns nothing if there are no qualified statement embeddings
 * publishes a message to the PubSub topic STATEMENT_CHANGED_VECTOR
 * @param {String} stid
 * @return {Promise<boolean>}
 */
const resetStatementVector = async function(stid) {
  const statement = await getStatement(stid);
  if (!statement) {
    functions.logger.error(`Statement not found: ${stid}`);
    return false;
  }
  const strings = getStatementEmbeddingStrings(statement);
  if (strings.length === 0) {
    return true;
  }

  const embeddings = await generateEmbeddings(strings);
  return await setVector(statement.stid, embeddings, "statements");
};

/**
 * Fetches the strings to embed for a statement
 * Note: context is first
 * @param {Statement} statement
 * @return {string[]}
 */
const getStatementEmbeddingStrings = function(statement) {
  const ret = [];
  if (statement.context) {
    ret.push(statement.context);
  }
  if (statement.value) {
    ret.push(statement.value);
  }
  return ret;
};


module.exports = {
  findStatements,
  resetStatementVector,
};
