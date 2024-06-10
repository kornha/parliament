<div align="center">
  <picture>
    <source srcset="https://github.com/kornha/political_think/assets/5386694/0f8fd310-eef9-41d9-b94e-64c3f74d788b" media="(prefers-color-scheme: dark)" width="100">
    <source srcset="https://github.com/kornha/political_think/assets/5386694/d73da709-c502-4aa5-8e4b-30147c7024ca" media="(prefers-color-scheme: light)" width="100">
    <img src="https://github.com/kornha/political_think/assets/5386694/d73da709-c502-4aa5-8e4b-30147c7024ca" alt="logo_white">
  </picture>
</div>

# Parliament

![In Progress](https://img.shields.io/badge/status-pre%20release-blue)

**Parliament** is an open-source news project that organizes news into `Confidence`, `Bias`, and `Newsworthiness` to tell maximally truthful news in a clear and measurable way.

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
    5. [Newsworthiness](#newsworthiness)
        1. [Algorithm](#algorithm)
    6. [Concepts](#concepts)
        1. [Story](#story)
        2. [Post](#post)
        3. [Entity](#entity)
        4. [Claim](#claim)
        5. [Opinion](#opinion)
        6. [Phrase](#phrase)
2. [Development](#development)

# Whitepaper 

### Credible News

![In Progress](https://img.shields.io/badge/status-in%20progress-yellow)

## Mission

> Parliament's mission is telling maximally truthful news in a clear and measurable way.

Think about how you understand news. You may consume one or multiple news sources. It may be social content, cable news, print news, your favorite Telegram group, or a handful of other news points. Ultimately, you will infer the claims these sources are making, and when you are sufficiently satisfied you will either arrive at a conclusion about what you think has happened, or consider yourself unsure. Implicitly, you are assigning a judgment value to various news outlets, favoring the credibility of some over others. Once you have enough credible confirmations for your own personal standard, you may consider something to be effectively true. 

One aspect of this credibility scoring is your `Confidence` in the news outlet. For people, our confidence in certain outlets is weighed by many things, including our history with the outlet (this X account has been right many times), and also by our `Bias` towards the outlet (this news provider conforms to my beliefs of the world). And finally, we get riled up by news that appears in large, bold headlines, like *NIXON RESIGNS*. News goes viral. News commentators globally will discuss `Stories`, with variable geograpghy, at different levels of frequency. This score we call `Newsworthiness`.

Each human consumes news differently due to their unique experiences and circumstances. This is partly why news is perceived so differently by different individuals. Parliament's mission to abstract these variables to tell maximally truthful news in a clear and measureable way.

Let's dive further.

## Confidence

> **Confidence**: The likelihood of something being true based on how true it has been in the past.

How do we know that something is true? This is a philosophical question, and there are several product approaches to addressing it. X, for instance, relies on community notes. FactCheck.org focuses on fact checking. These two approaches work by direct content validation. A strategy that, when implemented correctly, can be extremely accurate.
Parliament takes what you may call the additional level of abstraction to the above. In the view of Parliament, FactCheck.org, @elonmusk, X fact checker, NYT, a random account on IG, etc. are each we call an `Entity`. Otherwise put, Parliament does use fact checkers too, it just tries to use all of them. And, based on if they've been right or wrong in the data we've collected, we know how much to trust them going forward. In this mode of thinking, we can assign news `Confidence` scores, a score between `0.0` and `1.0`, where 0 represents *maximal certainty that something is false*, and 1.0 represents *maximal certainty that something is true*. Total certainty is unknowable, and both 0.0 and 1.0 can never be acheived.

### Algorithm

We will only cover a high level of the confidence algorithm here, as the specifics are written in the code. 

Let us say as a human I am introduced to a new user on X/IG/Tiktok etc. Now, depending on who introduced me, perhaps the paltform's algorithm, perhaps a friend, I may view content differently. Regardless, I will have a measure of doubt as to how much I trust the author (aka `Entity`), which may change over time.

At Parliament we assume new sources are of even uncertainty; currently we assume new people 50% likely to be honest.

We then look at the `Claims` a given `Entity` as made. If these claims have are mutually agreed on by many parties, old and new, we can start to collect a `Consensus` on a claim, much like a blockchain algorithm, which is an possible future implementation. Once claims form a level of consensus, we can then punish the people who have been wrong, and reward the people who have been right. Of course, once we punish/reward the `Entities`, other claims may change consensus, creating a finite ripple effect.

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

Consider a *Parliamentary* (roll credits) system of government, in which there are different parties that appeal to different voter segments, which in turn correlates a party to bias groups. Let's say in our Parliament the seating is circular, and simlar parties seat near one another. We can organize our Parliament by asking the following question:

### Algorithm

*If I were to seat every member of Parliament at a round table, such that I wanted to maximize agreement and minimize the disagreement between a member and the two people sitting to next to the member, how would I seat the people?* The reason this is chosen is more philosphical than mathetical, as it assumes there is a center, right, left, and the antithesis union of right and left, the extreme. This is a manifestation of the _horseshoe theory_. If we accept this assumption, we mathetically represent bias as an angle between `0.0` and `360.0` degrees, and calculate angle updates by simple angular arithmetic.

### Center
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 47 29 PM" src="https://github.com/kornha/political_think/assets/5386694/40ebf810-a37a-45c8-b4fd-bfef17e7adad">
</div>

We represent the Center with the color Green. This is done to be analoguous with American political colors. Left = Blue, Right = Red, hence RGB -> BGR and Green is center. Center content is defined as *content that right and left would each agree on or each disagree on*, and *content that disagrees with extreme*. In practice, these are people we seat 1/2 way between left and right, but absent of fringe views.

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

Left is defined at those most opposite of our anchor, right. _content that right would most disagree with_. 

### Extreme
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 49 33 PM" src="https://github.com/kornha/political_think/assets/5386694/62593f14-ca77-4b0c-94ef-6fc7464b8b76">
</div>

Extreme, represented as pink (255,0,255) where green is (0,255,0), is defined as _content that right and left would each agree on or each disagree on_, _content that disagrees with center_, and _content that expresses `Opinions`, `Phrases`, and `Claims` which will are likely to be deemed offensive by other groupings_.

Hence for a given claim we can now say how confident we are that it is true, and how biased are the people who are making it. Likewise for the entities we can record our confidence in their reporting, and how biased they tend to be. This provides significant value for us to understand and contextualize news. But how do we know _what_ news to show people? To answer this question, we must consider another concept, `Newsworthiness`.

## Newsworthiness

> **Newsworthiness**: The cross-bias consensus for how newsworthy a given `Story` is.

There is almost an unlimited amount of news, and choosing _what_ news to publish is a core part of any platform. For instance, a heavily biased platform may choose to publish news that corroborates their narrative more than news that supports a different narrative. Even within this context, regionalization of the platform, reader interest, and other aspects control _what_ gets published. Under the hood, something is filtering large amounts of information and deciding what is newsworthy. In contrast, social media feeds may show different news to different people, as what is important and interesting to one person may be different than to another. In aggregate some `Stories` and `Posts` will be shown more than others, but this may reflect the bias or even abuse of the platform or the algorithm. If we wish to label all `Stories`, we must determine a way they can be labeled without bias. To solve this question, we calculate `Newsworthiness`.

### Algorithm

A heuristic would be to consider something newsworthy if it is discussed with high frequency. Social media feeds and news outlets rely on this heuristic significantly. As discussed, this is not sufficient, and it favors bias. However, if we already know bias as we have calculated above, we can consider something to be `Newsworthy` if it not only has a high frequency in our given publication period, but it also has a high frequency amongst some or all bias groups. This exact algorithm is still being calculated but it yields a number between `0.0` and `1.0` where `0.0` represents _the least possible newsworthy event_ and `1.0` represents _the most possible newsworthy event_. For regionalization we don't change the scale at all, it is a global concept from which we can still filter be region for localized news.

## Concepts

### Story

A Story is an event that happened.
- It is created from a collection of Posts that are 'talking about the same thing.' (more on this below)
- A Story has a title, a description, a headline, a subheadline, which are textual descriptions of the Story.
- A Story has a "happenedAt" timestamp, which represents when the event happened in the real world.
- A Story has an "newsworthiness" value, which is a number between 0.0 and 1.0, where 1.0 is the most possibly newsworthy event.
- A Story has a lat and long, which are the best estimates of the location of the Story.
- A Story may have photos, which are images that are associated with the Story.
- A Story may have Claims, which are statements that are either supported or refuted by the Posts.

### Post

- A Post is a social media posting or an article. It can come from X (Twitter), Instagram, or other social sources.
- It may also be a news article published to an online platform.
- A Post can have a title, a description, and a body, the latter two of which are optional.
- A Post may have images, videos or other media, or even link to other Posts.
- A Post has an author, which we call an Entity.
- A Post has a "sourceCreatedAt" time which represents when the Post was originally created on the social/news platform.
- A Post can belong to a Story and have Claims.

### Entity

- An Entity is an auther, sometimes one person and sometimes a whole news outlet, depending on the level of granularity that can be obtained.
- An Entity has a Bias and Confidence score tracking the Entity's history.
- An Entity is associated with a list of Posts, Claims, Opinions, and Phrases.

### Claim

- A Claim is a statement that has "pro" and "against" list of Posts either supporting or refuting the Claim.
- A Claim has a "value" field, which is the statement itself.
- A Claim has a "pro" field, which is a list of Posts that support the Claim.
- A Claim has an "against" field, which is a list of Posts that refute the Claim.
- A Claim has a "context" field, which provides more information about the Claim, and helps for search.
- A Claim is fundemtally verifiable; a non-verfiable "claim" is called an `Opinon`.
- A Claim has an associated `Confidence`.
- A Claim has associated `Entities`

### Opinion

- A Opinion is a statement that has "pro" and "against" list of Posts either supporting or rejecting the Opinion.
- A Opinion has a "value" field, which is the statement itself.
- A Opinion has a "pro" field, which is a list of Posts that support the Claim.
- A Opinion has an "against" field, which is a list of Posts that refute the Claim.
- A Opinion has a "context" field, which provides more information about the Claim, and helps for search.
- A Opinion is fundemtally non-verifiable; a verfiable "opinion" is called an `Claim`
- An Opinion has an associated `Bias`.
- An Opinon has associated `Entities`.

### Phrase

- A Phrase is a word or group of words that are used to express `Posts`, `Claims`, and `Opinions`.
- A Phrase utilizes repeated and specific language.
- A Phrase has an associated `Bias`.
- A Phrase has associated `Entities`.

# Contact
Parliament is open source. TheParliament.app (to be released shortly) is a commercial hosted and deployed implemenation of Parliament. For investment information and other queries, please email <a href="mailto:contact@theparliament.app">contact@theparliament.app</a>.

# Development
Parliament includes a website theparliament.app, with iOS and Android (coming soon) in the repo as well. The Parliament whitepaper above is being implemented in this repo with Firebase, OpenAI, and GitHub. Additional contributors are welcome.

## Flutter

Install flutter and run this as a flutter project using an IDE of your choice. We recommend VSCode. You can currently run this on iOS and web locally.

## Firebase

We are running Node.js functions on Firebase Functions. We use several additional Firebase services including Firestore, Pubsub, Storage, and Auth. 
