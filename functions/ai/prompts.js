/* eslint-disable max-len */
const _ = require("lodash");
const {millisToIso} = require("../common/utils");

const regenerateStoryPrompt = function(story, primaryPosts, secondaryPosts) {
  return `
        You will be given a Story and a list of Posts that are associated with the Story.
        Description of a Story:
        ${storyDescriptionPrompt()}

        Description of a Post:
        ${postDescriptionPrompt()}

        The Posts will be either primary or secondary.
        A Primary Post is a post that is directly associated with the Story, and is used to generate the Title and Description of the Story.
        A Secondary Post is a post that is indirectly associated with the Story, and can inform the Title and Description of the Story, 
        but it may have other content which should not be included in the Story.

        You will be given a Story, list of Primary Posts, and a list of Secondary Posts. Both lists of Posts will be ordered by recency.
        You will be given the Story's current Title and Description. If there is no new information, and the Title and Description meet criteria, you should not change them.
        You will also be asked to output the Story's ID (aka, the sid) and the time the event happened at (happenedAt). 
        You should always output the same sid passed in, and update the happenedAt if and only if the time the event happened at became more clear or changed.

        Here's the instructions for outputting a Story:
        ${newStoryPrompt()}

        Here is the Story:
        ${storyToJSON(story)}

        Here are the Primary Posts (if any):
        ${primaryPosts.map((_post) => postToJSON(_post)).join("\n")}

        Here are the Secondary Posts (if any):
        ${secondaryPosts.map((_post) => postToJSON(_post)).join("\n")}

        ${storyJSONOutput()}
  `;
};

const findStoriesPrompt = function(post, stories) {
  return `
        You will be given a Post and a list of Stories (can be empty).

        Description of a Post:
        ${postDescriptionPrompt()}

        Description of a Story:
        ${storyDescriptionPrompt()}

        Your goal is to find all the Stories (aka events) that the Post belongs to, or makes a clear reference or claim to.
        A Story is typically an event, with a specific time and place. Sometimes however, Stories do not have a time and place, and instead are a subject or topic.

        Since a Story is an event, you will ONLY return the Story if the Post directly mentions the event or makes a claim about the event.
        You will also create "new" Stories, if the Post mentions an event/topic that is not passed in the list of stories.

        Here's a high level example that explains how to decide the granularity of a Story:
        ${findStoryExample()}

        here are the Stories: ${_.isEmpty(stories) ? "[]" : stories.map((_story) => storyToJSON(_story)).join("\n")}
        here is the Post: ${postToJSON(post)}

        Output a list of 0, 1, or many stories. Order the output by the most relevant story first (at position 0), from most to least relevant. 
        if the Post refers to an existing Story, return the Story ID, otherwise return null (as the ID) for a new Story. If you are creating a new Story, follow these instructions:

        How to output a new Story, (if a new Story is needed):
        ${newStoryPrompt()}

        Output the following JSON ordered from most to least relevant Story:
        {"stories":[${storyJSONOutput()}, ...]}
        `;
};

const findClaimsPrompt = function(post, claims) {
  return `
        You will be given a Post and a list of Claims (can be empty).

        Description of a Post:
        ${postDescriptionPrompt()}

        Description of a Claim:
        ${claimsDescriptionPrompt()}

        Your goal is to find all the Claims that the Post makes. 
        Note that since a Claim has a "pro" and "against" list of Posts, you may return a Claim as "against" if the post makes an alternative Claim that inherently refutes this Claim.

        For example;

        Here's a high level example:
        ${findClaimExample()}

        here are the Claims: ${_.isEmpty(claims) ? "[]" : claims.map((claim) => claimToJSON(claim)).join("\n")}
        here is the Post: ${postToJSON(post)}

        Output a list of 0, 1, or many Claims. Order the output by the most relevant Claim first (at position 0), from most to least relevant. 
        if the Post refers to an existing Claim, return the claim ID (cid), otherwise return null (as the ID) for a new Claim. If you are creating a new Claim, follow these instructions:

        How to output a new Claim, (if a new Claim is needed):
        ${newClaimPrompt()}

        Output the following JSON ordered from most to least relevant Claim:
        {"claims":[${claimJSONOutput()}, ...]}
        `;
};

const findClaimsForStoryPrompt = function(story, claims) {
  return `
        You will be given a Story and a list of Claims.

        Description of a Story:
        ${storyDescriptionPrompt()}

        Description of a Claim:
        ${claimsDescriptionPrompt()}

        Your goal is to find all the Claims that directly relate to the story.
        Claims must be directly making a claim about the Story, and not to other events or topics.

        For example;

        Here's a high level example:
        ${findClaimForStoryExample()}

        here are the Claims: ${_.isEmpty(claims) ? "[]" : claims.map((claim) => claimToJSON(claim)).join("\n")}
        here is the Story: ${storyToJSON(story)}

        Output a list of 0, 1, or many Claim IDs (aka cid) Note you are outputting the claim cid and not the Story sid. 
        Order the output by the most relevant Claim ID first (at position 0), from most to least relevant. 

        Output the following JSON ordered from most to least relevant Claim:
        {"cids":[cid1, cid2, ...]}
        `;
};

