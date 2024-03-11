/* eslint-disable require-jsdoc */

const functions = require("firebase-functions");
const {generatePostAiFields} = require("../ai/post_ai");
const {createNewRoom, updatePost} = require("../common/database");
const {FieldValue} = require("firebase-admin/firestore");
const admin = require("firebase-admin");
const {generateStoryForPost, generateStoryAiFields} = require("../ai/story_ai");
const {getTextContentFromBrowser} = require("../common/utils");

exports.onPostUpdate = functions.firestore
    .document("posts/{pid}")
    .onWrite(async (change) => {
      const before = change.before.data();
      const after = change.after.data();

      if (!after) {
        return Promise.resolve();
      }

      // IFF a post was given a new story, notify the story
      // does NOT notify if the post was just created
      // to prevent perigon use case
      if (before && before.sid != after.sid) {
        generateStoryAiFields(after.sid);
      }

      // On publish, create a new room
      // agnostic of the states below
      if (after.status == "published" &&
      (!before || before.status != "published")) {
        createNewRoom(after.pid, "posts");
      }

      // STATES
      // 1. Post is published, but has no body (and requires one)
      // 2. Post is published, but has no story
      // 3. Post is published, and has a story
      // 4. Post description or title is updated

      if (after.status == "published" &&
       after.body == null &&
       after.sourceType == "article") {
        // if this fails, it sets a dummy body!
        // TODO: Make articles not require body
        setPostBody(after);
      } else if (after.status == "published" && after.sid == null) {
        // if this fails the post is errored..
        // generates story if not existant
        generateStoryForPost(after);
      } else if (after.sid && (!before || before.sid != after.sid)) {
        generatePostAiFields(after);
      } else if (before && (before.description != after.description ||
        before.title != after.title)) {
        generatePostAiFields(after);
      }

      return Promise.resolve();
    });

exports.incrementPostMessages = function(pid) {
  return admin.firestore()
      .collection("posts")
      .doc(pid)
      .update({
        messageCount: FieldValue.increment(1),
      });
};

const setPostBody = async function(post) {
  const content = await getTextContentFromBrowser(post.url);
  if (content) {
    updatePost(post.pid, {body: content});
  } else {
    // HACK: Content always updated for article
    // to prevent infinite loop
    updatePost(post.pid, {body: "Could not fetch content"});
  }
};

//
// DEPRECATED
//

// We don't store roomcount with posts
// We store debateBiasCount instead which only tracks room reporting score

// exports.incrementRoomCount = function(pid, value = 1) {
//   return admin.firestore()
//       .collection("posts")
//       .doc(pid)
//       .update({
//         roomCount: FieldValue.increment(value),
//       });
// };
