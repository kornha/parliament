// firebase functions:secrets:set KEY

const secretsList = [
  "OPENAI_API_KEY",
  "PINECONE_KEY",
  "X_HANDLE_KEY",
  "X_PASSWORD_KEY",
  "X_EMAIL_KEY",
  "NEWS_API_KEY",
  "ADMIN_EMAIL_KEY",
  "CLOUD_API_KEY",
];

exports.defaultConfig = {
  timeoutSeconds: 60,
  // we dont list memory since we still use this for v1 and v2
  // and they use dif formats MiB vs MB
  secrets: secretsList,
  maxInstances: 10,
};

exports.gbConfig = {
  timeoutSeconds: 60,
  memory: "2GiB",
  secrets: secretsList,
  maxInstances: 10,
};

// LLM pipeline tasks spend their time awaiting OpenAI responses; 1GiB covers
// their graph fan-in reads without paying for 2GiB of idle headroom.
exports.llmConfig = {
  timeoutSeconds: 60,
  memory: "1GiB",
  secrets: secretsList,
  maxInstances: 10,
};

// Fan-in recompute handlers (entity/story bias+confidence) read every
// statement of their target; big entities OOMed 256Mi, then 512Mi as the
// denser feed grew top entities — 1GiB gives growth headroom.
exports.mediumConfig = {
  timeoutSeconds: 60,
  memory: "1GiB",
  secrets: secretsList,
  maxInstances: 10,
};

/* puppeteer limitations
 * 1 max concurrency!
 * we increase timeout
 * we don't want multiple browsers running in the same instance
 * 1GiB fits single-tweet fetches; the FEED scroll needs feedScrapeConfig
**/
exports.scrapeConfig = {
  timeoutSeconds: 300,
  concurrency: 1,
  maxInstances: 5,
  memory: "1GiB",
  secrets: secretsList,
};

// Feed scrolls accumulate the lazy-loaded timeline DOM plus harvested
// GraphQL payloads — they exceed 1GiB in production (and have spiked at
// 2GiB historically), so they keep the larger instance.
exports.feedScrapeConfig = {
  timeoutSeconds: 300,
  concurrency: 1,
  maxInstances: 5,
  memory: "2GiB",
  secrets: secretsList,
};
