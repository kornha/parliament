// eslint-disable-next-line no-unused-vars
const {BigQuery, Dataset} = require("@google-cloud/bigquery");
const {logger} = require("firebase-functions/v2");

const DATASET_ID = "polymarket";
const ASSET_TABLE = "assets";
const MARKET_TABLE = "markets";

let bigquery;

/**
 * Get the BigQuery client
 * @return {BigQuery}
 */
function getClient() {
  if (!bigquery) {
    bigquery = new BigQuery();
  }
  return bigquery;
}

/**
 * Get the BigQuery dataset
 * @return {Dataset}
 */
function getDataset() {
  return getClient().dataset(DATASET_ID);
}

// /////////////////////////////////////////////////////////////////////////////
// Merge
// /////////////////////////////////////////////////////////////////////////////

/**
 * Write data to BigQuery using a MERGE statement to avoid duplicates.
 * @param {string} tableId
 * @param {Object[]} rows
 */
async function mergeToBigQuery(tableId, rows) {
  logger.info(`Merging ${rows.length} rows into ${tableId}`);

  if (!getDataset().table(tableId).exists()) {
    initBq();
    return;
  }

  // chunk the rows if > 10k
  // loop if rows > 10k due to bq limits
  for (let i = 0; i < rows.length; i += 10000) {
    const chunk = rows.slice(i, i + 10000);
    try {
    // Dynamically generate the field names and values from the chunk
      const fields = Object.keys(chunk[0]);
      const fieldNames = fields.join(", ");
      const valueNames = fields.map((field) => {
        return `source.${field}`;
      }).join(", ");

      const onConditions = fields.map((field) => {
        return `target.${field} = source.${field}`;
      }).join(" AND ");

      const query = `
        MERGE \`${DATASET_ID}.${tableId}\` AS target
        USING (
          SELECT * FROM UNNEST(@chunk) AS source
        ) AS source
        ON ${onConditions}
        WHEN NOT MATCHED THEN
          INSERT (${fieldNames})
          VALUES (${valueNames});
      `;

      const options = {
        query: query,
        params: {chunk},
      };

      const [job] = await bigquery.createQueryJob(options);
      await job.getQueryResults();
      logger.info(`Merged ${chunk.length} rows into BigQuery`);
    } catch (error) {
      logger.error(`Error writing to BigQuery: ${error}`);
      break;
    }
  }
}


// /////////////////////////////////////////////////////////////////////////////
// Create/Startup
// /////////////////////////////////////////////////////////////////////////////

/**
 * Initializes BigQuery if required, else does nothing (no-op)
 * @return {Promise<boolean>} whether the tables exist
 */
async function initBq() {
  const assetsExists = (await getDataset().table(ASSET_TABLE).exists())[0];
  const marketsExists = (await getDataset().table(MARKET_TABLE).exists())[0];
  if (!assetsExists || !marketsExists) {
    logger.warn("Required table does not exist, initializing. Run in a 60s.");
    await createTables();
    return false;
  }
  return true;
}

// /////////////////////////////////////////////////////////////////////////////
// Market
// /////////////////////////////////////////////////////////////////////////////

const marketSchema = [
  {name: "marketId", type: "STRING", mode: "REQUIRED"},
  {name: "question", type: "STRING", mode: "REQUIRED"},
  {name: "questionId", type: "STRING", mode: "REQUIRED"},
  {name: "description", type: "STRING", mode: "REQUIRED"},
  {name: "outcomes", type: "STRING", mode: "REPEATED"}, // Array of strings
  {name: "photoURL", type: "STRING", mode: "NULLABLE"},
  {name: "slug", type: "STRING", mode: "REQUIRED"},
  {name: "startedAt", type: "INT64", mode: "REQUIRED"},
  {name: "endedAt", type: "INT64", mode: "REQUIRED"},
  {name: "createdAt", type: "INT64", mode: "REQUIRED"},
  {name: "updatedAt", type: "INT64", mode: "REQUIRED"},
  {name: "conditionId", type: "STRING", mode: "REQUIRED"},
  {name: "clobTokenIds", type: "STRING", mode: "REPEATED"}, // Array of strings
  {name: "active", type: "BOOL", mode: "REQUIRED"},
  {name: "acceptingOrders", type: "BOOL", mode: "REQUIRED"},
  {name: "acceptingOrdersTimestamp", type: "INT64", mode: "REQUIRED"},
];

const currentTimeMillis = Date.now();

// Calculate 5 years ago (in milliseconds)
const start = currentTimeMillis - (3 * 365 * 24 * 60 * 60 * 1000); // -3 yr

// Calculate 10 years into the future (in milliseconds)
const end = currentTimeMillis + (10 * 365 * 24 * 60 * 60 * 1000); // +10 yr

const marketPartition = {
  field: "createdAt", // INT64 field storing milliseconds since epoch
  range: {
    start: start,
    end: end,
    interval: 86400000, // One day in milliseconds
  },
};

const marketClustering = {
  fields: ["marketId"],
};

// /////////////////////////////////////////////////////////////////////////////
// Asset
// /////////////////////////////////////////////////////////////////////////////

const assetSchema = [
  {name: "assetId", type: "STRING", mode: "REQUIRED"},
  {name: "price", type: "FLOAT", mode: "REQUIRED"},
  {name: "conditionId", type: "STRING", mode: "REQUIRED"},
  {name: "timestamp", type: "INT64", mode: "REQUIRED"},
];

const assetPartition = {
  field: "timestamp",
  range: {
    start: start,
    end: end,
    interval: 86400000, // One day in milliseconds
  },
};
const assetClustering = {
  fields: ["assetId"],
};

const tableIds = [ASSET_TABLE, MARKET_TABLE];

const schemaMap = {
  [ASSET_TABLE]: assetSchema,
  [MARKET_TABLE]: marketSchema,

};
const partitionMap = {
  [ASSET_TABLE]: assetPartition,
  [MARKET_TABLE]: marketPartition,
};
const clusteringMap = {
  [ASSET_TABLE]: assetClustering,
  [MARKET_TABLE]: marketClustering,
};


/**
 * Create all required tables in BigQuery
 * @return {Promise<void>}
 */
async function createTables() {
  for (const tableId of tableIds) {
    const dataset = getClient().dataset(DATASET_ID);
    const table = dataset.table(tableId);
    const exists = (await table.exists())[0];
    if (!exists) {
      createTable(
          tableId,
          schemaMap[tableId],
          partitionMap[tableId],
          clusteringMap[tableId],
      );
    }
  }
}

/**
 * Create a new table in BigQuery if required
 * @param {string} tableId
 * @param {Object} schema
 * @param {Object} partition
 * @param {Object} clustering
 */
async function createTable(tableId, schema, partition, clustering) {
  const [table] = await getClient()
      .dataset(DATASET_ID)
      .createTable(tableId, {
        schema: schema,
        // timePartitioning: partition, use if we have time partition
        rangePartitioning: partition,
        clustering: clustering,
      });

  return table;
}

module.exports = {
  ASSET_TABLE,
  MARKET_TABLE,
  getClient,
  getDataset,
  mergeToBigQuery,
  initBq,
};