const findStoriesAndClaimsPrompt = function(post, stories, claims) {
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

    Your goal is to output the Stories EXACTLY as they are, BUT with the following change.

    1) If the Post makes a Claim that is already in the list of Claims, this Claim should be added to the Story, and the Post should be added to the "pro" or "against" list of the Claim. 
    1a) DO NOT OUTPUT A CLAIM THAT THE POST DOES NOT MAKE EVEN IF IT IS PART OF THE STORY ALREADY.
    1b) DO NOT OUTPUT OTHER PIDS THAT ARE ALREADY PART OF THE PRO OR AGAINST LIST OF THE CLAIM.
    2) If the Post makes a Claim that is inherently new (there is no matching Claim in the list), this Claim should be created and added to the Story, and the Post should be added to the "pro" or "against" list of the Claim.

    Here is how to output a new Claim:
    ${newClaimPrompt()}

    Here's a high level example:
    ${findClaimsAndStoriesExample()}

    here is the Post: ${postToJSON(post)}

    here are the Stories: ${_.isEmpty(stories) ? "[]" : stories.map((story) => storyToJSON(story)).join("\n")}

    here are the Claims: ${_.isEmpty(claims) ? "[]" : claims.map((claim) => claimToJSON(claim)).join("\n")}

    
    Output the stories in the same order as they were passed in, but with the new Claims added to the Stories, as follows:
    {"stories":[${storyJSONOutput(true)}, ...]}
  `;
};

//
// Secondary Promps
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
  `;
};

const storyDescriptionPrompt = function() {
  return `
        A Story is an event or trending topic. 
        A story is often temporal, and takes place at a specific time or over a small time window.

        The "sid" is the Story ID, which is a unique identifier for the Story.

        The "title" is a very concise, 2-7 word title of the Story. The title should be maximally interesting, and generally should scope the story to a specific event.
        The "description" is a 1-5 sentence description of the story. The description should be as descriptive as possible.
        Both the title and description should be extremely neutral.

        The "happenedAt" is the time that the event happened at, or our best guess.
        
        A Story is has several other fields.
        Primarily, a Story is a collection of Posts (social media postings or articles), which inform the Claims in the story. 
        Claims are a Statement about the Story that have supporters and or refuters.
        A Story maybe have a Bias and Credibility score as well.
    `;
};

const storyJSONOutput = function(claims = false) {
  return `{"sid":ID of the Story or null if Story is new, "title": "title of the story", "description": "the description of the story is a useful vector searchable description", "happenedAt": ISO 8601 time format that the event happened at, or null if it cannot be determined${claims ? `, "claims":[${claimJSONOutput()}, ...]` : ""}}`;
};

const storyToJSON = function(story) {
  return `
    START OF STORY
    sid: ${story.sid}
    title: ${story.title}
    description: ${story.description}
    happenedAt: ${millisToIso(story.happenedAt)}
    END OF STORY
  `;
};

//
// Post
//

const postDescriptionPrompt = function() {
  return `
        A Post is a social media posting or an article. It can come from X (aka Twitter), Facebook, Instagram, Reddit, Tiktok or other social sources.
        It may also be a news article published online to some platform.
        A Post can have a title, a description, and a body, the latter two of which are optional.
        A Post may have images, videos or other media.
        A Post has an author, which we call an Entity.
        A Post has a timestamp, which is the time the (original) Post was created. We call this "sourceCreatedAt".
        A Post may also be assigned Bias and Credibility scores. 
        Bias refers to the political bias of the Post, and Credibility refers to how confident we think the Post is to be true.
        `;
};

