const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {Timestamp, FieldPath, FieldValue} = require("firebase-admin/firestore");
const {v4} = require("uuid");
const _ = require("lodash");
const {retryAsyncFunction} = require("./utils");

// /////////////////////////////////////////
// User
// /////////////////////////////////////////
const createUser = async function(user) {
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

const getUsers = async function(uids) {
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

const updateUser = async function(uid, values) {
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

const deleteUser = async function(uid) {
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

// Important! For most cases use atomicCreatePost instead
const createPost = async function(post) {
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

const updatePost = async function(pid, values) {
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

const setPost = async function(pid, values) {
  if (!pid || !values) {
    functions.logger.error(`Could not set post: ${pid}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(pid);
  try {
    await postRef.set(values, {merge: true});
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};


const getPost = async function(pid) {
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

const getPosts = async function(pids) {
  if (!pids) {
    functions.logger.error(`Could not get posts: ${pids}`);
    return;
  }

  if (pids.length > 10) {
    functions.logger.error(`Too many pids! ${pids}`);
    return;
  }

  const postsRef = admin.firestore().collection("posts");
  try {
    const posts = await postsRef.where(FieldPath.documentId(),
        "in", pids).get();
    return posts.docs.map((post) => post.data());
  } catch (e) {
    return null;
  }
};

/**
 * fetches a post by xid
 * @param {*} xid
 * @param {*} sourceType
 * @return {Post}
 * */
const getPostByXid = async function(xid, sourceType) {
  if (!xid) {
    functions.logger.error(`Could not get post by xid: ${xid}`);
    return;
  }
  const postsRef = admin.firestore().collection("posts")
      .where("xid", "==", xid).where("sourceType", "==", sourceType).limit(1);
  try {
    const posts = await postsRef.get();
    return posts.docs.map((post) => post.data())[0];
  } catch (e) {
    return null;
  }
};

/**
 * fetches primary posts for story (faster than getAllPostsForStory)
 * @param {*} sid
 * @return {Array} of posts
 */
const getPostsForStory = async function(sid) {
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

/**
 * fetches primary and secondary posts for story
 * @param {*} sid
 * @return {Array} of posts
 */
const getAllPostsForStory = async function(sid) {
  if (!sid) {
    functions.logger.error(`Could not get posts mentioning story: ${sid}`);
    return;
  }
  const postsRef = admin.firestore().collection("posts")
      .where("sids", "array-contains", sid);
  try {
    const posts = await postsRef.get();
    return posts.docs.map((post) => post.data());
  } catch (e) {
    return null;
  }
};

const deletePost = async function(pid) {
  if (!pid) {
    functions.logger.error(`Could not delete post: ${pid}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(pid);
  try {
    await postRef.delete();
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

/**
 * Determines if we can find stories or if it is already in progress
 * Sets the post status to "finding" if we can proceed
 * Requires Post to be in "published" status with a vector
 * @param {String} pid
 * @return {Boolean} shouldProceed
 * */
const canFindStories = async function(pid) {
  if (!pid) {
    functions.logger.error(`Could not update post: ${pid}`);
    return;
  }

  const postRef = admin.firestore().collection("posts").doc(pid);

  let shouldProceed = false;
  // Start a transaction to check and set the post status
  await admin.firestore().runTransaction(async (transaction) => {
    const postDoc = await transaction.get(postRef);
    const post = postDoc.data();

    if (!post || !post.vector || post.status != "published") {
      return;
    }

    if (post.status == "published") {
      transaction.update(postRef, {status: "finding"});
      shouldProceed = true;
    }
  });

  return shouldProceed;
};

// Deprecated
const bulkSetPosts = async function(posts) {
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

// /////////////////////////////////////////
// Story
// /////////////////////////////////////////

const createStory = async function(story) {
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

const setStory = async function(sid, values) {
  if (!sid || !values) {
    functions.logger.error(`Could not set story: ${sid}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(sid);
  try {
    await storyRef.set(values, {merge: true});
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

const updateStory = async function(sid, values) {
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

const getStory = async function(sid) {
  if (!sid) {
    functions.logger.error(`Could not get story: ${sid}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(sid);
  try {
    const story = await storyRef.get();
    return story.data();
  } catch (e) {
    functions.logger.error(e);
    return null;
  }
};

const getRecentStories = async function(time) {
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

const getStories = async function(sids) {
  if (!sids) {
    functions.logger.error(`Could not get stories: ${sids}`);
    return;
  }

  if (sids.length > 10) {
    functions.logger.error(`Too many sids! ${sids}`);
    return;
  }

  const storiesRef = admin.firestore().collection("stories");
  try {
    const stories = await storiesRef.where(FieldPath.documentId(),
        "in", sids).get();
    return stories.docs.map((story) => story.data());
  } catch (e) {
    return null;
  }
};

/**
 * fetches all stories that mention a post
 * opposite of getAllPostsForStory
 * fetches primary and secondary posts
 * @param {*} pid
 * @return {Array<Story>} of stories
 * */
const getAllStoriesForPost = async function(pid) {
  if (!pid) {
    functions.logger.error(`Could not get stories for post: ${pid}`);
    return;
  }
  const storiesRef = admin.firestore().collection("stories")
      .where("pids", "array-contains", pid);
  try {
    const stories = await storiesRef.get();
    return stories.docs.map((story) => story.data());
  } catch (e) {
    return null;
  }
};

// /////////////////////////////////////////
// Entity
// /////////////////////////////////////////

/**
 * Creates an entity
 * @param {Entity} entity
 * @return {Promise<Boolean>}
 * */
const createEntity = async function(entity) {
  if (!entity.eid || !entity.handle || !entity.createdAt || !entity.updatedAt) {
    functions.logger.error(`Could not create entity: ${entity}`);
    return;
  }
  const entityRef = admin.firestore().collection("entities").doc(entity.eid);
  try {
    await entityRef.create(entity);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

const updateEntity = async function(eid, values) {
  if (!eid || !values) {
    functions.logger.error(`Could not update entity: ${eid}`);
    return;
  }
  const entityRef = admin.firestore().collection("entities").doc(eid);
  try {
    await entityRef.update(values);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

/**
 * Finds or creates an entity by handle.
 * @param {string} handle the entity handle.
 * @param {string} sourceType the source type.
 * @return {string} the entity id.
 */
const findCreateEntity = async function(handle, sourceType) {
  if (!handle) {
    functions.logger.error("No handle provided.");
    return;
  }

  if (!sourceType) {
    functions.logger.error("No sourceType provided.");
    return;
  }
  // check if first char is @
  // need to see if this is needed for other platforms
  if (handle[0] == "@" && sourceType == "x") {
    handle = handle.slice(1);
  }

  const entity = await retryAsyncFunction(() =>
    getEntityByHandle(handle), 2, 1000, false);

  if (entity) {
    return entity.eid;
  }

  const eid = v4();
  const newEntity = {
    eid: eid,
    handle: handle,
    sourceType: sourceType,
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
  };
  await retryAsyncFunction(() => createEntity(newEntity));
  return eid;
};

const getEntity = async function(eid) {
  if (!eid) {
    functions.logger.error(`Could not get entity: ${eid}`);
    return;
  }
  const entityRef = admin.firestore().collection("entities").doc(eid);
  try {
    const entity = await entityRef.get();
    return entity.data();
  } catch (e) {
    return null;
  }
};

/**
 * Fetches an entity by handle
 * @param {String} handle
 * @return {Entity}
 * */
const getEntityByHandle = async function(handle) {
  if (!handle) {
    functions.logger.error(`Could not get entity: ${handle}`);
    return;
  }
  const entityRef = admin.firestore().collection("entities")
      .where("handle", "==", handle).limit(1);
  try {
    const entities = await entityRef.get();
    return entities.docs.map((entity) => entity.data())[0];
  } catch (e) {
    return null;
  }
};

// /////////////////////////////////////////
// Room
// /////////////////////////////////////////

const createNewRoom = async function(parentId, parentCollection) {
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

const getRoom = async function(rid) {
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

const setRoom = async function(rid, values) {
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

const updateRoom = async function(rid, values) {
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

const getMessages = async function(rid, end = null, limit = 100) {
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
// Claims
// /////////////////////////////////////////

const createClaim = async function(claim) {
  if (!claim.cid || !claim.value || !claim.createdAt || !claim.updatedAt) {
    functions.logger.error(`Could not create claim: ${claim}`);
    return;
  }
  const claimRef = admin.firestore().collection("claims").doc(claim.cid);
  try {
    await claimRef.create(claim);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

const updateClaim = async function(cid, values) {
  if (!cid || !values) {
    functions.logger.error(`Could not update claim: ${cid}`);
    return;
  }
  const claimRef = admin.firestore().collection("claims").doc(cid);
  try {
    await claimRef.update(values);
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

const getClaims = async function(cids) {
  if (!cids) {
    functions.logger.error(`Could not get Claims: ${cids}`);
    return;
  }

  if (cids.length > 10) {
    functions.logger.error(`Too many cids! ${cids}`);
    return;
  }

  const claimsRef = admin.firestore().collection("claims");
  try {
    const claims = await claimsRef.where(FieldPath.documentId(),
        "in", cids).get();
    return claims.docs.map((claim) => claim.data());
  } catch (e) {
    return null;
  }
};

const setClaim = async function(claim) {
  if (!claim.cid || !claim.createdAt || !claim.updatedAt) {
    functions.logger.error(`Could not create claim: ${claim}`);
    return;
  }
  const claimRef = admin.firestore().collection("claims").doc(claim.cid);
  try {
    await claimRef.set(claim, {merge: true});
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

const deleteClaim = async function(cid) {
  if (!cid) {
    functions.logger.error(`Could not delete claim: ${cid}`);
    return;
  }
  const claimRef = admin.firestore().collection("claims").doc(cid);
  try {
    await claimRef.delete();
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

/**
 * fetches all claims for a post
 * @param {*} pid
 * @return {Array<Claim>} of claims
 * */
const getAllClaimsForPost = async function(pid) {
  if (!pid) {
    functions.logger.error(`Could not get claims for post: ${pid}`);
    return;
  }
  const claimsRef = admin.firestore().collection("claims")
      .where("pids", "array-contains", pid);
  try {
    const claims = await claimsRef.get();
    return claims.docs.map((claim) => claim.data());
  } catch (e) {
    return null;
  }
};

/**
 * fetches all claims for a story
 * @param {*} sid
 * @return {Array<Claim>} of claims
 * */
const getAllClaimsForStory = async function(sid) {
  if (!sid) {
    functions.logger.error(`Could not get claims for story: ${sid}`);
    return;
  }
  const claimsRef = admin.firestore().collection("claims")
      .where("sids", "array-contains", sid);
  try {
    const claims = await claimsRef.get();
    return claims.docs.map((claim) => claim.data());
  } catch (e) {
    return null;
  }
};

// /////////////////////////////////////////
// Generic
// /////////////////////////////////////////

const getDBDocument = async function(id, collectionId) {
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

// /////////////////////////////////////////
// Vector
// /////////////////////////////////////////

/**
 * Set a vector for a document
 * @param {String} id
 * @param {Array | VectorValue} vector
 * @param {String} collectionId
 * @return {Promise<Boolean>}
 */
const setVector = async function(id, vector, collectionId) {
  if (!id || !vector || !collectionId) {
    functions.logger.error(`Could not update: ${id}`);
    return;
  }

  if (_.isArray(vector)) {
    vector = FieldValue.vector(vector);
  }

  const ref = admin.firestore().collection(collectionId).doc(id);
  try {
    await ref.set({
      vector: vector,
    }, {merge: true});
    return true;
  } catch (e) {
    functions.logger.error(e);
    return false;
  }
};

/**
 * Search for vectors in a collection
 * @param {Array | VectorValue} vector
 * @param {String} collectionId
 * @param {Number} topK // set to 7 to reduce context window
 * @return {Promise<Array>}
 */
const searchVectors = async function(vector, collectionId, topK = 7) {
  if (!vector || !collectionId) {
    functions.logger.error(`Could not search: ${vector}`);
    return;
  }

  // else we assume its of type VectorValue
  if (_.isArray(vector)) {
    vector = FieldValue.vector(vector);
  }

  const collection = admin.firestore().collection(collectionId);
  // Requires single-field vector index
  const vectorQuery = collection.findNearest("vector",
      vector, {
        limit: topK,
        distanceMeasure: "COSINE",
      });

  try {
    const vectorQuerySnapshot = await vectorQuery.get();
    if (_.isEmpty(vectorQuerySnapshot)) {
      return null;
    }
    const results = vectorQuerySnapshot.docs.map((doc) => doc.data());
    return results;
  } catch (e) {
    functions.logger.error(e);
    return null;
  }
};

module.exports = {
  createUser,
  getUsers,
  updateUser,
  deleteUser,
  //
  createPost,
  updatePost,
  setPost,
  deletePost,
  getPost,
  getPostByXid,
  getPosts,
  getPostsForStory,
  getAllPostsForStory,
  bulkSetPosts,
  canFindStories,
  //
  createStory,
  setStory,
  updateStory,
  getStory,
  getRecentStories,
  getStories,
  getAllStoriesForPost,
  //
  createEntity,
  getEntity,
  getEntityByHandle,
  updateEntity,
  findCreateEntity,
  //
  createNewRoom,
  getRoom,
  setRoom,
  updateRoom,
  //
  createClaim,
  updateClaim,
  getClaims,
  setClaim,
  deleteClaim,
  getAllClaimsForPost,
  getAllClaimsForStory,
  //
  getMessages,
  //
  getDBDocument,
  //
  setVector,
  searchVectors,
};
