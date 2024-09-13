/* eslint-disable max-len */
const WebSocket = require("ws");
const {ClobClient, Chain} = require("@polymarket/clob-client");
const ethers = require("ethers");
const {SignatureType} = require("@polymarket/order-utils");
const {logger} = require("firebase-functions/v2");
const axios = require("axios");
const {defineSecret} = require("firebase-functions/params");

const _polyWallet = defineSecret("POLYMARKET_WALLET");
const _polyKey = defineSecret("POLYMARKET_KEY");


const POLYMARKET_WEBSOCKET_URL =
  "wss://ws-subscriptions-clob.polymarket.com/ws/market";
const POLYMARKET_URL = "https://clob.polymarket.com";

let key;
let authClient;
let client;

/**
 * Get client (authenticated)
 * @param {boolean} authenticated
 * @return {ClobClient} client
 */
function getClient(authenticated = false) {
  if (authenticated) {
    if (authClient) {
      return authClient;
    }

    const wallet = _polyWallet.value();
    const key = _polyKey.value();

    const signer = new ethers.Wallet(key); // PK
    authClient = new ClobClient(
        POLYMARKET_URL,
        Chain.POLYGON,
        signer,
        {},
        SignatureType.POLY_PROXY,
        wallet, // wallet address
    );

    return authClient;
  } else {
    if (client) {
      return client;
    }
    client = new ClobClient(POLYMARKET_URL, Chain.POLYGON);
    return client;
  }
}

/**
 * Derive API key
 * @return {ApiKeyCreds} key
 */
async function getKey() {
  if (key) {
    return key;
  }

  key = await getClient(true).deriveApiKey();
  return key;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////
// Markets
// //////////////////////////////////////////////////////////////////////////////////////////////////

// HARD CODED!
// const tags = ["Elon Musk", "Mention Markets", "hamas", "banking", "Tweet Markets",
//   "Pop Culture", "Lebanon", "ackman", "Gaza", "zelensky", "putin",
//   "venezulea", "legal", "migrants", "Venezuela", "Politics", "Geopolitics",
//   "court cases", "ilegal", "Telegram", "US Election", "united kingdom",
//   "palestine", "Economy", "England", "Ukraine", "Business", "Iran",
//   "Twitter", "Biden", "corporate law", "Aliens", "hezbollah",
//   "house of representatives", "Fed Rates", "mexico", "US News", "economics",
//   "Cristopher Wray", "Global Elections", "congress", "Middle East", "Kamala",
//   "crime", "uk", "Israel", "war", "Trump", "stocks", "Polling",
//   "Supreme Court", "Breaking News", "Brazil", "russia", "washington"];

// /**
//  * Get historical data
//  * @param {string} assetId
//  * @param {number} startTs
//  * @param {string} fidelity
//  * @return {Object} historical data
//  */
// function getHistoricalData(assetId, startTs, fidelity) {
//   const url = `${POLYMARKET_URL}?startTs=${startTs}&market=${assetId}&earliestTimestamp=${startTs}&fidelity=${fidelity}`;
//   return axios.get(url)
//       .then((response) => response.data.history)
//       .catch((error) => {
//         logger.infoor("Error fetching historical data:", error);
//         throw error;
//       });
// }
/**
 * Get CLOB API 'market' aka condition, used in their CLOB API
 * eg., 0xdd22472e552920b8438158ea7238bfadfa4f736aa4cee91a6b86c39ead110917
 * @param {string} conditionId id of the market
 * @return {Object} market
 */
async function getCondition(conditionId) {
  return getClient().getMarket(conditionId);
}

/**
 * Get Polymarket market
 * @param {string} marketId
 * @return {Object} market
 * @throws {Error} error
 */
async function getMarket(marketId) {
  const url =
  `https://gamma-api.polymarket.com/markets/${marketId}`;

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    logger.error("Error fetching data from Polymarket API:", error);
  }
}

/**
 * Get all Polymarket markets iteratively
 * @param {boolean} active - Whether to fetch active markets (default: true)
 * @param {boolean} closed - Whether to fetch closed markets (default: false)
 * @param {boolean} archived - Whether to include archived markets (default: false)
 * @param {number} tagId - Tag id to filter markets (default: 2, Politics)
 * @param {boolean} relatedTags - Whether to include related tags (default: true)
 * @param {number} totalLimit - Limit of markets in total, (not per request!) (default: 100)
 * @return {Array} - Array containing all markets
 */
