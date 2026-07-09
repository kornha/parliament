/* eslint-disable max-len */
//
// webscraper.js
//
// Deterministic, AI-free URL -> Post extractor.
//
// Given an arbitrary URL it returns a `processItem`-ready pre-post object by
// routing to the most faithful extractor for that source:
//   - X / Twitter     -> existing puppeteer scraper (via a "scraping" stub)
//   - Reddit          -> the public .json endpoint
//   - YouTube         -> the public oEmbed endpoint
//   - everything else -> structured metadata (JSON-LD / OpenGraph) first, then
//                        Mozilla Readability for the article body.
//
// The AI never writes any post content; its only job upstream is to surface the
// URLs. Extraction here is the deterministic "source of truth" feeding the math.
//
const {logger} = require("firebase-functions/v2");
const {JSDOM, VirtualConsole} = require("jsdom");
const {Readability} = require("@mozilla/readability");

// Swallow the parsed page's own console/JS/CSS errors so they don't flood
// our logs. We never execute page scripts; this only silences JSDOM noise.
const _virtualConsole = new VirtualConsole();
const {isXURL} = require("./xscraper");
const {urlToDomain, getSocialScore, getStatus, isoToMillis} =
  require("../common/utils");

// A real browser UA; many sites 403 the default node-fetch agent.
const _userAgent =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";

// Below this, an extracted body is treated as junk / paywall / non-article.
const MIN_BODY = 200;
// Cap the bytes we parse so a giant page can't blow up memory.
const _maxBytes = 3 * 1024 * 1024;
const _fetchTimeoutMs = 15000;

// ////////////////////////////////////////////////////////////////////////////
// Router
// ////////////////////////////////////////////////////////////////////////////

/**
 * Resolves an arbitrary URL into a `processItem`-ready pre-post object.
 * Returns null if the URL could not be turned into a usable post.
 * @param {string} url
 * @return {Promise<Object|null>}
 */
const getPostFromUrl = async function(url) {
  if (!url || typeof url !== "string") return null;

  try {
    if (isXURL(url)) return xStub(url);
    if (isRedditURL(url)) return await getRedditPost(url);
    if (isYouTubeURL(url)) return await getYouTubePost(url);
    return await getGenericArticle(url);
  } catch (e) {
    logger.warn(`getPostFromUrl failed for ${url}: ${e.message}`);
    return null;
  }
};

/**
 * Resolves many URLs into posts and persists them via the existing pipeline.
 * Mirrors processNewsLinks: dedup + entity/platform creation are handled by
 * processItem, so re-ingesting the same URL is idempotent.
 * @param {Array<string>} links
 * @param {string|null} poster uid if user-initiated, else null (system)
 * @param {number} [depth] ripple depth stamped on each created post
 * @return {Promise<Array<string>>} created/updated post ids
 */
const processWebLinks = async function(links, poster = null, depth = undefined) {
  // Lazy require to avoid a require cycle with contentProcessor.
  const {processItem} = require("./contentProcessor");
  const pids = [];
  for (const link of links) {
    const data = await getPostFromUrl(link);
    if (!data) {
      logger.info(`No post extracted from ${link}`);
      continue;
    }
    if (depth != null) data.depth = depth;
    // A user-initiated paste stays a draft; system-gathered posts publish.
    if (poster && data.status !== "scraping") data.status = "draft";
    const platformType = isXURL(link) ? "x" : "news";
    const pid = await processItem(data, platformType, poster);
    if (pid) pids.push(pid);
  }
  return pids;
};

// ////////////////////////////////////////////////////////////////////////////
// X / Twitter
// ////////////////////////////////////////////////////////////////////////////

/**
 * X needs the authenticated puppeteer scraper, which the existing pipeline runs
 * on "scraping" posts (onPostChangedXid -> xupdatePost). So we just hand back
 * the same stub extractDataFromXLink produces and let that chain enrich it.
 * @param {string} link
 * @return {Object|null}
 */
