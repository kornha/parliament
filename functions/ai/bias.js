/* eslint-disable require-jsdoc */
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
const {logger} = require("firebase-functions/v2");

// TODO: could abstract these
const applyVoteToBias = async function(pid, vote, {add = true}) {
  const postRef = admin.firestore().collection("posts").doc(pid);

  try {
    await admin.firestore().runTransaction(async (t) => {
      const doc = await t.get(postRef);

      if (!doc.exists) {
        logger.error(`Post ${pid} does not exist!`);
        return;
      }

      const post = doc.data();
      let newBiasPosVal;

      if (post.voteCountBias == null ||
        post.voteCountBias <= 0 ||
        post.userBias === null) {
        if (!add) {
          logger.error(`Cannot remove vote in ${pid}, empty!`);
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
    logger.error(e);
  }
};

const applyDebateToBias = async function(pid, winningPosition, {add = true}) {
  const postRef = admin.firestore().collection("posts").doc(pid);

  try {
    await admin.firestore().runTransaction(async (t) => {
      const doc = await t.get(postRef);

      if (!doc.exists) {
        logger.error(`Post ${pid} does not exist!`);
        return;
      }

      const post = doc.data();
      let newBiasPosVal;

      if (post.debateCountBias == null ||
        post.debateCountBias <= 0 ||
        post.debateBias === null) {
        if (!add) {
          logger.error(`Cannot remove debate bias in ${pid}, empty!`);
          return;
        }
        newBiasPosVal = winningPosition.angle;
      } else if (post.debateCountBias == 1 && !add) {
        newBiasPosVal = null;
      } else {
        let direction = getDirection(post.debateBias.position.angle,
            winningPosition.angle);
        direction = add ? direction :
          direction == "clockwise" ? "counterclockwise" : "clockwise";
        //
        const dist = getDistance(post.debateBias.position.angle,
            winningPosition.angle);
        const magnitude = dist / (post.debateCountBias + (add ? 1.0 : -1.0));

        //
        newBiasPosVal = addPosition(post.debateBias.position.angle, magnitude,
            direction);
      }

      t.update(postRef, {
        debateBias: newBiasPosVal !== null ?
        {position: {"angle": newBiasPosVal}} : null,
        debateCountBias: FieldValue.increment(add ? 1 : -1),
      });
    });
  } catch (e) {
    logger.error(e);
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
    logger.error("Invalid direction");
    return;
  }
  const newAngle = direction == "clockwise" ?
      currAngle - magnitude : currAngle + magnitude;

  return (newAngle + 360) % 360;
};

module.exports = {
  applyVoteToBias,
  applyDebateToBias,
  getDirection,
  getDistance,
  addPosition,
};


// DEPRECATED
// exports.computeBias = async function(post) {
//   const content = await getTextContentForPost(post);

//   if (!content) {
//     logger.error(`Invalid content for ${post.url}, ${content}`);
//     return;
//   }
//   const prompt = `You will be given text from a webpage.
//         Determine the bias of a webpage. Output should be the following:
//         {"angle": 0.0-360.0}
//         0 represents a 'right wing bias'. 180 represents a 'left wing bias'.
//         270 represents an extremist bias. 90 represents a centrist bias.
//         Note that 359 is 1 away from 0 so would be a right wing bias.
//         For example, if the webpage is an extremist right wing webpage,
//         the output should be between 0 and 270, something like:
//         {"angle": 315}.
//         Everything else in this prompt is the text:
//         ${content}
//       `;

//   const completion = await new OpenAI(
//   getOpenApiKey(),
// ).chat.completions.create({
//     messages: [
//       {
//         role: "system",
//         content: `You are a machine that only returns and replies with valid,
//                 iterable RFC8259 compliant JSON in your responses`,
//       },
//       {
//         role: "user", content: prompt,
//       },
//     ],
//     model: "gpt-4", // gpt-3.5-turbo is cheap, trying 4-turbo
//   });
//   try {
//     const position = JSON.parse(completion.choices[0].message.content);
//     if (position.angle == null) {
//       logger.error(`Invalid decision: ${position}`);
//       return;
//     }
//     admin.firestore()
//         .collection("posts")
//         .doc(post.pid)
//         .update({
//           aiBias: {position: position},
//         });
//   } catch (e) {
//     logger.error(`Invalid decision: ${e}`);
//     logger.error(completion);
//     return;
//   }
// };

