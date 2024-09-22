const _ = require("lodash");
const {getStory, getPlatforms, updateStory,
} = require("../common/database");
const {logger} = require("firebase-functions/v2");
const {getDistance} = require("./bias");
const {retryAsyncFunction} = require("../common/utils");

// //////////////////////////////////////////////////////////////////
// Newsworthiness
// //////////////////////////////////////////////////////////////////

/**
 * E2E Logic onStory for setting newsworthiness
 * @param {String} sid
 * @return {Promise<void>}
 * */
async function onStoryShouldChangeNewsworthiness(sid) {
  const story = await getStory(sid);
  if (!story) {
    return Promise.resolve();
  }

  const platforms = await getPlatforms(story.plids);

  const newsworthiness = calculateNewsworthiness(story, platforms);

  if (newsworthiness != null) {
    logger.info(`Updating Story newsworthiness: ${sid} ${newsworthiness}`);
    await retryAsyncFunction(() =>
      updateStory(sid, {newsworthiness: newsworthiness}));
  }

  return Promise.resolve();
}

/**
 * Calculate the newsworthiness of a story
 * prereqs: story avgBias, stats, platform stats
 * @param {Story} story - the story to calculate the newsworthiness for
 * @param {Array<Platform>} platforms - the list of platforms of the posts
 * @return {number|null} the newsworthiness of the story or null if not prereqs
 */
function calculateNewsworthiness(story, platforms) {
  if (!story || !platforms || platforms.length === 0) {
    return null;
  }

  const avgOfAvgLikes =
    platforms.reduce((acc, platform) => acc + platform.avgLikes, 0) /
    platforms.length;
  const avgOfAvgReplies =
    platforms.reduce((acc, platform) => acc + platform.avgReplies, 0) /
    platforms.length;
  const avgOfAvgReposts =
    platforms.reduce((acc, platform) => acc + platform.avgReposts, 0) /
    platforms.length;
  const avgOfAvgBookmarks =
    platforms.reduce((acc, platform) => acc + platform.avgBookmarks, 0) /
    platforms.length;
  const avgOfAvgViews =
    platforms.reduce((acc, platform) => acc + platform.avgViews, 0) /
    platforms.length;

  const adjustLikes =
    avgOfAvgLikes > 0 ? story.avgLikes / avgOfAvgLikes : 0;
  const adjustReplies =
    avgOfAvgReplies > 0 ? story.avgReplies / avgOfAvgReplies : 0;
  const adjustReposts =
    avgOfAvgReposts > 0 ? story.avgReposts / avgOfAvgReposts : 0;
  const adjustBookmarks =
    avgOfAvgBookmarks > 0 ? story.avgBookmarks / avgOfAvgBookmarks : 0;
  const adjustViews =
    avgOfAvgViews > 0 ? story.avgViews / avgOfAvgViews : 0;

  const adjustedScore =
    adjustLikes +
    adjustReplies +
    adjustReposts +
    adjustBookmarks +
    adjustViews;

  const engagementScore = adjustedScore / (adjustedScore + 1);

  const angleDiff = story.bias != null ? getDistance(story.bias, 90) : 90;
  const biasMultiple = 1 - angleDiff / 180;

  const newsworthiness = engagementScore * biasMultiple;

  return Math.max(0, Math.min(1, newsworthiness));
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
    averages.avgReplies =
        parseFloat((totals.replies / counts.replies).toFixed(2));
  }
  if (counts.reposts > 0) {
    averages.avgReposts =
        parseFloat((totals.reposts / counts.reposts).toFixed(2));
  }
  if (counts.likes > 0) {
    averages.avgLikes = parseFloat((totals.likes / counts.likes).toFixed(2));
  }
  if (counts.bookmarks > 0) {
    averages.avgBookmarks =
        parseFloat((totals.bookmarks / counts.bookmarks).toFixed(2));
  }
  if (counts.views > 0) {
    averages.avgViews = parseFloat((totals.views / counts.views).toFixed(2));
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

module.exports = {
  onStoryShouldChangeNewsworthiness,
  calculateAverageStats,
  didChangeStats,
  calculateNewsworthiness,
};
