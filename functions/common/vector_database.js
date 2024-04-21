const {defineSecret} = require("firebase-functions/params");
const {Pinecone} = require("@pinecone-database/pinecone");
const {generateEmbeddings} = require("./llm");
const {sleep} = require("openai/core");
const functions = require("firebase-functions");
const {isLocal} = require("./utils");


const _pineconeApiKey = defineSecret("PINECONE_KEY");

const STORY_INDEX = isLocal ? "story-index-local" : "story-index";
const POST_INDEX = isLocal ? "post-index-local" : "post-index";
const CLAIM_INDEX = isLocal ? "claim-index-local" : "claim-index";

/**
 *
 * Saves the data to the vector database
 * Waits until field is available before returning (pinecone bs)
 * @param {string} id is sid or pid
 * @param {Array<number>} vector value
 * @param {string} indexString name (currently STORY_INDEX or POST_INDEX)

 * @return {Promise<void>}
 */
const saveEmbeddings = async function(id, vector, indexString) {
  const pc = new Pinecone({apiKey: _pineconeApiKey.value()});

  // to be renamed content-text
  const index = pc.index(indexString);

  // some horse shit about pinecone being eventually consistent,
  // makes us need to check if its updated before returning
  const stats = await index.describeIndexStats();
  const count = stats.totalRecordCount ?? 0;


  // if (includeSparse) {
  //   // Not yet handled!
  //   // requires us to change from cosine to dotproduct
  //   // also requires us to figure out how to generate the sparse Indexes.
  //   // not clear on the advantage just yet but its used in other documents
  //   throw new Error("Not Supported Yet!");
  // }

  await index.upsert([{
    id: id,
    values: vector,
  }]);

  // TODO: not scalable!
  // loop for ~50s and check if stats updated
  for (let i = 0; i < 20; i++) {
    // todo: might need to change this to query index
    // else this could falsely alert us
    const stats = await index.describeIndexStats();
    const countNew = stats.totalRecordCount ?? 0;
    if (countNew > count) {
      return true;
    } else {
      await sleep(3000);
    }
  }
  functions.logger.error("Could not save embedding in time");
  return false;
};

/**
 * Fetches embeddings for pre-embedded strings
 * and saves it to the db.
 * @param {string} id is sid or pid
 * @param {Array<string>} texts value
 * @param {string} indexString name (currently STORY_INDEX or POST_INDEX)
 */
const saveStrings = async function(id, texts, indexString) {
  const embeddings = await generateEmbeddings(texts);
  return saveEmbeddings(id, embeddings, indexString);
};

/**
 * Searches the vector database
 * @param {Array<number>} vector value
 * @param {string} indexString name (currently STORY_INDEX or POST_INDEX)
 * @return {Promise<[string]>} list of ids
 */
const searchVectors = async function(vector, indexString) {
  const pc = new Pinecone({apiKey: _pineconeApiKey.value()});

  const index = pc.index(indexString);

  const resp = await index.query({
    vector: vector,
    // currently needs to be <=10 or we change the getStories whereIn query
    topK: 10,
  });

  return resp?.matches?.map((match) => match.id) ?? [];
};

/**
  * Fetches the embeddings for the id
  * @param {string} id
  * @param {string} indexString name (currently STORY_INDEX or POST_INDEX)
  * @return {Promise<*>} record
  */
const getVector = async function(id, indexString) {
  const pc = new Pinecone({apiKey: _pineconeApiKey.value()});

  const index = pc.index(indexString);

  const resp = await index.fetch([id]);
  return resp?.records[id]?.values ?? null;
};

/**
  * Fetches the embeddings for the ids
  * @param {Array<string>} ids
  * @param {string} indexString name (currently STORY_INDEX or POST_INDEX)
  * @return {Promise<*>} record
  */
const getVectors = async function(ids, indexString) {
  const pc = new Pinecone({apiKey: _pineconeApiKey.value()});

  const index = pc.index(indexString);

  const resp = await index.fetch(ids);
  return !resp ? [] :
  Object.values(resp.records).map((record) => record.values);
};

const deleteVector = async function(id, indexString) {
  const pc = new Pinecone({apiKey: _pineconeApiKey.value()});

  const index = pc.index(indexString);

  return index.deleteOne(id);
};

/**
 * Searches the vector database
 * @param {Array<string>} texts value
 * @param {string} indexString name (currently STORY_INDEX or POST_INDEX)
 * @return {Promise<*>}
 */
const searchStrings = async function(texts, indexString) {
  const embeddings = await generateEmbeddings(texts);
  return searchVectors(embeddings, indexString);
};

// const saveStoryEmbeddings = async function(story) {
//   const strings = getStoryEmbeddingStrings(story);
//   if (strings.length === 0) {
//     return true;
//   }

//   try {
//     await saveStrings(story.sid, strings, STORY_INDEX);
//     publishMessage(STORY_CHANGED_VECTOR, {sid: story.sid});
//     return true;
//   } catch (e) {
//     functions.logger.error("Error saving story embeddings", e);
//     return false;
//   }
// };

/**
 * Fetches the strings to embed for a story
 * @param {Story} story
 * @return {string[]}
 * */
const getStoryEmbeddingStrings = function(story) {
  const ret = [];
  if (story.title) {
    ret.push(story.title);
  }
  if (story.description) {
    ret.push(story.description);
  }
  return ret;
};


module.exports = {
  saveEmbeddings,
  saveStrings,
  searchVectors,
  searchStrings,
  getStoryEmbeddingStrings,
  deleteVector,
  getVector,
  getVectors,
  STORY_INDEX,
  POST_INDEX,
  CLAIM_INDEX,
};