async function getMarkets({
  active = true,
  closed = false,
  archived = false,
  tagId = 2, // 2 is the tag id for "Politics"
  relatedTags = true,
  totalLimit = 200, // this is the total limit, not the limit per request
} = {}) {
  let allMarkets = [];
  let keepFetching = true;
  let offset = 0;
  const apiLimit = 100; // Polymarket API limit max is 100

  while (keepFetching) {
    const url =
    `https://gamma-api.polymarket.com/markets?` +
    `order=createdAt&` +
    `ascending=false&` +
    `${archived != null ? `archived=${archived}&` : ""}` +
    `${active != null ? `active=${active}&` : ""}` +
    `${closed != null ? `closed=${closed}&` : ""}` +
    `${tagId != null ? `tag_id=${tagId}&` : ""}` +
    `related_tags=${relatedTags}&` +
    `limit=${apiLimit}&` +
    `offset=${offset}`;

    try {
      const response = await axios.get(url);
      const data = response.data;

      if (data.length > 0) {
        if (allMarkets.length + data.length > totalLimit) {
          data.splice(totalLimit - allMarkets.length); // Limit the number of markets to the total limit
        }
        allMarkets = allMarkets.concat(data);
        if (allMarkets.length >= totalLimit) {
          keepFetching = false;
        }
        // If less than limit results returned, stop fetching
        if (data.length < apiLimit) {
          keepFetching = false;
        }

        offset += apiLimit; // Increase the offset by the limit for the next request

        // Sleep for 2 seconds before making the next request to avoid rate limiting
        await new Promise((resolve) => setTimeout(resolve, 2000));
      } else {
        keepFetching = false; // No more data to fetch
      }
    } catch (error) {
      logger.error("Error fetching data from Polymarket API:", error);
      keepFetching = false;
    }
  }

  return allMarkets;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////
// Events
// //////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Get Events, which is the only apparent way to get the tag ids
 * @return {Event} events (which are higher level concepts that can have 1 or many markets)
 */
async function getEvents() {
  const url =`https://gamma-api.polymarket.com/events`;

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    logger.error("Error fetching data from Polymarket API:", error);
  }
}


// //////////////////////////////////////////////////////////////////////////////////////////////////
// Prices
// //////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Get prices history
 * @param {string} assetId
 * @param {number} fidelity
 */
async function getPricesHistory(assetId, fidelity) {
  const filterParams = {
    market: "21742633143463906290569050155826241533067272736897614950488156847949938836455",
    fidelity: fidelity, // The resolution of the data, in minutes
    interval: "max", // 1h, 1w, 1m, 1y, max
  };
  return getClient(true).getPricesHistory(filterParams);
}

// //////////////////////////////////////////////////////////////////////////////////////////////////
// Subscriptions
// //////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Subscribe to Polymarket markets
 * @return {void}
 */
function subscribeToMarkets() {
  // I think the left side needs quotes
  const subscribeMessage = {
    "type": "Market",
    "assets_ids": ["21742633143463906290569050155826241533067272736897614950488156847949938836455", "48331043336612883890938759509493159234755048973500640148014422747788308965732"],
  };

  const ws = new WebSocket(POLYMARKET_WEBSOCKET_URL);
  ws.on("open", () => {
    logger.info("Opening socket connection");
    // eslint-disable-next-line quotes
    ws.send(JSON.stringify(subscribeMessage), (err) => {
      if (err) {
        logger.info("send error", err);
        process.exit(1);
      }
    });
  });
  ws.on("message", (data) => {
    logger.info("Received message");
    const jsonString = data.toString("utf8");
    const message = JSON.parse(jsonString);
    logger.info(message);
  });
  ws.on("error", (error) => {
    logger.info(error);
  });
  ws.on("close", (message) => {
    logger.info("Closing socket connection");
    logger.info(message);
  });
}


module.exports = {
  subscribeToMarkets,
  getClient,
  getKey,
  getCondition,
  getMarket,
  getMarkets,
  getEvents,
  getPricesHistory,
};
