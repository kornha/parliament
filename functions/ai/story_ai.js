/* eslint-disable max-len */
const functions = require("firebase-functions");
const {OpenAI} = require("openai");
const {updatePost, getRecentStories, createStory, getPostsForStory, updateStory, getStory} = require("../common/database");
const {Timestamp} = require("firebase-admin/firestore");
const {v4} = require("uuid");
const {getOpenApiKey} = require("./llm");

exports.generateStoryForPost = async function(post) {
  // last 2 days
  const starttime = Timestamp.now().toMillis() - 24 * 2 * 60 * 60 * 1000;
  const stories = await getRecentStories(starttime);

  const prompt =
    `
        You are given a post, and a list of stories. The goal is to determine which story
        the post belongs to. If the post does not belong to any story, you will respond with a null value.
        This will trigger the creation of a new story (in a different process).
        
        A post is an article or social media post. It is said to "belong" to a story, 
        if the post appears to be talking about not only the same topic, but the same specific event as well.
        For example, if the post is about a specific protest, and the story is about the same protest, 
        they belong together. However, if the post is about the same broader event, but not related the protest, 
        they do not belong toegther.  

        HERE IS THE POST IN QUESTION:
        TITLE: ${post.title}
        BODY: ${post.description}
        URL: ${post.url}

        HERE ARE THE STORIES:
        ${stories.map((_story) => "SID:" + _story.sid + "\nTITLE:" + _story.title + "\nBODY:" + _story.description).join("\n")}

        Output the following JSON;
        IF THE POST BELONGS TO A STORY: {"sid": "sid from the story that the post belongs to"}
        IF THE POST DOES NOT BELONG TO A STORY: {"sid": null}
   `;

  const completion = await new OpenAI(getOpenApiKey()).chat.completions.create({
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

    // sanity check the story exists
    let story = null;
    if (generation.sid) {
      story = await getStory(generation.sid);
    }

    if (story != null) {
      updatePost(post.pid, {sid: generation.sid});
    } else {
      const sid = v4();
      const story = {
        sid: sid,
        // TODO: Make nullable
        title: "Title is being generated.", // set these here since they are required
        description: "Description is being generated.", // set these here since they are required
        createdAt: Timestamp.now().toMillis(),
        updatedAt: Timestamp.now().toMillis(),
        locations: [],
      };
      const success = await createStory(story);
      if (!success) {
        functions.logger.error(`Could not create story: ${story}`);
        updatePost(post.pid, {status: "error"});
        return;
      }
      updatePost(post.pid, {sid: story.sid});
    }
  } catch (e) {
    functions.logger.error(`Invalid decision: ${e}`);
    functions.logger.error(completion);
    // Do we need this? stops infinite loop
    updatePost(post.pid, {status: "error"});
    return;
  }
};

// TODO: sinconsistent that this uses sid but the above uses post
exports.generateStoryAiFields = async function(sid) {
  if (!sid) {
    functions.logger.error(`Could not generate AI fields for story: ${sid}`);
    return;
  }

  const story = await getStory(sid);

  if (!story) {
    functions.logger.error(`Could not generate AI fields for story: ${story}`);
    return;
  }

  const posts = await getPostsForStory(story.sid);
  if (!posts) {
    functions.logger.error(`Could not get posts for story: ${story.sid}`);
    return;
  }

  const prompt =
    `
       You are given a list of posts (articles or social posts), and a story (if any).
       Your goal is to write a title, description, and list the countries for the story, based on the posts.
       The title and description will be strings, and the country locations will be an array of 2 letter country codes.
       The story may already have a title, description and list of countries. 
       If they are still valid, you can simply return these. 
       However, bew information may have come in which make them out of date, or incorrect. 
       Write a very clear title, that is non-biased. Write a clear description that is non-biased as well.
       Return a list of locations ordered by most to least relevant. 
       If there is one location that is fine, but if there are multiple, return them all. 
       Don't include irrelevant locations.
      
       Here are the posts:
        ${posts.map((_post) =>
    "TITLE:" + _post.title +
    "\nDESCRIPTION:" + _post.description +
    "\nSOURCE (if any): " + _post.url +
    "\nBODY (if any): " + _post.body +
    "\nLOCATIONS (if any): " + _post.locations?.map((_location) => _location).join(",") ?? "[]")
      .join("\n")}

       Output JSON: 
       {"title": "title", "description": "description", "locations": ["2 letter counter code"]}
   `;

  const completion = await new OpenAI(getOpenApiKey()).chat.completions.create({
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
    if (generation == null || generation.title == null || generation.description == null) {
      functions.logger.error(`Invalid generation: ${generation}`);
      return;
    }
    updateStory(story.sid, {
      "title": generation.title,
      "description": generation.description,
      "updatedAt": Timestamp.now().toMillis(),
    });
  } catch (e) {
    functions.logger.error(`Invalid decision: ${e}`);
    functions.logger.error(completion);
    return;
  }
};