const xStub = function(link) {
  const handle = link.split("/")[3];
  if (handle === "i" || handle === "@i") return null;
  return {
    xid: link.split("/").pop(),
    url: link,
    handle,
    platformUrl: "x.com",
    status: "scraping",
  };
};

// ////////////////////////////////////////////////////////////////////////////
// Reddit
// ////////////////////////////////////////////////////////////////////////////

const isRedditURL = function(url) {
  return /(^|\.|\/)reddit\.com\//i.test(url) || /(^|\.|\/)redd\.it\//i.test(url);
};

/**
 * Uses Reddit's public JSON (append .json to any thread URL). Free, no key,
 * but requires a real User-Agent or it 429s. Recovers real social metrics
 * (upvotes, comments) that feed virality -> newsworthiness.
 * @param {string} url
 * @return {Promise<Object|null>}
 */
const getRedditPost = async function(url) {
  const clean = url.split("?")[0].replace(/\/+$/, "");
  const jsonUrl = `${clean}.json`;
  const res = await fetchWithUa(jsonUrl);
  if (!res || !res.ok) return null;

  const json = await res.json();
  const data = json?.[0]?.data?.children?.[0]?.data;
  if (!data || !data.title) return null;

  const body = [data.title, data.selftext].filter(Boolean).join("\n\n");
  const photoURL = decodeEntities(
      data.preview?.images?.[0]?.source?.url ||
      (typeof data.thumbnail === "string" &&
        data.thumbnail.startsWith("http") ? data.thumbnail : null),
  );

  return finalize({
    xid: data.name || `t3_${data.id}`,
    url: clean,
    handle: data.author ? `u/${data.author}` : `r/${data.subreddit}`,
    platformUrl: "reddit.com",
    title: data.title,
    body,
    photo: photoURL ? {photoURL} : null,
    sourceCreatedAt: data.created_utc ? data.created_utc * 1000 : null,
    likes: data.score || data.ups || 0,
    replies: data.num_comments || 0,
  });
};

// ////////////////////////////////////////////////////////////////////////////
// YouTube
// ////////////////////////////////////////////////////////////////////////////

const isYouTubeURL = function(url) {
  return /(^|\.|\/)youtube\.com\//i.test(url) || /(^|\.|\/)youtu\.be\//i.test(url);
};

const _youtubeId = function(url) {
  const m =
    url.match(/[?&]v=([\w-]{11})/) ||
    url.match(/youtu\.be\/([\w-]{11})/) ||
    url.match(/\/shorts\/([\w-]{11})/) ||
    url.match(/\/embed\/([\w-]{11})/);
  return m ? m[1] : null;
};

/**
 * Uses YouTube's public oEmbed endpoint (free, no key). Body is thin (title +
 * channel), so these are light corroborating posts rather than full sources.
 * @param {string} url
 * @return {Promise<Object|null>}
 */
const getYouTubePost = async function(url) {
  const id = _youtubeId(url);
  if (!id) return null;
  const canonical = `https://www.youtube.com/watch?v=${id}`;
  const oembed =
    `https://www.youtube.com/oembed?url=${encodeURIComponent(canonical)}` +
    `&format=json`;
  const res = await fetchWithUa(oembed);
  if (!res || !res.ok) return null;

  const data = await res.json();
  if (!data?.title) return null;

  return finalize({
    xid: id,
    url: canonical,
    handle: data.author_name || "YouTube",
    platformUrl: "youtube.com",
    title: data.title,
    body: data.title,
    photo: data.thumbnail_url ? {photoURL: data.thumbnail_url} : null,
    // oEmbed exposes no publish date; finalize() defaults it to now.
    sourceCreatedAt: null,
  });
};

// ////////////////////////////////////////////////////////////////////////////
// Generic article (the majority of the internet)
// ////////////////////////////////////////////////////////////////////////////

/**
 * Faithful, site-agnostic extraction: structured metadata (JSON-LD / OpenGraph)
 * first, then Mozilla Readability for the body. No per-site selectors.
 * @param {string} url
 * @return {Promise<Object|null>}
 */
