/* eslint-disable max-len */
const {getClient} = require("./polymarket");
const {mergeToBigQuery, ASSET_TABLE} = require("../warehouse/bq");
const {millisToIso} = require("../common/utils");
const {logger} = require("firebase-functions/v2");

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
 * Upload asset data to BQ from Polymarket
 * Per some BS Polymarket API, we need to give the creation time of the market
 * and get all data
 * @param {string} assetId
 * @param {string} conditionId
 * @param {number} startTime - start timestamp in MILLIS
 */
async function updateAssetData(assetId, conditionId, startTime) {
  logger.info(`Updating asset data for ${assetId}`);

  const filterParams = {
    market: assetId,
    fidelity: 1, // The resolution of the data, in minutes. 1 is lowest
    startTs: startTime / 1000, // Convert to seconds
  };

  const resp = await getClient(true).getPricesHistory(filterParams);

  logger.info(`Got ${resp.history.length} rows for ${assetId}`);

  const rows = resp.history.map((element) => {
    return {
      assetId: assetId,
      price: element.p,
      conditionId: conditionId,
      timestamp: millisToIso(element.t * 1000),
    };
  });

  // loop if rows > 10k due to bq limits
  for (let i = 0; i < rows.length; i += 10000) {
    const chunk = rows.slice(i, i + 10000);
    await mergeToBigQuery(ASSET_TABLE, chunk);
  }
}

module.exports = {
  updateAssetData,
};
