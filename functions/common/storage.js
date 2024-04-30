
const admin = require("firebase-admin");

/**
  * @param {post} post in question
  * @param {String} content is the text to be saved
  */
const setTextContentInStorage = async function(post, content) {
  const file = admin.storage().bucket().file(`posts/text/${post.pid}.txt`);
  await file.save(content, {
    contentType: "text/plain",
    gzip: true,
  });
};

/**
    * @param {post} post
    * @return {String | null} content text from or null if unavailable
    */
const getTextContentFromStorage = async function(post) {
  console.log(`posts/text/${post.pid}.txt`);
  const file = admin.storage().bucket().file(`posts/text/${post.pid}.txt`);
  const exists = await file.exists();
  if (!exists[0]) return;
  const text = await file.download().then((data) => {
    return data[0].toString();
  });
  return text;
};

module.exports = {
  setTextContentInStorage,
  getTextContentFromStorage,
};
