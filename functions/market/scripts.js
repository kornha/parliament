/* eslint-disable max-len */
const {getClient, getMarkets} = require("./polymarket");
const {mergeToBigQuery, ASSET_TABLE, initBq, MARKET_TABLE, queryBq} = require("../warehouse/bq");
const {logger} = require("firebase-functions/v2");
const {isoToMillis} = require("../common/utils");

// first
// upload to bq
// add script that steps through a timer
// on tick -> if.. buy other market and set limit order
// test needs to mock this out

// ultimate
// save active market to firestore
// upload market data to BQ
//

/**
 * Runs a given script
 * @return {Promise<void>}
 * */
async function testPolymarket() {
  // await updateMarkets();
  const customQuery = `
    LOWER(question) LIKE '%will trump say%' OR LOWER(question) LIKE '%will donald trump say%'
  `;

  const results = await queryBq({tableId: MARKET_TABLE, customQuery: customQuery});
  results.forEach((result) => {
    console.log(result.question);
  });
}

/**
 * Upload market data to BQ from Polymarket
 * @return {Promise<void>}
 * */
async function updateMarkets() {
  const avail = await initBq();
  if (!avail) {
    logger.warn("BigQuery tables not available.");
    return Promise.resolve();
  }

  const markets = await getMarkets({totalLimit: 5000,
    active: null,
    archived: null,
    closed: null});

  if (!markets) {
    logger.error("Unable to fetch markets!");
    return;
  }

  const rows = [];

  for (const market of markets) {
    if (!market.clobTokenIds) {
      console.log("No clobTokenIds for market", market.question);
      continue;
    }

    rows.push({
      marketId: market.id,
      question: market.question,
      questionId: market.questionID,
      description: market.description,
      outcomes: JSON.parse(market.outcomes),
      photoURL: market.image,
      slug: market.slug,
      startedAt: isoToMillis(market.startDate),
      endedAt: isoToMillis(market.endDate),
      createdAt: isoToMillis(market.createdAt),
      updatedAt: isoToMillis(market.updatedAt),
      conditionId: market.conditionId,
      clobTokenIds: JSON.parse(market.clobTokenIds),
      active: market.active,
      acceptingOrders: market.acceptingOrders,
      acceptingOrdersTimestamp: isoToMillis(market.acceptingOrdersTimestamp),
    });
  }

  await mergeToBigQuery(MARKET_TABLE, rows);
}

/**
 * Upload asset data to BQ from Polymarket
 * Per some BS Polymarket API, we need to give the creation time of the market
 * and get all data
 * @param {string} assetId
 * @param {string} conditionId
 * @param {number} startedAt - start timestamp in MILLIS
 */
async function updateAssetData(assetId, conditionId, startedAt) {
  logger.info(`Updating asset data for ${assetId}`);

  const filterParams = {
    market: assetId,
    fidelity: 1, // The resolution of the data, in minutes. 1 is lowest
    startTs: startedAt / 1000, // Convert to seconds
  };

  const resp = await getClient(true).getPricesHistory(filterParams);

  logger.info(`Got ${resp.history.length} rows for ${assetId}`);

  const rows = resp.history.map((element) => {
    return {
      assetId: assetId,
      price: element.p,
      conditionId: conditionId,
      timestamp: element.t * 1000,
    };
  });

  await mergeToBigQuery(ASSET_TABLE, rows);
}

module.exports = {
  testPolymarket,
  updateAssetData,
  updateMarkets,
};
