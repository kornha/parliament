const functions = require("firebase-functions");
const {setVector, getStatement} = require("../common/database");
const {generateEmbeddings, generateCompletions} = require("../common/llm");
const {writeTrainingData} = require("./trainer");
const _ = require("lodash");
const {findStatementsPrompt} = require("./prompts");
const {logger} = require("firebase-functions/v2");

const findStatements = async function(post, stories, statements) {
  if (!post || _.isEmpty(stories)) {
    functions.logger.error("Post/Stories are missing. Cannot find statements");
    return;
  }

  // Note we need not remove the statements already from the post
  const prompt = findStatementsPrompt({
    post: post,
    stories: stories,
    statements: statements,
    training: true,
    includePhotos: true,
  });

  const resp =
    await generateCompletions({
      messages: prompt,
      loggingText: "findStatements " + post.pid,
    });

  if (!resp || !resp.stories || resp.stories.length === 0) {
    logger.warn(`Cannot find Statements for post! ${post.pid}`);
    return null;
  }

  writeTrainingData("findStatements", post, stories, statements, resp);

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
