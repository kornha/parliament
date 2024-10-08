const newsBase = require("eventregistry");
const {
  ReturnInfo,
  QueryArticles,
  RequestArticlesRecentActivity,
  QueryItems,
  ArticleInfoFlags,
  SourceInfoFlags,
  RequestArticleInfo,
} = require("eventregistry");
const {defineSecret} = require("firebase-functions/params");
const _newsApiKey = defineSecret("NEWS_API_KEY");
const {logger} = require("firebase-functions/v2");
const {findCreatePlatform,
  getPostByXid,
  findCreateEntity, createPost,
  updatePost} = require("../common/database");
const _ = require("lodash");
const {v5} = require("uuid");
const {Timestamp} = require("firebase-admin/firestore");
const {isoToMillis, getStatus} = require("../common/utils");


let _newsApi;
/**
 * Returns the news api instance
 * @return {newsBase.EventRegistry} instance
 * */
const newsApi = function() {
  if (!_newsApi) {
    _newsApi = new newsBase.EventRegistry({
      apiKey: _newsApiKey.value(),
      allowUseOfArchive: false,
    });
  }
  return _newsApi;
};

const newsCategories = [
  "dmoz/Business",
  "dmoz/Computers",
  "dmoz/Society",
  "dmoz/Science",
];

const newsSources = [
  "nytimes.com",
  "cnn.com",
  "us.cnn.com",
  "aljazeera.com",
  "aljazeera.net",
  "timesofisrael.com",
  "reuters.com",
  "wsj.com",
  "hosted.ap.org",
  "businessinsider.com",
  "politico.com",
  "apnews.com",
  "bbc.com",
  "news.bbc.co.uk",
  "foxnews.com",
  "axios.com",
  "theguardian.com",
  // "washingtonpost.com",
  "vox.com",
  "cbsnews.com",
  "independent.co.uk",
  "scmp.com",
];

/**
 * Processes news links
 * Does it as a List to be similar to the processXLinks function
 * This is not used on API fetch as the API has the data and we need
 * to create the post directly
 * @param {Array} links
 * @param {string} poster uid to apply if posted by user
 */
const processNewsLinks = async function(links, poster = null) {
  const pids = [];
  for (const link of links) {
    const article = await getArticleFromLink(link);
    const _pids = await processArticles([article], poster);
    pids.push(..._pids);
  }

  return pids;
};

/**
 * Processes articles from news API
 * Similar to processXLinks, but we already have the data and don't need to
 * scrape from X
 * @param {Array} articles
 * @param {string} poster uid to apply if posted by user
 * @return {Array} pids
 * */
const processArticles = async function(articles, poster = null) {
  const pids = [];

  for (const article of articles) {
    const platform = await findCreatePlatform(article.source.uri);
    const xid = article.uri;
    const post = await getPostByXid(xid, platform.plid);
    if (post == null) {
      let handle;
      if (_.isEmpty(article.authors) || article.authors[0].isAgency) {
        handle = article.source.title;
      } else {
        handle = article.authors[0].name; // TODO: There can be multiple authors
      }

      const entity = await findCreateEntity(handle, platform);
      if (entity.eid == null) {
        logger.error("Could not find entity for handle: " + handle);
        continue; // Skip to the next iteration if no entity is found
      }
      const post = {
        pid: v5(xid, platform.plid),
        eid: entity.eid,
        xid: xid,
        url: article.url,
        status: poster == null ? "published" : "draft",
        plid: platform.plid,
        poster: poster,
        createdAt: Timestamp.now().toMillis(),
        updatedAt: Timestamp.now().toMillis(),
        sourceCreatedAt: isoToMillis(article.dateTimePub),
        title: article.title,
        body: article.body,
        photo: article.image ? {photoURL: article.image} : null,
        reposts: article.shares?.facebook ?? 0,
      };

      const success = await createPost(post);
      if (success) {
        pids.push(post.pid);
      } else {
        logger.error("Could not create post for xid: " + xid);
      }
    } else {
      logger.info("Post already exists for xid: " + xid);
      const status = (post.status != "scraping" &&
        post.status != "draft" &&
        post.status != null) ? post.status :
        post.poster ? "draft" : "published";

      const _post = {
        // we set to published unless status is in draft
        status: status,
        sourceCreatedAt: isoToMillis(article.dateTimePub),
        updatedAt: Timestamp.now().toMillis(),
        title: article.title,
        body: article.body,
        poster: poster,
        // will change with API change
        // description: metadata.description,
        photo: article.image ? {photoURL: article.image} : null,
        // video: omitted...
        reposts: article.shares?.facebook ?? 0,
      };
      await updatePost(post.pid, _post);
      logger.info(`Updated post: ${post.pid} with news metadata.`);
      pids.push(post.pid);
    }
  }
  return pids;
};

