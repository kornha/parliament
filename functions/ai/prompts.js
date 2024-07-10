/* eslint-disable max-len */
const _ = require("lodash");
const {millisToIso} = require("../common/utils");

const generateImageDescriptionPrompt = function(photoURL) {
  const messages = [];
  messages.push({
    type: "text",
    text: `Generate a detailed description for the following image.
    This description will be used in vector search for similar content.`,
  });
  messages.push({type: "image_url", image_url: {url: photoURL}});
  messages.push({
    type: "text", text: `
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

  messages.push({type: "text", text: "Only output Stories that you are certain Post belongs to. The Post must either directly mention the content in the Story, or make a Claim about the Story. For any Stories that you output, order them by most to least relevant."});
  messages.push({type: "text", text: `{"stories":[${storyJSONOutput()}, ...], "removed":["sid1", "sid2", ...]}`});

  return messages;
};


const findClaimsPrompt = function({
  post,
  stories,
  claims,
  training = false,
  includePhotos = true}) {
  // Assuming each post and story has an 'photoURL' property
  const messages = training ? [
    {type: "text", text: findClaimsForTrainingText()},
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
  You will be given a Post and a list of candidate Stories (can be empty).

  Description of a Post:
  ${postDescriptionPrompt()}

  Description of a Story:
  ${storyDescriptionPrompt()}

  - Return only Stories that this Post "belongs to". 
  - Create new Stories if the Post "belongs to" a Story that is not in the list of candidate Stories. 
  - If multiple candidate Stories "belong to" each other, or in contrast if a candidate Story is overloaded and discussing multiple events, you may choose to Merge or Split the Story(ies). In this case, Simply output the new merged/split Story(ies) as a new Story(ies), and include the old Stor(ies) in the 'removed' output.
  - You should always return at least 1 Story (new or candidate).
  
  A Post "belongs to" a Story if and only if one of these criteria are met:
  1. The Post *directly mentions* the key events in the Story,
  2. The Post *makes a claim* specifically about the Story's key event.
  3. The Post is *overwhelmingly likely* to be about the Story, and mentions some details of the Story.
  4. The Post contains a photo that is relevant or duplicated from the Story.

  If a Post does not meet these criteria, it does not "belong to" the Story and should *NOT* be included in the output. Output a new Story if the Post provides sufficient information to define a distinct new event that is not covered by any existing candidate Stories.

  Here's how you update/create Story fields, when necessary:
  ${newStoryPrompt()}

  Here's a high level example that explains all of this. Please follow this thoroughly!
  ${findStoryExample()}
`;
};

const findClaimsForTrainingText = function() {
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
  Description should be 1-many sentences, and completely describes every detail we know about the Story. It should be focused around the event, and provide all known details and call out opinions.
  The Headline should be as ENGAGING as possible, and should be written in active tense. Eg., if a Title might be "Khameini addresses US students in a tweet", the Headline might be "Khameini: US students are on the right side of history".
  The Subheadline should be equally as engaging, and a far shorter description of the Story, 1-3 sentences. Eg, "Khameini's tweet to US students is a unusual bridge between the fundementalist Iranian regime and progressive students".

  HappenedAt:
  'happenedAt' is the time the event happened in the REAL WORLD, not the timestamp of the Posts. Determine when the Story "happenedAt" based on the time the Post(s) were created, as well as context in the Post(s). Eg., if a Post says "today Trump had a rally in the Bronx", and the Post 'sourceCreatedAt' is at 9PM Eastern, the "happenedAt" is the time of the rally, since 'day' is mentioned, our best guess would be 2PM ET (but outputted in ISO 8601 format).

  Lat/Long:
  the 'lat' and 'long' are the location of the event, or our best guess. If the Story is about a Trump rally in the Bronx, the lat and long should be in the Bronx. If the Story is about Rutgers U, the lat and long should be of their campus in NJ, at the closest location that can be determined. If the Post only mentions a person, the lat and long might be the country they are from. The lat and long should almost NEVER be null unless absolutely no location is mentioned or inferred.

  Importance:
  'importance' is a value between 0.0 and 1.0, where 1.0 would represent the most possible newsworthy news, like the breakout of WW3 or the dropping of an atomic bomb, and 0.0 represents complete non-news, like some non-famous person's opinion, or a cat video. 
  0.0-0.2 is non-news. This includes opinions, personal stories and anecdotes, emotional ploys, lamenting something, and any *non-newsworthy* events.
  0.2-0.4 is interesting news to those who follow a subject.
  0.4-0.6 is interesting news to even those who infrequently follow the topic. 
  0.6-0.8 is interesting news to everyone globally. 
  0.8-1.0 is extremely urgent news. 
  When deciding importance, consider the tone of the Post, the number of Posts in the Story, and the subject matter. Note that using a tone like "Breaking" does not mean the Story is important. When the Story is new, start it at the lower end of it's importance range, and increase it as more Posts come in. 
  Eg., random opinion -> 0.1, 
  Trump rally -> 0.3, 
  Trump rally with violence -> 0.5, 
  Trump rally with violence and many Posts -> 0.7, 
  China declares war on Taiwan -> 0.7, 
  China declares war on Taiwan with many Posts -> 0.95.

  Photos:
  'photos' (sometimes described photoURL and photoDescription) are, optionally, the photos that are associated with the Story. They should be ordered by most interesting, and deduped, removing not only identical but even very similar photos. Iff the Post has a photoURL that is relevant to the Story and is not a dupe, it should be included in the Story's photos. Do not include the Post URL in the photoURL.`;
};

const storyDescriptionPrompt = function() {
  return `A Story is an something that happened. Some specific time, place, and subject.
  The information is formed from collection of Posts that are 'talking about the same specific event.'
  A Story has a title, a description, a headline, a subheadline, which are textual descriptions of the Story.
  A Story has a "happenedAt" timestamp, which represents when the event happened in the real world.
  A Story has an "importance" value, which is a number between 0.0 and 1.0, where 1.0 is the most possibly newsworthy event.
  A Story has a lat and long, which are the best estimates of the location of the Story.
  A Story may have photos, which are images that are associated with the Story.
  A Story may have Claims, which are statements that are either supported or refuted by the Posts.
  `;
};

const storyJSONOutput = function(claims = false) {
  return `{"sid":ID of the Story or null if Story is new, "title": "title of the story", "description": "the full description of the story is a useful vector searchable description", "headline" "short, active, engaging title shown to users", "subHeadline":"active, engaging, short description shown to users", "importance": 0.0-1.0 relative importance of the story, "happenedAt": ISO 8601 time format that the event happened at, or null if it cannot be determined, "lat": lattitude best estimate of the location of the Story, "long": longitude best estimate, "photos:[{"photoURL":photoURL field in the Post if any, "description": photoDescription field in the Post, if any}, ...list of UNIQUE photos taken from the Posts ordered by most interesting]${claims ? `, "claims":[${claimJSONOutput()}, ...]` : ""}}`;
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
        A Post usually belongs to one or many Stories, and may have Claims.`;
};

//
// Claims
//

const claimsDescriptionPrompt = function() {
  return `A Claim is a statement that has "pro" and "against" list of Posts either supporting or refuting the Claim.
            A Claim has a "value" field, which is the statement itself.
            A Claim has a "pro" field, which is a list of Posts that support the Claim.
            A Claim has an "against" field, which is a list of Posts that refute the Claim.
            A Claim has a "claimedAt" field, which is the earliest time that the Claim was made at and is valid for. This is the time window in which the Claim was made that other Claims can be compared to. Generally within 48 hours we assume that new Claims are about the same event.
            A Claim may have a "context" field, which provides more information about the Claim, and helps for search.`;
};

const newClaimPrompt = function() {
  return `CID:
  CID should be null for new Claims, and copied if outputting an existing Claim.

  Value:
  The 'value' field is the text of the Claim. It should be a verifiable statement that is direct and clear, not an opinion. It should be as neutral as possible. Eg., "Trump is a Republican" is a Claim, "Trump is a good president" is an opinion. Any sort of human value judgement is an opinion, and should not be outputted. The value field should also be in the "positive" form, eg., "Trump is a Republican" not "Trump is not a Democrat".

  Pro/Against:
  The 'pro' and 'against' fields are lists of Post IDs that support or refute the Claim. If the Post is in support of the Claim, it should be added to the 'pro' list. If the Post is against the Claim, it should be added to the 'against' list.

  ClaimedAt:
  'claimedAt' is the time the Claim is valid for. This is the time window in which the Claim was made that other Claims can be compared to. Generally within 24-48 hours we assume that new Claims are about the same event. The 'claimedAt' should be the time the Claim was made, in ISO 8601 format.`;
};

const claimJSONOutput = function() {
  return `{"cid":ID of the Claim or null if the Claim is new, "value": "text of the claim", "pro": [pid of the post] or [] if post is not in support, "against": [pid of the post] or [] if the post is not against the claim", "claimedAt": "ISO 8601 time format that informs us what the Claim is valid for"}`;
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
  return ` As was stated;
    A Post "belongs to" a Story if and only if one of these criteria are met:
    1. The Post *directly mentions* the key events in the Story,
    2. The Post *makes a claim* specifically about the Story's key event.
    3. The Post is *very likely* to be about the Story, and mentions some details of the Story.
    4. The Post contains a photo that is relevant or duplicated from the Story.

    You may also need to Merge or Split Stories if the Post introduces information that causes a candidate Story to be Merged or Split.

    This is an example that demonstrates this:
    
    INPUT: POST 1 (below), WITH ZERO CANDIDATE STORIES:
    "The loss of life in Gaza, military or civilian, is a tragedy that belongs to Hamas.
    I grieve as a father and my thoughts are with the families who lost their brave children."
    The Post contains a photoURL of an image that says: "8 killed in Gaza in deadliest attack in months".
    sourceCreatedAt: "2024-06-15T17:15:00Z"

    OUTPUT (POST 1) WITH EXPLANATION:
    You can infer that the Story here is that 8 Israeli soldiers were killed in an attack in Gaza. This Story is about the attack. Not about the wider war, or other comments about Gaza today.

    Hence, a Title for the Story could be: "Eight Israeli Soldiers Killed in Gaza Attack".
    Since this is the first post in the Stories, it is hard to say how important each is. We generally judge the importance by the tone, subject matter, and urgency of the Posts, but if there's only 1 Post we mute our response. The importance of the Story could be 0.45, since it appears to be a significant event, but we only have 1 Post so far.
    The Description (of the first story could be) could be: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months." This is all we know so far.
    The Headline (of the first Story) could be: "Eight Israeli Soldiers Killed in Deadliest Attack in Months".
    The SubHeadline (of the first Story) could be: "Eight Israeli soldiers were killed in an attack in Gaza, the deadliest in months."
    The happenedAt can be inferred from the sourceCreatedAt of the Post. The Post was made at 5:15PM Z, so the attack likely happened around 12:15PM Z, ~5 hours before the Post was made. Given that the time is not mentioned in the Post, this is our best guess. If we can infer any time, from the photo, timezone, or anything else, we use this in our estimate.
    The "lat"/"long" for the first Story should be the location of Gaza.
    Since the Post has a photoURL, and we are making a new Story (so there are no duplicate photos), we should include the photoURL (and if present photoDescription) in the Story.
    Output this Story (as a new Story) in the JSON format listed at the end of the prompt.

    INPUT POST 2, 1 CANDIDATE STORY: 
    "To say that all Palestinians are guilty for the crimes of Hamas is a terrible insult to the Palestinian peace activists who argue against Hamas' ideology every day and many who Hamas imprisoned and killed just for criticising their ideas."
    sourceCreatedAt: "2021-06-15T12:30:00Z"

    We have 1 candidate Story, the Eight Soldier Story just created above.
    
    POST 2 OUTPUT:
    This Post does *NOT* belong to the candidate Story "Eight Israeli Soldiers Killed in Gaza Attack" because it does not directly mention the key event (8 soldiers killed) or make a claim about the soldiers being killed. 
    Compared to our criteria:
    1. The Post *directly mentions* the key events in the Story, NOT FULLFILLED.
    2. The Post *makes a claim* specifically about the Story's key event. NOT FULLFILLED.
    3. The Post is *very likely* to be about the Story, and mentions some details of the Story. NOT FULLFILLED, the Post is not *very likly* to be specifically related to the Soliders death though it is a similar time and place.
    4. The Post contains a photo that is relevant or duplicated from the Story. NOT FULLFILLED.
    Since this Post does not meet the criteria for belonging to the existing Story, we will output only a new Story.
 
    The output is only the *new* Story, which is titled: "Palestinian Peace Activists Against Hamas". It is an Opinion with only 1 Post, so it has ultra low importance, 0.05. Its happenedAt is vague and should be set to the time of the sourceCreatedAt. The lat/long should be the best guess of the location of the Post, which is likely Gaza. The other fields can be inferred, and are omitted in this instruction.

    POST 3, 2 CANDIDATE STORIES: 
    "EIGHT ISRAELI SOLDIERS KILLED IN DEADLIEST GAZA INCIDENT SINCE JANUARY
    Eight Israeli soldiers were killed in a blast in Rafah, southern Gaza, this morning, marking the deadliest IDF incident in the Strip since January. Only one soldier, Cpt. Wassem Mahmoud, 23, has been named. The other families have been notified, with names to be released later. The soldiers were in a Namer armored combat engineering vehicle (CEV) when it was hit by a major explosion. The convoy was heading to buildings captured after an overnight offensive against Hamas. The cause of the blast is under investigation. This brings the IDF death toll in the current offensive to 307."
    sourceCreatedAt: "2024-06-15T15:07:00Z"

    And we have 2 candidate Stories, the Eight Soldier Story, and the Palestinian Peace Activists Story.

    POST 3 OUTPUT:
    This Post clearly "belongs to" the Eight Soldier Story, as it *directly mentions* the death of Eight Israeli soldiers, and makes a Claim about the Story.
    
    When there is more information, update the existing Story. For example, the Title of the Story might remain the same, but the Description should be updated to include the new information, such as the name of the soldier that was killed, how the attack happened, and the total death toll thus far. The subheadline should also change to include this new information, for example "A Namer CEV vehicle was hit, killing eight Israeli soldiers and bringing the IDF death toll to 307".

    The importance could be updated to 0.5 as there are 2 Posts now. The happenedAt will still refer to the initial threat, and our best guess of 3 hours before the first Post is still the most reasonable. The lat/long should also remain the same.

    POST 4, 1 CANIDATE STORY:
    Post:
    "Italy raided factories & found that Armani and Dior bags are made by illegal Chinese workers in Italy who sleep in the workshop and make €2-3/hr. Both companies have been placed under Italian court administration. \n\nDior paid a supplier $57 to assemble* a handbag that sells for $2,780\n\nArmani bags that were sold to consumers for €1,800 cost €93* to make. \n\n(These don’t include raw materials costs)\n\nPeople often wrongly conflate higher prices for higher ethical standards."
    sourceCreatedAt: "2024-07-04T04:00:00Z"
    photo: "A woman carrying a Dior bag".

    Candidate Story:
    title: "Dior Bag Production Costs",
    headline: "Dior Bags: $57 to Make, $2,780 to Buy",
    subHeadline: "Italian prosecutors reveal Dior's production costs for luxury bags.",
    description: "Italian prosecutors have uncovered that Dior pays only $57 to produce bags that retail for $2,780. This revelation raises questions about the pricing strategies of luxury brands and the value they offer to consumers.
    happenedAt: "2024-07-03T23:00:00Z"

    POST 4 OUTPUT:
    Post 4 belongs to the Dior Bag Story, as it mentions elements of the Story, is a similar time and place, and is *very likely* to be talking about the Story.

    POST 5, 2 CANDIDATE STORIES:
    "I was talking to a friend from Gaza this morning, and I thought I knew what they were going through until he opened the camera and showed me the massive destruction of an area where we used to hang out. At first, I were unsure of him because I struggled to recall the neighborhood, which I used to visit at least once each week. Observing people's shapes can reveal how they are suffering as a result of the scarcity of food entering Gaza."
    sourceCreatedAt: "2024-06-15T8:08:00Z"

    The two candidate Stories are the Eight Soldier Story and the Palestinian Peace Activists Story. 
    
    POST 5 OUTPUT:
    This Post does not belong to either of the Stories. It *does not directly mention* the death of the soldiers, nor does it make a Claim about the Story. It does not mention the Palestinian peace activists, nor does it make a Claim about them either. It is its own Story. 
    It should have an importance of 0.2, since it's a personal anecdote, and not providing newsworthy information.

    POST 6, 2 CANDIDATE STORIES:
    "BREAKING: Israeli Haaretz: IDF Ordered Hannibal Directive on October 7 to Prevent Hamas Taking Soldiers Captive Documents and testimonies obtained by Haaretz reveal the Hannibal operational order, which directs the use of force to prevent soldiers being taken into captivity, was employed at three army facilities infiltrated by Hamas, potentially endangering civilians as well. Haaretz proves once again that Israel allowed October 7th to happen, and is responsible for the largest number of Israeli civilian casualties on that day."
    sourceCreatedAt: "2024-06-20T8:08:00Z"

    Candidate Stories:
    1) 
      title: "IDF Hannibal Directive on October 7",
      headline: "IDF Used Hannibal Directive to Prevent Hamas Capturing Soldiers",
      subHeadline: "IDF's Hannibal directive on October 7 aimed to prevent Hamas from taking soldiers captive, potentially endangering civilians.",
      description: "Documents and testimonies obtained by Haaretz reveal that the IDF employed the Hannibal operational order on October 7 to prevent soldiers from being taken captive by Hamas. This directive, which directs the use of force to prevent soldiers from being taken into captivity, was employed at three army facilities infiltrated by Hamas, potentially endangering civilians as well.",
      happenedAt: "2024-06-20T8:08:00Z"
    2)
      title: "Hannibal Directive Used on October 7",
      headline: "Israel Used Hannibal Directive on October 7",
      subHeadline: "Haaretz confirms Israel's use of the Hannibal directive on October 7, targeting vehicles and areas near Gaza.",
      description: "Haaretz confirms that Israel used the Hannibal directive on October 7, which included orders to attack any vehicle driving towards Gaza, indiscriminately bomb the area with mortar shells and artillery, and make it a 'kill zone'. Drones were also dispatched to attack the Re’im outpost close to the Nova festival. The directive was employed at three army facilities infiltrated by Hamas, potentially endangering civilians.",
      happenedAt: "2024-06-20T8:08:00Z"

    POST 6 OUTPUT:
    Clearly, the two candidate Stories are about the same event, the IDF's use of the Hannibal Directive on October 7. The Stories should be Merged, and the Post belongs to the Merged Story. Hence, the output should be a new Story, with information from both events (omitted here). The "removed" section of the output should include the SIDs from both candidate Stories.

    POST 7, 4 CANDIDATE STORIES:
    "Senator JD Vance says he has “not gotten the call” from Trump asking him to be his VP. This comes amid a whirlwind of speculation about who Trump will pick as his running mate.",
    sourceCreatedAt: "2024-06-20T8:08:00Z"

    Candidate Stories:
    1) 
      title: "Trump VP Selection Speculation",
      headline: "Trump's VP Pick: White Man or Marco Rubio?",
      subHeadline: "Speculation arises about Trump's potential VP pick being a white man or Marco Rubio.",
      description: "Donald Trump is speculated to pick a white man or Marco Rubio, who is perceived by some as thinking he is white, for his Vice President. This speculation is based on a social media post by Dean Obeidallah. Additionally, there is speculation that Trump will not choose a running mate who is a hardliner on abortion. All the aspirants clearly understand that and are willing to abandon positions they held for decades with the exception of Tim Scott, which is one reason he won’t be picked. The new post suggests that the VP choice will not be someone from Florida, indicating a disappointment in the current political landscape.",
      happenedAt: "2024-06-20T8:08:00Z"
    2)
      title: "Trump Vice President Appointment",
      headline: "Who Will Trump Appoint as Vice President?",
      subHeadline: "Public asked for opinions on Trump's Vice President appointment.",
      description: "A social media post is asking the public who they want to see President Trump appoint as his Vice President. The post does not provide any further details or context about the appointment.",
      happenedAt: "2024-06-20T9:31:00Z"
    3) 
      title: "Trump VP Selection Announcement",
      headline: "Trump to Announce VP Selection This Week",
      subHeadline: "Donald Trump is expected to reveal his Vice Presidential pick this week.",
      description: "Donald Trump is reportedly set to announce his Vice Presidential selection this week. The announcement is highly anticipated and has generated significant public interest. Additionally, there is speculation that Trump will not choose a running mate who is a hardliner on abortion.",
      happenedAt: "2024-06-20T10:01:00Z"
    4)
      title: "Palestinian Peace Activists Against Hamas",
      headline: "Palestinian Peace Activists Speak Out Against Hamas",
      subHeadline: "Palestinian peace activists face imprisonment and death for criticizing Hamas.",
      description: "The Post discusses the plight of Palestinian peace activists who argue against Hamas' ideology and face imprisonment and death for their criticism.",
      happenedAt: "2024-06-20T10:01:00Z"

    POST 5 OUTPUT:
    In this case, the first 3 candidate Stories are clearly discussing the speculation around Trump's VP pick. The Stories have a very similar happenedAt, and have the same subject. They clearly "belong to" each other, and should be Merged. The 4th candidate Story does not belong to the other Stories. The Post "belongs to" the new, Merged, Story. Hence the output is a new Story, and the removed section should include the 3 SIDs of the Stories that were merged. The 4th candidate Story is not outputted at all.

    END OF EXAMPLE.

    A note on photos:
    If, for example the Posts each had the same photo OR VERY SIMILAR PHOTOS about the attack, you would output the photoURL and photoDescription of the first photo only (so as to dedupe), copied from one of the Posts. If the photos are different enough and both are relevant, you would output both photos, ordered by most interesting. If another Post were to come in with an unclear description, but the same photo, it is very likely part of the same Story. Try and order the insteresting photos first.`;
};

const findClaimsAndStoriesExample = function() {
  return `Let's say we have a Post that says: 
    "The loss of life in Gaza, military or civilian, is a tragedy that belongs to Hamas.
    I grieve as a father and my thoughts are with the families who lost their brave children."
    Including an image that says: "8 killed in Gaza in deadliest attack in months".
    sourceCreatedAt: "2024-06-15T17:15:00Z"

    And we have a Story that has the Title: 
    "Eight Soldiers Killed in Gaza Attack"

    The Story should have the Claims:
    1) 8 Israeli soldiers were killed in an attack in Gaza.
    claimedAt: June 6 2024 5:15PM.
    2) The attack on Israeli soldiers was the deadliest in months.
    claimedAt: June 6 2024 5:15PM.

    Put simply, a Claim is any verifiable Claim about a Story (hence not an opinon)`;
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
  const formatted = {
    cid: claim.cid,
    value: claim.value,
    pro: claim.pro,
    against: claim.against,
    claimedAt: millisToIso(claim.claimedAt),
    context: claim.context,
  };

  return JSON.stringify(formatted);
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
  findClaimsPrompt,
  findStoriesForTrainingText,
  findClaimsForTrainingText,
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


