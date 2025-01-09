const _ = require("lodash");
const {
  getStory,
  updateStory, getPost,
  getAllPostsForEntity, getAllPostsForPlatform, updatePost,
  getAllPostsForStory,
} = require("../common/database");
const {logger} = require("firebase-functions/v2");
const {getDistance} = require("./bias");
const {retryAsyncFunction} = require("../common/utils");

// //////////////////////////////////////////////////////////////////
// Virality
// //////////////////////////////////////////////////////////////////
/**
 * Calculate the virality of a post (percentile rank)
 * @param {String} pid - the pid to calculate the virality for
 * @return {Promise<void>}
 * */
async function onPostShouldChangeVirality(pid) {
  const post = await getPost(pid);
  if (!post) {
    return Promise.resolve();
  }

  const entityPosts = await getAllPostsForEntity(post.eid);
  const entityVirality = calculatePostVirality(post, entityPosts);

  const platformPosts = await getAllPostsForPlatform(post.plid);
  const platformVirality = calculatePostVirality(post, platformPosts);

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

/**
 * Calculate the virality (percentile) of a post compared to others.
 * @param {Post} post - The post to calculate the virality for
 * @param {Array<Post>} posts - The list of all posts
 * @return {number|null} The virality (0.0 - 1.0) or null if no valid fields
 */
function calculatePostVirality(post, posts) {
  // The possible fields to consider
  const fields = ["replies", "reposts", "likes", "bookmarks", "views"];

  // Filter only those fields on this post that are non-null
  const validFields = fields.filter((field) => post[field] != null);

  // If the post does not have any valid fields to compare, return null
  if (validFields.length === 0) {
    return null;
  }

  let percentileSum = 0;

  // For each valid field, compute this post's percentile among all posts
  for (const field of validFields) {
    const postValue = post[field];

    // Gather all posts that also have a non-null value for this field
    const validPosts = posts.filter((p) => p[field] != null);

    // Count how many of those have a value <= this post's value
    const numLessOrEqual = validPosts.reduce((count, p) => {
      return count + (p[field] <= postValue ? 1 : 0);
    }, 0);

    // Calculate the percentile: fraction of posts with <= this post's value
    // (this will be between 0.0 and 1.0)
    const percentile = numLessOrEqual / validPosts.length;

    percentileSum += percentile;
  }

  // Average percentile across all valid fields
  const averagePercentile = percentileSum / validFields.length;

  // Round the final percentile to 2 decimal places
  return parseFloat(averagePercentile.toFixed(2));
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
 * Calculate the average of the stats for a post
 * @param {Array<Object>} posts - the list of posts
 * @return {Array<Object>} the avg stats; UNDEFINED if the field is not present
 * */
function calculateAverageStats(posts) {
  if (_.isEmpty(posts)) return {};

  const fields = ["replies", "reposts", "likes", "bookmarks", "views"];
  const totals = {
    replies: 0,
    reposts: 0,
    likes: 0,
    bookmarks: 0,
    views: 0,
  };
  const counts = {
    replies: 0,
    reposts: 0,
    likes: 0,
    bookmarks: 0,
    views: 0,
  };

  posts.forEach((post) => {
    fields.forEach((field) => {
      if (post[field] !== null && post[field] !== undefined) {
        totals[field] += post[field];
        counts[field] += 1;
      }
    });
  });

  const averages = {};

  if (counts.replies > 0) {
    averages.avgReplies = _.round(totals.replies / counts.replies, 2);
  }
  if (counts.reposts > 0) {
    averages.avgReposts = _.round(totals.reposts / counts.reposts, 2);
  }
  if (counts.likes > 0) {
    averages.avgLikes = _.round(totals.likes / counts.likes, 2);
  }
  if (counts.bookmarks > 0) {
    averages.avgBookmarks = _.round(totals.bookmarks / counts.bookmarks, 2);
  }
  if (counts.views > 0) {
    averages.avgViews = _.round(totals.views / counts.views, 2);
  }

  return averages;
}

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
        after.avgLikes || after.avgBookmarks || after.avgViews) ||
      _update && (before.avgReplies != after.avgReplies ||
        before.avgReposts != after.avgReposts ||
           before.avgLikes != after.avgLikes ||
        before.avgBookmarks != after.avgBookmarks ||
           before.avgViews != after.avgViews) ||
      _delete && (before.avgReplies || before.avgReposts ||
        before.avgLikes || before.avgBookmarks || before.avgViews);
  } else {
    return _create && (after.replies || after.reposts ||
        after.likes || after.bookmarks || after.views) ||
      _update && (before.replies != after.replies ||
        before.reposts != after.reposts || before.likes != after.likes ||
        before.bookmarks != after.bookmarks || before.views != after.views) ||
      _delete && (before.replies || before.reposts ||
        before.likes || before.bookmarks || before.views);
  }
}

/**
 * Calculate the scaled happenedAt for a story
 * @param {Story} story - the story to calculate the scaled happenedAt for
 * @return {number|null} the scaled happenedAt or null if not possible
 */
function calculateScaledHappenedAt(story) {
  if (!story || story.happenedAt == null) {
    return null;
  }

  // Define the scaling factor (e.g., 1 day in milliseconds)
  const newsworthinessScale = 43200000; // 1/2 day in milliseconds
  const newsworthiness = story.newsworthiness != null ?
    story.newsworthiness : 0.1; // magic number

  // Calculate the adjusted timestamp
  const scaledHappenedAt =
    story.happenedAt + Math.round(newsworthiness * newsworthinessScale);

  return scaledHappenedAt;
}

module.exports = {
  onPostShouldChangeVirality,
  onStoryShouldChangeNewsworthiness,
  calculateAverageStats,
  didChangeStats,
  calculateNewsworthiness,
  calculateScaledHappenedAt,
};
