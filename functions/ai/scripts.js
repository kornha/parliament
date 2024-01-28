const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {getTextContentFromStorage} = require("../common/utils");


// To generate
// go to terminal and start a firebase shell:
// firebase functions:shell
// then run this in shell terminal: generateBiasTraining({}, {})
exports.generateBiasTraining = functions
    .https
    .onCall(async (data, context) => {
      // get posts
      // get user bias
      // draft jsonl
      // upload to storage
      // return
      console.log("Generating bias training data");
      const posts = await admin.firestore()
          .collection("posts")
          .where("userBias", "!=", null)
          .get();
      console.log("posts:", posts.docs.length);

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


      const content = await Promise.all(posts.docs.map( async (pd) => {
        const post = pd.data();
        const content = await getTextContentFromStorage(post);
        if (!content || !post.userBias) {
          return null;
        }

        return JSON.stringify({
          messages: [
            {"role": "system", "content": systemContent},
            {"role": "user", "content": content},
            {"role": "assistant", "content":
                post.userBias.angle.toFixed(2)},
          ],
        });
      }));

      const jsonl = (await content).join("\n");

      console.log("jsonl created", jsonl.length);
      const file = admin.storage().bucket().file(`ai/bias.json`);
      await file.save(jsonl, {
        contentType: "application/json",
        gzip: true,
      });
      console.log("Done generating bias training data");
      return;
    });

