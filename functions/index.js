/* eslint-disable no-unused-vars */
const admin = require("firebase-admin");
const {logger} = require("firebase-functions/v2");
const {onRoomChange, startDebate} = require("./messages/room");
const {onMessageChange} = require("./messages/message");
const {onAuthUserCreate,
  onAuthUserDelete,
  setUsername} = require("./models/user");
const {TaskQueue} = require("firebase-admin/functions");
const {
  onPostUpdate, onPostPublished,
  onPostShouldFindStoriesAndStatements,
  onPostChangedXid,
  onPostChangedVector,
  shouldFindStoriesAndStatements,
  onPostShouldFindStoriesAndStatementsTask,
  onStoryChangedPosts,
  onStatementChangedPosts,
  onEntityChangedPosts,
  onPostChangedStats,
} = require("./models/post");
const {onVoteBiasChange, onVoteCredibilityChange} = require("./models/vote");
const {generateBiasTraining} = require("./ai/scripts");
const {onLinkPaste, onScrapeX, onScrapeFeed} = require("./content/content");
const {debateDidTimeOut, debateDidTimeOutTask} = require("./messages/clock");
const {
  onStoryUpdate, onStoryPostsChanged,
  onStoryShouldChangeVector, onStoryShouldChangeStatements,
  onStatementChangedStories,
  onPostChangedStories,
  onStoryShouldChangeStats,
} = require("./models/story");
const {
  onStatementUpdate, onStatementChangedVector,
  onStatementShouldChangeContext,
  onPostChangedStatements,
  onStoryChangedStatements,
  onEntityChangedStatements,
  onStatementShouldChangeConfidence,
  onStatementChangedConfidence,
  onStatementChangedBias,
  onStatementShouldChangeBias,
} = require("./models/statement");
const {
  onEntityUpdate,
  onEntityShouldChangeImage,
  onPostChangedEntity,
  onStatementChangedEntities,
  onEntityChangedConfidence,
  onEntityShouldChangeConfidence,
  onEntityShouldChangeBias,
  onEntityChangedBias,
  onEntityShouldChangeStats,
} = require("./models/entity");

admin.initializeApp();

// For Local Task Mocking Only
// cannot use isLocal from utils as its not initialized
if (process.env.FUNCTIONS_EMULATOR === "true") {
  Object.assign(TaskQueue.prototype, {
    enqueue: async (message, params) => {
      if (message.pid) {
        logger.info(
            `local onPostShouldFindStoriesAndStatementsTask: ${message.pid}`);
        await shouldFindStoriesAndStatements(message.pid);
      } else {
        const end = new Date(params.scheduleTime);
        const now = Date.now();
        const delta = end - now;
        setTimeout(() => {
          debateDidTimeOut(message);
        }, delta);
      }
    },
  });
}

// Used as a dev-time helper to test functions
const functions = require("firebase-functions/v2");

const {updateAssetData} = require("./market/scripts");
const {getMarkets, getMarket,
  getCondition, getEvents} = require("./market/polymarket");
const {initBq, mergeToBigQuery, MARKET_TABLE} = require("./warehouse/bq");
const {isoToMillis} = require("./common/utils");
const {times, cond} = require("lodash");

const test = functions.https.onCall(async (data, context) => {
  // uploadAssetData("
  // 21742633143463906290569050155826241533
  // 067272736897614950488156847949938836455");
  // const q = await getMarket("506171");
  // const events = await getEvents();
  // logger.info(events);

  const avail = await initBq();
  if (!avail) {
    logger.warn("BigQuery tables not available.");
    return Promise.resolve();
  }

  const markets = await getMarkets({totalLimit: 1});

  if (!markets) {
    logger.error("Unable to fetch markets!");
    return;
  }

  const rows = markets.map((market) => {
    return {
      marketId: market.id,
      question: market.question,
      questionId: market.questionID,
      description: market.description,
      outcomes: JSON.parse(market.outcomes),
      photoURL: market.image,
      slug: market.slug,
      startedAt: market.startDate,
      endedAt: market.endDate,
      createdAt: market.createdAt,
      updatedAt: market.updatedAt,
      conditionId: market.conditionId,
      clobTokenIds: JSON.parse(market.clobTokenIds),
      active: market.active,
      acceptingOrders: market.acceptingOrders,
      acceptingOrdersTimestamp: market.acceptingOrdersTimestamp,
    };
  });

  await mergeToBigQuery(MARKET_TABLE, rows);

  for (const market of markets) {
    // const assetIds = JSON.parse(market.clobTokenIds);
    // const startTime = isoToMillis(market.startDate);
    // const conditionId = market.conditionId;
    // for (const assetId of assetIds) {
    //   await updateAssetData(assetId, conditionId, startTime);
    // }
  }
});


module.exports = {
  onAuthUserCreate,
  onAuthUserDelete,
  setUsername,
  onVoteBiasChange,
  onVoteCredibilityChange,
  // Post
  onPostUpdate,
  onMessageChange,
  onPostPublished,
  onPostShouldFindStoriesAndStatements,
  onPostShouldFindStoriesAndStatementsTask,
  onPostChangedVector,
  onPostChangedXid,
  onStoryChangedPosts,
  onStatementChangedPosts,
  onEntityChangedPosts,
  onPostChangedStats,
  // Story
  onStoryUpdate,
  onStoryPostsChanged,
  onStoryShouldChangeVector,
  onStoryShouldChangeStatements,
  onStatementChangedStories,
  onPostChangedStories,
  onStoryShouldChangeStats,
  // Statement
  onStatementUpdate,
  onStatementChangedVector,
  onStatementShouldChangeContext,
  onStoryChangedStatements,
  onPostChangedStatements,
  onEntityChangedStatements,
  onStatementShouldChangeConfidence,
  onStatementChangedConfidence,
  onStatementChangedBias,
  onStatementShouldChangeBias,
  // Room
  onRoomChange,
  startDebate,
  debateDidTimeOutTask,
  // Entity
  onEntityUpdate,
  onEntityShouldChangeImage,
  onPostChangedEntity,
  onStatementChangedEntities,
  onEntityChangedConfidence,
  onEntityShouldChangeConfidence,
  onEntityShouldChangeBias,
  onEntityChangedBias,
  onEntityShouldChangeStats,
  // Content
  onLinkPaste,
  onScrapeX,
  onScrapeFeed,
  // Scripts
  generateBiasTraining,
  // Dev helper
  test,
};
