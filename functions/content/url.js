const urlMetadata = require("url-metadata");
const functions = require("firebase-functions");
const {v4} = require("uuid");
const {Timestamp} = require("firebase-admin/firestore");
const {createPost} = require("../common/database");
const {urlToDomain, getTextContentFromX,
  isoToMillis} = require("../common/utils");

// Requires 1GB to run
const urlToPost = async function(url, uid) {
  if (!url) {
    throw new functions.https
        .HttpsError("invalid-argument", "No link provided.");
  }

  const domain = urlToDomain(url);
  if (domain == "x.com" || domain == "twitter.com") {
    return xToPost(url, uid);
  } else {
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

  const post = {
    pid: v4(),
    creator: xMetaData.creator,
    status: "draft",
    createdAt: time,
    updatedAt: time,
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
  urlToPost,
};
