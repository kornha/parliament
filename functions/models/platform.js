
//
// Firestore

const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {defaultConfig, scrapeConfig, gbConfig} = require("../common/functions");
const {publishMessage,
  PLATFORM_SHOULD_CHANGE_IMAGE,
  PLATFORM_CHANGED_POSTS,
  PLATFORM_CHANGED_ENTITIES,
  PLATFORM_SHOULD_CHANGE_STATS,
  PLATFORM_CHANGED_STORIES,
  PLATFORM_CHANGED_STATS,
  POST_SHOULD_CHANGE_VIRALITY} = require("../common/pubsub");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {getImageFromURL} = require("../content/scraper");
const {updatePlatform,
  getAllPostsForPlatform,
  getPlatform,
  getAverages,
} = require("../common/database");
const {logger} = require("firebase-functions/v2");
const {
  isFibonacciNumber,
  getSocialScore} = require("../common/utils");
const {FieldValue, Timestamp} = require("firebase-admin/firestore");
const {didChangeStats} = require("../ai/newsworthiness");
const _ = require("lodash");

//
exports.onPlatformUpdate = onDocumentWritten(
    {
      document: "platforms/{plid}",
      ...defaultConfig,
    },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before && !after) {
        return Promise.resolve();
      }

      const _create = !before && after;
      const _delete = before && !after;
      const _update = before && after;

      if (_create && after.photoURL == null ||
        _update && before.url !== after.url) {
        await publishMessage(PLATFORM_SHOULD_CHANGE_IMAGE, after);
      }

      if (didChangeStats(_create, _update, _delete, before, after, true)) {
        await publishMessage(PLATFORM_CHANGED_STATS,
            {plid: after?.plid || before?.plid});
      }

      // TODO: we only do this on delete currently!
      // this is because platform does not have posts or entities
      // as that would be long
      if (_delete) {
        await publishMessage(PLATFORM_CHANGED_POSTS,
            {before: before, after: after});
        await publishMessage(PLATFORM_CHANGED_ENTITIES,
            {before: before, after: after});
        await publishMessage(PLATFORM_CHANGED_STORIES,
            {before: before, after: after});
      }

      return Promise.resolve();
    },
);

// /////////////////////////////////////////////////////////////////
// Stats
// /////////////////////////////////////////////////////////////////

/**
 * Platform should change stats
 * TODO: NEEDS TO RUN LOT LESS, ON LESS DATA!
 */
exports.onPlatformShouldChangeStats = onMessagePublished(
    {
      topic: PLATFORM_SHOULD_CHANGE_STATS,
      ...gbConfig, // this fetches 1k posts, might be causing memory issues
    },
    async (event) => {
      const plid = event.data.message.json.plid;
      if (!plid) {
        return Promise.resolve();
      }
      logger.info(`onPlatformShouldChangeStats: ${plid}`);

      const platform = await getPlatform(plid);
      if (!platform) {
        return Promise.resolve();
      }

      if (platform.statsCount == null) {
        platform.statsCount = 0;
      }

      const isFibonacci = isFibonacciNumber(platform.statsCount);

      // increment doesn't work on null. Stats count is technically 1 higher
      // we move this up here to reduce concurrent cases of the same count
      await updatePlatform(plid, {statsCount: platform.statsCount == 0 ? 1 :
              FieldValue.increment(1)});

      if (isFibonacci) {
        logger.info(
            `Updating platform stats ${plid} count: ${platform.statsCount}`);

        const stats = await getAverages("posts", "plid", plid,
            ["likes", "reposts", "replies", "bookmarks", "views"]);
        // can be {} if no stats in child posts
        if (stats != null && !_.isEmpty(stats)) {
          // do this here since getAverages is limited to 5
          stats.avgSocialScore = getSocialScore({
            likes: stats.avgLikes,
            reposts: stats.avgReposts,
            replies: stats.avgReplies,
            bookmarks: stats.avgBookmarks,
            views: stats.avgViews,
          });
          await updatePlatform(plid, stats, 5);
        }
      }

      return Promise.resolve();
    },
);

exports.onPlatformChangedStats = onMessagePublished(
    {
      topic: PLATFORM_CHANGED_STATS,
      ...gbConfig, // this fetches 1-2k+ posts, might be causing memory issues
    },
    async (event) => {
      const plid = event.data.message.json.plid;
      if (!plid) {
        return Promise.resolve();
      }
      logger.info(`onPlatformChangedStats: ${plid}`);

      // technically this is not a prerequisite for a post changing virality
      // however the post virality needs to update when there are few posts
      // this is a useful cadence to do so
      // this also double triggers with entity stats
      // this becomes less useful as there is more data but needed at start
      // will be shifted to BQ
      const threeDaysAgo = Timestamp.now().toMillis() - 3 * 24 * 60 * 60 * 1000;
      const posts = await getAllPostsForPlatform(plid, threeDaysAgo, 20);
      if (_.isEmpty(posts)) {
        logger.warn(`No posts for platform ${plid}`);
        return Promise.resolve();
      }

      for (const post of posts) {
        await publishMessage(POST_SHOULD_CHANGE_VIRALITY,
            {pid: post.pid});
      }

      return Promise.resolve();
    });

/**
 * Platform should change image
 */
exports.onPlatformShouldChangeImage = onMessagePublished(
    {
      topic: PLATFORM_SHOULD_CHANGE_IMAGE,
      ...scrapeConfig, // currently this heavy config, we get images by scraping
    },
    async (event) => {
      const platform = event.data.message.json;
      logger;
      const photoURL = await getImageFromURL("https://" + platform.url);
      if (photoURL) {
        await updatePlatform(platform.plid, {
          photoURL: photoURL,
        });
      }

      return Promise.resolve();
    });


