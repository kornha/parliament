const functions = require("firebase-functions");
const {applyVoteToBias} = require("../ai/bias");
const {applyVoteToCredbility} = require("../ai/credibility");

//
// Vote trigger (subcollection)
//

exports.onVoteBiasChange = functions.firestore
    .document("posts/{pid}/votesBias/{uid}")
    .onWrite(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      if (!before && !after) {
        functions.logger.error(`Vote ${change} without before or after!`);
        return;
      } else if (before && after &&
          before.bias.position.angle === after.bias.position.angle) {
        return null;
      } else if (!before && after) {
        await applyVoteToBias(context.params.pid, after, {add: true});
      } else if (before && !after) {
        await applyVoteToBias(context.params.pid, before, {add: false});
      } else {
        await applyVoteToBias(context.params.pid, before, {add: false});
        await applyVoteToBias(context.params.pid, after, {add: true});
        // admin.firestore()
        //     .collection("posts")
        //     .doc(after.pid).get().then((doc) => {
        //       const post = doc.data();
        //       computeBias(post);
        //     });
      }
    });


exports.onVoteCredibilityChange = functions.firestore
    .document("posts/{pid}/votesCredibility/{uid}")
    .onWrite(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      if (!before && !after) {
        functions.logger.error(`Vote ${change} without before or after!`);
        return;
      } else if (before && after &&
          before.credibility.value === after.credibility.value) {
        return null;
      } else if (!before && after) {
        await applyVoteToCredbility(context.params.pid, after, {add: true});
      } else if (before && !after) {
        await applyVoteToCredbility(context.params.pid, before, {add: false});
      } else {
        await applyVoteToCredbility(context.params.pid, before, {add: false});
        await applyVoteToCredbility(context.params.pid, after, {add: true});
      }
    });
