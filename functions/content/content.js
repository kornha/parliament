const functions = require("firebase-functions");
const {fetchFromPerigon} = require("./perigon");
const {authenticate} = require("../common/auth");
const {urlToPost} = require("./url");

// ////////////////////////////
// API's
// ////////////////////////////

// for fetching content from the internet
const onTriggerContent = functions.https.onCall(async (data, context) => {
  authenticate(context);

  if (!data.source) {
    throw new functions.https
        .HttpsError("invalid-argument", "No source provided.");
  }

  // fetches content from internet
  return fetchContent(data.source);
});

const fetchContent = async function(source) {
  if (source == "perigon") {
    return fetchFromPerigon();
  }

  return {complete: true};
};


// for content pasted by users
const onLinkPaste = functions.https.onCall(async (data, context) => {
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


module.exports = {
  onTriggerContent,
  onLinkPaste,
};
