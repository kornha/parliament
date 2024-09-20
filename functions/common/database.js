const admin = require("firebase-admin");
const {Timestamp, FieldPath, FieldValue} = require("firebase-admin/firestore");
const {v4} = require("uuid");
const _ = require("lodash");
const {retryAsyncFunction, urlToDomain} = require("./utils");
const {logger} = require("firebase-functions/v2");

// /////////////////////////////////////////
// User
// /////////////////////////////////////////
const createUser = async function(user) {
  if (!user.uid) {
    logger.error(`Could not create user: ${user}`);
    return;
  }
  const userRef = admin.firestore().collection("users").doc(user.uid);
  try {
    await userRef.create(user);
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const getUsers = async function(uids) {
  if (!uids) {
    logger.error(`Could not get users: ${uids}`);
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

const updateUser = async function(uid, values, skipError) {
  if (!uid || !values) {
    logger.error(`Could not update user: ${uid}`);
    return;
  }
  const userRef = admin.firestore().collection("users").doc(uid);
  try {
    await userRef.update(values);
    return true;
  } catch (e) {
    if (e?.code && e?.code == skipError) {
      return true;
    }
    logger.error(e);
    return false;
  }
};

const deleteUser = async function(uid) {
  if (!uid) {
    logger.error(`Could not delete user: ${uid}`);
    return;
  }
  const userRef = admin.firestore().collection("users").doc(uid);
  try {
    await userRef.delete();
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

// /////////////////////////////////////////
// post
// /////////////////////////////////////////

// Important! For most cases use atomicCreatePost instead
const createPost = async function(post) {
  if (!post.pid || !post.createdAt || !post.updatedAt || !post.status ) {
    logger.error(`Could not create post: ${post}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(post.pid);
  try {
    await postRef.create(post);
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const updatePost = async function(pid, values, skipError) {
  if (!pid || !values) {
    logger.error(`Could not update post: ${pid}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(pid);
  try {
    await postRef.update(values);
    return true;
  } catch (e) {
    if (e?.code && e?.code == skipError) {
      return true;
    }
    logger.error(e);
    return false;
  }
};

const setPost = async function(pid, values) {
  if (!pid || !values) {
    logger.error(`Could not set post: ${pid}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(pid);
  try {
    await postRef.set(values, {merge: true});
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};


const getPost = async function(pid) {
  if (!pid) {
    logger.error(`Could not get post: ${pid}`);
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
    logger.error(`Could not get posts: ${pids}`);
    return;
  }

  if (pids.length > 10) {
    logger.error(`Too many pids! ${pids}`);
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
 * @param {*} plid
 * @return {Post}
 * */
const getPostByXid = async function(xid, plid) {
  if (!xid) {
    logger.error(`Could not get post by xid: ${xid}`);
    return;
  }
  const postsRef = admin.firestore().collection("posts")
      .where("xid", "==", xid)
      .where("plid", "==", plid).limit(1);
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
    logger.error(`Could not get posts for story: ${sid}`);
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
 * fetches all posts for entity
 * @param {*} eid
 * @return {Array<Post>} of posts
 */
const getAllPostsForEntity = async function(eid) {
  if (!eid) {
    logger.error(`Could not get posts for entity: ${eid}`);
    return;
  }
  // one to many entity:posts
  const postsRef = admin.firestore().collection("posts")
      .where("eid", "==", eid);
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
    logger.error(`Could not get posts mentioning story: ${sid}`);
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

/**
 * get all posts for statement
 * @param {*} stid
 * @return {Array<Post>} of posts
 * */
const getAllPostsForStatement = async function(stid) {
  if (!stid) {
    logger.error(`Could not get posts for statement: ${stid}`);
    return;
  }
  const postsRef = admin.firestore().collection("posts")
      .where("stids", "array-contains", stid);
  try {
    const posts = await postsRef.get();
    return posts.docs.map((post) => post.data());
  } catch (e) {
    return null;
  }
};

/**
 * fetches all posts for platform
 * @param {*} plid
 * @param {*} limit // INCLUDES LIMIT DUE TO POTENTIAL SIZE
 * @return {Array} of posts
 */
const getAllPostsForPlatform = async function(plid, limit = 10000) {
  if (!plid) {
    logger.error(`Could not get posts for platform: ${plid}`);
    return;
  }
  const postsRef = admin.firestore().collection("posts")
      .where("plid", "==", plid)
      .orderBy("updatedAt", "desc")
      .limit(limit);
  try {
    const posts = await postsRef.get();
    return posts.docs.map((post) => post.data());
  } catch (e) {
    return null;
  }
};

const deletePost = async function(pid) {
  if (!pid) {
    logger.error(`Could not delete post: ${pid}`);
    return;
  }
  const postRef = admin.firestore().collection("posts").doc(pid);
  try {
    await postRef.delete();
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

// /////////////////////////////////////////
// Story
// /////////////////////////////////////////

/**
 * Determines if we can find stories or if it is already in progress
 * Sets the post status to "finding" if we can proceed
 * Requires Post to be in "published" or "found" status with a vector
 * @param {String} pid
 * @return {Boolean} shouldProceed
 * */
const canFindStories = async function(pid) {
  if (!pid) {
    logger.error(`Could not update post: ${pid}`);
    return;
  }

  const postRef = admin.firestore().collection("posts").doc(pid);

  let shouldProceed = false;
  // Start a transaction to check and set the post status
  await admin.firestore().runTransaction(async (transaction) => {
    const postDoc = await transaction.get(postRef);
    const post = postDoc.data();

    if (!post || !post.vector ||
      (post.status != "published" && post.status != "found")
    ) {
      return;
    }

    if (post.status == "published" || post.status == "found") {
      transaction.update(postRef, {status: "finding"});
      shouldProceed = true;
    }
  });

  return shouldProceed;
};

// Deprecated
const bulkSetPosts = async function(posts) {
  if (!posts) {
    logger.error(`Could not bulk update posts: ${posts}`);
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
    logger.error(e);
    return false;
  }
};

const createStory = async function(story) {
  if (!story.sid || !story.createdAt) {
    logger.error(`Could not create story: ${story}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(story.sid);
  try {
    await storyRef.create(story);
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const setStory = async function(sid, values) {
  if (!sid || !values) {
    logger.error(`Could not set story: ${sid}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(sid);
  try {
    await storyRef.set(values, {merge: true});
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const updateStory = async function(sid, values, skipError) {
  if (!sid || !values) {
    logger.error(`Could not update story: ${sid}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(sid);
  try {
    await storyRef.update(values);
    return true;
  } catch (e) {
    if (e?.code && e?.code == skipError) {
      return true;
    }
    logger.error(e);
    return false;
  }
};

const getStory = async function(sid) {
  if (!sid) {
    logger.error(`Could not get story: ${sid}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(sid);
  try {
    const story = await storyRef.get();
    return story.data();
  } catch (e) {
    logger.error(e);
    return null;
  }
};

const deleteStory = async function(sid) {
  if (!sid) {
    logger.error(`Could not delete story: ${sid}`);
    return;
  }
  const storyRef = admin.firestore().collection("stories").doc(sid);
  try {
    await storyRef.delete();
    return true;
  } catch (e) {
    logger.error(e);
    return false;
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
    logger.error(`Could not get stories: ${sids}`);
    return;
  }

  if (sids.length > 10) {
    logger.error(`Too many sids! ${sids}`);
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
    logger.error(`Could not get stories for post: ${pid}`);
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

/**
 * fetches all stories for platform
 * @param {*} plid
 * @param {*} limit // INCLUDES LIMIT DUE TO POTENTIAL SIZE
 * @return {Array} of stories
 */
const getAllStoriesForPlatform = async function(plid, limit = 10000) {
  if (!plid) {
    logger.error(`Could not get stories for platform: ${plid}`);
    return;
  }
  const storiesRef = admin.firestore().collection("stories")
      .where("plids", "array-contains", plid)
      .orderBy("updatedAt", "desc")
      .limit(limit);
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
    logger.error(`Could not create entity: ${entity}`);
    return;
  }
  const entityRef = admin.firestore().collection("entities").doc(entity.eid);
  try {
    await entityRef.create(entity);
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const updateEntity = async function(eid, values, skipError) {
  if (!eid || !values) {
    logger.error(`Could not update entity: ${eid}`);
    return;
  }
  const entityRef = admin.firestore().collection("entities").doc(eid);
  try {
    await entityRef.update(values);
    return true;
  } catch (e) {
    if (e?.code && e?.code == skipError) {
      return true;
    }
    logger.error(e);
    return false;
  }
};

/**
 * Finds or creates an entity by handle.
 * @param {string} handle the entity handle.
 * @param {Platform} platform the source type.
 * @return {entity} the entity id.
 * @throws {Error} if the entity could not be created.
 */
const findCreateEntity = async function(handle, platform) {
  if (!handle) {
    logger.error("No handle provided.");
    return;
  }

  if (!platform) {
    logger.error("No platform provided.");
    return;
  }

  // check if first char is @
  // might need to be tweaked for other platforms
  if (handle[0] == "@") {
    handle = handle.slice(1);
  }

  const entity = await retryAsyncFunction(() =>
    getEntityByHandle(handle), 2, 1000, false);

  if (entity) {
    return entity;
  }

  const eid = v4();
  const newEntity = {
    eid: eid,
    handle: handle,
    plid: platform.plid,
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
  };
  if (await retryAsyncFunction(() => createEntity(newEntity))) {
    return newEntity;
  } else {
    throw new Error("Could not create entity.");
  }
};

const getEntity = async function(eid) {
  if (!eid) {
    logger.error(`Could not get entity: ${eid}`);
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
    logger.error(`Could not get entity: ${handle}`);
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

/**
 * fetches all entities for a statement
 * @param {*} stid
 * @return {Array<Entity>} of entities
 * */
const getAllEntitiesForStatement = async function(stid) {
  if (!stid) {
    logger.error(`Could not get entities for statement: ${stid}`);
    return;
  }
  const entitiesRef = admin.firestore().collection("entities")
      .where("stids", "array-contains", stid);
  try {
    const entities = await entitiesRef.get();
    return entities.docs.map((entity) => entity.data());
  } catch (e) {
    return null;
  }
};

/**
 * fetches all entities for a platform
 * @param {*} plid
 * @param {*} limit // INCLUDES LIMIT DUE TO POTENTIAL SIZE
 * @return {Array<Entity>} of entities
 * */
const getAllEntitiesForPlatform = async function(plid, limit = 10000) {
  if (!plid) {
    logger.error(`Could not get entities for platform: ${plid}`);
    return;
  }
  const entitiesRef = admin.firestore().collection("entities")
      .where("plid", "==", plid).limit(limit);
  try {
    const entities = await entitiesRef.get();
    return entities.docs.map((entity) => entity.data());
  } catch (e) {
    return null;
  }
};

// /////////////////////////////////////////
// Platform
// /////////////////////////////////////////

const getPlatform = async function(plid) {
  if (!plid) {
    logger.error(`Could not get platform: ${plid}`);
    return;
  }
  const platformRef = admin.firestore().collection("platforms").doc(plid);
  try {
    const platform = await platformRef.get();
    return platform.data();
  } catch (e) {
    return null;
  }
};

const createPlatform = async function(platform) {
  if (!platform.plid || !platform.createdAt || !platform.url) {
    logger.error(`Could not create platform: ${platform}`);
    return;
  }
  const platformRef = admin
      .firestore()
      .collection("platforms")
      .doc(platform.plid);
  try {
    await platformRef.create(platform);
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const updatePlatform = async function(plid, values, skipError) {
  if (!plid || !values) {
    logger.error(`Could not update platform: ${plid}`);
    return;
  }
  const platformRef = admin.firestore().collection("platforms").doc(plid);
  try {
    await platformRef.update(values);
    return true;
  } catch (e) {
    if (e?.code && e?.code == skipError) {
      return true;
    }
    logger.error(e);
    return false;
  }
};

/**
 * fetches all platforms by ids
 * @param {*} plids
 * @return {Array<Platform>} of platforms
 * */
const getPlatforms = async function(plids) {
  if (!plids) {
    logger.error(`Could not get platforms: ${plids}`);
    return;
  }

  if (plids.length > 10) {
    logger.error(`Too many plids! ${plids}`);
    return;
  }

  const platformsRef = admin.firestore().collection("platforms");
  try {
    const platforms = await platformsRef.where(FieldPath.documentId(),
        "in", plids).get();
    return platforms.docs.map((platform) => platform.data());
  } catch (e) {
    return null;
  }
};

/**
 * Finds or creates a platform by URL.
 * @param {string} link the platform URL.
 * @return {platform} the platform.
 * @throws {Error} if the platform could not be created.
 */
const findCreatePlatform = async function(link) {
  if (!link) {
    logger.error("No link provided.");
    return;
  }

  const url = urlToDomain(link);

  const platform = await retryAsyncFunction(() =>
    getPlatformByURL(url), 2, 1000, false);

  if (platform) {
    return platform;
  }

  const plid = v4();
  const newPlatform = {
    plid: plid,
    url: url,
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
  };

  if (await retryAsyncFunction(() => createPlatform(newPlatform))) {
    return newPlatform;
  } else {
    throw new Error("Could not create platform.");
  }
};

const getPlatformByURL = async function(url) {
  if (!url) {
    logger.error(`Could not get platform by url: ${url}`);
    return;
  }
  const platformRef = admin.firestore().collection("platforms")
      .where("url", "==", url).limit(1);
  try {
    const platforms = await platformRef.get();
    return platforms.docs.map((platform) => platform.data())[0];
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
    logger.error(e);
    return false;
  }
};

const getRoom = async function(rid) {
  if (!rid) {
    logger.error(`Could not get room: ${rid}`);
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
    logger.error(`Could not bulk update room: ${rid}`);
    return;
  }
  const roomRef = admin.firestore()
      .collection("rooms")
      .doc(rid);

  try {
    await roomRef.set(values, {merge: true});
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const updateRoom = async function(rid, values, skipError) {
  if (!rid || !values) {
    logger.error(`Could not update room: ${rid}`);
    return;
  }
  const roomRef = admin.firestore()
      .collection("rooms")
      .doc(rid);
  try {
    await roomRef.update(values);
    return true;
  } catch (e) {
    if (e?.code && e?.code == skipError) {
      return true;
    }
    logger.error(e);
    return false;
  }
};

// /////////////////////////////////////////
// Messages
// /////////////////////////////////////////

const getMessages = async function(rid, end = null, limit = 100) {
  if (!rid) {
    logger.error(`Could not get messages for room`);
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
// Statements (Statements, Opinions, Phrasings)
// /////////////////////////////////////////

const createStatement = async function(statement) {
  if (!statement.stid ||
    !statement.value ||
    !statement.createdAt || !statement.updatedAt) {
    logger.error(`Could not create statement: ${statement}`);
    return;
  }
  const statementRef =
   admin.firestore().collection("statements").doc(statement.stid);
  try {
    await statementRef.create(statement);
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const updateStatement = async function(stid, values, skipError) {
  if (!stid || !values) {
    logger.error(`Could not update statement: ${stid}`);
    return;
  }
  const statementRef = admin.firestore().collection("statements").doc(stid);
  try {
    await statementRef.update(values);
    return true;
  } catch (e) {
    if (e?.code && e?.code == skipError) {
      return true;
    }
    logger.error(e);
    return false;
  }
};

const getStatement = async function(stid) {
  if (!stid) {
    logger.error(`Could not get statement: ${stid}`);
    return;
  }
  const statementRef = admin.firestore().collection("statements").doc(stid);
  try {
    const statement = await statementRef.get();
    return statement.data();
  } catch (e) {
    return null;
  }
};

const getStatements = async function(stids) {
  if (!stids) {
    logger.error(`Could not get statements: ${stids}`);
    return;
  }

  if (stids.length > 10) {
    logger.error(`Too many stids! ${stids}`);
    return;
  }

  const statementsRef = admin.firestore().collection("statements");
  try {
    const statements = await statementsRef.where(FieldPath.documentId(),
        "in", stids).get();
    return statements.docs.map((statement) => statement.data());
  } catch (e) {
    return null;
  }
};

const setStatement = async function(statement) {
  if (!statement.stid || !statement.createdAt || !statement.updatedAt) {
    logger.error(`Could not create statement: ${statement}`);
    return;
  }
  const statementRef =
    admin.firestore().collection("statements").doc(statement.stid);
  try {
    await statementRef.set(statement, {merge: true});
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

const deleteStatement = async function(stid) {
  if (!stid) {
    logger.error(`Could not delete statement: ${stid}`);
    return;
  }
  const statementRef = admin.firestore().collection("statements").doc(stid);
  try {
    await statementRef.delete();
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

/**
 * fetches all statements for a post
 * @param {*} pid
 * @return {Array<Statement>} of statements
 * */
const getAllStatementsForPost = async function(pid) {
  if (!pid) {
    logger.error(`Could not get statements for post: ${pid}`);
    return;
  }
  const statementsRef = admin.firestore().collection("statements")
      .where("pids", "array-contains", pid);
  try {
    const statements = await statementsRef.get();
    return statements.docs.map((statement) => statement.data());
  } catch (e) {
    return null;
  }
};

/**
 * fetches all statements for a story
 * @param {*} sid
 * @return {Array<Statement>} of statements
 * */
const getAllStatementsForStory = async function(sid) {
  if (!sid) {
    logger.error(`Could not get statements for story: ${sid}`);
    return;
  }
  const statementsRef = admin.firestore().collection("statements")
      .where("sids", "array-contains", sid);
  try {
    const statements = await statementsRef.get();
    return statements.docs.map((statement) => statement.data());
  } catch (e) {
    return null;
  }
};

/**
 * fetches all statements for an entity
 * @param {*} eid
 * @return {Array<Statement>} of statements
 * */
const getAllStatementsForEntity = async function(eid) {
  if (!eid) {
    logger.error(`Could not get statements for entity: ${eid}`);
    return;
  }
  const statementsRef = admin.firestore().collection("statements")
      .where("eids", "array-contains", eid);
  try {
    const statements = await statementsRef.get();
    return statements.docs.map((statement) => statement.data());
  } catch (e) {
    return null;
  }
};


// /////////////////////////////////////////
// Generic
// /////////////////////////////////////////

const getDBDocument = async function(id, collectionId) {
  if (!id || !collectionId) {
    logger.error(`Could not get: ${id}`);
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

/**
 * Generic method for deleting a field from a document, matching a where clause
 * @param {String} collection
 * @param {String} fieldName
 * @param {String} equality
 * @param {String} fieldValue
 * @param {Boolean} list deleting an item from a list or not
 * @return {Promise<void>}
 */
async function deleteAttribute(collection,
    fieldName, equality, fieldValue, list=false) {
  const ref = admin.firestore().collection(collection);
  const query = ref.where(fieldName, equality, fieldValue);

  const snapshot = await query.get();

  if (snapshot.empty) {
    return;
  }

  const batch = admin.firestore().batch();

  snapshot.forEach((doc) => {
    const docRef = doc.ref;
    if (list) {
      batch.update(docRef, {[fieldName]: FieldValue.arrayRemove(fieldValue)});
    } else {
      batch.update(docRef, {[fieldName]: FieldValue.delete()});
    }
  });

  await batch.commit();
}

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
    logger.error(`Could not update: ${id}`);
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
    logger.error(e);
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
    logger.error(`Could not search: ${vector}`);
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
    logger.error(e);
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
  getAllPostsForStatement,
  getAllPostsForEntity,
  getAllPostsForPlatform,
  bulkSetPosts,
  canFindStories,
  //
  createStory,
  setStory,
  updateStory,
  deleteStory,
  getStory,
  getRecentStories,
  getStories,
  getAllStoriesForPost,
  getAllStoriesForPlatform,
  //
  createEntity,
  getEntity,
  getEntityByHandle,
  updateEntity,
  findCreateEntity,
  getAllEntitiesForStatement,
  getAllEntitiesForPlatform,
  //
  createNewRoom,
  getRoom,
  setRoom,
  updateRoom,
  //
  createStatement,
  updateStatement,
  getStatement,
  getStatements,
  setStatement,
  deleteStatement,
  getAllStatementsForPost,
  getAllStatementsForStory,
  getAllStatementsForEntity,
  //
  findCreatePlatform,
  createPlatform,
  updatePlatform,
  getPlatform,
  getPlatformByURL,
  getPlatforms,
  //
  getMessages,
  //
  getDBDocument,
  deleteAttribute,
  //
  setVector,
  searchVectors,
};
