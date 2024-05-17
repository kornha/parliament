/* eslint-disable max-len */
const _ = require("lodash");
const {millisToIso} = require("../common/utils");

const findStoriesPrompt = function(post, stories) {
  return `You will be given a Post and a list of Stories (can be empty).\nPost: ${postToJSON(post)}\nStories: ${storiesToJSON(stories)}\nOutput JSON ordered from most to least relevant Story. Do not output irrelevant Stories. Do not output Claims.`;
};

const findStoriesAndClaimsPrompt = function(post, stories, claims) {
  return `You will be given a Post, a list of Stories (cannot be empty), and a list of Claims (can be empty).\nPost: ${postToJSON(post)}\nStories: ${storiesToJSON(stories)}\nClaims: ${claimsToJSON(claims)}\nOutput the Stories in the order they are inputted, but now include Claims (either create a new one or add an existing one), and if the Post is for or against a Claim be sure to list its in the Claim's pro/against.`;
};

const generateImageDescriptionPrompt = function(photoURL) {
  const messages = [];
  messages.push({type: "text",
    text: `Generate a detailed description for the following image.
    This description will be used in vector search for similar content.`,
  });
  messages.push({type: "image_url", image_url: {url: photoURL}});
  messages.push({type: "text", text: `
    Output format:{ "description": "A detailed description of the image"}
  `});
  return messages;
};

// //////////////////////////////////////
// TRAINING PROMPTS
// //////////////////////////////////////

const findStoriesTrainingPrompt = function(post, stories) {
  // Prepare the initial set of messages with description texts
  const messages = [
    {type: "text", text: `
      You will be given a Post and a list of Stories (can be empty).

      Description of a Post:
      ${postDescriptionPrompt()}

      Description of a Story:
      ${storyDescriptionPrompt()}

      Your goal is to find all the Stories (aka events) that the Post belongs to, or makes a clear reference or claim to.
      A Story is typically an event, with a specific time and place. Sometimes, however, Stories do not have a time and place and instead are a subject or topic.

      Since a Story is an event, you will ONLY return the Story if the Post directly mentions the event or makes a claim about the event.
      You will also create "new" Stories, if the Post mentions an event/topic that is not passed in the list of stories.

      Here's a high level example that explains how to decide the granularity of a Story:
      ${findStoryExample()}
    `},
  ];

  messages.push({type: "text", text: `Here is the Post: ${postToJSON(post)}`});

  // removing image for now
  // if (post.photo?.photoURL) {
  //   messages.push({type: "image_url", image_url: {url: post.photo?.photoURL}});
  // }

  // Add messages for stories
  if (_.isEmpty(stories)) {
    messages.push({type: "text", text: "Here are the Stories (if any): []"});
  } else {
    messages.push({type: "text", text: "Here are the Stories (if any): "});
    stories.forEach((story) => {
      messages.push({type: "text", text: storyToJSON(story)});
      // if (story.photoURL) {
      //   messages.push({type: "image_url", image_url: {url: story.photoURL}});
      // }
    });
  }

  messages.push({type: "text", text: "If you are creating a new Story, follow these instructions:"});
  messages.push({type: "text", text: newStoryPrompt()});

  messages.push({type: "text", text: "Output the following JSON ordered from most to least relevant Story:"});
  messages.push({type: "text", text: `{"stories":[${storyJSONOutput()}, ...]}`});

  return messages;
};


