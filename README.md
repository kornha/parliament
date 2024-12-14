<div align="center">
  <picture>
    <source srcset="https://github.com/kornha/political_think/assets/5386694/0f8fd310-eef9-41d9-b94e-64c3f74d788b" media="(prefers-color-scheme: dark)" width="100">
    <source srcset="https://github.com/kornha/political_think/assets/5386694/d73da709-c502-4aa5-8e4b-30147c7024ca" media="(prefers-color-scheme: light)" width="100">
    <img src="https://github.com/kornha/political_think/assets/5386694/d73da709-c502-4aa5-8e4b-30147c7024ca" alt="logo_white">
  </picture>
</div>

# Parliament

![In Progress](https://img.shields.io/badge/status-pre%20release-blue)

**Parliament** is an open-source news project that organizes news by `Confidence`, `Bias`, `Newsworthiness`, and `Contextualization` to tell maximally truthful news in a clear and measurable way.

### Key Concepts

* **Parliament** is the open-source repo that anyone can contribute to.
* Parliament is based on the whitepaper [Credible News](#whitepaper).
* Anyone can host a Parliament, provided there is compliance with the [LICENSE](LICENSE).
* Hosted website and mobile apps coming soon.
    
*This project is in pre-release, and as such, is a preview. Many features are in development.*

<div align="center">
  <img src="https://github.com/kornha/political_think/assets/5386694/512b8b18-edec-4b15-9af2-67d70388def0" alt="01f62b98-cedc-4730-b564-d71607a066b3" height="300">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://github.com/kornha/political_think/assets/5386694/e8d7932f-1f84-4f1b-ae1a-5553aa15759e" alt="01f62b98-cedc-4730-b564-d71607a066b3" height="300">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://github.com/kornha/political_think/assets/5386694/f52bb89e-18f4-4a8a-819b-acc629cb79f8" alt="01f62b98-cedc-4730-b564-d71607a066b3" height="300">
</div>

# Table of Contents
1. [Whitepaper](#whitepaper)
    1. [Credible News](#credible-news)
    2. [Mission](#mission)
    3. [Confidence](#confidence)
        1. [Confidence Algorithm](#confidence-algorithm)
    4. [Bias](#bias)
        1. [Bias Algorithm](#bias-algorithm)
        2. [Center](#center)
        3. [Right](#right)
        4. [Left](#left)
        5. [Extreme](#extreme)
    5. [Newsworthiness](#newsworthiness)
        1. [Newsworthiness Algorithm](#newsworthiness-algorithm)
    6. [Contextualization](#contextualization)
        1. [Contextualization Algorithm](#contextualization-algorithm)
    7. [Concepts](#concepts)
        1. [Story](#story)
        2. [Post](#post)
        3. [Entity](#entity)
        4. [Platform](#platform)
        5. [Statement](#statement)
        6. [Claim](#claim)
        7. [Opinion](#opinion)
        8. [Phrase](#phrase)
2. [Contact](#contact)
    1. [Socials](#socials)
3. [Development](#development)
    1. [Commitment to Zero Political Evangelism](#commitment-to-zero-political-evangelism)
    2. [Why Participate?](#why-participate)
        1. [Shared Ownership](#shared-ownership)
        2. [Swag](#swag)
        3. [Learn](#learn)
    3. [Getting Started](#getting-started)
        1. [Discord](#discord)
        2. [Instructions](#instructions)

# Whitepaper 

### Credible News

by [Alexander Kornhauser](https://www.linkedin.com/in/alexkornhauser/).

## Mission

> Parliament's mission is telling maximally truthful news in a clear and measurable way.

Think about how you understand news. You may consume one or multiple news sources. It may be social media content, cable news, online or print news, your favorite Telegram group, or another news provider. Ultimately, you will infer the claims these sources are making, and when you are sufficiently satisfied, you will either arrive at a conclusion about what you think has happened or consider yourself unsure. Implicitly, you are assigning a unique judgment value to various news outlets, favoring the credibility of some over others. Once you have enough credible confirmations for your own personal threshold, you may consider something to be effectively true. 

For people, our perceived credibility in certain outlets is weighed by many things, including our `Confidence` in the accuracy of the outlet (*this X account has been right many times, so they're probably correct now*), and by our `Bias` towards the outlet (*this news provider conforms to my beliefs of the world, so I'll trust their interpretation*). 

We also perceive some news events to be more important than others. This may be due to various factors, such as ramifications that impact our lives, significant geopolitical events, events that confirm or reject our beliefs, local concerns, unique occurrences (_man bites dog_), or other considerations. For example, on August 9, 1974, when the New York Times published *NIXON RESIGNS* in capital letters on their front page, they were expressing significant urgency in the event. While the importance of the `Story` is different to each person, i.e., it may have been more interesting to an American autoworker than to a Nepalese farmer, the New York Times felt it was newsworthy enough for their audience to warrant an all-caps title. This judgment we call `Newsworthiness`.

News, when told, also includes a varying contextualization around the event that may significantly alter our understanding and perception of an event. In the most simplest case, an image can be so powerful, only to reverse its meaning when it is zoomed out. The fairness and completeness around which a `Story` is told we call `Contextualization`. 

Each human consumes news differently due to their unique experiences and circumstances. This is partly why the same event can be perceived so differently by different individuals. 
Parliament's mission is to tell maximally truthful news in a clear and measurable way.

Let's dive into how the system works.

## Confidence

> **Confidence**: The likelihood of something being true based on how true it has been in the past.

How do we know that something is true? This is a philosophical question, and there are several product approaches to addressing it. X, for instance, relies on community notes. FactCheck.org focuses on fact-checking. These two approaches work by direct content validation. A strategy that, when implemented correctly, can be extremely accurate.
Parliament takes what you may call the additional level of abstraction to the above. In the view of Parliament, FactCheck.org, @elonmusk, X fact checker, NYT, a random account on IG, etc. are each what we call an `Entity`. Otherwise put, Parliament does use fact checkers too, it just tries to use all of them. And, based on if they've been right or wrong in the data we've collected, we know how much to trust them going forward. In this mode of thinking, we can assign news `Confidence` scores, a score between `0.0` and `1.0`, where 0 represents *maximal certainty that something is false*, and 1.0 represents *maximal certainty that something is true*. Total certainty is unknowable, and both 0.0 and 1.0 can never be achieved.

### Confidence Algorithm

We will only cover a high level of the confidence algorithm here, as the specifics are [written in the code](functions/ai/confidence.js). 

Let us say as a human I am introduced to a new user on X/IG/TikTok etc. Now, depending on who introduced me, perhaps the platform's algorithm, perhaps a friend, I may view content differently. Regardless, I will have a measure of doubt as to how much I trust the author (aka `Entity`), which may change over time.

At Parliament we assume new sources are of even uncertainty; currently we assume new people are 50% likely to be honest.

We then look at the `Claims` a given `Entity` has made. If these claims are mutually agreed on by many parties, old and new, we can start to collect a `Consensus` on a claim, much like a blockchain algorithm, which is a possible future implementation. Once claims form a level of consensus, we can then punish the people who have been wrong, and reward the people who have been right. Of course, once we punish/reward the `Entities`, other claims may change consensus, creating a finite ripple effect.

Currently we track `confidence` in an `Entity` by:
```
/**
 * Calculate the confidence of an entity based on its past statements.
 * @param {Entity} entity The entity object.
 * @param {Statement[]} statements The array of statement objects.
 * @return {number} The confidence of the entity.
 */
function calculateEntityConfidence(entity, statements) {
  let totalScore = BASE_CONFIDENCE;
  let count = 0;

  // Loop through statements most recent first
  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];

    if (statement.confidence == null) {
      continue;
    }

    count++;

    // more recent statements are penalized/rewarded more
    const decay = Math.pow(DECAY_FACTOR, i);

    const decidedPro = statement.confidence > DECIDED_THRESHOLD;
    const decidedAgainst = statement.confidence < 1 - DECIDED_THRESHOLD;

    if (!decidedPro && !decidedAgainst) {
      continue;
    }

    let isCorrect = false;
    let isIncorrect = false;

    if (decidedPro) {
      isCorrect = entity.pids.some((pid) => statement.pro.includes(pid));
      isIncorrect = entity.pids.some((pid) => statement.against.includes(pid));
    } else if (decidedAgainst) {
      isCorrect = entity.pids.some((pid) => statement.against.includes(pid));
      isIncorrect = entity.pids.some((pid) => statement.pro.includes(pid));
    }

    // this allows us to weight the confidence equally for distance to 0 or 1
    const adjustedConfidence = Math.abs(statement.confidence - 0.5) * 2;

    if (isCorrect) {
      totalScore +=
        CORRECT_REWARD * (1 - totalScore) * decay * adjustedConfidence;
    } else if (isIncorrect) {
      totalScore +=
        INCORRECT_PENALTY * totalScore * decay * adjustedConfidence;
    }
  }

  if (count === 0) {
    return null;
  }

  return Math.max(0, Math.min(1, totalScore));
}
```

Separately, we calculate a `Claim` `Confidence` by:
```
/**
 * Calculate the confidence of a statement based on its entities.
 * @param {Statement} statement The statement id object.
 * @param {Entity[]} entities The array of entity objects.
 * @return {number} The nullable confidence of the statement.
 */
function calculateStatementConfidence(statement, entities) {
  if (entities.length === 0) {
    return null;
  }

  let weightedSum = 0;
  let totalWeight = 0;

  for (let i = 0; i < entities.length; i++) {
    const entity = entities[i];

    const pro =
      statement.pro?.some((pid) => entity.pids.includes(pid)) ?? false;
    const against =
      statement.against?.some((pid) => entity.pids.includes(pid)) ?? false;

    if (!pro && !against || !entity.confidence) {
      continue;
    }

    let confidence = entity.confidence;

    // Reverse confidence if the entity is "anti" the statement
    if (against) {
      confidence = 1 - confidence;
    }

    // Inverse Quadratic Weighting: weight = 1 - (1 - confidence)^2
    // This is done to weight high/lows confidence more heavily
    const weight = 1 - Math.pow(1 - confidence, 2);

    // Add to weighted sum
    weightedSum += weight * confidence;
    totalWeight += weight;
  }

  // if no entities have confidence, don't update
  if (totalWeight == 0) {
    return null;
  }

  // Calculate new confidence
  const newConfidence = weightedSum / totalWeight;

  // Ensure confidence is within [0, 1]
  return Math.max(0, Math.min(1, newConfidence));
}
```

Put simply, an Entity's confidence is calculated like a credit score, while a Statement's confidence is an average. We choose to trigger this only when our confidence in a claim changes beyond a defined `ConfidenceDelta`, so as to not overburden practical implementations. At any given snapshot, that is our best confidence that something is true, and can be applied to an `Entity`, `Claim`, or `Post`. As entities' confidence score changes, so does our confidence in the claims they make.

## Bias

> **Bias**: An angular grouping of `Entities` based on their `Posts`, `Claims`, `Opinions`, and `Phrases`, such that the closer the angle the more maximal the agreement.

<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 49 33 PM" src="https://github.com/kornha/political_think/assets/5386694/62593f14-ca77-4b0c-94ef-6fc7464b8b76">
  &nbsp;
  <img width="50" alt="Screenshot 2024-06-07 at 2 49 48 PM" src="https://github.com/kornha/political_think/assets/5386694/c07b063c-75f1-4050-99a1-7f3b0f5410b9">
  &nbsp;
  <img width="50" alt="Screenshot 2024-06-07 at 2 50 53 PM" src="https://github.com/kornha/political_think/assets/5386694/527d2bf4-c7ba-425f-be56-d48aea3bfd8a">
  &nbsp;
  <img width="50" alt="Screenshot 2024-06-07 at 2 47 29 PM" src="https://github.com/kornha/political_think/assets/5386694/40ebf810-a37a-45c8-b4fd-bfef17e7adad">
</div>

In principle, understanding political `Bias` requires a currency for comparing bias in different `Posts`, `Entities`, `Phrases` and `Opinions`. In practice to solve this problem, people will often say things like *right wing* or *left wing* or *progressive* or *conservative*. However, someone that is extremely conservative may agree with someone that is extremely liberal, how do we model this? 

Consider a *Parliamentary* (roll credits) system of government, in which there are different parties that appeal to different voter segments, which in turn correlates a party to bias groups. Let's say in our Parliament the seating is circular, and similar parties seat near one another. We can organize our Parliament by asking the following question:

### Bias Algorithm

*If I were to seat every member of Parliament at a round table, such that I wanted to maximize agreement and minimize the disagreement between a member and the two people sitting next to the member, how would I seat the people?* The reason this is chosen is more philosophical than mathematical, as it assumes there is a center, right, left, and anti-center, what we label the extreme. This is a mode of grouping that we find to be understandable by many people and is a manifestation of the _horseshoe theory_. If we accept this assumption, we mathematically represent bias as an angle between `0.0` and `360.0` degrees, and calculate angle updates by simple angular arithmetic. The full algorithm [written in the code](functions/ai/confidence.js).

```
/**
 * Takes in a list of iterables (entities or statements) and returns avg.
 * Accounts for whether the post is pro or against.
 * @param {Object[]} iterable A list of entities or statements.
 * @param {Object} target The target object, either an entity or statement.
 * @param {boolean} isEntityTarget Whether the target is an entity
 * @return {number} The bias (angle) of the entity or statement.
 * */
function calculateAverageBias(iterable, target, isEntityTarget) {
  let x = 0;
  let y = 0;
  let count = 0;

  // Loop through iterable to calculate the average angle
  for (let i = 0; i < iterable.length; i++) {
    const biasObj = iterable[i];

    if (biasObj.bias == null) {
      continue;
    }

    let pro = false;
    let against = false;

    if (isEntityTarget) {
      // Target is entity: Check if posts are in the pro/against lists
      pro = biasObj.pro?.some((pid) => target.pids.includes(pid)) ?? false;
      against = biasObj.against?.
          some((pid) => target.pids.includes(pid)) ?? false;
    } else {
      // Target is statement: does statement's lists contain the entity's posts
      pro = target.pro?.some((pid) => biasObj.pids.includes(pid)) ?? false;
      against = target.against?.
          some((pid) => biasObj.pids.includes(pid)) ?? false;
    }

    let bias = biasObj.bias;

    // Reverse the bias if it's in the against list
    if (against) {
      bias = (bias + 180) % 360;
    } else if (pro) {
      // do nothing
    }

    const angleInRadians = (bias * Math.PI) / 180;

    // Convert the angle to a vector and accumulate
    x += Math.cos(angleInRadians);
    y += Math.sin(angleInRadians);
    count++;
  }

  // If no valid biases, return null
  if (count === 0) {
    return null;
  }

  // Calculate the average vector direction
  const averageX = x / count;
  const averageY = y / count;

  // Convert the average vector back to an angle
  const averageBias = Math.atan2(averageY, averageX) * (180 / Math.PI);

  // Ensure the angle is in the range [0, 360)
  return (averageBias + 360) % 360;
}
```

### Center
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 47 29 PM" src="https://github.com/kornha/political_think/assets/5386694/40ebf810-a37a-45c8-b4fd-bfef17e7adad">
</div>

We represent the Center with the color Green. This is done to be analogous with American political colors. Left = Blue, Right = Red, hence RGB -> BGR and Green is center. Center content is defined as *content that right and left would each agree on or each disagree on*, and *content that disagrees with extreme*. In practice, these are people we seat 1/2 way between left and right at the top of our circle.
### Right
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 50 53 PM" src="https://github.com/kornha/political_think/assets/5386694/527d2bf4-c7ba-425f-be56-d48aea3bfd8a">
</div>

Right is our anchor. We need to choose the first people to seat. We define right pseudo-arbitrarily as a traditional conservative mentality;
- more likely than not to favor small government policy
- more likely than not to favor lower taxes and laissez faire economics
- more likely than not to favor family values
- more likely than not to express nationalism and patriotism
- more likely than not to favor stricter law and order measures

### Left
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 49 48 PM" src="https://github.com/kornha/political_think/assets/5386694/c07b063c-75f1-4050-99a1-7f3b0f5410b9">
</div>

Left is defined as those most opposite of our anchor, right. _content that right would most disagree with_. 

### Extreme
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 49 33 PM" src="https://github.com/kornha/political_think/assets/5386694/62593f14-ca77-4b0c-94ef-6fc7464b8b76">
</div>

Extreme, represented as pink (255,0,255) where green is (0,255,0), is defined as _content that right and left would each agree on or each disagree on_, _content that disagrees with center_, and _content that expresses `Opinions`, `Phrases`, and `Claims` which are likely to be disagreed with by consensus_.

Hence for a given claim we can now say how confident we are that it is true, and how biased are the people who are making it. Likewise for the entities we can record our confidence in their reporting, and how biased they tend to be. This provides significant value for us to understand and contextualize news. But how do we know _what_ news to show people? To answer this question, we must consider another concept, `Newsworthiness`.

## Newsworthiness

> **Newsworthiness**: The cross-bias consensus for how newsworthy a given `Story` is.

There is almost an unlimited amount of news, and choosing _what_ news to publish is a core part of any platform. For instance, a heavily biased platform may choose to publish news that corroborates their narrative more than news that supports a different narrative. Even within this context, regionalization of the platform, reader interest, and other aspects control _what_ gets published. Under the hood, something is filtering large amounts of information and deciding what is newsworthy. In contrast, social media feeds may show different news to different people, as what is important and interesting to one person may be different than to another. In aggregate some `Stories` and `Posts` will be shown more than others, but this may reflect the bias or even abuse of the platform or the algorithm. If we wish to label all `Stories`, we must determine a way they can be labeled without bias. To solve this question, we calculate `Newsworthiness`.

### Newsworthiness Algorithm

A heuristic would be to consider something newsworthy if it is discussed with high frequency. Social media feeds and news outlets rely on this heuristic significantly. As discussed, this is not sufficient, and it favors bias. However, if we already know bias as we have calculated above, we can consider something to be `Newsworthy` if it not only has a high frequency in our given publication period, but it also has a high frequency amongst some or all bias groups. This exact algorithm is still being calculated but it yields a number between `0.0` and `1.0` where `0.0` represents _the least possible newsworthy event_ and `1.0` represents _the most possible newsworthy event_. For regionalization we don't change the scale at all, it is a global concept from which we can still filter by region for localized news.

## Contextualization

> **Contextualization**: The cross-bias consensus for what information should be included in a `Story`.

News providers will invariably include different information when telling a `Story`. Based on the information included, a viewer may perceive content very differently. If we were to find cross-bias consensus on what `Contextualization` to include in a given `Story`, we could maximally ensure fairness in reporting.

### Contextualization Algorithm

We calculate contextualization by ensuring information reporting meets a `Center` degree of `Bias`. That is, if we have significant amount of centrist sources, we will aggregate their contextualization of a `Story` and use that in our reporting. For each `Claim`, `Opinion`, or `Phrase` that is beyond centrist, we should be sure to include labeling of the contextualization, as well as contextualization from the angular opposite. In this way, we are always reporting news with fair `Contextualization` that matches our `Centrist` `Bias`. 

## Concepts

### Story

A Story is an event that happened.
- It is created from a collection of Posts that are 'talking about the same thing.' (more on this below)
- A Story has a title and description which are raw captures of the Story's information.
- A Story has a headline, subHeadline, lede, and article which are the `Contextualization` of the story.
- A Story has a "happenedAt" timestamp, which represents when the event happened in the real world.
- A Story has a "newsworthiness" value, which is a number between 0.0 and 1.0, where 1.0 is the most possibly newsworthy event.
- A Story has a lat and long, which are the best estimates of the location of the Story.
- A Story may have photos, which are images that are associated with the Story.
- A Story may have Claims, which are statements that are either supported or refuted by the Posts.

### Post

A Post is a social media post (text, image, video), news article, or any other news source posting.
- A Post can have a title, a description, and a body, the latter two of which are optional.
- A Post may have images, videos or other media, or even link to other Posts.
- A Post has an author, which we call an Entity.
- A Post has a "sourceCreatedAt" time which represents when the Post was originally created on the social/news platform.
- A Post can belong to a Story and have Claims.

### Entity

An Entity is an author, sometimes one person and sometimes a whole news outlet, depending on the level of granularity that can be obtained.
- An Entity has a Bias and Confidence score tracking the Entity's history.
- An Entity is associated with a list of Posts, Claims, Opinions, and Phrases.
- An Entity has an associated Platform. (Possibly multiple but limited to singleton currently.)

### Platform

A Platform is the outlet to which an Entity publishes. It can be social (eg., X, Instagram), news (eg., BBC, NYT), or any other outlet.
- A Platform has associated with Entities.
- A Platform has metadata attributes like avg. likes, avg. replies, avg. reposts, avg. bookmarks, avg. views.

### Statement
A Statement is either a `Claim`, `Opinion`, or `Phrase`.

### Claim

A Claim is a statement about an event that is verifiable.
- A Claim is a statement that has "pro" and "against" list of Posts either supporting or refuting the Claim.
- A Claim has a "value" field, which is the statement itself.
- A Claim has a "pro" field, which is a list of Posts that support the Claim.
- A Claim has an "against" field, which is a list of Posts that refute the Claim.
- A Claim has a "context" field, which provides more information about the Claim, and helps for search. Not to be confused with "Contextualization".
- A Claim is fundamentally verifiable; a non-verifiable "claim" is called an `Opinion`.
- A Claim has an associated `Confidence`.
- A Claim has associated `Entities`.

### Opinion

An opinion is a statement about an event that is not verifiable.
- An Opinion is a statement that has "pro" and "against" list of Posts either supporting or rejecting the Opinion.
- An Opinion has a "value" field, which is the statement itself.
- An Opinion has a "pro" field, which is a list of Posts that support the Claim.
- An Opinion has an "against" field, which is a list of Posts that refute the Claim.
- An Opinion has a "context" field, which provides more information about the Claim, and helps for search. Not to be confused with "Contextualization".
- An Opinion is fundamentally non-verifiable; a verifiable "opinion" is called a `Claim`.
- An Opinion has an associated `Bias`.
- An Opinion has associated `Entities`.

### Phrase

A Phrase is a word or group of words that are used to express `Posts`, `Claims`, and `Opinions`.
- A Phrase utilizes repeated and specific language.
- A Phrase has an associated `Bias`.
- A Phrase has associated `Entities`.

# Contact
Parliament is open source. For questions related to this GitHub repo, please [join our discord](https://discord.gg/HhdBKsK9Pq) or raise an issue in this repo.

**Parliament Foundation** is a commercial hosted and deployed implementation of Parliament. Parliament is not affiliated with and does not endorse Parliament Foundation. For inquiries, contact contact@parliament.foundation.

## Socials
- **Discord**: Parliament currently an official [Discord server](https://discord.gg/HhdBKsK9Pq). Join the Discord to ask questions.
- **GitHub**: Parliament supports an official [GitHub](https://github.com/kornha/parliament) (the page you're reading now). You can create issues and feature requests in the repo.
- **X, Reddit, IG, Tiktok and Others**: No current accounts, but these will be created in the near future.

# Development

### Commitment to Zero Political Evangelism
Parliament is an apolitical project, and due to the sensitive nature of the information Parliament presents, it is reasonable to think that political actors may wish to get involved. Parliament requires all contributors to abide by a `Commitment to Zero Political Evangelism`. Anyone in violation of this will be banned from the project. Expect this to be clarified as we develop further.

You should **not** participate if you are a political activist looking to push a political agenda. Parliament is apolitical, and always will be.

## Why Participate?

> You believe in our mission.

There are serious quality issues with current news. It is often misleading, decontextualized, or even fake. Parliament is an apolitical solution to this problem. If, and only if, this mission is for you, only then do we recommend you contribute.

### Shared ownership

While Parliament is open-source and non-commercial, and the repo can be used and forked according to our use policy (coming soon), TheParliament.app (also coming soon) is the official commercial implementation of Parliament and the only implementation that can use Parliament branding. 
TheParliament.app is reserving a meaningful amount of equity for top contributors.

### Swag

Contributors with accepted commits get swag at different milestones. (Coming soon!)

### Learn

Learn Flutter, backend, and AI/ML.

## Getting started

### Discord
[Join our Discord](https://discord.gg/HhdBKsK9Pq) to start asking questions and becoming part of the community.

### Instructions

1. Clone Parliament to your machine.
2. Install our frontend framework [Flutter](https://docs.flutter.dev/get-started/install). If you are new we recommend running a sample Flutter app.

**Note:**
- If it is your first time using flutter, we recommend setting up the demo project first
- We support both web and mobile development in Flutter. If you are not an iOS or mobile specialist, we recommend you work with web.
  
3. (Optional for iOS) [Install XCode](https://apps.apple.com/us/app/xcode/id497799835?mt=12) on your machine. We currently use Version 14.
4. Setup a [Firebase](https://firebase.google.com/) project, which comes with free credits.
5. Add an iOS and/or web project. Replace your variables in the `.env`, `firebase.json`, and `.firebaserc` files under the project root folder.

**Note:**
- `flutterfire` helps connect flutter to the Firebase/GCP project.
- Upon creating a Firebase project, you also have a GCP project.
   
6. (Strongly recommended) We recommend using [Flutterfire CLI](https://firebase.google.com/docs/flutter/setup?platform=ios) to assist your setup. Be sure to run through this end to end to connect your Flutter project to Firebase.

**Note:**
- Use the firebase emulator to develop locally.
- In `main.dart` you can set the `local` variable to true or false to direct the Flutter app to run locally.

7. (Optional, installed with firebase) familiarize with Firebase [emulator](https://firebase.google.com/docs/emulator-suite) for ease of development.
8. You will need to ensure Firestore, Firebase Auth, Google Sign in, Firebase Storage are enabled. Google each of these if there is any issue. Google sign in will not be handled by Flutterfire CLI, but enabling it is trivial. To enable, in Firebase select auth, and google sign in.
9. You will need to enable GCP secrets manager api, and a billing account. You can skip but will lead to limitations.

**Note:**
- We use Node JS version 20 for our backend.
- The code is inside the root project, under functions/.
    
10. You will need [NodeJS](https://nodejs.org/en/download/package-manager) on your machine.
11. Setup an an [OpenAI account](https://platform.openai.com/), which comes with free credits.
12. (Optional for advanced X scraping) Setup an X account that is Premium, (paid, can skip for simpler development).
13. (Optional for advanced news API) Setup an account with [Newsapi.ai](https://newsapi.ai/). This comes with free credits.
14. (Optional for maps support) Enable [Static Maps API](https://console.cloud.google.com/google/maps-apis/) in your new [Google Cloud](cloud.google.com) Project, which got created when you created a Firebase project. From there, you will need to setup your Maps API. Setup `dark_mode Static – Raster` and `light_mode Static – Raster` maps. For each map, add a style that matches the colors in Parliament's [palette](/lib/common/constants.dart#L9), by making the water equal the background color, and the surface equal the `primaryColor` from the [theme](/lib/common/ztheme.dart#L8). All borders are set to the onPrimaryColor.

**Note:**
- VSCode is our recommended IDE, or a VSCode fork/compatible IDE.
- Try running the backend and frontend in different IDE windows.
- If you are not using VSCode, each following the build prompts in launch.json and package.json for Frontend and Backend respectively.

15. Start building your Flutter web/ios app by clicking on Run > Start Debugging in VSCode.
16. After that, your Node by clicking on Run > Start Debugging in VSCode.
17. It's possible you might need to tweak your VSCode run script.

**Note:** 
- After completing steps 15. and 16., a website window/iOS app should open.
  
18. Once the Parliament web page is open, log in by pressing "Sign in with G" at the bottom of the screen.
19. Add a post by clicking on the plus symbol at the upper-right of the window "+".
20. Click to paste an X.com link that has text only or text and one image, and paste it into the box in the center of the screen where it says "Paste a link here" by clicking anywhere in that region.

**Note:** 
- If you are running this on a computer with 8 GB ram or less, it is recommended that you close all windows or any running applications to free as much space as possible since, generate step will requires a lot of RAM space.
- You should see Chromium pop up twice, if it takes too long for it to run that means that you need to pay attention to your RAM space.
 
21. To generate a story click on the green buttion "Generate" in the upper right center of the window.

**Note:** 
Firebase may prompt you to add env vars, but if it doesn't, or if you run into billing or other account setup issues, Googling them should be straightforward to solve.
Feel free to add helpful info to this readme.

22. Afterwards press "generate". From here, navigate back to the home screen, pull to refresh, and if you see a Story you are set up!

For any questions connect in our [Discord](https://discord.gg/HhdBKsK9Pq).

