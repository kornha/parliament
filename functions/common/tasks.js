const {getFunctions} = require("firebase-admin/functions");
const {logger} = require("firebase-functions/v2");
const {GoogleAuth} = require("google-auth-library");
const {isLocal} = require("./utils");
const {database} = require("./database");


const POST_SHOULD_FIND_STORIES_TASK = "onPostShouldFindStoriesTask";
const POST_SHOULD_FIND_STATEMENTS_TASK = "onPostShouldFindStatementsTask";
const STORY_SHOULD_FIND_CONTEXT_TASK = "onStoryShouldFindContextTask";

/**
 * Queues a task for a specified queue with a message.
 * @param {String} queue - The name of the queue.
 * @param {Object} message - The message to enqueue.
 * @param {Number} [delaySeconds=1] - The delay in seconds before executing.
 */
const queueTask = async function(queue, message, delaySeconds = 1) {
  logger.info(`Queueing task ${queue} with message ${JSON.stringify(message)}`);

  const _queue = getFunctions().taskQueue(queue);
  const targetUri = await getFunctionUrl(queue);
  const enrichedMessage = {
    ...message,
    task: queue,
  };

  await _queue.enqueue(
      enrichedMessage,
      {
        scheduleDelaySeconds: delaySeconds,
        dispatchDeadlineSeconds: 60 * 5, // 5 minutes
        uri: targetUri,
      },
  );
};

/**
 * Checks/queues a task based on the provided conditions.
 * This is needed since cloud tasks can't dedupe easily...
 * @param {String} collectionName - The name of the collection.
 * @param {String} id - The ID of the document.
 * @param {Function} conditionFn - The function to check conditions.
 * @param {Object} updates - The updates to apply to the document.
 * @param {String} queue - The name of the queue to send the task to.
 * @param {Object} message - The message to send with the task.
 * @param {Number} [delaySeconds=1] - The delay in seconds before
 * @return {Promise<Boolean>} - Whether the task is sent.
 */
const tryQueueTask = async function(
    collectionName,
    id,
    conditionFn,
    updates,
    queue,
    message,
    delaySeconds = 1,
) {
  if (!id) {
    logger.error(`Invalid document ID: ${id}`);
    return false;
  }

  const docRef = database().collection(collectionName).doc(id);

  let shouldProceed = false;
  // Start a transaction to check conditions and update the document
  await database().runTransaction(async (transaction) => {
    const docSnapshot = await transaction.get(docRef);
    const docData = docSnapshot.data();

    if (!docData) {
      logger.error(`Document not found: ${collectionName}/${id}`);
      return;
    }

    // Use the provided condition function to determine if we should proceed
    if (!conditionFn(docData)) {
      logger.info(
          `Conditions not met for document: ${collectionName}/${id}`);
      return;
    }

    // Update the document with the provided updates
    transaction.update(docRef, updates);
    shouldProceed = true;
  });

  if (shouldProceed) {
    await queueTask(queue, message, delaySeconds);
  }
  return shouldProceed;
};

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
  tryQueueTask,
  POST_SHOULD_FIND_STORIES_TASK,
  POST_SHOULD_FIND_STATEMENTS_TASK,
  STORY_SHOULD_FIND_CONTEXT_TASK,
};
