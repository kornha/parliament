const secretsList = [
  "OPENAI_API_KEY",
  "PINECONE_KEY",
  "X_HANDLE_KEY",
  "X_PASSWORD_KEY",
  "X_EMAIL_KEY",
  "NEWS_API_KEY",
  "ADMIN_EMAIL_KEY",
];

exports.defaultConfig = {
  timeoutSeconds: 60,
  // we dont list memory since we still use this for v1 and v2
  // and they use dif formats MiB vs MB
  secrets: secretsList,
};

exports.gbConfig = {
  timeoutSeconds: 60,
  memory: "2GiB",
  secrets: secretsList,
};

/* puppeteer limitations
 * 1 max concurrency!
 * we increase timeout
 * we don't want multiple browsers running in the same instance
**/
exports.scrapeConfig = {
  timeoutSeconds: 300,
  concurrency: 1,
  memory: "2GiB",
  secrets: secretsList,
};
