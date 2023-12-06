const functions = require("firebase-functions");
const {Timestamp} = require("firebase-admin/firestore");

//
// Db triggers
//

exports.onPostCreate = functions.firestore
    .document("posts/{pid}")
    .onCreate((change) => {
      const post = change.after.data();
      if (post) {
        if (["delivered", "seen"].includes(post.status)) {
          return null;
        } else {
          return change.after.ref.update({
            status: "delivered",
            // this is technically overwriting local set timestamp
            createdAt: Timestamp.now().toMillis(),
          });
        }
      } else {
        return null;
      }
    });