const getGenericArticle = async function(url) {
  const html = await fetchHtml(url);
  if (!html) return null;

  const dom = new JSDOM(html, {url, virtualConsole: _virtualConsole});
  const doc = dom.window.document;

  // Extract metadata BEFORE Readability, which mutates/strips the DOM.
  const meta = extractMeta(doc);

  let parsed = null;
  try {
    parsed = new Readability(doc).parse();
  } catch (e) {
    logger.warn(`Readability failed for ${url}: ${e.message}`);
  }

  const title = meta.title || parsed?.title || doc.title || null;
  if (!title) return null;

  // Prefer JSON-LD articleBody, else the longer of Readability / meta desc.
  const readBody = (parsed?.textContent || "").trim();
  const body = [meta.articleBody, readBody, meta.description]
      .filter(Boolean)
      .sort((a, b) => b.length - a.length)[0] || null;

  // Quality gate: must have a title and a real body. Skip paywalls / junk.
  if (!body || body.length < MIN_BODY) {
    logger.info(`Quality gate skip (body=${body?.length ?? 0}) for ${url}`);
    return null;
  }

  return finalize({
    xid: meta.canonical || url,
    url: meta.canonical || url,
    handle: meta.author || meta.siteName || urlToDomain(url),
    platformUrl: urlToDomain(url),
    title,
    body,
    photo: meta.image ? {photoURL: meta.image} : null,
    sourceCreatedAt: meta.published ? isoToMillis(meta.published) : null,
  });
};

/**
 * Pulls site-agnostic metadata from a parsed document: JSON-LD schema.org
 * Article data, then OpenGraph / Twitter / standard meta tags.
 * @param {Document} doc
 * @return {Object}
 */
const extractMeta = function(doc) {
  const ld = extractJsonLd(doc);

  return {
    title:
      ld?.headline ||
      firstContent(doc, ["meta[property='og:title']", "meta[name='twitter:title']"]),
    description:
      ld?.description ||
      firstContent(doc, [
        "meta[property='og:description']",
        "meta[name='twitter:description']",
        "meta[name='description']",
      ]),
    image:
      jsonLdImage(ld) ||
      firstContent(doc, ["meta[property='og:image']", "meta[name='twitter:image']"]),
    author:
      jsonLdAuthor(ld) ||
      firstContent(doc, ["meta[property='article:author']", "meta[name='author']"]),
    published:
      ld?.datePublished ||
      firstContent(doc, [
        "meta[property='article:published_time']",
        "meta[name='date']",
        "meta[name='pubdate']",
        "time[datetime]",
      ]),
    articleBody: typeof ld?.articleBody === "string" ?
      ld.articleBody.trim() : null,
    siteName:
      ld?.publisher?.name ||
      firstContent(doc, ["meta[property='og:site_name']"]),
    canonical:
      firstContent(doc, ["link[rel='canonical']", "meta[property='og:url']"]),
  };
};

/**
 * Returns the first non-empty content/href among a list of selectors.
 * @param {Document} doc
 * @param {Array<string>} selectors
 * @return {string|null}
 */
const firstContent = function(doc, selectors) {
  for (const sel of selectors) {
    const el = doc.querySelector(sel);
    const val = el?.getAttribute("content") ||
      el?.getAttribute("href") || el?.getAttribute("datetime");
    if (val) return val.trim();
  }
  return null;
};

/**
 * Finds the first schema.org Article-like node in any JSON-LD blocks.
 * @param {Document} doc
 * @return {Object|null}
 */
