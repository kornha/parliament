const {onCall} = require("firebase-functions/v2/https");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {logger} = require("firebase-functions/v2");
const {getTextContentFromStorage} = require("../common/utils");

// To generate
// go to terminal and start a firebase shell:
// firebase functions:shell
// then run this in shell terminal: generateBiasTraining({}, {})
exports.generateBiasTraining = onCall(
    async (data, context) => {
    // get posts
    // get user bias
    // draft jsonl
    // upload to storage
    // return
      logger.info("Generating bias training data");
      const firestore = getFirestore();
      const storage = getStorage();

      const posts = await firestore
          .collection("posts")
          .where("userBias", "!=", null)
          .get();
      logger.info("posts:", posts.docs.length);

      const systemContent =
      `You are a machine that only returns and replies with valid, 
      iterable RFC8259 compliant JSON in your responses. 
      You will be given text from a webpage. 
      Determine the bias of a webpage. 
      Output should be the following: {'angle': 0.0-360.0}. 
      0 represents a 'right wing bias'. 180 represents a 'left wing bias'. 
      270 represents an extremist bias. 90 represents a centrist bias. 
      Note that 359 is 1 away from 0 so would be a right wing bias. 
      For example, if the webpage is an extremist right wing webpage, 
      the output should be between 0 and 270, something like: {'angle': 315}. 
      Prompts are the exact scraping of webpage text`;

      const content = await Promise.all(posts.docs.map(async (pd) => {
        const post = pd.data();
        const content = await getTextContentFromStorage(post);
        if (!content || !post.userBias) {
          return null;
        }

        return JSON.stringify({
          messages: [
            {"role": "system", "content": systemContent},
            {"role": "user", "content": content},
            {"role": "assistant", "content": post.userBias.angle.toFixed(2)},
          ],
        });
      }));

      const jsonl = content.filter(Boolean).join("\n");

      logger.info("jsonl created", jsonl.length);
      const file = storage.bucket().file(`ai/bias.json`);
      await file.save(jsonl, {
        contentType: "application/json",
        gzip: true,
      });
      logger.info("Done generating bias training data");
      return;
    },
);
