exports.gbConfig = {
  timeoutSeconds: 60,
  memory: "2GiB",
  secrets: ["OPENAI_API_KEY", "PINECONE_KEY",
    "X_HANDLE_KEY", "X_PASSWORD_KEY", "X_EMAIL_KEY"],
};

/* puppeteer limitations
 * we increase timeout
 * we don't want multiple browsers running in the same instance
**/
exports.scrapeConfig = {
  timeoutSeconds: 300,
  concurrency: 1,
  memory: "2GiB",
  secrets: ["OPENAI_API_KEY", "PINECONE_KEY",
    "X_HANDLE_KEY", "X_PASSWORD_KEY", "X_EMAIL_KEY"],
};

exports.defaultConfig = {
  timeoutSeconds: 60,
  // we dont list memory since we still use this for v1 and v2
  // and they use dif formats MiB vs MB
  secrets: ["OPENAI_API_KEY", "PINECONE_KEY",
    "X_HANDLE_KEY", "X_PASSWORD_KEY", "X_EMAIL_KEY"],
};
