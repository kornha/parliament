// contentProcessor.js

const {
  findCreatePlatform,
  getPostByXid,
  findCreateEntity,
  createPost,
  updatePost,
} = require("../common/database");
const {v5} = require("uuid");
const {Timestamp} = require("firebase-admin/firestore");
const {logger} = require("firebase-functions/v2");
const {getContentFromX} = require("./xscraper");
const {isoToMillis, getStatus} = require("../common/utils");
const {getArticleFromLink, getPostFromArticle} = require("./news");
const {HttpsError} = require("firebase-functions/https");

/**
 * Processes an array of items.
 * @param {Array<Object>} items - The array of item data to process.
 * @param {string} platformType - The type of source ('x' or 'news').
 * @param {string|null} poster - UID of the poster, if applicable.
 * @return {Promise<Array<string>>} - Array of post IDs.
 */
async function processItems(items, platformType, poster = null) {
  const pids = [];
  for (const data of items) {
    const pid = await processItem(data, platformType, poster);
    if (pid) {
      pids.push(pid);
    }
  }
  return pids;
}

/**
   * Processes an array of links
   * @param {Array<string>} links - The array of links to process.
   * @param {string} platformType - The type of source ('x' or 'news').
   * @param {string|null} poster - UID of the poster, if applicable.
   * @return {Promise<Array<string>>} - Array of post IDs.
   */
async function processLinks(links, platformType, poster = null) {
  const pids = [];
  for (const link of links) {
    const pid = await processLink(link, platformType, poster);
    if (pid) {
      pids.push(pid);
    }
  }
  return pids;
}

/**
   * Processes an item (e.g., article or X post data).
   * @param {Object} data - The item data to process.
   * @param {string} platformType - The type of source ('x' or 'news').
   * @param {string|null} poster - UID of the poster, if applicable.
   * @return {Promise<string|null>} - Post ID if processed successfully
   */
async function processItem(data, platformType, poster = null) {
  const {
    xid,
    url,
    handle,
    platformUrl,
    status,
    title,
    body,
    photo,
    sourceCreatedAt,
    video,
    replies,
    reposts,
    likes,
    bookmarks,
    views,

  } = data;

  if (!xid || !url || !handle || !platformUrl || !handle || !status ||
    (status != "scraping" && (!platformUrl || !title || !sourceCreatedAt))) {
    logger.error(`Missing required data for item: ${JSON.stringify(data)}`);
    return;
  }

  // Find or create the platform
  const platform = await findCreatePlatform(platformUrl);

  // Check if the post already exists
  const existingPost = await getPostByXid(xid, platform.plid);

  let post;
  if (!existingPost) {
    // Find or create the entity
    const entity = await findCreateEntity(handle, platform);
    if (!entity.eid) {
      logger.error(`Could not find or create entity for handle: ${handle}`);
      return null;
    }

    // Create a new post
    post = {
      pid: v5(xid, platform.plid),
      eid: entity.eid,
      xid,
      url,
      poster,
      status: status,
      plid: platform.plid,
      createdAt: Timestamp.now().toMillis(),
      updatedAt: Timestamp.now().toMillis(),
      ...(sourceCreatedAt && {sourceCreatedAt}),
      ...(video && {video}),
      ...(title && {title}),
      ...(body && {body}),
      ...(photo && {photo}),
      ...(reposts && {reposts}),
      ...(likes && {likes}),
      ...(bookmarks && {bookmarks}),
      ...(views && {views}),
      ...(replies && {replies}),
    };

    const success = await createPost(post);
    if (!success) {
      logger.error(`Failed to create post for xid: ${xid}`);
      return null;
    }
  } else {
    // Use the existing post
    post = existingPost;
    await updatePostWithData(post, platformType, data);
    logger.info(`Post already exists with pid: ${post.pid}`);
  }

  return post.pid;
}

/**
   * Processes a link by fetching the item data and then processing it.
   * @param {string} link - The link to process.
   * @param {string} platformType - The type of source ('x' or 'news').
   * @param {string|null} poster - UID of the poster, if applicable.
   * @return {Promise<string|null>} - Post ID if processed successfully
   */
