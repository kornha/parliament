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
  secrets: ["OPENAI_API_KEY", "PINECONE_KEY",
    "X_HANDLE_KEY", "X_PASSWORD_KEY", "X_EMAIL_KEY"],
};