const extractJsonLd = function(doc) {
  const types = new Set([
    "NewsArticle", "Article", "ReportageNewsArticle", "BlogPosting",
    "OpinionNewsArticle", "AnalysisNewsArticle", "Report",
  ]);
  const isArticle = (node) => {
    if (!node || typeof node !== "object") return false;
    const t = node["@type"];
    if (Array.isArray(t)) return t.some((x) => types.has(x));
    return types.has(t);
  };

  const scripts = doc.querySelectorAll("script[type='application/ld+json']");
  for (const script of scripts) {
    let json;
    try {
      json = JSON.parse(script.textContent);
    } catch (e) {
      continue;
    }
    const nodes = [];
    const collect = (x) => {
      if (Array.isArray(x)) x.forEach(collect);
      else if (x && typeof x === "object") {
        nodes.push(x);
        if (Array.isArray(x["@graph"])) x["@graph"].forEach(collect);
      }
    };
    collect(json);
    const hit = nodes.find(isArticle);
    if (hit) return hit;
  }
  return null;
};

const jsonLdImage = function(ld) {
  if (!ld?.image) return null;
  const img = ld.image;
  if (typeof img === "string") return img;
  if (Array.isArray(img)) {
    return typeof img[0] === "string" ? img[0] : img[0]?.url || null;
  }
  return img.url || null;
};

const jsonLdAuthor = function(ld) {
  if (!ld?.author) return null;
  const a = ld.author;
  if (typeof a === "string") return a;
  if (Array.isArray(a)) {
    return a[0]?.name || (typeof a[0] === "string" ? a[0] : null);
  }
  return a.name || null;
};

// ////////////////////////////////////////////////////////////////////////////
// Helpers
// ////////////////////////////////////////////////////////////////////////////

/**
 * Normalizes a pre-post: fills a default timestamp, computes status, and
 * derives social score ONLY when engagement data exists (else leaves it unset
 * so the post sits out the virality mean instead of dragging it to zero).
 * @param {Object} data
 * @return {Object}
 */
const finalize = function(data) {
  const hasSocial = data.likes != null || data.replies != null ||
    data.reposts != null || data.views != null || data.bookmarks != null;

  const post = {
    ...data,
    sourceCreatedAt: data.sourceCreatedAt || Date.now(),
    ...(hasSocial && {
      socialScore: getSocialScore({
        likes: data.likes,
        replies: data.replies,
        reposts: data.reposts,
        views: data.views,
        bookmarks: data.bookmarks,
      }),
    }),
  };
  // Default to published; processWebLinks downgrades to draft when user-posted.
  post.status = getStatus({...post, status: "published"}, "published");
  return post;
};

/**
 * Fetches a URL with a browser UA, timeout, and size cap. Returns null on
 * non-2xx, non-HTML content, or network error.
 * @param {string} url
 * @return {Promise<string|null>}
 */
const fetchHtml = async function(url) {
  const res = await fetchWithUa(url);
  if (!res || !res.ok) return null;

  const type = res.headers.get("content-type") || "";
  if (!type.includes("html")) {
    logger.info(`Skipping non-html (${type}) ${url}`);
    return null;
  }

  const buf = await res.arrayBuffer();
  if (buf.byteLength > _maxBytes) {
    return Buffer.from(buf).subarray(0, _maxBytes).toString("utf-8");
  }
  return Buffer.from(buf).toString("utf-8");
};

/**
 * fetch() wrapper with browser UA + timeout. Follows redirects by default.
 * @param {string} url
 * @return {Promise<Response|null>}
 */
const fetchWithUa = async function(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), _fetchTimeoutMs);
  try {
    return await fetch(url, {
      redirect: "follow",
      signal: controller.signal,
      headers: {
        "User-Agent": _userAgent,
        "Accept": "text/html,application/json,application/xhtml+xml," +
          "application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
      },
    });
  } catch (e) {
    logger.warn(`fetch failed for ${url}: ${e.message}`);
    return null;
  } finally {
    clearTimeout(timer);
  }
};

const decodeEntities = function(str) {
  if (!str) return str;
  return str
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&quot;/g, "\"")
      .replace(/&#x27;/g, "'")
      .replace(/&#39;/g, "'");
};

module.exports = {
  getPostFromUrl,
  processWebLinks,
  //
  isRedditURL,
  isYouTubeURL,
};
