const {defineSecret} = require("firebase-functions/params");
const {OpenAI} = require("openai");
const functions = require("firebase-functions");
const {generateImageDescriptionPrompt} = require("../ai/prompts");

const _openApiKey = defineSecret("OPENAI_API_KEY");

// need to add secret to functions.js
const OPENAI_API_KEY = function() {
  return _openApiKey.value();
};

/**
 * Generates completions for the given prompt
 * @param {List<Message>} messages since images needs to be separated
 * @param {string} loggingText optional loggingText
 * @return {Promise<string>} completion response
 */
const generateCompletions = async function(messages, loggingText = null) {
  if (messages.length === 0) {
    functions.logger.error("No messages provided");
    return null;
  }

  functions.logger.info(`Generating completions for ` + loggingText ?
    loggingText : `${messages.length} messages`);

  const completion = await new OpenAI(_openApiKey.value(),
  ).chat.completions.create({
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
    temperature: 0.0,
    // gpt-4-1106-preview for 128k token (50 page) context window
    model: "gpt-4-turbo",
    response_format: {"type": "json_object"},
  });
  try {
    const generation = JSON.parse(completion.choices[0].message.content);
    if (generation == null) {
      functions.logger.error(`Invalid generation: ${generation}`);
      return null;
    }

    functions.logger.info(`Tokens used: 
      ${completion.usage.total_tokens}`);

    return generation;
  } catch (e) {
    functions.logger.error(`Invalid decision: ${e}`);
    functions.logger.error(completion);
    return null;
  }
};


/**
 * Generates the vector embeddings for the given texts
 * @param {Array<string>} texts
 * @param {string} photoURL // we currently generate description and vector this
 * @return {Promise<Array<number>>} vector response
 */
const generateEmbeddings = async function(texts, photoURL = null) {
  if (texts.length === 0 && photoURL === null) {
    functions.logger.error("No texts or photoURL provided");
    return null;
  }

  if (photoURL) {
    const resp =
      await generateCompletions(generateImageDescriptionPrompt(photoURL),
          "photoURL");
    if (!resp?.description) {
      functions.logger.error("Error generating image description");
    } else {
      texts.push(resp.description);
    }
  }

  functions.logger.info(`Generating embeddings for ${texts.length} texts`);

  // since we want 1 vector
  const concatenatedTexts = texts.join(" ");

  const textEmbeddingResponse = await new OpenAI(_openApiKey.value())
      .embeddings.create({
        model: "text-embedding-3-small",
        input: concatenatedTexts,
      });
  if (textEmbeddingResponse?.data?.[0]?.embedding === undefined) {
    functions.logger.error("Error: no data in response");
  }
  const vector = textEmbeddingResponse.data[0].embedding;
  if (textEmbeddingResponse.data.length > 1) {
    functions.logger.warn("Multiple embeddings available");
  }

  functions.logger.info(`Tokens used: 
    ${textEmbeddingResponse.usage.total_tokens}`);

  return vector;
};


module.exports = {
  generateCompletions,
  generateEmbeddings,
  OPENAI_API_KEY,
};