async function processLink(link, platformType, poster = null) {
  logger.info(`Processing link: ${link}`);
  let data;
  try {
    data = await extractDataFromLink(link, platformType, poster);
  } catch (error) {
    logger.error(`Failed to extract data from link: ${link}`, error);
    return null;
  }

  if (!data) {
    logger.warn(`No data extracted from link: ${link}`);
    return null;
  }

  return await processItem(data, platformType, poster);
}

/**
   * Extracts data from a link based on the source type.
   * @param {string} link - The link to extract data from.
   * @param {string} platformType - The type of source ('x' or 'news').
   * @param {string|null} poster - UID of the poster, if applicable.
   * @return {Promise<Object|null>} - Extracted data or null
   */
async function extractDataFromLink(link, platformType, poster = null) {
  if (platformType === "x") {
    return await extractDataFromXLink(link);
  } else if (platformType === "news") {
    return await extractDataFromNewsLink(link);
  } else {
    throw new Error(`Unsupported source type: ${platformType}`);
  }
}

/**
   * Extracts data from an X link.
   * @param {string} link - The X link to process.
   * @return {Promise<Object|null>} - Extracted data or null if invalid.
   */
async function extractDataFromXLink(link) {
  const xid = link.split("/").pop();
  const handle = link.split("/")[3];

  if (handle === "i" || handle === "@i") {
    logger.warn(`Skipping unsupported link: ${link}`);
    return null;
  }

  return {
    xid,
    url: link,
    handle,
    platformUrl: "x.com",
    status: "scraping",
    extraData: null, // No extra data needed at this point
  };
}

/**
   * Extracts data from a news link.
   * @param {string} link - The news link to process.
   * @return {Promise<Object|null>} - Extracted data or null if invalid.
   */
async function extractDataFromNewsLink(link) {
  const article = await getArticleFromLink(link);
  if (!article) {
    logger.warn(`Cannot find article for link: ${link}`);
    return null;
  }

  return getPostFromArticle(article, "draft");
}

/**
   * Updates a post with additional data based on the source type.
   * @param {Object} post - The post to update.
   * @param {string} platformType - The type of source ('x' or 'news').
   * @param {Object} data - Additional data needed for the update.
   * @return {Promise<void>}
   */
async function updatePostWithData(post, platformType, data) {
  if (platformType === "x") {
    await updatePostWithXData(post);
  } else if (platformType === "news") {
    await updatePostWithNewsData(post, data);
  } else {
    throw new Error(`Unsupported source type: ${platformType}`);
  }
}

/**
   * Updates a post with data from X.
   * @param {Object} post - The post to update.
   * @return {Promise<void>}
   */
async function updatePostWithXData(post) {
  const xData = await getContentFromX(post.url);

  if (!xData) {
    throw new HttpsError("invalid-argument",
        "Could not fetch content from " + post.url);
  }

  const time = isoToMillis(xData.isoTime);

  const updateData = {
    title: xData.title,
    photo: xData.photoURL ? {photoURL: xData.photoURL} : null,
    video: xData.videoURL ? {videoURL: xData.videoURL} : null,
    sourceCreatedAt: time,
    replies: xData.replies,
    reposts: xData.reposts,
    likes: xData.likes,
    bookmarks: xData.bookmarks,
    views: xData.views,
    updatedAt: Timestamp.now().toMillis(),
  };

  const status = getStatus(updateData, post.status);
  updateData.status = status;

  await updatePost(post.pid, updateData);
  logger.info(`Updated post: ${post.pid} with X data.`);
}

/**
   * Updates a post with data from a news article.
   * @param {Object} post - The post to update.
   * @param {Object} data - The processed data from the link.
   * @return {Promise<void>}
   */
async function updatePostWithNewsData(post, data) {
  const status = getStatus(post, post.status);

  const updateData = {
    title: data.title,
    body: data.body,
    photo: data.photo,
    sourceCreatedAt: data.sourceCreatedAt,
    status: status,
    updatedAt: Timestamp.now().toMillis(),
    ...(data.replies && {replies: data.replies}),
    ...(data.reposts && {reposts: data.reposts}),
    ...(data.likes && {likes: data.likes}),
    ...(data.bookmarks && {bookmarks: data.bookmarks}),
    ...(data.views && {views: data.views}),
  };

  await updatePost(post.pid, updateData);
}

module.exports = {
  processItems,
  processLinks,
  processItem,
  processLink,
};
