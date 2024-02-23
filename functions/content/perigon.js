const functions = require("firebase-functions");
const {Timestamp} = require("firebase-admin/firestore");
const {getPost, bulkSetPosts,
  getStory, setStory} = require("../common/database");


const apiKey = "4e075db6-ebca-4ded-8faf-313affbd7650";
const storiesBase = "https://api.goperigon.com/v1/stories/all?";
const articlesBase = `https://api.goperigon.com/v1/all?`;
const maxStoriesPerFetch = 3; // needed to not throttle gpt
const maxArticlesPerFetch = 3; // needed to not throttle gpt


// ////////////////////////////
// Perigon APIs
// ////////////////////////////

const fetchFromPerigon = async function() {
  const pstories = await getPerigonStories();
  if (!pstories) {
    return;
  }

  for (const pstory of pstories) {
    const story = _toStory(pstory);
    const dbStory = await getStory(story.sid);
    if (dbStory) {
      if (dbStory.updatedAt >= new Date(pstory.updatedAt).getTime()) {
        continue;
      }
      story.createdAt = dbStory.createdAt;
      story.updatedAt = Timestamp.now().toMillis();
    }
    const articles = await getArticles(pstory);
    const posts = [];
    for (const article of articles) {
      const post = _toPost(story, article);
      const dbPost = await getPost(article.articleId);
      if (dbPost) {
        if (dbPost.updatedAt >= new Date(article.refreshDate).getTime()) {
          continue;
        }
        post.createdAt = dbPost.createdAt;
        post.updatedAt = Timestamp.now().toMillis();
      }
      posts.push(post);
    }
    return setStory(story).then((result) => {
      if (result) {
        bulkSetPosts(posts);
      }
    });
  }
};


const getPerigonStories = async function() {
  // const last12hr = new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString();
  const last36hr = new Date(Date.now() - 36 * 60 * 60 * 1000).toISOString();
  // const last12hr = new Date(Date.now() - 12 * 60 * 60 * 1000)

  // .split("T")[0]; // YYYY-MM-DD
  const storiesUrl = `${storiesBase}`+
      `category=Politics` +
      `&sortBy=count` +
      `&from=${last36hr}` +
      `&apiKey=${apiKey}`;

  return fetch(storiesUrl)
      .then((res) => res.json())
      .then((json) => {
        return json.results.slice(0, maxStoriesPerFetch);
      }).catch((err) => {
        functions.logger.error(`Could not fetch stories: ${err}`);
        return;
      });
};

const _toStory = function(story) {
  return {
    sid: story.id,
    title: story.name,
    description: story.summary,
    locations: story.countries.map((country) => country.name),
    // these fields are local, not set from perigon
    // they are updated above if db entry exists
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
  };
};

const getArticles = async function(pstory) {
  const articlesUrl = `${articlesBase}`+
        `clusterId=${pstory.id}` +
        `&sortBy=refreshDate` +
        `&paywall=false` +
        `&apiKey=${apiKey}`;

  return await fetch(articlesUrl)
      .then((res) => res.json())
      .then((json) => {
        return json.articles.slice(0, maxArticlesPerFetch);
      }).catch((err) => {
        functions.logger.error(`Could not fetch articles: ${err}`);
        return;
      });
};

const _toPost = function(story, article) {
  return {
    pid: article.articleId,
    sid: story.sid,
    creator: article.source.domain,
    title: article.title,
    description: article.description,
    body: article.content,
    url: article.url,
    // full content or article instead of perigon description
    status: "published",
    sourceType: "article",
    // these fields are local, not set from perigon
    // they are updated above if db entry exists
    createdAt: Timestamp.now().toMillis(),
    updatedAt: Timestamp.now().toMillis(),
    imageUrl: article.imageUrl,
    locations: article.locations.map((location) => location.country),
    // importance: generation.importance,
    // aiCredibility: generation.credibility,
    // aiBias: generation.bias,
    // source: story.source.name,
  };
};

module.exports = {
  fetchFromPerigon,
};
