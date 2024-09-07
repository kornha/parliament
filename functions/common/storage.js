const admin = require("firebase-admin");
const {logger} = require("firebase-functions");

/**
  * @param {String} path
  * @param {String} content
  * @param {String} contentType application/json or text/plain
  */
const setContent = async function(path,
    content,
    contentType = "application/json") {
  const file = admin.storage().bucket().file(path);
  try {
    await file.save(content, {
      contentType: contentType,
      // gzip: gzip,
    });
  } catch (error) {
    logger.error(`Error setting content at path: ${path}`, error);
  }
};

/**
  * Retrieves content from Google Cloud Storage, decompressing it if necessary.
  * @param {String} path - The path to the file in the storage bucket.
  * @return {Promise<String>} - The retrieved content as a string.
  */
const getContent = async function(path) {
  const file = admin.storage().bucket().file(path);
  const [exists] = await file.exists();
  if (!exists) {
    logger.warn(`File does not exist at path: ${path}`);
    return null;
  }

  try {
    const dataBuffer = await file.download();
    return dataBuffer[0].toString();
  } catch (error) {
    logger.error(`Error downloading file: ${path}`, error);
    return null;
  }
};

module.exports = {
  setContent,
  getContent,
};
