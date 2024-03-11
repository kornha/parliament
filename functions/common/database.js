const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {Timestamp} = require("firebase-admin/firestore");
const {v4} = require("uuid");

// /////////////////////////////////////////
// User
// /////////////////////////////////////////
exports.createUser = async function(user) {
  if (!user.uid) {
    functions.logger.error(`Could not create user: ${user}`);
    return;
  }
  const userRef = admin.firestore().collection("users").doc(user.uid);
  try {
    await userRef.create(user);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.getUsers = async function(uids) {
  if (!uids) {
    functions.logger.error(`Could not get users: ${uids}`);
    return;
  }
  const usersRef = admin.firestore().collection("users");
  try {
    const users = await usersRef.where("uid", "in", uids).get();
    return users.docs.map((user) => user.data());
  } catch (e) {
    return null;
  }
};

exports.updateUser = async function(uid, values) {
  if (!uid || !values) {
    functions.logger.error(`Could not update user: ${uid}`);
    return;
  }
  const userRef = admin.firestore().collection("users").doc(uid);
  try {
    await userRef.update(values);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.deleteUser = async function(uid) {
  if (!uid) {
    functions.logger.error(`Could not delete user: ${uid}`);
    return;
  }
  const userRef = admin.firestore().collection("users").doc(uid);
  try {
    await userRef.delete();
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

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
    await postRef.update(values, {merge: true});
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
  if (!story.sid || !story.createdAt) {
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

// TODO: change to sid, values instead of whole story object
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

exports.updateStory = async function(sid, values) {
  if (!sid || !values) {
    functions.logger.error(`Could not update story: ${sid}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(sid);
  try {
    await storyRef.update(values, {merge: true});
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

exports.getRecentStories = async function(time) {
  const storiesRef = admin.firestore().collection("stories")
      .where("createdAt", ">", time)
      .orderBy("createdAt", "desc")
      .limit(100);
  try {
    const stories = await storiesRef.get();
    return stories.docs.map((story) => story.data());
  } catch (e) {
    return null;
  }
};

// /////////////////////////////////////////
// Room
// /////////////////////////////////////////

exports.createNewRoom = async function(parentId, parentCollection) {
  const rid = v4();
  const createdAt = Timestamp.now().toMillis();

  const roomRef = admin.firestore().collection("rooms").doc(rid);

  const room = {
    rid: rid,
    parentId: parentId,
    parentCollection: parentCollection,
    createdAt: createdAt,
    status: "waiting",
    users: [],
    leftUsers: [],
    rightUsers: [],
    centerUsers: [],
    extremeUsers: [],
  };
  try {
    await roomRef.create(room);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.getRoom = async function(rid) {
  if (!rid) {
    functions.logger.error(`Could not get room: ${rid}`);
    return;
  }
  const roomRef = admin.firestore().collection("rooms").doc(rid);
  try {
    const room = await roomRef.get();
    return room.data();
  } catch (e) {
    return null;
  }
};

exports.setRoom = async function(rid, values) {
  if (!rid || !values) {
    functions.logger.error(`Could not bulk update room: ${rid}`);
    return;
  }
  const roomRef = admin.firestore()
      .collection("rooms")
      .doc(rid);

  try {
    await roomRef.set(values, {merge: true});
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

exports.updateRoom = async function(rid, values) {
  if (!rid || !values) {
    functions.logger.error(`Could not update room: ${rid}`);
    return;
  }
  const roomRef = admin.firestore()
      .collection("rooms")
      .doc(rid);

  try {
    await roomRef.update(values);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

// /////////////////////////////////////////
// Messages
// /////////////////////////////////////////

exports.getMessages = async function(rid, end = null, limit = 100) {
  if (!rid) {
    functions.logger.error(`Could not get messages for room`);
    return;
  }
  let messagesRef = admin.firestore()
      .collection("rooms")
      .doc(rid)
      .collection("messages")
      .orderBy("createdAt", "desc");


  // If 'end' is provided, apply a condition to select messages before 'end'
  if (end !== null) {
    messagesRef = messagesRef.where("createdAt", "<", end);
  }
  messagesRef = messagesRef.limit(limit);
  try {
    const messages = await messagesRef.get();
    return messages.docs.map((message) => message.data());
  } catch (e) {
    return null;
  }
};


// /////////////////////////////////////////
// Generic
// /////////////////////////////////////////

exports.getDBDocument = async function(id, collectionId) {
  if (!id || !collectionId) {
    functions.logger.error(`Could not get: ${id}`);
    return;
  }
  const ref = admin.firestore().collection(collectionId).doc(id);
  try {
    const data = await ref.get();
    return data.data();
  } catch (e) {
    return null;
  }
};
