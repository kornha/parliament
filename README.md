<div align="center">
  <picture>
    <source srcset="https://github.com/kornha/political_think/assets/5386694/0f8fd310-eef9-41d9-b94e-64c3f74d788b" media="(prefers-color-scheme: dark)" width="100">
    <source srcset="https://github.com/kornha/political_think/assets/5386694/d73da709-c502-4aa5-8e4b-30147c7024ca" media="(prefers-color-scheme: light)" width="100">
    <img src="https://github.com/kornha/political_think/assets/5386694/d73da709-c502-4aa5-8e4b-30147c7024ca" alt="logo_white">
  </picture>
</div>

# Parliament

![In Progress](https://img.shields.io/badge/status-pre%20release-blue)

**Parliament** is an open-source news project that organizes news into `Confidence`, `Bias`, and `Importance` to tell maximally truthful news in a clear and measurable way.

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
2. [Development](#development)

# Whitepaper

### Credible News

## Mission

> Parliament's mission is telling maximally truthful news in a clear and measurable way.

Think about how you understand news. You may consume one or multiple news sources. It may be social content, cable news, print news, your favorite Telegram group, or a handful of other news points. Ultimately, you will infer the claims these sources are making, and when you are sufficiently satisfied you will either arrive at a conclusion about what you think has happened, or consider yourself unsure. Implicitly, you are assigning a judgment value to various news outlets, favoring the credibility of some over others. Once you have enough credible confirmations for your own personal standard, you may consider something to be effectively true. 

One aspect of this credibility scoring is your `Confidence` in the news outlet. For people, our confidence in certain outlets is weighed by many things, including our history with the outlet (this X account has been right many times), and also by our `Bias` towards the outlet (this news provider conforms to my beliefs of the world). And finally, we get riled up by news that appears in large, bold headlines, like *NIXON RESIGNS*. News goes viral. News commentators globally will discuss `Stories`, with variable geograpghy, at different levels of frequency. This score we call `Importance`.

Each human consumes news differently due to their unique experiences and circumstances. This is partly why news is perceived so differently by different individuals. Parliament's mission to abstract these variables to tell maximally truthful news in a clear and measureable way.

Let's dive further.

## Confidence

> **Confidence**: The likelihood of something being true based on how true it has been in the past.

How do we know that something is true? This is a philosophical question, and there are several product approaches to addressing it. X, for instance, relies on community notes. FactCheck.org focuses on fact checking. These two approaches work by direct content validation. A strategy that, when implemented correctly, can be extremely accurate.
Parliament takes what you may call the additional level of abstraction to the above. In the view of Parliament, FactCheck.org, @elonmusk, X fact checker, NYT, a random account on IG, etc. are each we call an `Entity`. Otherwise put, Parliament does use fact checkers too, it just tries to use all of them. And, based on if they've been right or wrong in the data we've collected, we know how much to trust them going forward. In this mode of thinking, we can assign news `Confidence` scores, a score between `0.0` and `1.0`, where 0 represents *maximal certainty that something is false*, and 1.0 represents *maximal certainty that something is true*. Total certainty is unknowable, and both 0.0 and 1.0 can never be acheived.

### Algorithm

![In Progress](https://img.shields.io/badge/status-in%20progress-yellow)

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

Consider a *Parliamentary* (roll credits) system of government, where there are different parties that appeal to different voter segments, which in turn correlates a party to a bias groups. We can organize our Parliament by asking the following question:

### Algorithm
![In Progress](https://img.shields.io/badge/status-in%20progress-yellow)

*If I were to seat every member of Parliament at a round table, such that I wanted to maximize agreement and minimize the disagreement between a member and the two people sitting to next to the member, how would I seat the people?* The reason this is chosen is more philosphical than mathetical, as it assumes there is a center, right, left, and the antithesis union of right and left, the extreme. This is a manifestation of the _horseshoe theory_. If we accept this assumption, we mathetically represent bias as an angle between 0.0 and 360.0 degrees, and calculate angle updates by simple angular arithmatic.

### Center
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 47 29 PM" src="https://github.com/kornha/political_think/assets/5386694/40ebf810-a37a-45c8-b4fd-bfef17e7adad">
</div>

We represent the Center with the color Green. This is done to be analoguous with American political colors. Left = Blue, Right = Red, hence RGB -> BGR and Green is center. Center content is defined as *content that right and left would each agree on or each disagree on*, and *content that disagrees with extreme*. In practice, these are people we seat 1/2 way between left and right, on the less fringe side.

### Right
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 50 53 PM" src="https://github.com/kornha/political_think/assets/5386694/527d2bf4-c7ba-425f-be56-d48aea3bfd8a">
</div>

Right is our anchor. We need to choose the first people to seat. We arbitrarily choose right as a vuiew that tends to favor certain political preferences. We define right pseudo-arbitrarily as a traditional conservative mentality;
- more likely than not to favor small government policy
- more likely than not to favor lower taxes and laissez faire economics
- more likely than not to be restrictive on abortion policies
- more likely than not to favor stricter law and order measures
- more likely than not to perceive alternative sexual preferences antognistically

### Left
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 49 48 PM" src="https://github.com/kornha/political_think/assets/5386694/c07b063c-75f1-4050-99a1-7f3b0f5410b9">
</div>

Left is defined at those most opposite of our anchor, right. _content that right would most disagree with_. 

### Extreme
<div align="start">
  <img width="50" alt="Screenshot 2024-06-07 at 2 49 33 PM" src="https://github.com/kornha/political_think/assets/5386694/62593f14-ca77-4b0c-94ef-6fc7464b8b76">
</div>

Extreme, represented as pink (255,0,255) where green is (0,255,0), is defined as _content that right and left would each agree on or each disagree on_, and _content that disagrees with center_. In order to anchor our graph, extreme is content associated with offensive and extreme terms, or content that 'looks' extreme.

We incrementally update a Bias based on `Claims`, `Opinions` and `Phrases`.

Hence for a given claim we can now say how confident we are it is true, and how biased are the people who are making it. Likewise for the entities we can record our confidence in their reporting, and how biased they tend to be. Determining mathematical truth from here is trivial.

# Development
Parliament includes a website theparliament.app, with iOS and Android (coming soon) in the repo as well. The Parliament whitepaper above is being implemented in this repo with Firebase, OpenAI, and GitHub. Additional contributors are welcome.

## Flutter

Install flutter and run this as a flutter project using an IDE of your choice. We recommend VSCode. You can currently run this on iOS and web locally.

## Firebase

We are running Node.js functions on Firebase Functions. We use several additional Firebase services including Firestore, Pubsub, Storage, and Auth. 
