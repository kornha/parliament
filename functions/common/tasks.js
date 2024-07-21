const {getFunctions} = require("firebase-admin/functions");
const functions = require("firebase-functions");
const {GoogleAuth} = require("google-auth-library");

const POST_SHOULD_FIND_STORIES_AND_CLAIMS_TASK =
 "onPostShouldFindStoriesAndClaimsTask";

/**
 *
 * @param {String} queue
 * @param {json} message
 */
async function queueTask(queue, message) {
  functions.logger.info(
      `Queuing task ${queue} with message ${JSON.stringify(message)}`);

  const _queue = getFunctions().taskQueue(queue);
  const targetUri = await getFunctionUrl(queue);

  await _queue.enqueue(
      message,
      {
        scheduleDelaySeconds: 1,
        // scheduleTime: new Date(time),
        dispatchDeadlineSeconds: 60 * 5, // 5 minutes
        uri: targetUri,
      });
}

const getFunctionUrl = async (name, location = "us-central1") => {
  // not really needed but removes external request
  if (process.env.FUNCTIONS_EMULATOR == "true") {
    return `https://127.0.0.1:5001/political-think/${location}/${name}`;
  }

  const gAuth = new GoogleAuth({
    scopes: "https://www.googleapis.com/auth/cloud-platform",
  });
  const projectId = await gAuth.getProjectId();

  const url =
      "https://cloudfunctions.googleapis.com/v2beta/" +
      `projects/${projectId}/locations/${location}/functions/${name}`;

  const client = await gAuth.getClient();
  const res = await client.request({url});
  const uri = res.data?.serviceConfig?.uri;
  if (!uri) {
    throw new Error(`Unable to retreive uri for function at ${url}`);
  }

  return uri;
};

module.exports = {
  queueTask,
  POST_SHOULD_FIND_STORIES_AND_CLAIMS_TASK,
};
