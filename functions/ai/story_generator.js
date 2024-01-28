/* eslint-disable max-len */
const {OpenAI} = require("openai");
const functions = require("firebase-functions");
const {getStories, getArticles} = require("../common/utils");
const {Timestamp} = require("firebase-admin/firestore");
const {createPost} = require("../common/database");
const maxArticlesPerPost = 10;
const maxPostsToCreate = 10;


exports.generateStories = functions.https.onCall(async (data, context) => {
  const stories = await getStories();
  if (!stories) {
    throw new functions.https.HttpsError("not-found", "No stories for the window.");
  }
  for (let i = 0; i < maxPostsToCreate; i++) {
    const story = stories[i];
    await generatePost(story, articles);
    const articles = await getArticles(story);
    generatePost(story, articles);
  }
  return {complete: true};
});

const generatePost = async function(story, articles) {
  if (!articles || articles.length == 0) {
    return;
  }

  let content = `STORY TITLE: ${story.name} ` + "\n";
  content += `STORY SUMMARY: ${story.summary} ` + "\n";
  for (let j = 0; j < maxArticlesPerPost; j++) {
    const article = articles[j];
    if (!article) continue;
    content += `SOURCE: ${article.source.domain}\n `;
    content += `ARTICLE TITLE: ${article.title}\n `;
    content += `CONTENT: ${article.content}\n `;
  }


  const prompt = `You will be given a overarching story, 
        and a series of news articles on the topic.
        Write for me an ultra ENGAGING title, 
        and a short 1 sentence description of what happened. Your description should
        be very clear and only quote facts mentioned in the article.
        IMPORTANCE:
        Also assess the importance based on the text in the articles.
        If it is extremely urgent news give it a 10. If it is mundane give it a 1.
        Typically, things should have low importance, reserve an importance over 5 for rare situations.
        CREDIBILITY:
        Additionally, assess the credibility of the overall story. 
        If all claims are backed by all other articles give it a ten. 
        If you are unsure or claims are still developing, give it a 5.
        If claims are proven entirely false, give it a 1. In beteween values use your judgement.
        Also, include a reason for your credibility assessment.
        BIAS:
        Additionally, determine the bias of the story. Output should be the following:
        {"angle": 0.0-360.0}. Note that it should be in this "position" object json format, with "angle" as the key.
        0 represents a 'right wing bias'. 180 represents a 'left wing bias'.
        270 represents an extremist bias. 90 represents a centrist bias.
        Note that 359 is 1 away from 0 so would be a heavy right wing bias.
        For example, if the webpage is an extremist right wing webpage,
        the output should be between 0 and 270, something like:
        {"angle": 315}. Also include a reason for your bias assessment.
        Your output should be the following JSON;
        {title:"Ultra engaging article header", description:"short 1 sentence", importance:1-10, credibility:{value:1-10, reason:"why"}, bias:{position:{angle:0-360}, reason:"why"}
        Everything else in this prompt is the story and article text:
        ${content}
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

    const post = _toPost(story, articles, generation);
    createPost(post);
  } catch (e) {
    functions.logger.error(`Invalid decision: ${e}`);
    functions.logger.error(completion);
    return;
  }
};

const _toPost = function(story, articles, generation) {
  return {
    pid: story.id,
    title: generation.title,
    description: generation.description,
    status: "published",
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
    imageUrl: articles[0].imageUrl,
    importance: generation.importance,
    locations: story.topCountries,
    aiCredibility: generation.credibility,
    aiBias: generation.bias,
    // url: story.url,
    // source: story.source.name,
  };
};

exports.generateStoryData = async function(story, posts) {

};