const postToJSON = function(post) {
  return `
        START OF POST
        pid: ${post.pid}
        title (if any): ${post.title}
        description (if any): ${post.description}
        body (if any): ${post.body}
        sourceCreatedAt: ${millisToIso(post.sourceCreatedAt)}
        credibility (if any): ${post.credibility}
        bias (if any): ${post.bias}
        END OF POST
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

const claimToJSON = function(claim) {
  return `
        START OF CLAIM
        cid: ${claim.cid}
        value: ${claim.value}
        context (if any): ${claim.context}
        pro: ${claim.pro ? claim.pro.join(", ") : "[]"}
        against: ${claim.against ? claim.against.join(", ") : "[]"}
        END OF CLAIM
    `;
};

const newClaimPrompt = function() {
  return `
        The value of the Claim should be a statement that is either supported or refuted by the Post. 
        If you are creating a new Claim, the value should be the statement in the "positive" sense, and the Post should be either "pro" or "against" the Claim.
        Eg., if you want to make a Claim that "Iran did not close airspace over Tehran" (and the Post supports this), the Claim should be "Iran closed airspace over Tehran" and the Post should be "against" the Claim.
        When outputting pro and against, you should output the post ID (pid) of the post that is either for or against the claim inside of an array, for example against: [pid] instead of against: pid.
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

    While this Post mentions Iran and a report about closing airspace over Tehran, in conjunction with Israel, you can infer that there is an urgent tension between Iran and Israel.
    Hence, a Title for the Story could be: "Iran Closes Airspace" or "Iran and Israel at War". While both would be right, since we generally lean on the side of granularity, the former title would be preferable.

    The Description could be: "Amidst rising tensions between Iran and Israel, it was reported by Iran state media that they closed airspace over Tehran. This post wast later removed, and the situation remains ongoing."

    Now let's say there's another Post that comes in. It says: 
    "Tesla is in early discussions with Reliance Industries about a possible joint venture to build an electric-vehicle manufacturing facility in India, report says"
    sourceCreatedAt: "2021-05-10T12:30:00Z"

    This post clearly belongs to another Story, (which we will omit here).

    Now let's say there's a third Post that comes in. It says: 
    "Defense Minister Gallant:
    Whoever attacks Israel will counter strong defenses, followed by forceful strike in their territory; our enemies are unaware of the surprises we're preparing; Israel knows how to respond quickly across the Middle East."
    sourceCreatedAt: "2021-05-10T13:00:00Z"

    This Post is clearly related to the first Post; the first Post mentions a possible attack from Iran on Israel, and this latter Post mentions how Israel will respond to any threats.
    While you can choose to group these into the same Story, or keep them separate, in this case, since the sourceCreatedAt (time the post was made) is similar, it is likely they are referring to the same event, (Iran attack and Israel response) and should be grouped together.
    
    Hence the Title of the Story might be updated, "Iran and Israel at War", and now the description of the Story could be updated to include the new information.

    For example; the Description could be: "Amidst rising tensions between Iran and Israel it was rumored that Iran closed airspace over Tehran. This is unclear. Meanwhile Defense Minister Gallant has stated that Israel will respond to attacks on enemy territory."
  `;
};

const findClaimExample = function() {
  return `
    Let's say this is the Post:
    "Iran state media removes report about closing airspace over Tehran after warnings of possible strike on Israel"
    sourceCreatedAt (time post was published, different from the Story's 'happenedAt'): "2021-05-10T12:00:00Z" 

    The Claims here are that 1) Iran had made a report about closing airspace over Tehran near the "sourceCreatedAt" time of the Post and 2) They later changed this report and did not end up closing airspace, and 3) There were warnings of a possible strike on Israel.

    If there is a Claim that says "Iran closed airspace over Tehran", then this Post would be "against" that Claim, as the.
    If there is a Claim that says "Iran did not close airspace over Tehran", then this Post would be "for" that Claim.
    If there is a Claim that says "There were warnings of a possible strike on Israel" then this Post would be "for" that Claim.
    If there is a Claim that says "Iran said they are closing their airspace over Tehran", then this Post would be "for" that Claim.
  `;
};

const findClaimForStoryExample = function() {
  return `
    Let's say this is the Story:
    "Joe Biden spoke to Bibi Netanyahu about his plans for war with Iran"
    happenedAt: "2021-05-10T12:00:00Z"

    Let's say there are two Claims in question:
    1) value: "Joe Biden spoke to Bibi Netanyahu for 3 hours"
       context: "The 2021 War between Israel and Iran"
    2) value: "Joe Biden went on a trip to Delaware to visit his family"
       context: "Joe Biden's trips in 2021"
    3) value: "Joe Biden spoke to Bibi Netanyahu about his plans for war with Iran"
       context: "The 2024 War between Israel and Iran"
    Since the first Claim is directly related to the Story, it should be included.
    The second Claim should be ignored. 
    The third claim also should be ignored due to it referring to a different event.
    `;
};

const findClaimsAndStoriesExample = function() {
  return `
    Let's say we have a Post that says: 
    "Iran state media removes report about closing airspace over Tehran after warnings of possible strike on Israel".
    sourceCreatedAt: "2021-05-10T12:00:00Z"

    And we have a Story that has the Title: 
    "Iran and Israel on the Brink of War"
    Description: 
    "Iran and Israel are on the brink of war, and the two countries are beginning a defensive posture."

    Claims: 
    1) "Iran is on the brink of war with Israel".

    In this case, the Post has introduced a new Claims that are directly related to the Story; 
    and the Claims: "Iran media had reported closing its airspace" as well as "Iran media removed the report of closing its airspace"
    should be added to the Story.

    After this the Story should have 3 Claims:
    1) "Iran is on the brink of war with Israel"
    2) "Iran media had reported closing its airspace"
    3) "Iran media removed the report of closing its airspace"    
  `;
};

module.exports = {
  regenerateStoryPrompt,
  findStoriesPrompt,
  findClaimsPrompt,
  findClaimsForStoryPrompt,
  findStoriesAndClaimsPrompt,
  storyDescriptionPrompt,
  storyJSONOutput,
  credibilityDescriptionPrompt,
  credibilityJSONOutput,
  biasDescriptionPrompt,
  biasJSONOutput,
};


