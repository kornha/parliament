const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {Timestamp} = require("firebase-admin/firestore");
const {v4} = require("uuid");

// /////////////////////////////////////////
// post
// /////////////////////////////////////////

exports.createPost = async function(post) {
  if (!post.pid || !post.createdAt || !post.updatedAt || !post.status ) {
    functions.logger.error(`Could not create post: ${post}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(post.pid);
  try {
    await postRef.create(post);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.updatePost = async function(pid, values) {
  if (!pid || !values) {
    functions.logger.error(`Could not update post: ${pid}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(pid);
  try {
    await postRef.update(values);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.bulkSetPosts = async function(posts) {
  if (!posts) {
    functions.logger.error(`Could not bulk update posts: ${posts}`);
    return;
  }
  const batch = admin.firestore().batch();
  posts.forEach((post) => {
    const postRef = admin.firestore().collection("posts").doc(post.pid);
    batch.set(postRef, post, {merge: true});
  });
  try {
    await batch.commit();
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.getPost = async function(pid) {
  if (!pid) {
    functions.logger.error(`Could not get post: ${pid}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(pid);
  try {
    const post = await postRef.get();
    return post.data();
  } catch (e) {
    return null;
  }
};

exports.getPostsForStory = async function(sid) {
  if (!sid) {
    functions.logger.error(`Could not get posts for story: ${sid}`);
    return;
  }
  const postsRef = admin.firestore().collection("posts")
      .where("sid", "==", sid);
  try {
    const posts = await postsRef.get();
    return posts.docs.map((post) => post.data());
  } catch (e) {
    return null;
  }
};

// /////////////////////////////////////////
// Story
// /////////////////////////////////////////

exports.createStory = async function(story) {
  if (!story.sid || !story.createdAt ) {
    functions.logger.error(`Could not create story: ${story}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(story.sid);
  try {
    await storyRef.create(story);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.setStory = async function(story) {
  if (!story.sid || !story.createdAt || !story.updatedAt) {
    functions.logger.error(`Could not create story: ${story}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(story.sid);
  try {
    await storyRef.set(story, {merge: true});
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.getStory = async function(sid) {
  if (!sid) {
    functions.logger.error(`Could not get story: ${sid}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(sid);
  try {
    const story = await storyRef.get();
    return story.data();
  } catch (e) {
    return null;
  }
};

// /////////////////////////////////////////
// Room
// /////////////////////////////////////////

exports.createNewRoom = async function(parentId, parentType) {
  const rid = v4();
  const createdAt = Timestamp.now().toMillis();
  const collectionName = parentType + "s";

  const roomRef = collectionName ?
  admin.firestore()
      .collection(collectionName)
      .doc(parentId)
      .collection("rooms")
      .doc(rid) :
      admin.firestore().collection("rooms").doc(rid);

  const room = {
    rid: rid,
    parentId: parentId,
    createdAt: createdAt,
    status: "waiting",
    parentType: parentType,
    users: [],
    left: [],
    right: [],
  };
  try {
    await roomRef.create(room);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

