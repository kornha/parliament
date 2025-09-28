/* eslint-disable max-len */

/**
 * Output schema for stories
 * @return {ResponseFormatJSONSchema}
 */
const storyOutputSchema = function() {
  return {
    name: "stories_response",
    type: "json_schema",
    description: "Structured output of stories to add/update and stories to remove",
    strict: true,
    schema: {
      type: "object",
      properties: {
        stories: {
          type: "array",
          description: "List of stories to add or update (order by 'most interesting' if applicable)",
          items: {
            type: "object",
            properties: {
              sid: {
                type: ["string", "null"],
                description: "ID of the Story or null if the Story is new",
              },
              title: {
                type: "string",
                description: "Title of the story",
              },
              description: {
                type: "string",
                description: "Full, richly detailed description; optimized for vector search",
              },
              happenedAt: {
                type: ["string", "null"],
                format: "date-time",
                description: "ISO 8601 timestamp when the event happened, or null if unknown",
              },
              lat: {
                type: ["number", "null"],
                minimum: -90,
                maximum: 90,
                description: "Best-estimate latitude, or null if unknown",
              },
              long: {
                type: ["number", "null"],
                minimum: -180,
                maximum: 180,
                description: "Best-estimate longitude, or null if unknown",
              },
              photos: {
                type: "array",
                description: "All relevant, clearly unique photos from Posts, ordered by most interesting",
                items: {
                  type: "object",
                  properties: {
                    photoURL: {
                      type: "string",
                      description: "URL of the photo (e.g., the Post's photoURL)",
                    },
                    description: {
                      type: "string",
                      description: "Short description/caption for the photo",
                    },
                  },
                  required: ["photoURL", "description"],
                  additionalProperties: false,
                },
              },
            },
            required: ["sid", "title", "description", "happenedAt", "lat", "long", "photos"],
            additionalProperties: false,
          },
        },
        removedStories: {
          type: "array",
          description: "List of Story IDs to remove",
          items: {type: "string"},
        },
      },
      required: ["stories", "removedStories"],
      additionalProperties: false,
    },
  };
};

/**
 * Output schema for statements detection
 * @return {ResponseFormatJSONSchema}
 */
const statementOutputSchema = function() {
  return {
    name: "statements_response",
    type: "json_schema",
    description: "Structured output of statements to add/update and statements to remove",
    strict: true,
    schema: {
      type: "object",
      properties: {
        statements: {
          type: "array",
          description: "List of statements the post makes (new or existing)",
          items: {
            type: "object",
            properties: {
              stid: {
                type: ["string", "null"],
                description: "ID of the Statement or null if the Statement is new",
              },
              value: {type: "string", description: "Text of the statement"},
              side: {
                type: "string",
                enum: ["pro", "against"],
                description: "Whether the post supports or refutes the statement",
              },
              context: {
                type: "string",
                description: "Detailed context for vector search; exhaustive but neutral",
              },
              statedAt: {
                type: ["string", "null"],
                format: "date-time",
                description: "ISO 8601 earliest known time the statement was made",
              },
              type: {
                type: "string",
                enum: ["claim", "opinion"],
                description: "Whether the statement is a verifiable claim or an opinion",
              },
            },
            required: ["stid", "value", "side", "context", "statedAt", "type"],
            additionalProperties: false,
          },
        },
        removedStatements: {
          type: "array",
          description: "List of Statement IDs to remove (due to merge/split)",
          items: {type: "string"},
        },
      },
      required: ["statements", "removedStatements"],
      additionalProperties: false,
    },
  };
};

/**
 * Output schema for story context generation
 * @return {ResponseFormatJSONSchema}
 */
const contextOutputSchema = function() {
  return {
    name: "story_context_response",
    type: "json_schema",
    description: "Structured output for story contextualization fields",
    strict: true,
    schema: {
      type: "object",
      properties: {
        sid: {type: "string", description: "ID of the Story"},
        headline: {type: ["string", "null"], description: "2-6 word engaging headline"},
        subHeadline: {type: ["string", "null"], description: "1-2 sentence subheadline"},
        lede: {type: ["string", "null"], description: "Bullet-style synopsis; sentences separated by two newlines"},
        article: {type: ["string", "null"], description: "Optional 1-8 paragraph article"},
      },
      required: ["sid", "headline", "subHeadline", "lede", "article"],
      additionalProperties: false,
    },
  };
};

/**
 * Output schema for image description generation
 * @return {ResponseFormatJSONSchema}
 */
const imageDescriptionSchema = function() {
  return {
    name: "image_description_response",
    type: "json_schema",
    description: "A concise but descriptive caption for the image",
    strict: true,
    schema: {
      type: "object",
      properties: {
        description: {type: "string", description: "Detailed description for vector search"},
      },
      required: ["description"],
      additionalProperties: false,
    },
  };
};

module.exports = {
  storyOutputSchema,
  statementOutputSchema,
  contextOutputSchema,
  imageDescriptionSchema,
};
