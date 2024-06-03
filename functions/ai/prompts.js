/* eslint-disable max-len */
const _ = require("lodash");
const {millisToIso} = require("../common/utils");

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

const findStoriesPrompt = function({post, stories, training = false, includePhotos = true}) {
  // Prepare the initial set of messages with description texts
  const messages = training ? [
    {type: "text", text: findStoriesForTrainingText()},
  ] : [];

  messages.push({type: "text", text: `Here is the Post: ${postToJSON(post, !includePhotos)}`});

  if (post.photo?.photoURL && includePhotos) {
    messages.push({type: "image_url", image_url: {url: post.photo?.photoURL}});
  }

  // Add messages for stories
  if (_.isEmpty(stories)) {
    messages.push({type: "text", text: "Here are the Stories (if any): []"});
  } else {
    messages.push({type: "text", text: "Here are the Stories (if any): "});
    stories.forEach((story) => {
      messages.push({type: "text", text: storyToJSON(story, !includePhotos)});
      if (!_.isEmpty(story.photos) && includePhotos) {
        story.photos.forEach((photo) => {
          messages.push({type: "image_url", image_url: {url: photo.photoURL}});
        });
      }
    });
  }

  messages.push({type: "text", text: "Output the following JSON ordered from most to least relevant Story:"});
  messages.push({type: "text", text: `{"stories":[${storyJSONOutput()}, ...]}`});

  return messages;
};