const findStoriesAndClaimsTrainingPrompt = function(post, stories, claims) {
  // Assuming each post and story has an 'photoURL' property
  const messages = [
    {type: "text", text: `
      You will be given a Post, a list of Stories (can be empty), and a list of Claims (can be empty).

      Description of a Post:
      ${postDescriptionPrompt()}

      Description of a Story:
      ${storyDescriptionPrompt()}

      Description of a Claim:
      ${claimsDescriptionPrompt()}

      The Stories represent all Stories the Post is currently associated with.
      The Claims represent all Claims that are already associated with all these Stories, as well as Claims that are associated with all other Posts already associated with these Stories.

      Your goal is to output the Stories EXACTLY as they are, BUT with the following change.
      
      1) If the Post makes a Claim that is already in the list of Claims, this Claim should be added to the Story, and the Post should be added to the "pro" or "against" list of the Claim.
      1a) DO NOT OUTPUT A CLAIM THAT THE POST DOES NOT MAKE EVEN IF IT IS PART OF THE STORY ALREADY.
      1b) DO NOT OUTPUT OTHER PIDS THAT ARE ALREADY PART OF THE PRO OR AGAINST LIST OF THE CLAIM.
      2) If the Post makes a Claim that is inherently new (there is no matching Claim in the list), this Claim should be created and added to the Story, and the Post should be added to the "pro" or "against" list of the Claim.

      Here is how to output a new Claim:
      ${newClaimPrompt()}

      Here's a high level example:
      ${findClaimsAndStoriesExample()}
    `},
  ];

  messages.push({type: "text", text: `Here is the Post: ${postToJSON(post)}`});

  // removing images for now
  // if (post.photo?.photoURL) {
  //   messages.push({type: "image_url", image_url: {url: post.photo?.photoURL}});
  // }

  if (_.isEmpty(stories)) {
    messages.push({type: "text", text: "There are no stories associated with this post."});
  } else {
    messages.push({type: "text", text: `Here are the Stories:`});
    stories.forEach((story) => {
      messages.push({type: "text", text: `${storyToJSON(story)}`});
      // if (story.photoURL) {
      //   messages.push({type: "image_url", image_url: {url: story.photoURL}});
      // }
    });
  }

  if (_.isEmpty(claims)) {
    messages.push({type: "text", text: "There are no claims associated with the stories/posts."});
  } else {
    messages.push({type: "text", text: `Here are the Claims:`});
    claims.forEach((claim) => {
      messages.push({type: "text", text: `${claimToJSON(claim)}`});
    });
  }

  messages.push({type: "text", text: "Output the stories in the same order as they were passed in, but with the new Claims added to the Stories, as follows:"});
  messages.push({type: "text", text: `{"stories":[${storyJSONOutput(true)}, ...]}`});

  return messages;
};

//
// Secondary Training Promps
//

//
// Story
//

const newStoryPrompt = function() {
  return `
  The Title and Description of the story should be the most neutral, and the most minimal vector distance for all posts.
  The Title should be 2-6 words, and the Description should be 1-5 sentences.
  They should be as neutral as possible, and include language as definitive only if consensus is clear.
  'happenedAt' is the time for when the event in the story happened. If the time is not clear, output the time that was passed in, which can be null.
  'importance' is a value between 0.0 and 1.0, where 1.0 would represent insanely urgent news, like the breakout of WW3, and 0.0 represents non-news, like a pure opinion (that isn't newsworthy), or a cat video.
  `;
};

const storyDescriptionPrompt = function() {
  return `
        A Story is a subject. Two Posts are discussing the same Story if they are talking about the same thing.
        A Story is something has a time and a place, and is generally an event. Sometimes, however, a Story is a subject or topic. We know if two Posts belong to the same Story if they are clearly talking about the same thing.

        The "sid" is the Story ID, which is a unique identifier for the Story.

        The "title" is a very concise, 2-7 word title of the Story. The title should be maximally interesting, and generally should scope the story to a specific event.
        The "description" is a 1-5 sentence description of the story. The description should be as descriptive as possible.
        Both the title and description should be extremely neutral.

        The "happenedAt" is the time that the event happened at, or our best guess.
        
        The "importance" is a value between 0.0 and 1.0, where 1.0 would represent insanely urgent news, like the breakout of WW3, and 0.0 represents non-news, like a pure opinion (that isn't newsworthy), or a cat video.
        Generally, a Story will have a 0.5. You can judge the importance by the subject matter, but also by the urgency in the posts.

        A Story is has several other fields.
        Primarily, a Story is a collection of Posts (social media postings or articles), which inform the Claims in the story. 
        Claims are a Statement about the Story that have supporters and or refuters.
        A Story maybe have a Bias and Credibility score as well.
    `;
};

const storyJSONOutput = function(claims = false) {
  return `{"sid":ID of the Story or null if Story is new, "title": "title of the story", "description": "the description of the story is a useful vector searchable description", "importance": 0.0-1.0 relative importance of the story, "happenedAt": ISO 8601 time format that the event happened at, or null if it cannot be determined${claims ? `, "claims":[${claimJSONOutput()}, ...]` : ""}}`;
};

//
// Post
//

const postDescriptionPrompt = function() {
  return `
        A Post is a social media posting or an article. It can come from X (aka Twitter), Facebook, Instagram, Reddit, Tiktok or other social sources.
        It may also be a news article published online to some platform.
        A Post can have a title, a description, and a body, the latter two of which are optional.
        A Post may have images, videos or other media. You may only be given a description of the image, which you will use to judge.
        A Post has an author, which we call an Entity.
        A Post has a timestamp, which is the time the (original) Post was created. We call this "sourceCreatedAt".
        A Post may also be assigned Bias and Credibility scores. 
        Bias refers to the political bias of the Post, and Credibility refers to how confident we think the Post is to be true.
        `;
};

//
// Claims
//

