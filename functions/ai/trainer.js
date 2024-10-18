/* eslint-disable max-len */
const {setContent, getContent} = require("../common/storage");
const {findStoriesPrompt, findStatementsPrompt, findContextPrompt} = require("./prompts");
const {logger} = require("firebase-functions/v2");

const filePath = "training/fine_tune.jsonl";

/**
   * Appends a new JSONL entry to the file in Google Cloud Storage.
   * @param {string} promptName - The promptName type.
   * @param {Post} post - The post data.
   * @param {List<Story>} stories - List of story objects.
   * @param {List<Statements>} statements - List of statement objects.
   * @param {Object} output - The expected result
   */
const writeTrainingData =
async function(promptName, post, stories, statements, output) {
  const messages = [];

  // System message for context setup
  messages.push({
    role: "system",
    content: "You are a machine that only returns and replies with valid, iterable RFC8259 compliant JSON in your responses with no leading or trailing characters",
  });

  if (promptName === "findStories") {
    messages.push({
      role: "user",
      content: findStoriesPrompt({
        post: post,
        stories: stories,
        training: false,
        includePhotos: false,
      }),
    });
  } else if (promptName === "findStatements") {
    messages.push({
      role: "user",
      content: findStatementsPrompt({
        post: post,
        stories: stories,
        statements: statements,
        training: false,
        includePhotos: false,
      }),
    });
  } else if (promptName === "findContext") {
    messages.push({
      role: "user",
      content: findContextPrompt({
        story: stories[0], // accepts single story
        statements: statements,
        training: false,
        includePhotos: false,
      }),
    });
  }

  messages.push({
    role: "assistant",
    content: JSON.stringify(output),
  });

  // Creating a single JSONL line with message data
  const jsonlContent = JSON.stringify({messages}) + "\n";

  // Retrieve current content from GCS
  let currentContent = await getContent(filePath);
  if (currentContent === null) {
    currentContent = ""; // Initialize as empty if the file does not exist
  }

  // Append the new JSONL content to the existing content
  const newContent = currentContent + jsonlContent;

  // Write back the updated content to GCS
  await setContent(filePath, newContent,
      "application/json").catch((error) => {
    logger.error("Error writing JSONL content to GCS: ", error);
  });
};

module.exports = {writeTrainingData};