/**
 * Fetches top news articles and processes them
 * @param {number} limit
 * @param {string} poster uid to apply if posted by user
 * @return {Promse<Array<Post>>} pre posts
 * */
const getTopNewsPosts = async function(limit = 5) {
  const articles = await getRecentArticles();
  // sort and limit to top 5
  const topArticles = articles.sort((a, b) => {
    return (b.shares?.facebook ?? 0) - (a.shares?.facebook ?? 0);
  }).slice(0, limit);

  const posts = topArticles.map((article) => {
    return getPostFromArticle(article, "published");
  });

  return posts;
};

const returnInfo = new ReturnInfo({
  sourceInfo: new SourceInfoFlags({
    socialMedia: true,
    image: true,
  }),
  articleInfo: new ArticleInfoFlags({
    image: true,
    videos: true,
    body: true,
    sentiment: false,
    socialScore: true,
  }),
});

/**
 * Fetches an article from a link
 * @param {string} link
 * @return {Promise<Artcle | null>}
 * */
const getArticleFromLink = async function(link) {
  const artMapper = new newsBase.ArticleMapper(newsApi());
  const artUri = await artMapper.getArticleUri(link);
  if (artUri == null) {
    return null;
  }
  const q2 = new newsBase.QueryArticle(artUri);
  q2.setRequestedResult(new RequestArticleInfo(returnInfo));
  const ret = await newsApi().execQuery(q2);
  return ret[artUri]?.info ? ret[artUri].info : null;
};

/**
 * Gets the pre-post data from an article
 * @param {Article} article
 * @param {string} defaultStatus - expecting status, may be overridden
 * @return {Post} pre-post data
 */
const getPostFromArticle = function(article, defaultStatus = "draft") {
  const xid = article.uri;
  const handle = article.authors?.[0]?.name || article.source.title;

  const post = {
    xid,
    url: article.url,
    handle,
    platformUrl: article.source.uri,
    sourceCreatedAt: isoToMillis(article.dateTimePub),
    title: article.title,
    body: article.body,
    photo: article.image ? {photoURL: article.image} : null,
    video: article.videos?.[0]?.uri ? {videoURL: article.videos[0].uri} : null,
    reposts: article.shares?.facebook || 0,
  };

  const status = getStatus(post, defaultStatus);
  post.status = status;

  return post;
};

/**
 * Returns recent articles from top news sources
 * @return {Promise<Array>} articles
 * */
const getRecentArticles = async function() {
  const query = new QueryArticles({
    // eslint-disable-next-line new-cap
    categoryUri: QueryItems.OR(newsCategories),
    // eslint-disable-next-line new-cap
    sourceUri: QueryItems.OR(newsSources),
    isDuplicateFilter: "skipDuplicates",
  });
  query.setRequestedResult(
      new RequestArticlesRecentActivity({
        maxArticleCount: 100,
        updatesAfterMinsAgo: 720,
        returnInfo: returnInfo,
      }),
  );
  const response = await newsApi().execQuery(query);
  const articles = response.recentActivityArticles["activity"];
  return articles;
};

module.exports = {
  processNewsLinks,
  getArticleFromLink,
  getTopNewsPosts,
  getPostFromArticle,
};
