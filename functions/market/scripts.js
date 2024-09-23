
const {getClient, getMarkets} = require("./polymarket");
const {mergeToBigQuery,
  MARKET_TABLE,
  ASSET_TABLE, initBq,
  queryBq} = require("../warehouse/bq");
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
  await updateMarkets();
  // const customQuery = `
  //   (LOWER(question) LIKE '%trump say%')
  //   AND
  //   (LOWER(question) LIKE '%speech%' OR
  //    LOWER(question) LIKE '%rally%' OR LOWER(question) LIKE '%town hall%')
  //   ORDER BY createdAt DESC
  // `;

  // const results = await queryBq({tableId: MARKET_TABLE,
  //    customQuery: customQuery});
  // for (const result of results) {
  //   for (const tokenId of result.clobTokenIds) {
  //     await updateAssetData(tokenId, result.conditionId, result.createdAt);
  //   }
  // }
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

  const markets = await getMarkets({totalLimit: 50,
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

    const tokens = JSON.parse(market.clobTokenIds);

    let winner = null;
    const outcomePrices = JSON.parse(market.outcomePrices).map(parseFloat);
    const TOLERANCE = 0.009;
    const index = outcomePrices.findIndex((price) =>
      Math.abs(price - 1.0) < TOLERANCE);

    if (index !== -1) {
      winner = tokens[index];
    }

    const row = {
      marketId: market.id,
      question: market.question,
      questionId: market.questionID,
      description: market.description,
      outcomes: JSON.parse(market.outcomes),
      outcomePrices: outcomePrices,
      photoURL: market.image,
      slug: market.slug,
      startedAt: isoToMillis(market.startDate),
      endedAt: isoToMillis(market.endDate),
      createdAt: isoToMillis(market.createdAt),
      updatedAt: isoToMillis(market.updatedAt),
      conditionId: market.conditionId,
      clobTokenIds: tokens,
      active: market.active,
      acceptingOrders: market.acceptingOrders,
      acceptingOrdersTimestamp: isoToMillis(market.acceptingOrdersTimestamp),
    };

    if (winner != null) {
      row.winner = winner;
    }

    rows.push(row);
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

  const resp = await getClient().getPricesHistory(filterParams);

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
