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
// Query
// /////////////////////////////////////////////////////////////////////////////
/**
 * Query a BigQuery table with a custom query
 * @param {string} datasetId - The dataset ID to query (default is polymarket)
 * @param {string} tableId - The BigQuery table to query
 * @param {string} customQuery - A custom SQL query to execute (required)
 * @param {number} limit - Limit the number of results (default is 1000)
 * @return {Promise<Object[]>} - The query results
 */
async function queryBq({datasetId = DATASET_ID,
  tableId, customQuery, limit = 1000}) {
  // Construct the full query using the dataset, table, and custom query
  let query = `SELECT * FROM \`${datasetId}.${tableId}\``;

  // Append the custom query conditions if provided
  if (customQuery) {
    query += ` WHERE ${customQuery}`;
  }

  // Append the limit to the query
  query += ` LIMIT ${limit}`;

  const options = {
    query,
  };

  // Run the query
  const [rows] = await getClient().query(options);
  return rows;
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

  const compositeKeyFields = compositeKeyMap[tableId];

  for (let i = 0; i < rows.length; i += 10000) {
    const chunk = rows.slice(i, i + 10000);
    try {
      // Dynamically generate the field names and values from the chunk
      const fields = Object.keys(chunk[0]);
      const fieldNames = fields.join(", ");
      const valueNames = fields.map((field) => `source.${field}`).join(", ");

      // Only compare the composite key fields in the ON condition
      const onConditions = compositeKeyFields.map((field) => {
        return `target.${field} = source.${field}`;
      }).join(" AND ");

      // Update non-key fields on match
      const updateConditions =
        fields.filter((field) => !compositeKeyFields.includes(field))
            .map((field) => `target.${field} = source.${field}`)
            .join(", ");

      const query = `
        MERGE \`${DATASET_ID}.${tableId}\` AS target
        USING (
          SELECT * FROM UNNEST(@chunk) AS source
        ) AS source
        ON ${onConditions}
        WHEN MATCHED THEN
          UPDATE SET ${updateConditions}
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
  {name: "startedAt", type: "INT64", mode: "NULLABLE"},
  {name: "endedAt", type: "INT64", mode: "NULLABLE"},
  {name: "createdAt", type: "INT64", mode: "REQUIRED"},
  {name: "updatedAt", type: "INT64", mode: "REQUIRED"},
  {name: "conditionId", type: "STRING", mode: "REQUIRED"},
  {name: "clobTokenIds", type: "STRING", mode: "REPEATED"}, // Array of strings
  {name: "active", type: "BOOL", mode: "REQUIRED"},
  {name: "acceptingOrders", type: "BOOL", mode: "NULLABLE"},
  {name: "acceptingOrdersTimestamp", type: "INT64", mode: "NULLABLE"},
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

// bq doesn't have composite keys but we use them for updates
const compositeKeyMap = {
  [ASSET_TABLE]: ["assetId", "timestamp"],
  [MARKET_TABLE]: ["marketId", "createdAt"],
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
  queryBq,
  getClient,
  getDataset,
  mergeToBigQuery,
  initBq,
};

