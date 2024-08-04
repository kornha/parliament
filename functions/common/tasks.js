const {getFunctions} = require("firebase-admin/functions");
const {logger} = require("firebase-functions/v2");
const {GoogleAuth} = require("google-auth-library");
const {isLocal} = require("./utils");

const POST_SHOULD_FIND_STORIES_AND_CLAIMS_TASK =
"onPostShouldFindStoriesAndClaimsTask";

/**
 * Queues a task for a specified queue with a message.
 * @param {String} queue - The name of the queue.
 * @param {Object} message - The message to enqueue.
 */
async function queueTask(queue, message) {
  logger.info(`Queuing task ${queue} with message ${JSON.stringify(message)}`);

  const _queue = getFunctions().taskQueue(queue);
  const targetUri = await getFunctionUrl(queue);

  await _queue.enqueue(
      message,
      {
        scheduleDelaySeconds: 1,
        dispatchDeadlineSeconds: 60 * 5, // 5 minutes
        uri: targetUri,
      },
  );
}

/**
 * Retrieves the function URL for the specified function.
 * @param {String} name - The name of the function.
 * @param {String} [location='us-central1'] - The location of the function.
 * @return {Promise<String>} - The URL of the function.
 */
const getFunctionUrl = async (name, location = "us-central1") => {
  if (isLocal) {
    return `https://127.0.0.1:5001/political-think/${location}/${name}`;
  }

  const gAuth = new GoogleAuth({
    scopes: "https://www.googleapis.com/auth/cloud-platform",
  });
  const projectId = await gAuth.getProjectId();

  const url =
    `https://cloudfunctions.googleapis.com/v2/projects/${projectId}/locations/${location}/functions/${name}`;

  const client = await gAuth.getClient();
  const res = await client.request({url});
  const uri = res.data?.serviceConfig?.uri;
  if (!uri) {
    throw new Error(`Unable to retrieve URI for function at ${url}`);
  }

  return uri;
};

module.exports = {
  queueTask,
  POST_SHOULD_FIND_STORIES_AND_CLAIMS_TASK,
};
