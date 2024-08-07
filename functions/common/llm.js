const {defineSecret} = require("firebase-functions/params");
const {OpenAI} = require("openai");
const _openApiKey = defineSecret("OPENAI_API_KEY");
const {logger} = require("firebase-functions/v2");


// need to add secret to functions.js
const OPENAI_API_KEY = function() {
  return _openApiKey.value();
};

let _openAi;
/**
 * Returns the OpenAI instance
 * @return {OpenAI} openai instance
 * */
const llm = function() {
  if (!_openAi) {
    _openAi = new OpenAI(_openApiKey.value());
  }
  return _openAi;
};

/**
 * Generates completions for the given prompt
 * @param {List<Message>} messages since images needs to be separated
 * @param {string} loggingText optional loggingText
 * @param {string} imageModel whether we need a model that supports images
 * @return {Promise<string>} completion response
 */
const generateCompletions = async function(messages,
    loggingText = null,
    imageModel = true,
) {
  if (messages.length === 0) {
    logger.error("No messages provided");
    return null;
  }

  logger.info(`Generating completions for ` + loggingText ?
    loggingText : `${messages.length} messages`);

  const completion = await llm().chat.completions.create({
    messages: [
      {
        role: "system",
        content: `You are a machine that only returns and replies with valid,
              iterable RFC8259 compliant JSON in your responses 
              with no leading or trailing characters`,
      },
      {
        "role": "user",
        "content": messages,
      },

    ],
    // max_tokens: 300,
    temperature: 0.00,
    model: imageModel ? "gpt-4o" : "ft:gpt-3.5-turbo-1106:parliament::9VmmK9Vp",
    response_format: {"type": "json_object"},
  });
  try {
    const generation = JSON.parse(completion.choices[0].message.content);
    if (generation == null) {
      logger.error(`Invalid generation: ${generation}`);
      return null;
    }

    logger.info(`Tokens used: ${completion.usage.total_tokens}`);

    return generation;
  } catch (e) {
    logger.error(`Invalid decision: ${e}`);
    logger.error(completion);
    return null;
  }
};


/**
 * Generates the vector embeddings for the given texts
 * @param {Array<string>} texts
 * @return {Promise<Array<number>>} vector response
 */
const generateEmbeddings = async function(texts) {
  if (texts.length === 0) {
    logger.error("No texts provided");
    return null;
  }

  logger.info(`Generating embeddings for ${texts.length} texts`);

  // since we want 1 vector
  const concatenatedTexts = texts.join(" ");

  const textEmbeddingResponse = await llm()
      .embeddings.create({
        model: "text-embedding-3-small",
        input: concatenatedTexts,
      });
  if (textEmbeddingResponse?.data?.[0]?.embedding === undefined) {
    logger.error("Error: no data in response");
  }
  const vector = textEmbeddingResponse.data[0].embedding;
  if (textEmbeddingResponse.data.length > 1) {
    logger.warn("Multiple embeddings available");
  }

  // eslint-disable-next-line max-len
  logger.info(`Tokens used: ${textEmbeddingResponse.usage.total_tokens}`);

  return vector;
};

module.exports = {
  generateCompletions,
  generateEmbeddings,
  OPENAI_API_KEY,
};