const claimsDescriptionPrompt = function() {
  return `
            A Claim is a statement that has "pro" and "against" list of Posts either supporting or refuting the Claim.
            A Claim has a "value" field, which is the statement itself.
            A Claim has a "pro" field, which is a list of Posts that support the Claim.
            A Claim has an "against" field, which is a list of Posts that refute the Claim.
            A Claim has a "context" field, which provides more information about the Claim, and helps for search.
        `;
};

const newClaimPrompt = function() {
  return `
        The value of the Claim should be a statement that is either supported or refuted by the Post.
        Note that a Claim is not an Opinion. If a Post expresses an opinion, it is not a Claim and do not output it as such.
        If you are creating a new Claim, the value should be the statement in the "positive" sense, and the Post should be either "pro" or "against" the Claim.
        Eg., if you want to make a Claim that "Iran did not close airspace over Tehran" (and the Post supports this), the Claim should be "Iran closed airspace over Tehran" and the Post should be "against" the Claim.
        When outputting pro and against, you should output the post ID (pid) of the post that is either for or against the claim inside of an array, for example against: [pid] instead of against: pid.
        Eg., a Post titled "I stand behind what I tweeted on October 7th. Can you say the same?" would not be a Claim, since it is expressing an opion.
        Note again that Claims are generally listed in the positive;
        A Claim such as: "The UN has not imposed sanctions on Hamas leadership" would be better worded "The UN has imposed sanctions on Hamas leadership".
        `;
};

const claimJSONOutput = function() {
  return `{"cid":ID of the Claim or null if the Claim is new, "value": "text of the claim", "pro": [pid of the post] or [] if post is not in support, "against": [pid of the post] or [] if the post is not against the claim"}`;
};

//
// Credibility and Bias
//

const credibilityDescriptionPrompt = function() {
  return `
            Creditability Score ranges from 0.0 - 1.0 and assesses how likely we think something is to be true.
            A score of 0.5 indicates total uncertainty, about the subject (which could be a Claim, Entity, Post, or other object with a Credibility Score).
            0.0 indicates complete certainty that the subject is wrong/false, while 1.0 indicates complete certainty that the subject is correct/true.
            Hence, 0.0 and 1.0 are near impossible to achieve.
            For example, a Credibility Score on 0.8 on a Post (social media posting or a news article) would indicate that the Post is reliable.
            In the case of an Entity (author of Post), a Credibility Score of 0.8 would indicate that the Entity is very reliable. 
            The score is typically mathematically computed, but can generated in some instances.
            Practically, the scores are designed to have over 0.75 as strong confidence, and under 0.25 as strong disbelief.
            Credibility Scores can also optionally be assigned a reason why the score was given in certain contexts.
        `;
};

const credibilityJSONOutput = function() {
  return `Output this JSON: {"credibility": 0.0-1.0, "reason": "why"}`;
};

const biasDescriptionPrompt = function() {
  return `
            Bias Scores range from 0.0 - 360.0 and assesses the political bias of the subject.
            A score of 0.0 indicates a right wing bias, 180.0 indicates a left wing bias, 270.0 indicates an extremist bias, and 90.0 indicates a centrist bias.
            The score is typically mathematically computed, but can generated in some instances.
            When done mathematically, the scores are designed to seat people in a circle, by minimizing the distance of their political positions.
            With this underpinning, if we consider the political Right to mean "Conservative" and Left to mean "Liberal",
            we can obtain a circular distribution of political bias.
            A score of 359.0 would be 1 away from 0.0, and hence a heavy right wing bias.
            For example, a Bias Score of 315.0 on a Post (social media posting or a news article) would indicate that the Post is extremely right.
            Trains of extremeism include: offensiveness, decontextualization, appearance of bot-like or propaganda-like behavior, unreasonable political onesidedness, and more.
            Bias Scores can also optionally be assigned a reason why the score was given in certain contexts.
        `;
};

const biasJSONOutput = function() {
  return `Output this JSON: {"angle": 0.0-360.0, "reason": "why"}`;
};

