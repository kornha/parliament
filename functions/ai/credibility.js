const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
const {logger} = require("firebase-functions/v2");

exports.applyVoteToCredbility = async function(pid, vote, {add = true}) {
  const postRef = admin.firestore().collection("posts").doc(pid);

  try {
    await admin.firestore().runTransaction(async (t) => {
      const doc = await t.get(postRef);

      if (!doc.exists) {
        logger.error(`Post ${pid} does not exist!`);
        return;
      }

      const post = doc.data();
      let newCredibility;

      if (post.voteCountCredibility == null ||
          post.voteCountCredibility <= 0 ||
          post.credibility === null) {
        if (!add) {
          logger.error(`Cannot remove vote in ${pid}, empty!`);
          return;
        }
        newCredibility = vote.credibility.value;
      } else if (post.voteCountCredibility == 1 && !add) {
        newCredibility = null;
      } else {
        let direction = vote.credibility.value > post.userCredibility.value ?
             1 : -1;
        direction = add ? direction : direction * -1;
        //
        const dist =
            Math.abs(post.userCredibility.value - vote.credibility.value);
        const magnitude =
            dist / (post.voteCountCredibility + (add ? 1.0 : -1.0));

        //
        newCredibility = post.userCredibility.value + (magnitude * direction);
      }

      t.update(postRef, {
        userCredibility: newCredibility !== null ?
            {"value": newCredibility} : null,
        voteCountCredibility: FieldValue.increment(add ? 1 : -1),
      });
    });
  } catch (e) {
    logger.error(e);
  }
};
