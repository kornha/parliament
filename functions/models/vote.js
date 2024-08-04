const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions/v2");
const {applyVoteToBias} = require("../ai/bias");
const {applyVoteToCredbility} = require("../ai/credibility");

//
// Vote trigger (subcollection)
//

exports.onVoteBiasChange = onDocumentWritten(
    {
      document: "posts/{pid}/votesBias/{uid}",
    },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before && !after) {
        logger.error(`Vote ${event} without before or after!`);
        return;
      } else if (before && after &&
          before.bias.position.angle === after.bias.position.angle) {
        return null;
      } else if (!before && after) {
        await applyVoteToBias(event.params.pid, after, {add: true});
      } else if (before && !after) {
        await applyVoteToBias(event.params.pid, before, {add: false});
      } else {
        await applyVoteToBias(event.params.pid, before, {add: false});
        await applyVoteToBias(event.params.pid, after, {add: true});
      }
    },
);

exports.onVoteCredibilityChange = onDocumentWritten(
    {
      document: "posts/{pid}/votesCredibility/{uid}",
    },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before && !after) {
        logger.error(`Vote ${event} without before or after!`);
        return;
      } else if (before && after &&
        before.credibility.value === after.credibility.value) {
        return null;
      } else if (!before && after) {
        await applyVoteToCredbility(event.params.pid, after, {add: true});
      } else if (before && !after) {
        await applyVoteToCredbility(event.params.pid, before, {add: false});
      } else {
        await applyVoteToCredbility(event.params.pid, before, {add: false});
        await applyVoteToCredbility(event.params.pid, after, {add: true});
      }
    },
);
