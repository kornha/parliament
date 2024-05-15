exports.gbConfig = {
  timeoutSeconds: 60,
  memory: "1GB",
  secrets: ["OPENAI_API_KEY", "PINECONE_KEY",
    "X_HANDLE_KEY", "X_PASSWORD_KEY", "X_EMAIL_KEY"],
};

exports.defaultConfig = {
  timeoutSeconds: 60,
  memory: "256MB",
  secrets: ["OPENAI_API_KEY", "PINECONE_KEY",
    "X_HANDLE_KEY", "X_PASSWORD_KEY", "X_EMAIL_KEY"],
};
