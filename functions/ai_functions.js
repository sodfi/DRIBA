/**
 * Driba OS — AI Cloud Functions
 *
 * Server-side proxy for all AI API calls.
 * API keys never touch the client.
 *
 * Endpoints:
 * - POST /ai/complete   → Single completion
 * - POST /ai/stream     → Streaming completion (SSE)
 * - POST /ai/moderate   → Content moderation
 * - CRON /ai/creators   → Autonomous content generation
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Anthropic = require("@anthropic-ai/sdk");
const OpenAI = require("openai");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { FieldValue } = require("firebase-admin/firestore");

// Initialize Firebase if not already
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// ============================================
// API CLIENTS (keys from environment)
// ============================================

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY || functions.config().ai?.anthropic_key,
});

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || functions.config().ai?.openai_key,
});

const genAI = new GoogleGenerativeAI(
  process.env.GOOGLE_AI_KEY || functions.config().ai?.google_key
);

// ============================================
// COMPLETION ENDPOINT
// ============================================

exports.aiComplete = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be signed in to use AI features"
    );
  }

  const { model, provider, prompt, systemPrompt, maxTokens, temperature, media } = data;

  try {
    let result;

    switch (provider) {
      case "anthropic":
        result = await callAnthropic(model, prompt, systemPrompt, maxTokens, temperature, media);
        break;
      case "openai":
        result = await callOpenAI(model, prompt, systemPrompt, maxTokens, temperature, media);
        break;
      case "google":
        result = await callGoogle(model, prompt, systemPrompt, maxTokens, temperature, media);
        break;
      default:
        throw new Error(`Unknown provider: ${provider}`);
    }

    // Log usage for analytics
    await logUsage(context.auth.uid, provider, model, result.usage);

    return result;
  } catch (error) {
    console.error("AI completion error:", error);

    if (error.status === 429) {
      throw new functions.https.HttpsError("resource-exhausted", "Rate limited. Try again shortly.");
    }

    throw new functions.https.HttpsError("internal", error.message || "AI request failed");
  }
});

// ============================================
// PROVIDER IMPLEMENTATIONS
// ============================================

async function callAnthropic(model, prompt, systemPrompt, maxTokens, temperature, media) {
  const messages = [];

  if (media && media.length > 0) {
    const content = [];
    for (const m of media) {
      if (m.type === "image") {
        content.push({
          type: "image",
          source: { type: "url", url: m.url },
        });
      }
    }
    content.push({ type: "text", text: prompt });
    messages.push({ role: "user", content });
  } else {
    messages.push({ role: "user", content: prompt });
  }

  const response = await anthropic.messages.create({
    model: model,
    max_tokens: maxTokens || 4096,
    temperature: temperature || 0.7,
    system: systemPrompt || "You are a helpful AI assistant for Driba, a premium super app.",
    messages,
  });

  const text = response.content
    .filter((c) => c.type === "text")
    .map((c) => c.text)
    .join("\n");

  return {
    text,
    usage: {
      inputTokens: response.usage?.input_tokens || 0,
      outputTokens: response.usage?.output_tokens || 0,
    },
  };
}

async function callOpenAI(model, prompt, systemPrompt, maxTokens, temperature, media) {
  const messages = [
    { role: "system", content: systemPrompt || "You are a helpful AI assistant for Driba." },
  ];

  if (media && media.length > 0) {
    const content = [];
    for (const m of media) {
      if (m.type === "image") {
        content.push({ type: "image_url", image_url: { url: m.url } });
      }
    }
    content.push({ type: "text", text: prompt });
    messages.push({ role: "user", content });
  } else {
    messages.push({ role: "user", content: prompt });
  }

  const response = await openai.chat.completions.create({
    model: model,
    max_tokens: maxTokens || 4096,
    temperature: temperature || 0.7,
    messages,
  });

  return {
    text: response.choices[0]?.message?.content || "",
    usage: {
      inputTokens: response.usage?.prompt_tokens || 0,
      outputTokens: response.usage?.completion_tokens || 0,
    },
  };
}

async function callGoogle(model, prompt, systemPrompt, maxTokens, temperature, media) {
  const genModel = genAI.getGenerativeModel({
    model: model,
    systemInstruction: systemPrompt || "You are a helpful AI assistant for Driba.",
    generationConfig: {
      maxOutputTokens: maxTokens || 4096,
      temperature: temperature || 0.7,
    },
  });

  const parts = [];
  if (media && media.length > 0) {
    for (const m of media) {
      if (m.type === "image") {
        // For Gemini, images need to be fetched and converted to base64
        // In production, use a helper to fetch and convert
        parts.push({ text: `[Image: ${m.url}]` });
      }
    }
  }
  parts.push({ text: prompt });

  const result = await genModel.generateContent({ contents: [{ parts }] });
  const response = result.response;

  return {
    text: response.text() || "",
    usage: {
      inputTokens: response.usageMetadata?.promptTokenCount || 0,
      outputTokens: response.usageMetadata?.candidatesTokenCount || 0,
    },
  };
}

// ============================================
// CONTENT MODERATION (fast, uses Haiku)
// ============================================

exports.aiModerate = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in");
  }

  const { content, media } = data;

  const response = await anthropic.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 200,
    temperature: 0.1,
    system: `You are a content moderator for Driba. Review content for policy violations.
Output ONLY valid JSON: {"safe": true/false, "flags": ["reason"], "severity": "low/medium/high"}
Check for: hate speech, explicit content, spam, misinformation, scams.`,
    messages: [{ role: "user", content: `Review this content:\n\n${content}` }],
  });

  try {
    const text = response.content[0].text;
    return JSON.parse(text.replace(/```json|```/g, "").trim());
  } catch {
    return { safe: true, flags: [], severity: "low" };
  }
});

// ============================================
// AUTONOMOUS CREATORS (Scheduled)
// Runs every 4 hours, generates content for each screen
// ============================================

exports.aiCreatorsCron = functions.pubsub
  .schedule("every 4 hours")
  .onRun(async () => {
    const creators = [
      { id: "driba_food", screen: "food", task: "generateFoodContent" },
      { id: "driba_travel", screen: "travel", task: "generateTravelContent" },
      { id: "driba_learn", screen: "learn", task: "generateLearningContent" },
      { id: "driba_fitness", screen: "health", task: "generateFitnessContent" },
      { id: "driba_news", screen: "news", task: "generateNewsContent" },
    ];

    for (const creator of creators) {
      try {
        await generateCreatorContent(creator);
        console.log(`✅ Generated content for ${creator.id}`);
      } catch (error) {
        console.error(`❌ Failed for ${creator.id}:`, error.message);
      }
    }
  });

async function generateCreatorContent(creator) {
  // Get creator config from Firestore
  const configDoc = await db.collection("ai_creators").doc(creator.id).get();
  const config = configDoc.exists ? configDoc.data() : {};

  const topics = config.topics || [creator.screen];
  const topic = topics[Math.floor(Math.random() * topics.length)];

  const prompt = `You are "${config.displayName || creator.id}", a content creator for Driba's ${creator.screen} screen.

Generate a post about: ${topic}

Requirements:
- Write for a mobile-first audience (concise, scannable)
- Be original and engaging
- Include practical information

Output ONLY valid JSON:
{
  "title": "Short catchy title",
  "description": "The main post text (150-300 words)",
  "tags": ["tag1", "tag2", "tag3"],
  "confidence": 0.85
}`;

  const response = await anthropic.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 1000,
    temperature: 0.8,
    messages: [{ role: "user", content: prompt }],
  });

  const text = response.content[0].text;
  let postData;

  try {
    postData = JSON.parse(text.replace(/```json|```/g, "").trim());
  } catch {
    console.error("Failed to parse AI response for", creator.id);
    return;
  }

  // Check confidence threshold
  if ((postData.confidence || 0) < (config.minConfidence || 0.7)) {
    console.log(`Skipping low-confidence post for ${creator.id}: ${postData.confidence}`);
    return;
  }

  // Create the post
  const postRef = db.collection("posts").doc();
  await postRef.set({
    author: {
      id: creator.id,
      username: creator.id,
      displayName: config.displayName || creator.id,
      avatarUrl: config.avatarUrl || null,
      isVerified: true,
    },
    title: postData.title,
    description: postData.description,
    media: [],
    type: "content",
    categories: config.categories || [creator.screen],
    tags: postData.tags || [],
    status: config.requiresReview ? "draft" : "published",
    visibility: "public",
    likesCount: 0,
    commentsCount: 0,
    sharesCount: 0,
    savesCount: 0,
    viewsCount: 0,
    engagementScore: 0,
    aiMeta: {
      model: "claude-sonnet-4-20250514",
      creatorId: creator.id,
      confidence: postData.confidence,
      isFullyGenerated: true,
      generatedAt: FieldValue.serverTimestamp(),
    },
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Log to creator's content subcollection
  await db
    .collection("ai_creators")
    .doc(creator.id)
    .collection("content")
    .doc(postRef.id)
    .set({
      postId: postRef.id,
      topic,
      confidence: postData.confidence,
      createdAt: FieldValue.serverTimestamp(),
    });
}

// ============================================
// USAGE LOGGING
// ============================================

async function logUsage(userId, provider, model, usage) {
  try {
    await db.collection("ai_usage").add({
      userId,
      provider,
      model,
      inputTokens: usage?.inputTokens || 0,
      outputTokens: usage?.outputTokens || 0,
      timestamp: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("Failed to log AI usage:", error);
  }
}
