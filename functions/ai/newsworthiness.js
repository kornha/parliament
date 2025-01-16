const _ = require("lodash");
const {
  getStory,
  updateStory, getPost,
  updatePost,
  getAllPostsForStory,
  getCount,
} = require("../common/database");
const {logger} = require("firebase-functions/v2");
const {getDistance} = require("./bias");
const {retryAsyncFunction} = require("../common/utils");
const {Timestamp} = require("firebase-admin/firestore");

// //////////////////////////////////////////////////////////////////
// Virality
// //////////////////////////////////////////////////////////////////
/**
 * Calculate the virality of a post (percentile rank)
 * TODO: THIS NEEDS TO USE BQ!
 * @param {String} pid - the pid to calculate the virality for
 * @return {Promise<void>}
 * */
async function onPostShouldChangeVirality(pid) {
  const post = await getPost(pid);
  if (!post) {
    return Promise.resolve();
  }

  const entityLower = await getCount("posts", "eid", post.eid,
      "socialScore", "<", post.socialScore);
  const entityTotal = await getCount("posts", "eid", post.eid);

  const entityVirality = entityTotal > 1 ?
    parseFloat((entityLower / entityTotal).toFixed(2)) : 1.0;

  const platformLower = await getCount("posts", "plid", post.plid,
      "socialScore", "<", post.socialScore);
  const platformTotal = await getCount("posts", "plid", post.plid);

  const platformVirality = platformTotal > 1 ?
      parseFloat((platformLower / platformTotal).toFixed(2)) : 1.0;

  const values = [entityVirality, platformVirality].filter(_.isNumber);
  const avgVirality = values.length ? _.mean(values) : null;

  if (avgVirality != null) {
    await updatePost(pid, {
      virality: avgVirality,
      entityVirality: entityVirality,
      platformVirality: platformVirality,
    });
  }
}


// //////////////////////////////////////////////////////////////////
// Newsworthiness
// //////////////////////////////////////////////////////////////////

/**
 * Newsworthiness is based on post virality and story bias
 * E2E Logic onStory for setting newsworthiness
 * @param {String} sid
 * @return {Promise<void>}
 * */
async function onStoryShouldChangeNewsworthiness(sid) {
  const story = await getStory(sid);
  if (!story) {
    return Promise.resolve();
  }

  const posts = await getAllPostsForStory(sid);
  if (_.isEmpty(posts)) {
    return Promise.resolve();
  }

  const entityValues = posts
      .map((post) => post.entityVirality)
      .filter((value) => value != null);

  const platformValues = posts
      .map((post) => post.platformVirality)
      .filter((value) => value != null);

  const viralityValues = posts
      .map((post) => post.virality)
      .filter((value) => value != null);

  const avgEntityVirality =
    entityValues.length > 0 ? _.mean(entityValues) : null;

  const avgPlatformVirality =
    platformValues.length > 0 ? _.mean(platformValues) : null;

  const virality =
    viralityValues.length > 0 ? _.mean(viralityValues) : null;

  const newsworthiness = calculateNewsworthiness(virality, story.bias);

  if (newsworthiness != null) {
    logger.info(`Updating Story newsworthiness: ${sid} ${newsworthiness}`);
    await retryAsyncFunction(() =>
      updateStory(sid, {
        newsworthiness: newsworthiness,
        virality: virality,
        avgEntityVirality: avgEntityVirality,
        avgPlatformVirality: avgPlatformVirality,
      }, 5));
  }

  return Promise.resolve();
}

/**
 * Calculate the newsworthiness of a story
 * prereqs: virality, bias
 * @param {number|null} virality - the viral score of the story
 * @param {number|null} bias - the story to calculate the newsworthiness for
 * @return {number|null} the newsworthiness of the story or null if not prereqs
 */
function calculateNewsworthiness(virality, bias) {
  if (virality == null) {
    return null;
  }

  const angleDiff = bias != null ? getDistance(bias, 90) : 90;

  const biasMultiple = 1 - angleDiff / 360; // 75% if right/left, 50% if extreme

  const newsworthiness = virality * biasMultiple;

  return _.round(Math.max(0, Math.min(1, newsworthiness)), 2);
}


// //////////////////////////////////////////////////////////////////
// Stats
// //////////////////////////////////////////////////////////////////

/**
   * Checks if the stats of a object have changed
   * @param {boolean} _create - if the post was created
   * @param {boolean} _update - if the post was updated
   * @param {boolean} _delete - if the post was deleted
   * @param {Object} before - the post before the change
   * @param {Object} after - the post after the change
   * @param {boolean} avg - if the average stats should be checked
   * @return {boolean} if the stats have changed
   * */
function didChangeStats(_create, _update, _delete, before, after, avg) {
  if (avg) {
    return _create && (after.avgReplies || after.avgReposts ||
        after.avgLikes || after.avgBookmarks || after.avgViews ||
         after.avgSocialScore) ||
      _update && (before.avgReplies != after.avgReplies ||
        before.avgReposts != after.avgReposts ||
           before.avgLikes != after.avgLikes ||
        before.avgBookmarks != after.avgBookmarks ||
           before.avgViews != after.avgViews ||
        before.avgSocialScore != after.avgSocialScore
      ) ||
      _delete && (before.avgReplies || before.avgReposts ||
        before.avgLikes || before.avgBookmarks || before.avgViews ||
        before.avgSocialScore);
  } else {
    return _create && (after.replies || after.reposts ||
        after.likes || after.bookmarks || after.views || after.socialScore) ||
      _update && (before.replies != after.replies ||
        before.reposts != after.reposts || before.likes != after.likes ||
        before.bookmarks != after.bookmarks || before.views != after.views ||
         before.socialScore != after.socialScore) ||
      _delete && (before.replies || before.reposts ||
        before.likes || before.bookmarks || before.views || before.socialScore);
  }
}

/**
 * Calculate the scaled happenedAt for a story
 * @param {Story} story - the story to calculate the scaled happenedAt for
 * @return {number|null} the scaled happenedAt or null if not possible
 */
function calculateNewsworthyAt(story) {
  if (!story || story.happenedAt == null) {
    return null;
  }

  // Define the scaling factor (e.g., 1 day in milliseconds)
  const NEWSWORTHYNESS_SCALE = 43200000; // 1/2 day in milliseconds

  const newsworthiness = story.newsworthiness != null ?
    story.newsworthiness : 0.1; // magic number

  // if its the future scale by createdAt
  const timeAt = story.happenedAt > Timestamp.now().toMillis() ?
    story.createdAt : story.happenedAt;

  // Calculate the adjusted timestamp
  const newsworthyAt =
    timeAt +
    Math.round(newsworthiness * NEWSWORTHYNESS_SCALE) -
    NEWSWORTHYNESS_SCALE;

  return newsworthyAt;
}

module.exports = {
  onPostShouldChangeVirality,
  onStoryShouldChangeNewsworthiness,
  didChangeStats,
  calculateNewsworthiness,
  calculateNewsworthyAt,
};
