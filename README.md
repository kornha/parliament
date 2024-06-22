<div align="center">
  <picture>
    <source srcset="https://github.com/kornha/political_think/assets/5386694/0f8fd310-eef9-41d9-b94e-64c3f74d788b" media="(prefers-color-scheme: dark)" width="100">
    <source srcset="https://github.com/kornha/political_think/assets/5386694/d73da709-c502-4aa5-8e4b-30147c7024ca" media="(prefers-color-scheme: light)" width="100">
    <img src="https://github.com/kornha/political_think/assets/5386694/d73da709-c502-4aa5-8e4b-30147c7024ca" alt="logo_white">
  </picture>
</div>

# Parliament

![In Progress](https://img.shields.io/badge/status-pre%20release-blue)

**Parliament** is an open-source news project that organizes news by `Confidence`, `Bias`, `Newsworthiness`, and `Context` to tell maximally truthful news in a clear and measurable way.

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
        1. [Algorithm](#algorithm)
    4. [Bias](#bias)
        1. [Algorithm](#algorithm)
        2. [Center](#center)
        3. [Right](#right)
        4. [Left](#left)
        5. [Extreme](#extreme)
    5. [Newsworthiness](#newsworthiness)
        1. [Algorithm](#algorithm)
    6. [Context](#context)
        1. [Algorithm](#algorithm)
    7. [Concepts](#concepts)
        1. [Story](#story)
        2. [Post](#post)
        3. [Entity](#entity)
        4. [Claim](#claim)
        5. [Opinion](#opinion)
        6. [Phrase](#phrase)
2. [Development](#development)
    1. [Why Participate?](#why-participate)
        1. [Shared ownership](#shared-ownership)
        2. [Swag](#swag)
        3. [Learn](#learn)
    2. [Getting started](#getting-started)
        1. [Discord](#discord)
        2. [Instructions](#instructions)   
        3. [Flutter](#flutter)
        4. [Firebase](#firebase)
        5. [AI/ML](#aiml)

# Whitepaper 

### Credible News

![In Progress](https://img.shields.io/badge/status-in%20progress-yellow)

## Mission

> Parliament's mission is telling maximally truthful news in a clear and measurable way.

Think about how you understand news. You may consume one or multiple news sources. It may be social media content, cable news, online or print news, your favorite Telegram group, or another news provider. Ultimately, you will infer the claims these sources are making, and when you are sufficiently satisfied, you will either arrive at a conclusion about what you think has happened or consider yourself unsure. Implicitly, you are assigning a unique judgment value to various news outlets, favoring the credibility of some over others. Once you have enough credible confirmations for your own personal threshold, you may consider something to be effectively true. 

For people, our perceived credibility in certain outlets is weighed by many things, including our `Confidence` in the accuracy of the outlet (*this X account has been right many times, so they're probably correct now*), and by our `Bias` towards the outlet (*this news provider conforms to my beliefs of the world, so I'll trust their interpretation*). 

We also perceive some news events to be more important than others. This may be due to various factors, such as ramifications that impact our lives, significant geopolitical events, events that confirm or reject our beliefs, local concerns, unique occurrences (_man bites dog_), or other considerations. For example, on August 9, 1974, when the New York Times published *NIXON RESIGNS* in capital letters on their front page, they were expressing significant urgency in the event. While the importance of the `Story` is different to each person, i.e., it may have been more interesting to an American autoworker than to a Nepalese farmer, the New York Times felt it was newsworthy enough for their audience to warrant an all-caps title. This judgment we call `Newsworthiness`.

News, when told, also includes a varying contextualization around the event that may significantly alter our understanding and perception of an event. In the most simplest case, an image can be so powerful, only to reverse its meaning when it is zoomed out. The fairness and completeness around which a `Story` is told we call `Context`. 

Each human consumes news differently due to their unique experiences and circumstances. This is partly why the same event can be perceived so differently by different individuals. 
Parliament's mission is to tell maximally truthful news in a clear and measurable way.

Let's dive further.

## Confidence

> **Confidence**: The likelihood of something being true based on how true it has been in the past.

How do we know that something is true? This is a philosophical question, and there are several product approaches to addressing it. X, for instance, relies on community notes. FactCheck.org focuses on fact-checking. These two approaches work by direct content validation. A strategy that, when implemented correctly, can be extremely accurate.
Parliament takes what you may call the additional level of abstraction to the above. In the view of Parliament, FactCheck.org, @elonmusk, X fact checker, NYT, a random account on IG, etc. are each what we call an `Entity`. Otherwise put, Parliament does use fact checkers too, it just tries to use all of them. And, based on if they've been right or wrong in the data we've collected, we know how much to trust them going forward. In this mode of thinking, we can assign news `Confidence` scores, a score between `0.0` and `1.0`, where 0 represents *maximal certainty that something is false*, and 1.0 represents *maximal certainty that something is true*. Total certainty is unknowable, and both 0.0 and 1.0 can never be achieved.

### Algorithm

We will only cover a high level of the confidence algorithm here, as the specifics are written in the code. 

Let us say as a human I am introduced to a new user on X/IG/TikTok etc. Now, depending on who introduced me, perhaps the platform's algorithm, perhaps a friend, I may view content differently. Regardless, I will have a measure of doubt as to how much I trust the author (aka `Entity`), which may change over time.

At Parliament we assume new sources are of even uncertainty; currently we assume new people are 50% likely to be honest.

We then look at the `Claims` a given `Entity` has made. If these claims are mutually agreed on by many parties, old and new, we can start to collect a `Consensus` on a claim, much like a blockchain algorithm, which is a possible future implementation. Once claims form a level of consensus, we can then punish the people who have been wrong, and reward the people who have been right. Of course, once we punish/reward the `Entities`, other claims may change consensus, creating a finite ripple effect.

Currently we track confidence in an entity by:
```
running_average = 1.0;
for each claim of Entity.claims:
  running_average = claim.consensus_confidence * correct_or_incorrect_scalar * running_average;
Entity.confidence = running_average / num_claims;
```
Essentially tracking the average confidence. As we evolve the algorithm, we seek to punish incorrect claims exponentially and reward correct claims incrementally. We may choose to trigger this only when our confidence in a claim changes beyond a defined `ConfidenceDelta`, so as to not overburden practical implementations. At any given snapshot, that is our best confidence that something is true, and can be applied to an `Entity`, `Claim`, or `Post`. As entities' confidence score changes, so does our confidence in the claims they make.

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

### Algorithm

*If I were to seat every member of Parliament at a round table, such that I wanted to maximize agreement and minimize the disagreement between a member and the two people sitting next to the member, how would I seat the people?* The reason this is chosen is more philosophical than mathematical, as it assumes there is a center, right, left, and anti-center, what we label the extreme. This is a mode of grouping that we find to be understandable by many people and is a manifestation of the _horseshoe theory_. If we accept this assumption, we mathematically represent bias as an angle between `0.0` and `360.0` degrees, and calculate angle updates by simple angular arithmetic.

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

### Algorithm

A heuristic would be to consider something newsworthy if it is discussed with high frequency. Social media feeds and news outlets rely on this heuristic significantly. As discussed, this is not sufficient, and it favors bias. However, if we already know bias as we have calculated above, we can consider something to be `Newsworthy` if it not only has a high frequency in our given publication period, but it also has a high frequency amongst some or all bias groups. This exact algorithm is still being calculated but it yields a number between `0.0` and `1.0` where `0.0` represents _the least possible newsworthy event_ and `1.0` represents _the most possible newsworthy event_. For regionalization we don't change the scale at all, it is a global concept from which we can still filter by region for localized news.

## Context

> **Context**: The cross-bias consensus for what information should be included in a `Story`.

News providers will invariably include different information when telling a `Story`. Based on the information included, a viewer may perceive content very differently. If we were to find cross-bias consensus on what `Context` to include in a given `Story`, we could maximally ensure fairness in reporting.

### Algorithm

We calculate context by ensuring information reporting meets a `Center` degree of `Bias`. That is, if we have significant amount of centrist sources, we will aggregate their contextualization of a `Story` and use that in our reporting. For each `Claim`, `Opinion`, or `Phrase` that is beyond centrist, we should be sure to include labeling of the context, as well as context from the angular opposite. In this way, we are always reporting news with fair `Context` that matches our `Centrist` `Bias`. 

## Concepts

### Story

A Story is an event that happened.
- It is created from a collection of Posts that are 'talking about the same thing.' (more on this below)
- A Story has a title, a description, a headline, a subheadline, which are textual descriptions of the Story.
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

### Claim

A Claim is a statement about an event that is verifiable.
- A Claim is a statement that has "pro" and "against" list of Posts either supporting or refuting the Claim.
- A Claim has a "value" field, which is the statement itself.
- A Claim has a "pro" field, which is a list of Posts that support the Claim.
- A Claim has an "against" field, which is a list of Posts that refute the Claim.
- A Claim has a "context" field, which provides more information about the Claim, and helps for search.
- A Claim is fundamentally verifiable; a non-verifiable "claim" is called an `Opinion`.
- A Claim has an associated `Confidence`.
- A Claim has associated `Entities`.

### Opinion

An opinion is a statement about an event that is not verifiable.
- An Opinion is a statement that has "pro" and "against" list of Posts either supporting or rejecting the Opinion.
- An Opinion has a "value" field, which is the statement itself.
- An Opinion has a "pro" field, which is a list of Posts that support the Claim.
- An Opinion has an "against" field, which is a list of Posts that refute the Claim.
- An Opinion has a "context" field, which provides more information about the Claim, and helps for search.
- An Opinion is fundamentally non-verifiable; a verifiable "opinion" is called a `Claim`.
- An Opinion has an associated `Bias`.
- An Opinion has associated `Entities`.

### Phrase

A Phrase is a word or group of words that are used to express `Posts`, `Claims`, and `Opinions`.
- A Phrase utilizes repeated and specific language.
- A Phrase has an associated `Bias`.
- A Phrase has associated `Entities`.

# Contact
Parliament is open source. For questions related to this GitHub repo, please raise an issue in this repo.

TheParliament.app (to be released shortly) is a commercial hosted and deployed implementation of Parliament. For investment information and other queries, please email <a href="mailto:contact@theparliament.app">contact@theparliament.app</a>.

# Development

![Instructions Coming Soon](https://img.shields.io/badge/status-instructions%20coming%20soon-green)

## Why Participate?

> You believe in our mission.

There are serious quality issues with current news. It is often misleading, decontextualized, or even fake. Parliament is an apolitical solution to this problem. If, and only if, this mission is for you, only then do we recommend you contribute.

You should **not** participate if you are a political activist looking to push a political agenda. Parliament is apolitical, and will always be.

### Shared ownership

While Parliament is open-source and non-commercial, and the repo can be used and forked according to our use policy (coming soon), TheParliament.app (also coming soon) is the official commercial implementation of Parliament and the only implementation that can use Parliament branding. 
TheParliament.app is reserving a meaningful amount of equity for top contributors.

### Swag

Contributors with accepted commits get swag at different milestones.

### Learn

Learn Flutter, backend, and AI/ML.

## Getting started

### Discord
[Join our Discord](https://discord.gg/HhdBKsK9Pq)

### Instructions

Install Flutter, Firebase, node, XCode on your machine.
Set up your own OpenAI and Firebase account. 
Set up the Firebase emulator locally.

Firebase may prompt you to add env vars, but if it doesn't, or if you run into billing or other account setup issues, Googling them should be straightforward to solve.
Feel free to add helpful info to this readme.

Once you run the project correctly, the frontend will appear in either iOS or web. You may sign in with Google and click the sync button in the top right.
When you click sync, after some moments, it will generate a list of Stories and Posts, resembling our news feed. From here you're set up!

### Flutter

All changes must be compatible for Flutter web, iOS, and Android.
In general we ask that you do not try and change many patterns unless there is discussion beforehand and approved by repo owner.
Spend some time studying the repo's use of Riverpod, BuildContext extensions, and other Flutter development patterns.
Note that we use declarative programming almost entirely in the fullstack application.

### Firebase

We are running Node.js functions on Firebase Functions. We use several additional Firebase services, including Firestore, Pubsub, Storage, and Auth. 
Feel free to study the repo's patterns and suggest changes. 

### AI/ML

We have complex AI strategies to solve our news problem. We strongly recommend deeply examining the logic before contributing to this portion.
We have chosen not to use a wrapper framework for now purely out of dev simplicity in directly using OpenAI APIs. 

