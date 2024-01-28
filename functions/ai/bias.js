/* eslint-disable require-jsdoc */
const {OpenAI} = require("openai");
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const {getTextContentForPost} = require("../common/utils");
const {FieldValue} = require("firebase-admin/firestore");

exports.computeBias = async function(post) {
  const content = await getTextContentForPost(post);

  if (!content) {
    functions.logger.error(`Invalid content for ${post.url}, ${content}`);
    return;
  }
  const prompt = `You will be given text from a webpage.
      Determine the bias of a webpage. Output should be the following:
      {"angle": 0.0-360.0}
      0 represents a 'right wing bias'. 180 represents a 'left wing bias'.
      270 represents an extremist bias. 90 represents a centrist bias.
      Note that 359 is 1 away from 0 so would be a right wing bias.
      For example, if the webpage is an extremist right wing webpage,
      the output should be between 0 and 270, something like:
      {"angle": 315}.
      Everything else in this prompt is the text:
      ${content}
    `;

  const completion = await new OpenAI().chat.completions.create({
    messages: [
      {
        role: "system",
        content: `You are a machine that only returns and replies with valid,
              iterable RFC8259 compliant JSON in your responses`,
      },
      {
        role: "user", content: prompt,
      },
    ],
    model: "gpt-4", // gpt-3.5-turbo is cheap, trying 4-turbo
  });
  try {
    const position = JSON.parse(completion.choices[0].message.content);
    if (position.angle == null) {
      functions.logger.error(`Invalid decision: ${position}`);
      return;
    }
    admin.firestore()
        .collection("posts")
        .doc(post.pid)
        .update({
          aiBias: {position: position},
        });
  } catch (e) {
    functions.logger.error(`Invalid decision: ${e}`);
    functions.logger.error(completion);
    return;
  }
};


exports.applyVoteToBias = async function(pid, vote, {add = true}) {
  const postRef = admin.firestore().collection("posts").doc(pid);

  try {
    await admin.firestore().runTransaction(async (t) => {
      const doc = await t.get(postRef);

      if (!doc.exists) {
        functions.logger.error(`Post ${pid} does not exist!`);
        return;
      }

      const post = doc.data();
      let newBiasPosVal;

      if (post.voteCountBias == null ||
        post.voteCountBias <= 0 ||
        post.userBias === null) {
        if (!add) {
          functions.logger.error(`Cannot remove vote in ${pid}, empty!`);
          return;
        }
        newBiasPosVal = vote.bias.position.angle;
      } else if (post.voteCountBias == 1 && !add) {
        newBiasPosVal = null;
      } else {
        let direction = getDirection(post.userBias.position.angle,
            vote.bias.position.angle);
        direction = add ? direction :
          direction == "clockwise" ? "counterclockwise" : "clockwise";
        //
        const dist = getDistance(post.userBias.position.angle,
            vote.bias.position.angle);
        const magnitude = dist / (post.voteCountBias + (add ? 1.0 : -1.0));

        //
        newBiasPosVal = addPosition(post.userBias.position.angle, magnitude,
            direction);
      }

      t.update(postRef, {
        userBias: newBiasPosVal !== null ?
        {position: {"angle": newBiasPosVal}} : null,
        voteCountBias: FieldValue.increment(add ? 1 : -1),
      });
    });
  } catch (e) {
    functions.logger.error(e);
  }
};

// tests
// console.log(getDirection(0,230)); //clockwise
// console.log(getDirection(270,275)); //counterclockwise
// console.log(getDirection(275,230)); //clockwise
// console.log(getDirection(40,181)); //counterclockwise
// console.log(getDirection(40,280)); //clockwise
// console.log(getDirection(0,180)); //counterclockwise
// console.log(getDirection(180,0)); //clockwise
// console.log(getDirection(272,92)); //counterclockwise
// console.log(getDirection(270,90)); //clockwise
// console.log(getDirection(90,270)); //counterclockwise
const getDirection = function(currAngle, newAngle) {
  // Normalize angles to be in the range [0, 360)
  const angle1 = (currAngle + 360) % 360;
  const angle2 = (newAngle + 360) % 360;

  const angularDistance = (angle2 - angle1 + 360) % 360;

  if (angularDistance == 180) {
    // need this because of JS 0 falsy
    if (angle1 == 0) return "counterclockwise";
    if (angle2 == 0) return "clockwise";
    // no value if on good/bad pole. Breaking case!!
    if (angle1 == 90) return "counterclockwise";
    if (angle1 == 270) return "clockwise";
    // otherwise move to center
    if (angle1 > 90 && angle1 < 270) return "clockwise";
    return "counterclockwise";
  }

  if (angularDistance > 180) return "clockwise";
  else return "counterclockwise";
};

const getDistance = function(currAngle, newAngle) {
  const delta = Math.abs(currAngle - newAngle);
  return Math.min(delta, 360.0 - delta);
};

const addPosition = function(currAngle, magnitude, direction) {
  if (direction != "clockwise" && direction != "counterclockwise") {
    functions.logger.error("Invalid direction");
    return;
  }
  const newAngle = direction == "clockwise" ?
      currAngle - magnitude : currAngle + magnitude;

  return (newAngle + 360) % 360;
};