const findStoriesAndClaimsPrompt = function({
  post,
  stories,
  claims,
  training = false,
  includePhotos = true}) {
  // Assuming each post and story has an 'photoURL' property
  const messages = training ? [
    {type: "text", text: findStoriesAndClaimsForTrainingText()},
  ] : [];

  messages.push({type: "text", text: `Here is the Post: ${postToJSON(post, !includePhotos)}`});

  if (post.photo?.photoURL && includePhotos) {
    messages.push({type: "image_url", image_url: {url: post.photo?.photoURL}});
  }

  if (_.isEmpty(stories)) {
    messages.push({type: "text", text: "There are no stories associated with this post."});
  } else {
    messages.push({type: "text", text: `Here are the Stories:`});
    stories.forEach((story) => {
      messages.push({type: "text", text: `${storyToJSON(story, !includePhotos)}`});
      if (!_.isEmpty(story.photos) && includePhotos) {
        story.photos.forEach((photo) => {
          messages.push({type: "image_url", image_url: {url: photo.photoURL}});
        });
      }
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

// ///////////////////////////////////
// PROMPT TEXTUAL DESCRIPTIONS
// ///////////////////////////////////

//
// Story
//

const findStoriesForTrainingText = function() {
  return `
  You will be given a Post and a list of Stories (can be empty). Return all Stories that the Post makes reference to, in order of relevance. Do not return irrelevant Stories. Create new Stories if the Post mentions a Story but the Story is not in the input list, and update existing Stories if the Post provides new and relevant information.

  Description of a Post:
  ${postDescriptionPrompt()}

  Description of a Story:
  ${storyDescriptionPrompt()}

  In the output, you will return zero, one, or many of the passed-in Stories if the Post "is a part" of the Story, ie. the Post mentions the Story or makes a claim about the Story, and order from most to least relevant. If there are any udpdates to the Story from the new Post, you will output that updated information with the Story. Otherwise you will omit the Story from the output.
  You will also create "new" Stories, if the Post mentions an event that is not passed in the list of stories.

  Here's how you update/create Story fields, when necessary:
  ${newStoryPrompt()}

  Here's a high level example that explains this:
  ${findStoryExample()}
`;
};

const findStoriesAndClaimsForTrainingText = function() {
  return `
  You will be given a Post, a list of Stories (can be empty), and a list of Claims (can be empty).

  Description of a Post:
  ${postDescriptionPrompt()}

  Description of a Story:
  ${storyDescriptionPrompt()}

  Description of a Claim:
  ${claimsDescriptionPrompt()}

  The Stories represent all Stories the Post is currently associated with.
  The Claims represent all Claims that are already associated with all these Stories, as well as Claims that are associated with all other Posts already associated with these Stories.

  Your goal is to output the Stories EXACTLY as they are BUT with the following change.
  
  1) If the Post makes a Claim that is already in the list of Claims, this Claim should be added to the Story, and the Post should be added to the "pro" or "against" list of the Claim.
  1a) DO NOT OUTPUT A CLAIM THAT THE POST DOES NOT MAKE EVEN IF IT IS PART OF THE STORY ALREADY.
  1b) DO NOT OUTPUT OTHER PIDS THAT ARE ALREADY PART OF THE PRO OR AGAINST LIST OF THE CLAIM.
  2) If the Post makes a Claim that is inherently new (there is no matching Claim in the list), this Claim should be created and added to the Story, and the Post should be added to the "pro" or "against" list of the Claim.

  Here is how to output a new Claim:
  ${newClaimPrompt()}

  Here's a high level example:
  ${findClaimsAndStoriesExample()}
`;
};

const newStoryPrompt = function() {
  return `
  SID:
  SID should be null for new Stories, and copied if outputting an existing Story.

  Title, Description, Headline, Subheadline:
  All of these fields need to use maximally neutral language. Posts often will used biased language, so steer clear of that.
  The Title should be 2-6 words categorical description of the Story.
  Description should be 1-many sentences, and completely describes every detail we know about the Story.
  The Headline should be as ENGAGING as possible, and should be written in active tense. Eg., if a Title might be "Khameini addresses US students in a tweet", the Headline might be "Khameini: US students are on the right side of history".
  The Subheadline should be equally as engaging, and a far shorter description of the Story, 1-3 sentences. Eg, "Khameini's tweet to US students is a unusual bridge between the fundementalist Iranian regime and progressive students".

  HappenedAt:
  'happenedAt' is the time the event happened in the REAL WORLD, not the timestamp of the Posts. Determine when the Story "happenedAt" based on the time the Post(s) were created, as well as context in the Post(s). Eg., if a Post says "today Trump had a rally in the Bronx", and the Post 'sourceCreatedAt' is at 9PM Eastern, the "happenedAt" is the time of the rally, since 'day' is mentioned, our best guess would be 2PM ET (but outputted in ISO 8601 format).

  Lat/Long:
  the 'lat' and 'long' are the location of the event, or our best guess. If the Story is about a Trump rally in the Bronx, the lat and long should be in the Bronx. If the Story is about Rutgers U, the lat and long should be of their campus in NJ, at the closest location that can be determined. If the Post only mentions a person, the lat and long might be the country they are from. The lat and long should almost NEVER be null unless absolutely no location is mentioned or inferred.

  Importance:
  'importance' is a value between 0.0 and 1.0, where 1.0 would represent the most possible newsworthy news, like the breakout of WW3 or the dropping of an atomic bomb, and 0.0 represents complete non-news, like some non-famous person's opinion, or a cat video. 0.0-0.2 is non-news. 0.2-0.4 is interesting news to those who follow a subject. 0.4-0.6 is interesting news to even those who infrequently follow the topic. 0.6-0.8 is interesting news to everyone globally. 0.8-1.0 is extremely urgent news. When deciding importance, consider the language in the Post, eg "Breaking", the subject of the Story, and also consider the number of Posts in a Story. Note that just because a Post contains "Breaking" does not mean the Story is important.

  Photos:
  'photos' are, optionally, the photos that are associated with the Story. They should be ordered by most interesting, and deduped, removing not only identical but even very similar photos. If the Post has a photo that is relevant to the Story, it should be included in the Story's photos.
  `;
};

const storyDescriptionPrompt = function() {
  return `A Story is an event that happened.
  It is created from a collection of Posts that are 'talking about the same thing.'
  A Story has a title, a description, a headline, a subheadline, which are textual descriptions of the Story.
  A Story has a "happenedAt" timestamp, which represents when the event happened in the real world.
  A Story has an "importance" value, which is a number between 0.0 and 1.0, where 1.0 is the most possibly newsworthy event.
  A Story has a lat and long, which are the best estimates of the location of the Story.
  A Story may have photos, which are images that are associated with the Story.
  A Story may have Claims, which are statements that are either supported or refuted by the Posts.
  `;
};

const storyJSONOutput = function(claims = false) {
  return `{"sid":ID of the Story or null if Story is new, "title": "title of the story", "description": "the full description of the story is a useful vector searchable description", "headline" "short, active, engaging title shown to users", "subHeadline":"active, engaging, short description shown to users", "importance": 0.0-1.0 relative importance of the story, "happenedAt": ISO 8601 time format that the event happened at, or null if it cannot be determined, "lat": lattitude best estimate of the location of the Story, "long": longitude best estimate, "photos:[{"photoURL":url of the photo copied from the Post, "description": description of the photo copied from the Post},..list of UNIQUE photos taken from the Posts, ordered by most interesting]${claims ? `, "claims":[${claimJSONOutput()}, ...]` : ""}}`;
};

//
// Post
//

const postDescriptionPrompt = function() {
  return `A Post is a social media posting or an article. It can come from X (Twitter), Instagram, or other social sources.
        It may also be a news article published to an online platform.
        A Post can have a title, a description, and a body, the latter two of which are optional.
        A Post may have images, videos or other media. You may only be given a description of the image, which you will consider in place of an actual image. Otherwise you will be given a URL to the image after the post.
        A Post has an author, which we call an Entity.
        A Post has a "sourceCreatedAt" time which represents when the Post was originally created on the social/news platform.
        A Post can belong to a Story and have Claims.`;
};

//
// Claims
//

const claimsDescriptionPrompt = function() {
  return `A Claim is a statement that has "pro" and "against" list of Posts either supporting or refuting the Claim.
            A Claim has a "value" field, which is the statement itself.
            A Claim has a "pro" field, which is a list of Posts that support the Claim.
            A Claim has an "against" field, which is a list of Posts that refute the Claim.
            A Claim has a "context" field, which provides more information about the Claim, and helps for search.`;
};

const newClaimPrompt = function() {
  return `The value of the Claim should be a statement that is either supported or refuted by the Post.
        Note that a Claim is not an Opinion. If a Post expresses an Opinion, it is not a Claim and do not output it as such.
        If you are creating a new Claim, the value should be the statement in the "positive" sense, and the Post should be either "pro" or "against" the Claim.
        Eg., if you want to make a Claim that "Iran did not close airspace over Tehran" (and the Post supports this), the Claim should be "Iran closed airspace over Tehran" and the Post should be "against" the Claim. Or, "The UN has not imposed sanctions on Hamas leadership" would be better worded "The UN has imposed sanctions on Hamas leadership".
        When outputting pro and against, you should output the post ID (pid) of the post that is either for or against the claim inside of an array, for example against: [pid] instead of against: pid.
        Eg., a Post titled "I stand behind what I tweeted on October 7th. Can you say the same?" would not be a Claim, since it is expressing an opion.`;
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
    There is a level of judgement here; if you are I are talking about the same thing, its the same Story.

    Let's say this is the post:
    "Iran state media removes report about closing airspace over Tehran after warnings of possible strike on Israel"
    sourceCreatedAt: "2021-05-10T12:00:00Z"

    While this Post mentions Iran and a report about closing airspace over Tehran, in conjunction with Israel, you can infer that there is an urgent tension between Iran and Israel. There are actually 2 Stories here; one about Iran closing airspace, and another about Iran threatening Israel.

    Hence, a Title for the Story could be: "Iran Closing Airspace", and the other Story title would be "Iran Threatens Israel".
    Since this is the first post in the Stories, it is hard to say how important each is. We generally judge the importance by the tone, subject matter, and urgency of the Posts, but if there's only 1 Post we mute our response. The importance of the Story could be 0.4 for Iran threat, and 0.3 for airspace, respectively. If there's more posts it will be higher.

    The Description (of the first story could be) could be: "Amidst rising tensions between Iran and Israel, it was reported by Iran state media that they closed airspace over Tehran. This post wast later removed, and the situation remains ongoing."

    The Headline (of the first Story) could be: "In a stark reversal, Iran no longer says it's closing its airspace".
    The SubHeadline (of the first Story) could be: "Iran state media initially reported about closing airspace over Tehran after warnings of possible confrontation with Israel. This post was later removed."

    The happenedAt will be different for the two Stories. For the "Iran Closing Airspace" Story, the "happenedAt" will refer to the time the airspace was reported closed. Since we have no idea, our best guess will be 2 days before the Post was made. Whereas the happenedAt for the "Iran Threatens Israel" Story will be the time the threat was made, which is likely only recently before the Post. Our best guess is 3 hours before the Post.

    The "lat"/"long" for the first Story should be the location of Tehran, Iran.

    Now let's say there's another Post that comes in. It says: 
    "Tesla is in early discussions with Reliance Industries about a possible joint venture to build an electric-vehicle manufacturing facility in India, report says"
    sourceCreatedAt: "2021-05-10T12:30:00Z"

    This post clearly belongs to another Story, (which we will omit here).

    Now let's say there's a third Post that comes in. It says: 
    "Defense Minister Gallant:
    Whoever attacks Israel will counter strong defenses, followed by forceful strike in their territory; our enemies are unaware of the surprises we're preparing; Israel knows how to respond quickly across the Middle East."
    sourceCreatedAt: "2021-05-10T13:00:00Z"

    This Post is clearly related to the first Post; the first Post mentions a possible attack from Iran on Israel, and this latter Post mentions how Israel will respond to any threats. This Post is talking about Iran striking Israel, "Iran threatens Israel" Story from above. Note that this is not about the Iran Airspace Story, as it is not mentioned in the Post, though it may be related. 
    Furthermore, since the sourceCreatedAt (time the post was made) is similar, they are likely talking about the same thing (and hence the same Story).
    
    Hence the Title of the Story might be updated, "Iran and Israel Trade Threats", and now the description of the Story could be updated to include the new information.
    As it appears the Story has gotten a bit more urgent, the importance could be updated to 0.5.

    For example; the Description could be: "Iran hinted at possible warnings of a strike against Israel, to which Israel's Defense Minister Gallant replied Israel will respond in turn across the Middle East".

    The Headline could be: "Bitter rivals; Iran and Israel trade stark threats".
    The SubHeadline could be: "Iran hinted at possible warnings of a strike against Israel, prompting a strong response from Israel Defense Minister Gallant".

    The happenedAt will still refer to the initial threat, and our best guess of 3 hours before the first Post is still the most reasonable.

    If, for example the Posts each had the same photo OR VERY SIMILAR PHOTOS, the Photo of the Iranian Ayatollah for example, you would output the url and description of the first photo only (so as to dedupe), copied from one of the Posts. If the photos are different enough and both are relevant, you would output both photos, ordered by most interesting.
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

    Put simply, a Claim is any verifiable Claim about a Story (hence not an opinon).
  `;
};

// /////////////////////////////////////
// Prompt JSON
// ////////////////////////////////////

/**
 * Converts ONLY SELECT DATA from a Post object to a prompt JSON string
 * USING JSON.stringify() will convert tons of data like vector
 * @param {Post} post
 * @param {boolean} includePhotoDescription // we can ommit if the outer fn has photos
 * @return {string} JSON string
 * */
const postToJSON = function(post, includePhotoDescription = true) {
  const formatted = {
    pid: post.pid,
    title: post.title,
    description: post.description,
    body: post.body,
    sourceCreatedAt: millisToIso(post.sourceCreatedAt),
    credibility: post.credibility,
    bias: post.bias,
    // used for tuning, comment in production code
    url: post.url,
    photoURL: post.photo?.photoURL,
  };

  // we omit if we have the photo to save context
  if (includePhotoDescription) {
    formatted.photoDescription = post.photo?.description;
  }

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
 * @param {Story} story
 * @param {boolean} includePhotoDescription
 * @return {string} JSON string
 * */
const storyToJSON = function(story, includePhotoDescription = true) {
  const formatted = {
    sid: story.sid,
    title: story.title,
    description: story.description,
    headline: story.headline,
    subHeadline: story.subHeadline,
    importance: story.importance,
    happenedAt: millisToIso(story.happenedAt),
    lat: story.lat,
    long: story.long,
    numPosts: story.pids?.length ?? 1,
    photos: story.photos.map((photo) => {
      const photoObj = {
        photoURL: photo.photoURL,
      };
      // Include photo description only if includePhotoDescription is true
      if (includePhotoDescription) {
        photoObj.description = photo.description;
      }
      return photoObj;
    }),
  };

  return JSON.stringify(formatted);
};

/**
 * Converts an array of Story objects to a prompt JSON string
 * @param {Array<Story>} stories
 * @param {boolean} includePhotosDescription
 * @return {string} JSON string
 * */
const storiesToJSON = function(stories, includePhotosDescription = true) {
  return "[" + stories.map((story) => storyToJSON(story, includePhotosDescription)) + "]";
};

module.exports = {
  findStoriesPrompt,
  findStoriesAndClaimsPrompt,
  findStoriesForTrainingText,
  findStoriesAndClaimsForTrainingText,
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


