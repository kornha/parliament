/* eslint-disable max-len */
const functions = require("firebase-functions");
const {OpenAI} = require("openai");
const {getPostsForStory, getStory, updatePost} = require("../common/database");

// bias, credibility, importance
exports.generatePostAiFields = async function(post) {
  // handle this later
  if (!post.sid) {
    return;
  }

  // fetch all posts in this story
  const posts = await getPostsForStory(post.sid);
  const story = await getStory(post.sid);

  const prompt =
    `
        You are given a post, which can be an article or social media posting, 
        and the story that this post is a subset of.
        You will also be given other posts in the same story for context.
        Determine the importance, credibility, and importance of the post.

        CREDIBILITY:
        Additionally, assess the credibility of the overall story.
        Creditability should range from 0.0 - 10.0.
        If ALL claims are backed by other posts in the story give it a ten.
        Use other posts in the story to validate claims.
        If that is not sufficient, search on the internet to validate claims.
        If you are unsure or claims are still developing, give it a 5.
        If claims are proven entirely false, give it a 0.0. In beteween values use your judgement.
        Also, include a reason for your credibility assessment.
        output: {"credibility": 0.0-10.0, "reason": "why"}

        BIAS:
        Additionally, determine the bias of the story. Output should be the following:
        {"angle": 0.0-360.0}. Note that it should be in this "position" object json format, with "angle" as the key.
        0 represents a 'right wing bias'. 180 represents a 'left wing bias'.
        270 represents an extremist bias. 90 represents a centrist bias.
        Note that 359 is 1 away from 0 so this would be a heavy right wing bias.
        For example, if the webpage is an extremist right wing webpage,
        the output should be between 0 and 270, something like:
        {"angle": 315}. Also include a reason for your bias assessment.
        output: {"bias": {"position": {"angle": 0.0-360.0}, "reason": "why"}}
        Note that the bias output is a json object with a "position" object inside it.

        IMPORTANCE:
        Finally, assess the importance of a post by analyzing the text in the post
        and determining how well written it is, compared to other posts in the same story, 
        while also considering how important the overall story is. 
        Also consider the source of the post, if available. 
        Credible sources, determined by the credibility above, should be given a higher importance. 
        You may also consider the importance of other posts in the story.
        Importance should range from 0 - 10 (integers only).
        0 would be a completely pointless post. 
        5 would be well written content 
        that does not distinguish much from other posts in the story.
        7 would be distinguished content in an an important story.
        10 would be extremely distinguished content in an extremely important story.
        output: {"importance": 0-10}

        HERE IS THE POST IN QUESTION:
        TITLE: ${post.title}
        BODY: ${post.description}

        HERE IS THE STORY:
        TITLE: ${story.title}
        DESCRIPTION: ${story.description}

        HERE ARE THE OTHER POSTS IN THE STORY, IF ANY:
        ${posts.map((_post) => _post.pid == post.pid ? "" :
         "TITLE" + _post.title + "\nBODY:" + _post.description).join("\n")}

        Output the following JSON;
        {"credibility": {"value": 0.0-10.0, "reason": "why"}, "bias": {"position": {"angle": 0.0-360.0}, "reason": "why"}, "importance": 0-10}
   `;

  const completion = await new OpenAI().chat.completions.create({
    messages: [
      {
        role: "system",
        content: `You are a machine that only returns and replies with valid,
                iterable RFC8259 compliant JSON in your responses 
                with no leading or trailing characters`,
      },
      {role: "user", content: prompt},
    ],
    // gpt-4-1106-preview for 128k token (50 page) context window
    model: "gpt-4-1106-preview",
    response_format: {"type": "json_object"},
  });
  try {
    const generation = JSON.parse(completion.choices[0].message.content);
    if (generation == null) {
      functions.logger.error(`Invalid generation: ${generation}`);
      return;
    }

    updatePost(post.pid, {
      aiCredibility: generation.credibility,
      aiBias: generation.bias,
      importance: generation.importance,
    });
  } catch (e) {
    functions.logger.error(`Invalid decision: ${e}`);
    functions.logger.error(completion);
    return;
  }
};

