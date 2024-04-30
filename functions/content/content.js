const functions = require("firebase-functions");
const {authenticate} = require("../common/auth");
const {gbConfig} = require("../common/functions");
const {isoToMillis, urlToDomain} = require("../common/utils");
const {findCreateEntity} = require("../models/entity");
const {v4} = require("uuid");
const {Timestamp} = require("firebase-admin/firestore");
const {getTextContentFromX} = require("./scraper");
const {createPost} = require("../common/database");
const urlMetadata = require("url-metadata");

// ////////////////////////////
// API's
// ////////////////////////////

// for content pasted by users
// Calls Puppeteer and requires 1GB to run
const onLinkPaste = functions.runWith(gbConfig)
    .https.onCall(async (data, context) => {
      authenticate(context);
      if (!data.link) {
        throw new functions.https
            .HttpsError("invalid-argument", "No link provided.");
      }

      // written to the database in this call
      const post = await urlToPost(data.link, context.auth.uid);

      if (!post || !post.pid) {
        throw new functions.https
            .HttpsError("invalid-argument", "Could not fetch metadata.");
      }

      return Promise.resolve(post.pid);
    });


// ////////////////////////////
// Helpers
// ////////////////////////////

/**
 * Takes in a URL and Creates the post in the database.
 * Currently supports X and Articles.
 * Articles needs refactoring.
 * @param {String} url
 * @param {String} uid
 * @return {Promise<void>}
 */
const urlToPost = async function(url, uid) {
  if (!url) {
    throw new functions.https
        .HttpsError("invalid-argument", "No link provided.");
  }

  const domain = urlToDomain(url);
  if (domain == "x.com" || domain == "twitter.com") {
    return xToPost(url, uid);
  } else {
    // BELOW NEEDS UPDATES BEFORE USING
    // DOES NOT UPDATE ENTITY
    return articleToPost(url, uid);
  }
};

// Requires 1GB to run
const xToPost = async function(url, uid) {
  const xMetaData = await getTextContentFromX(url);
  if (!xMetaData || !xMetaData.title) {
    throw new functions.https
        .HttpsError("invalid-argument", "Could not fetch content.");
  }

  const time = isoToMillis(xMetaData.isoTime);
  const eid = await findCreateEntity(xMetaData.creatorEntity, "x");

  const post = {
    pid: v4(),
    eid: eid,
    status: "draft",
    sourceCreatedAt: time,
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
    title: xMetaData.title,
    // currently no description pulled from X
    // will change with API change
    // description: metadata.description,
    imageUrl: xMetaData.imageUrl,
    sourceType: "x",
    url: url,
  };

  const success = await createPost(post);
  if (!success) {
    throw new functions.https
        .HttpsError("internal", "Could not create post.");
  }
  return post;
};

// NEEDS REFACTOR BEFORE USE
// ENTITY NOT UPDATED
const articleToPost = async function(url, uid) {
  let metadata;

  try {
    metadata = await urlMetadata(url);
  } catch (err) {
    throw new functions.https
        .HttpsError("invalid-argument", "Could not fetch metadata.");
  }

  const post = _metadataToPost(metadata, uid);
  const success = await createPost(post);
  if (!success) {
    throw new functions.https
        .HttpsError("internal", "Could not create post.");
  }
  return post;
};

const _metadataToPost = function(metadata, uid) {
  // if we have the twitter handle, use that as the creator
  let creatorEntity = metadata["twitter:site"];
  if (!creatorEntity) {
    creatorEntity = urlToDomain(metadata.url);
  }
  return {
    pid: v4(),
    creator: creatorEntity,
    poster: uid,
    status: "draft",
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
    title: metadata.title,
    description: metadata.description,
    imageUrl: metadata["og:image"],
    sourceType: "article", // todo: handle other types
    url: metadata.url,
  };
};

module.exports = {
  onLinkPaste,
};