const findStoryExample = function() {
  return `
    It can be said two Posts belong to the Story if they are clearly talking about the same thing.
    There is a level of judgement here; assume a Story is HIGHLY granular, but NOT EXTREMELY so.

    Let's say this is the post:
    "Iran state media removes report about closing airspace over Tehran after warnings of possible strike on Israel"
    sourceCreatedAt (time source of the post was published, different from the Story's 'happenedAt'): "2021-05-10T12:00:00Z" 

    While this Post mentions Iran and a report about closing airspace over Tehran, in conjunction with Israel, you can infer that there is an urgent tension between Iran and Israel. There are actually 2 Stories here; one about Iran closing airspace, and another about Iran threatening Israel.

    Hence, a Title for the Story could be: "Iran Closes Airspace", and the other Story title would be "Iran threatens Israel".
    And the importance of the Story would be perhaps 0.5 and 0.7, respectively, significant events, but perhaps not world changing.

    The Description (of the first story could be) could be: "Amidst rising tensions between Iran and Israel, it was reported by Iran state media that they closed airspace over Tehran. This post wast later removed, and the situation remains ongoing."

    Now let's say there's another Post that comes in. It says: 
    "Tesla is in early discussions with Reliance Industries about a possible joint venture to build an electric-vehicle manufacturing facility in India, report says"
    sourceCreatedAt: "2021-05-10T12:30:00Z"

    This post clearly belongs to another Story, (which we will omit here).

    Now let's say there's a third Post that comes in. It says: 
    "Defense Minister Gallant:
    Whoever attacks Israel will counter strong defenses, followed by forceful strike in their territory; our enemies are unaware of the surprises we're preparing; Israel knows how to respond quickly across the Middle East."
    sourceCreatedAt: "2021-05-10T13:00:00Z"

    This Post is clearly related to the first Post; the first Post mentions a possible attack from Iran on Israel, and this latter Post mentions how Israel will respond to any threats. This Post is talking about Iran striking Iran, "Iran threatens Israel" Story from above 
    Furthermore, since the sourceCreatedAt (time the post was made) is similar, they are likely talking about the same subject.
    
    Hence the Title of the Story might be updated, "Iran and Israel Trade Threats", and now the description of the Story could be updated to include the new information.
    As it appears the Story has gotten a bit more urgent, the importance could be updated to 0.75.

    For example; the Description could be: "Iran hinted at possible warnings of a strike against Israel, to which Gallant replied Israel will respond in turn"
  `;
};

const findClaimsAndStoriesExample = function() {
  return `
    Let's say we have a Post that says: 
    "Iran state media removes report about closing airspace over Tehran after warnings of possible strike on Israel".
    sourceCreatedAt: "2021-05-10T12:00:00Z"

    And we have a Story (1) that has the Title: 
    "Iran and Israel Trade Threats"
    and another Story (2) that has the Title:
    "Iran Closes Airspace"

    Story 1 should have the Claims:
    1) "Iran threatens strike on Israel"

    Story 2 should have the Claims:
    1) "Iran closes airspace over Tehran"
    2) "Iran media removed their report about closing airspace"

    Put simply, a Claim is any factual Claim about a Story (but is not an opinon).
  `;
};

// /////////////////////////////////////
// Prompt JSON
// ////////////////////////////////////

/**
 * Converts ONLY SELECT DATA from a Post object to a prompt JSON string
 * USING JSON.stringify() will convert tons of data like vector
 * @param {Object} post
 * @return {string} JSON string
 * */
const postToJSON = function(post) {
  const formatted = {
    pid: post.pid,
    title: post.title,
    description: post.description,
    body: post.body,
    photoDescription: post.photo?.description,
    sourceCreatedAt: millisToIso(post.sourceCreatedAt),
    credibility: post.credibility,
    bias: post.bias,
    // used for tuning, comment in production code
    url: post.url,
  };

  return JSON.stringify(formatted);
};

const claimToJSON = function(claim) {
  return JSON.stringify(claim, ["cid", "value", "pro", "against", "context"]);
};

/**
 * Converts an array of Claim objects to a prompt JSON string
 * @param {Array<Claim>} claims
 * @return {string} JSON string
 * */
const claimsToJSON = function(claims) {
  return "[" + claims.map((claim) => claimToJSON(claim)) + "]";
};

/**
 * Converts ONLY SELECT DATA from a Story object to a JSON string
 * USING JSON.stringify() will convert tons of data like vector
 * @param {Object} story
 * @return {string} JSON string
 * */
const storyToJSON = function(story) {
  const formatted = {
    sid: story.sid,
    title: story.title,
    description: story.description,
    photoDescription: story.photo?.description,
    importance: story.importance,
    happenedAt: millisToIso(story.happenedAt),
  };

  return JSON.stringify(formatted);
};

/**
 * Converts an array of Story objects to a prompt JSON string
 * @param {Array<Story>} stories
 * @return {string} JSON string
 * */
const storiesToJSON = function(stories) {
  return "[" + stories.map((story) => storyToJSON(story)) + "]";
};

module.exports = {
  findStoriesPrompt,
  findStoriesAndClaimsPrompt,
  findStoriesAndClaimsTrainingPrompt,
  findStoriesTrainingPrompt,
  //
  generateImageDescriptionPrompt,
  //
  //
  storyDescriptionPrompt,
  storyJSONOutput,
  credibilityDescriptionPrompt,
  credibilityJSONOutput,
  biasDescriptionPrompt,
  biasJSONOutput,
  //
  postToJSON,
  storiesToJSON,
  storyToJSON,
  claimsToJSON,
  claimToJSON,
};


