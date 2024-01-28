const functions = require("firebase-functions");
const {updateFromPerigon} = require("./perigon");


const onNewContent = functions.https.onCall(async (data, context) => {
  if (!data.source) {
    throw new functions.https
        .HttpsError("invalid-argument", "No source provided.");
  }


  return await updateContent(data.source);
});

const updateContent = async function(source) {
  if (source == "perigon") {
    return updateFromPerigon();
  }

  return {complete: true};
};

module.exports = {
  onNewContent,
};
