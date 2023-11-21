/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {v4: uuidv4} = require("uuid");
const {authenticate} = require("./auth");
const {Timestamp, FieldValue} = require("firebase-admin/firestore");
const {lockDebate, startDebate, finalizeDebate} = require("./debate");

//
// Db triggers
//

exports.onRoomChange = functions.firestore
    .document("rooms/{rid}")
    .onWrite((change) => {
      if (lockDebate(change)) {
        return null;
      } else if (startDebate(change)) {
        return null;
      } else if (finalizeDebate(change)) {
        return null;
      }
      return null;
    });

//
// Http functions
//

exports.joinRoom = functions.https.onCall(async (data, context) => {
  authenticate(context);

  const uid = context.auth.uid;
  const pid = data.pid;
  const userSide = data.position === "left" ? "leftUsers" : "rightUsers";
  const otherSide = data.position === "left" ? "rightUsers" : "leftUsers";

  let rid = await joinExistingRoom(pid, uid);
  if (rid) {
    return {rid: rid};
  }

  rid = await joinCandidateRoom(pid, userSide, otherSide, uid);
  if (rid) {
    return {rid: rid};
  }

  rid = await joinNewRoom(pid, uid, userSide, otherSide);
  return {rid: rid};
});


//
// Export Helpers
//

exports.incrementMessages = function(rid) {
  return admin.firestore()
      .collection("rooms")
      .doc(rid)
      .update({
        messageCount: FieldValue.increment(1),
      });
};


//
// Internal Helpers
//

async function joinExistingRoom(pid, uid) {
  const roomSnapshot = await admin.firestore()
      .collection("rooms")
      .where("pid", "==", pid)
      .where("users", "array-contains", uid)
      .limit(1)
      .get();

  if (!roomSnapshot.empty) {
    const rid = roomSnapshot.docs[0].data().rid;
    functions.logger.info(`User ${uid} is joining room ${rid}`);
    return rid;
  }

  return null;
}

async function joinCandidateRoom(pid, userSide, otherSide, uid) {
  const roomSnapshot = await admin.firestore()
      .collection("rooms")
      .where("pid", "==", pid)
      .where(userSide, "==", [])
      .where(otherSide, "!=", [])
      .limit(1)
      .get();

  if (!roomSnapshot.empty) {
    const room = roomSnapshot.docs[0].data();
    if (room[otherSide].includes(uid) || room["users"].includes(uid)) {
      // Handle error
    }
    const rid = room.rid;

    admin.firestore()
        .collection("rooms")
        .doc(rid)
        .update({
          users: FieldValue.arrayUnion(uid),
          [userSide]: FieldValue.arrayUnion(uid),
        });
    functions.logger.info(`User ${uid} is joining room ${rid}`);
    return rid;
  }

  return null;
}

async function joinNewRoom(pid, uid, userSide, otherSide) {
  const rid = uuidv4();
  await admin.firestore()
      .collection("rooms")
      .doc(rid)
      .set({
        rid: rid,
        pid: pid,
        createdAt: Timestamp.now().toMillis(),
        users: [uid],
        [userSide]: [uid],
        [otherSide]: [],
        status: "waiting",
      });
  return rid;
}


// const openai =
// new OpenAI("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");

// async function debate() {
//     const completion = await openai.chat.completions.create({
//         messages: [{ role: "system",
// content: "You are a helpful assistant." }],
//         model: "gpt-3.5-turbo",
//     });

//     console.log(completion.choices[0]);
// }
