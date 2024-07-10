const {defineSecret} = require("firebase-functions/params");
const {OpenAI} = require("openai");
const functions = require("firebase-functions");
const {findStoriesForTrainingText,
  findClaimsForTrainingText} = require("../ai/prompts");
const {getContent, setContent} = require("../common/storage");
const _openApiKey = defineSecret("OPENAI_API_KEY");

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
    functions.logger.error("No messages provided");
    return null;
  }

  functions.logger.info(`Generating completions for ` + loggingText ?
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
      functions.logger.error(`Invalid generation: ${generation}`);
      return null;
    }

    functions.logger.info(`Tokens used: ${completion.usage.total_tokens}`);

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
 * @return {Promise<Array<number>>} vector response
 */
const generateEmbeddings = async function(texts) {
  if (texts.length === 0) {
    functions.logger.error("No texts provided");
    return null;
  }

  functions.logger.info(`Generating embeddings for ${texts.length} texts`);

  // since we want 1 vector
  const concatenatedTexts = texts.join(" ");

  const textEmbeddingResponse = await llm()
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

  // eslint-disable-next-line max-len
  functions.logger.info(`Tokens used: ${textEmbeddingResponse.usage.total_tokens}`);

  return vector;
};

const findStoriesPath = "assistants/findStories.json";
const findClaimsPath = "assistants/findClaims.json";

/**
 * DEPRECATED
 * Using the assistants api, get the reuseable assistant for the given prompt
 * @param {string} prompt
 * @return {Promise<string>} assistant id
 */
const getAssistant = async function(prompt) {
  if (prompt !== "findStories" && prompt !== "findClaims") {
    functions.logger.error("Invalid prompt");
    throw new Error("Invalid prompt");
  }

  const path =
    prompt == "findStories" ? findStoriesPath : findClaimsPath;

  const assistantStorage = await getContent(path);

  if (assistantStorage) {
    const json = JSON.parse(assistantStorage);
    if (json.assistantId) {
      return json.assistantId;
    }
  }

  const promptText = prompt == "findStories" ?
    findStoriesForTrainingText() : findClaimsForTrainingText();

  const assistant =
    await llm().beta.assistants.create({
      name: prompt,
      instructions: promptText,
      response_format: {"type": "json_object"},
      temperature: 0.00,
      model: "gpt-4o",
    });

  functions.logger.info(`Created assistant ${assistant.id}`);

  await setContent(path, JSON.stringify({assistantId: assistant.id}));

  return assistant.id;
};

const generateAssistantCompletions = async function(messages, promptName) {
  const assistantId = await getAssistant(promptName);

  const thread = await llm().beta.threads.create({
    messages: [
      {
        "role": "user",
        "content": messages,
      },
    ],
  });


  const run = await llm().beta.threads.runs.createAndPoll(
      thread.id,
      {assistant_id: assistantId},
  );

  // tokens used
  functions.logger.info(`Tokens used: ${run.usage.total_tokens}`);

  if (run.status === "completed") {
    const _messages = await llm().beta.threads.messages.list(
        run.thread_id,
    );
    return JSON.parse(_messages[0].content);
  } else {
    console.log(run.status);
  }
};

module.exports = {
  generateCompletions,
  generateEmbeddings,
  generateAssistantCompletions,
  OPENAI_API_KEY,
};
