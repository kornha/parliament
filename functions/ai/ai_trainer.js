/* eslint-disable max-len */
const {setContent, getContent} = require("../common/storage");
const {postToJSON, storiesToJSON, claimsToJSON} = require("./prompts");
const functions = require("firebase-functions");

const filePath = "fine_tune.jsonl";

/**
   * Appends a new JSONL entry to the file in Google Cloud Storage.
   * @param {string} prompt - The prompt type.
   * @param {Post} post - The post data.
   * @param {List<Story>} stories - List of story objects.
   * @param {List<Claim>} claims - List of claim objects
   * @param {Object} output - The expected result
   */
const writeTrainingData =
async function(prompt, post, stories, claims, output) {
  const messages = [];

  // System message for context setup
  messages.push({
    role: "system",
    content: "You are a machine that only returns and replies with valid, iterable RFC8259 compliant JSON in your responses with no leading or trailing characters",
  });

  if (prompt === "findStories") {
    messages.push({
      role: "user",
      content: `You will be given a Post and a list of Stories (can be empty).\nPost: ${postToJSON(post)}\nStories: ${storiesToJSON(stories)}\nOutput JSON ordered from most to least relevant Story. Do not output irrelevant Stories. Do not output Claims.`,
    });
  } else if (prompt === "findStoriesAndClaims") {
    messages.push({
      role: "user",
      content: `You will be given a Post, a list of Stories (cannot be empty), and a list of Claims (can be empty).\nPost: ${postToJSON(post)}\nStories: ${storiesToJSON(stories)}\nClaims: ${claimsToJSON(claims)}\nOutput the Stories in the order they are inputted, but now include Claims (either create a new one or add an existing one), and if the Post is for or against a Claim be sure to list its in the Claim's pro/against.`,
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
    functions.logger.error("Error writing JSONL content to GCS: ", error);
  });
};

module.exports = {writeTrainingData};

