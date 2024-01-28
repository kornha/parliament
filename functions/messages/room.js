/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
const {incrementPostMessages} = require("../models/post");

//
// Db triggers
//

exports.onRoomChange = functions.firestore
    .document("rooms/{rid}")
    .onWrite((change) => {
      console.log("room change no parent");
      // if (lockDebate(change)) {
      //   return null;
      // } else if (startDebate(change)) {
      //   return null;
      // } else if (finalizeDebate(change)) {
      //   return null;
      // }
      // return null;
    });

exports.onRoomChange = functions.firestore
    .document("/{collectionId}/{parentId}/rooms/{rid}")
    .onWrite((change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const collectionId = context.params.collectionId;
      const parentId = context.params.parentId;

      // if (lockDebate(change)) {
      //   return null;
      // } else if (startDebate(change)) {
      //   return null;
      // } else if (finalizeDebate(change)) {
      //   return null;
      // }
      // return null;

      if (_messageDidIncrement(before, after)) {
        if (collectionId === "posts") {
          // post messages not room messages
          // we have different counts since 1 post can have many rooms
          incrementPostMessages(parentId);
        }
      }
    });

function _messageDidIncrement(before, after) {
  return after &&
        after.messageCount &&
        after.messageCount > 0 &&
         (!before.messageCount ||
          after.messageCount > before.messageCount);
}

//
// Export Helpers
//

exports.incrementRoomMessages = function(rid, parentId, collectionId) {
  return admin.firestore()
      .collection(collectionId)
      .doc(parentId)
      .collection("rooms")
      .doc(rid)
      .update({
        messageCount: FieldValue.increment(1),
      });
};

//
// Http functions
//

// exports.joinRoom = functions.https.onCall(async (data, context) => {
//   authenticate(context);

//   const uid = context.auth.uid;
//   const pid = data.pid;
//   const userSide = data.position === "left" ? "leftUsers" : "rightUsers";
//   const otherSide = data.position === "left" ? "rightUsers" : "leftUsers";

//   let rid = await joinExistingRoom(pid, uid);
//   if (rid) {
//     return {rid: rid};
//   }

//   rid = await joinCandidateRoom(pid, userSide, otherSide, uid);
//   if (rid) {
//     return {rid: rid};
//   }

//   rid = await joinNewRoom(pid, uid, userSide, otherSide);
//   return {rid: rid};
// });


//
// Internal Helpers
//

// async function joinExistingRoom(pid, uid) {
//   const roomSnapshot = await admin.firestore()
//       .collection("rooms")
//       .where("pid", "==", pid)
//       .where("users", "array-contains", uid)
//       .limit(1)
//       .get();

//   if (!roomSnapshot.empty) {
//     const rid = roomSnapshot.docs[0].data().rid;
//     functions.logger.info(`User ${uid} is joining room ${rid}`);
//     return rid;
//   }

//   return null;
// // }

// async function joinCandidateRoom(pid, userSide, otherSide, uid) {
//   const roomSnapshot = await admin.firestore()
//       .collection("rooms")
//       .where("pid", "==", pid)
//       .where(userSide, "==", [])
//       .where(otherSide, "!=", [])
//       .limit(1)
//       .get();

//   if (!roomSnapshot.empty) {
//     const room = roomSnapshot.docs[0].data();
//     if (room[otherSide].includes(uid) || room["users"].includes(uid)) {
//       // Handle error
//     }
//     const rid = room.rid;

//     admin.firestore()
//         .collection("rooms")
//         .doc(rid)
//         .update({
//           users: FieldValue.arrayUnion(uid),
//           [userSide]: FieldValue.arrayUnion(uid),
//         });
//     functions.logger.info(`User ${uid} is joining room ${rid}`);
//     return rid;
//   }

//   return null;
// }

// async function joinNewRoom(pid, uid, userSide, otherSide) {
//   const rid = uuidv4();
//   await admin.firestore()
//       .collection("rooms")
//       .doc(rid)
//       .set({
//         rid: rid,
//         pid: pid,
//         createdAt: Timestamp.now().toMillis(),
//         users: [uid],
//         [userSide]: [uid],
//         [otherSide]: [],
//         status: "waiting",
//       });
//   return rid;
// }
