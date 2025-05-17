const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {logger} = require("firebase-functions/v2");
const {authenticate} = require("../common/auth");
const {scrapeConfig} = require("../common/functions");
const {SHOULD_SCRAPE_FEED, publishMessage} = require("../common/pubsub");
const {findCreatePlatform} = require("../common/database");
const {scrapeFeed, scrapeMetaFeed} = require("./scraper");
const {getPlatformType} = require("../common/utils");
const {processLinks, processItems} = require("./contentProcessor");
const {getTopNewsPosts} = require("./news");

// ////////////////////////////
// API's
// ////////////////////////////

/**
 * Calls process Link for the given platform
 * @param {string} data.link
 * */
const onLinkPaste = onCall(
    {
      ...scrapeConfig,
    },
    async (request) => {
      authenticate(request);
      const data = request.data;
      if (!data.link) {
        throw new HttpsError("invalid-argument", "No link provided.");
      }

      const platform = await findCreatePlatform(data.link);

      const platformType = getPlatformType(platform);

      const pids = await processLinks([data.link],
          platformType, request.auth.uid);

      if (!pids.length) {
        throw new HttpsError("invalid-argument", "No post created.");
      }

      return pids[0];
    },
);

/**
 * Scrapes X feed
 * */
const fetchNews = onCall(
    {
      ...scrapeConfig,
    },
    async (request) => {
      authenticate(request);
      const platformType = request.data.platformType;
      if (platformType === "x") {
        await scrapeNewsAccounts(); // could also scrapeMetaFeed here.
        return {message: "Top news scraping initiated for X platform."};
      } else if (platformType === "news") {
        // For News, fetch articles and process them
        const topPosts = await getTopNewsPosts(5);
        const pids = await processItems(topPosts, platformType);
        return pids;
      } else {
        throw new Error(`Unsupported platform type: ${platformType}`);
      }
    },
);

/**
 * Pubsub to process a link
 * called typically from scraping environments
 */
const onShouldProcessLink = onMessagePublished(
    {
      ...scrapeConfig,
      topic: "onShouldProcessLink",
    },
    async (event) => {
      const message = event.data.message;

      if (!message.json.link) {
        logger.error("No link provided.");
        return;
      }

      const platform = await findCreatePlatform(message.json.link);

      const platformType = getPlatformType(platform);

      await processLinks([message.json.link],
          platformType, message.json.poster);

      return;
    },
);

/**
 * Pubsub to Scrape X feed
 */
const onScrapeFeed = onMessagePublished(
    {
      ...scrapeConfig,
      topic: SHOULD_SCRAPE_FEED,
    },
    async (event) => {
      const message = event.data.message;

      if (!message.json.link) {
        logger.error("No link provided.");
        return;
      }

      if (message.json.metaFeed) {
        await scrapeMetaFeed(message.json.link, message.json.limit);
      } else {
        await scrapeFeed(message.json.link, message.json.limit);
      }


      return;
    },
);

const topNewsAccounts = [
  "https://x.com/zerohedge",
  "https://x.com/TechCrunch",
  "https://x.com/Reuters",
  "https://x.com/CNN",
  "https://x.com/BBCBreaking",
  "https://x.com/nytimes",
  "https://x.com/AJEnglish",
  "https://x.com/FoxNews",
  "https://x.com/NBCNews",
  "https://x.com/ABC",
  "https://x.com/WSJ",
  "https://x.com/guardian",
  "https://x.com/Forbes",
  "https://x.com/BusinessInsider",
  "https://x.com/Politico",
  "https://x.com/Osint613",
  "https://x.com/visegrad24",
  "https://x.com/MarioNawfal",
  "https://x.com/MattWalshBlog",
  "https://x.com/sentdefender",
  "https://x.com/KobeissiLetter",
  "https://x.com/markets",
  "https://x.com/unusual_whales",
];

const NUM_ACCOUNTS = 6;
const NUM_POSTS = 5;

const scrapeNewsAccounts = async () => {
  // Pick up to NUM_ACCOUNTS distinct items
  const picked = new Set();
  while (picked.size < Math.min(NUM_ACCOUNTS, topNewsAccounts.length)) {
    const i = Math.floor(Math.random() * topNewsAccounts.length);
    picked.add(topNewsAccounts[i]);
  }

  for (const account of picked) {
    await publishMessage(SHOULD_SCRAPE_FEED, {
      link: account,
      metaFeed: false,
      limit: NUM_POSTS,
    });
  }
};

// ////////////////////////////
// Helpers
// ////////////////////////////

module.exports = {
  onLinkPaste,
  fetchNews,
  onScrapeFeed,
  onShouldProcessLink,
  scrapeNewsAccounts,
};
