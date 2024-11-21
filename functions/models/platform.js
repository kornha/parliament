
//
// Firestore

const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {defaultConfig, scrapeConfig} = require("../common/functions");
const {publishMessage,
  PLATFORM_SHOULD_CHANGE_IMAGE,
  PLATFORM_CHANGED_POSTS,
  PLATFORM_CHANGED_ENTITIES,
  PLATFORM_SHOULD_CHANGE_STATS,
  PLATFORM_CHANGED_STORIES,
  PLATFORM_CHANGED_STATS,
  STORY_SHOULD_CHANGE_NEWSWORTHINESS} = require("../common/pubsub");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {getImageFromURL} = require("../content/scraper");
const {updatePlatform,
  getAllPostsForPlatform,
  getPlatform,
  getAllStoriesForPlatform} = require("../common/database");
const {logger} = require("firebase-functions/v2");
const {
  isFibonacciNumber} = require("../common/utils");
const {FieldValue} = require("firebase-admin/firestore");
const {calculateAverageStats, didChangeStats} = require("../ai/newsworthiness");
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
      ...defaultConfig,
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
        const posts = await getAllPostsForPlatform(plid);
        if (_.isEmpty(posts)) {
          logger.warn(`No posts for platform ${plid}`);
        }

        const stats = calculateAverageStats(posts);
        // can be {} if no stats in child posts
        if (!_.isEmpty(stats)) {
          await updatePlatform(plid, stats);
        }
      }

      return Promise.resolve();
    });

exports.onPlatformChangedStats = onMessagePublished(
    {
      topic: PLATFORM_CHANGED_STATS,
      ...defaultConfig,
    },
    async (event) => {
      const plid = event.data.message.json.plid;
      if (!plid) {
        return Promise.resolve();
      }
      logger.info(`onPlatformChangedStats: ${plid}`);

      const stories = await getAllStoriesForPlatform(plid);
      if (!stories) {
        return Promise.resolve();
      }

      for (const story of stories) {
        await publishMessage(STORY_SHOULD_CHANGE_NEWSWORTHINESS,
            {sid: story.sid});
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


