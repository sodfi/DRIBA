/**
 * ============================================================
 * DRIBA OS — AUTONOMOUS CONTENT AGENTS (ALL-GOOGLE)
 * ============================================================
 *
 * One ecosystem. One billing. One auth.
 *
 * PIPELINE PER POST:
 *   1. RESEARCH  — Gemini 2.0 Flash + Google Search grounding
 *   2. WRITE     — Gemini 2.5 Pro creates post + media spec + voiceover script
 *   3. GENERATE  — Imagen 3 (photo) or Veo 2 (video) via Vertex AI
 *   4. VOICE     — Cloud TTS (WaveNet) generates voiceover audio
 *   5. UPLOAD    — Firebase Storage (image, video, audio → public URLs)
 *   6. PUBLISH   — Firestore document with ALL media attached
 *
 * Auth:
 *   Gemini API uses GEMINI_API_KEY (env var).
 *   Vertex AI + Cloud TTS use the Cloud Functions default service account.
 *   No extra API keys needed for Imagen, Veo, or TTS.
 *
 * GCP APIs to enable:
 *   - Vertex AI API (aiplatform.googleapis.com)
 *   - Cloud Text-to-Speech API (texttospeech.googleapis.com)
 *   - Generative Language API (generativelanguage.googleapis.com)
 *
 * ============================================================
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleAuth } = require("google-auth-library");

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const bucket = admin.storage().bucket("driba-os.firebasestorage.app");
const FV = admin.firestore.FieldValue;

// ─── Config ─────────────────────────────────────────────────

const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "driba-os";
const REGION = "us-central1";
const GEMINI_KEY = process.env.GEMINI_API_KEY || process.env.GOOGLE_AI_KEY || functions.config().ai?.google_key;

// Google Auth for Vertex AI + TTS (uses default service account in Cloud Functions)
const auth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

async function getAccessToken() {
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token || token;
}

// ─── Creator Profiles ───────────────────────────────────────
// Each creator has a unique personality, voice, and content strategy.

const CREATORS = {
  chef_aiden: {
    id: "ai_chef_aiden",
    name: "Chef Aiden",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=chef_aiden&backgroundColor=ff6b35",
    personality: `You are Chef Aiden — a warm, passionate AI food creator for Driba.
You discover trending recipes, restaurant stories, street food culture, and food science.
You write like a friend who happens to be a chef: casual, vivid, mouth-watering.
You love Moroccan cuisine but cover global food. 1-2 emojis max. Never hashtag-spam.`,
    researchTopics: [
      "trending recipes this week 2026",
      "new restaurant openings Morocco 2026",
      "viral food trends social media",
      "food science discoveries",
      "street food culture worldwide",
      "healthy cooking techniques latest",
    ],
    categories: ["food", "feed"],
    crossCategories: { healthy: ["food", "health", "feed"] },
    schedule: "every 4 hours",
    // Cloud TTS voice — warm male
    voice: { languageCode: "en-US", name: "en-US-Neural2-D", ssmlGender: "MALE" },
  },

  travel_nova: {
    id: "ai_travel_nova",
    name: "Nova Wanderer",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=travel_nova&backgroundColor=00b4d8",
    personality: `You are Nova Wanderer — a poetic, adventurous AI travel creator for Driba.
You find hidden gems, off-the-beaten-path places, and travel hacks.
You write like a travel journalist: vivid imagery, practical tips, wanderlust-inducing.
Morocco is your home base but you cover global travel. Short punchy sentences.`,
    researchTopics: [
      "hidden travel destinations 2026",
      "Morocco new travel discoveries",
      "best places to visit current season",
      "budget travel hacks tips",
      "digital nomad hotspots 2026",
      "adventure travel experiences trending",
    ],
    categories: ["travel", "feed"],
    schedule: "every 4 hours",
    voice: { languageCode: "en-US", name: "en-US-Neural2-F", ssmlGender: "FEMALE" },
  },

  news_pulse: {
    id: "ai_news_pulse",
    name: "Pulse",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=news_pulse&backgroundColor=ff3d71",
    personality: `You are Pulse — a sharp, objective AI news creator for Driba.
You find breaking stories, tech developments, science breakthroughs, and policy changes.
You write like a modern journalist: factual, concise, no sensationalism.
Focus on North Africa, tech, climate, and business. Always cite sources.`,
    researchTopics: [
      "breaking news technology today",
      "Morocco latest news developments",
      "Africa technology startups 2026",
      "climate change latest developments",
      "artificial intelligence news this week",
      "global economic business news today",
    ],
    categories: ["news", "feed"],
    crossCategories: { health: ["news", "health", "feed"] },
    schedule: "every 2 hours",
    voice: { languageCode: "en-US", name: "en-US-Neural2-A", ssmlGender: "MALE" },
  },

  health_vita: {
    id: "ai_health_vita",
    name: "Vita",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=vita_health&backgroundColor=00d68f",
    personality: `You are Vita — a knowledgeable, supportive AI wellness creator for Driba.
You share evidence-based health tips, fitness routines, nutrition science, mental wellness.
You write like a trusted health coach: encouraging but never preachy.
Cite studies when possible. No medical advice — empowerment through knowledge.`,
    researchTopics: [
      "latest health research findings 2026",
      "nutrition science new studies",
      "fitness trends evidence-based",
      "mental health wellness techniques",
      "sleep science latest research",
      "longevity research breakthroughs",
    ],
    categories: ["health", "feed"],
    crossCategories: { nutrition: ["health", "food", "feed"] },
    schedule: "every 4 hours",
    voice: { languageCode: "en-US", name: "en-US-Neural2-C", ssmlGender: "FEMALE" },
  },

  style_mira: {
    id: "ai_style_mira",
    name: "Mira Style",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=mira_style&backgroundColor=ffd700",
    personality: `You are Mira Style — a tastemaker AI lifestyle creator for Driba.
You discover artisan products, fashion trends, home decor, and design stories.
You write like a style editor: curated, aspirational but accessible.
Champion Moroccan and African artisans. Sustainability matters. Every product has a story.`,
    researchTopics: [
      "trending fashion products 2026",
      "Moroccan artisan crafts global",
      "sustainable fashion brands new",
      "home decor trends current",
      "beauty products trending natural",
      "handmade artisan marketplace trends",
    ],
    categories: ["commerce", "feed"],
    schedule: "every 6 hours",
    voice: { languageCode: "en-US", name: "en-US-Neural2-E", ssmlGender: "FEMALE" },
  },

  tech_arc: {
    id: "ai_tech_arc",
    name: "Arc",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=arc_tech&backgroundColor=8b5cf6",
    personality: `You are Arc — a sharp, practical AI tech creator for Driba.
You share app recommendations, privacy tips, AI tools, productivity hacks.
You write like a tech-savvy friend: no jargon, practical value, real tests.
Skeptical of hype, enthusiastic about what actually works.`,
    researchTopics: [
      "best new apps trending 2026",
      "AI tools productivity latest",
      "cybersecurity privacy tips consumers",
      "tech gadgets reviews new",
      "digital minimalism practical tips",
      "fintech mobile payments trends",
    ],
    categories: ["utility", "feed"],
    schedule: "every 4 hours",
    voice: { languageCode: "en-US", name: "en-US-Neural2-J", ssmlGender: "MALE" },
  },
};

// ============================================================
// PHASE 1: RESEARCH — Gemini 2.0 Flash + Google Search
// ============================================================

async function researchPhase(creator) {
  console.log(`  🔍 [${creator.name}] Researching...`);

  const topic = creator.researchTopics[Math.floor(Math.random() * creator.researchTopics.length)];

  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_KEY}`;

  const body = {
    contents: [{
      parts: [{
        text: `You are a research assistant for a content creator.
Search the web for: "${topic}"
Find the most interesting, recent, shareable finding about this topic.
Focus on NEW developments, surprising facts, or practical insights.

Return ONLY valid JSON — no markdown, no backticks:
{
  "headline": "One-line summary",
  "details": "2-3 paragraphs of key facts, data, context. Be specific.",
  "source": "Primary source name",
  "sourceUrl": "URL if available",
  "freshness": "today | this_week | this_month",
  "angle": "What makes this shareable",
  "relatedTopics": ["topic1", "topic2"]
}`,
      }],
    }],
    tools: [{ google_search: {} }],
    generationConfig: { temperature: 0.4, maxOutputTokens: 1500 },
  };

  try {
    const resp = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    if (!resp.ok) {
      console.warn(`  ⚠️ Gemini search failed (${resp.status}), using fallback`);
      return researchFallback(topic);
    }

    const data = await resp.json();
    const text = data.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") || "";
    const grounding = data.candidates?.[0]?.groundingMetadata;

    console.log(`  📊 [${creator.name}] Got ${grounding?.groundingChunks?.length || 0} grounded sources`);

    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return researchFallback(topic);

    const research = JSON.parse(jsonMatch[0]);
    research.groundedSources = (grounding?.groundingChunks || []).map((c) => ({
      title: c.web?.title || "",
      uri: c.web?.uri || "",
    }));
    return research;
  } catch (error) {
    console.error(`  ❌ Research error:`, error.message);
    return researchFallback(topic);
  }
}

async function researchFallback(topic) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_KEY}`;
  const body = {
    contents: [{ parts: [{ text: `Generate an interesting, factual insight about: "${topic}"\nReturn ONLY JSON: {"headline":"...","details":"...","source":"General knowledge","sourceUrl":"","freshness":"this_month","angle":"...","relatedTopics":[]}` }] }],
    generationConfig: { temperature: 0.7, maxOutputTokens: 1000 },
  };
  const resp = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
  const data = await resp.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
  const m = text.match(/\{[\s\S]*\}/);
  return m ? JSON.parse(m[0]) : { headline: topic, details: topic, source: "AI", freshness: "this_week", angle: "Interesting" };
}

// ============================================================
// PHASE 2: WRITE — Gemini 2.5 Pro
// Creates post text, media spec (photo/video), voiceover script.
// ============================================================

async function contentPhase(creator, research) {
  console.log(`  ✍️  [${creator.name}] Writing content...`);

  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-preview-05-06:generateContent?key=${GEMINI_KEY}`;

  const body = {
    systemInstruction: { parts: [{ text: creator.personality }] },
    contents: [{
      parts: [{
        text: `Based on this research, create a social media post for Driba.

RESEARCH:
Headline: ${research.headline}
Details: ${research.details}
Source: ${research.source}
Angle: ${research.angle}

YOUR TASK — Create ALL of the following:

1. POST TEXT: An engaging description (100-300 chars). Authentic to your voice.

2. MEDIA DECISION: Decide if this needs a PHOTO or VIDEO.
   - PHOTO: food shots, landscapes, products, portraits, infographics
   - VIDEO: tutorials, dynamic scenes, cooking processes, before/after, time-lapses

3. IMAGE/VIDEO PROMPT: A detailed generation prompt for Imagen 3 (photo) or Veo 2 (video).
   For photos: describe composition, lighting, colors, mood, camera angle, style in detail.
   For videos: describe scene, camera movement, action, duration (5-8 seconds), key moments.

4. VOICEOVER SCRIPT: A 15-30 second spoken narration for the post.
   Write it as natural speech — how you'd actually say this out loud.
   Include pauses with "..." for dramatic effect.
   This will be read aloud by text-to-speech, so make it conversational.

5. METADATA: hashtags (2-3), categories, engagement hook.

Return ONLY valid JSON — no markdown, no backticks, no explanation:
{
  "description": "Your post text",
  "hashtags": ["tag1", "tag2"],
  "categories": ["primary_screen", "feed"],
  "engagementHook": "Question or CTA",
  "mediaSpec": {
    "type": "image",
    "prompt": "Detailed Imagen 3 / Veo 2 prompt...",
    "negativePrompt": "blurry, text overlay, watermark, low quality, cartoon, anime",
    "style": "photorealistic",
    "aspectRatio": "9:16",
    "mood": "warm and inviting"
  },
  "voiceoverScript": "Hey everyone... here's something incredible I discovered today...",
  "contentMeta": {
    "topic": "Brief topic label",
    "source": "Source name",
    "factChecked": true,
    "confidence": 0.90
  }
}`,
      }],
    }],
    generationConfig: { temperature: 0.8, maxOutputTokens: 2000 },
  };

  const resp = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
  if (!resp.ok) throw new Error(`Gemini 2.5 Pro error: ${resp.status}`);

  const data = await resp.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text || "";
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error("Gemini did not return valid JSON");

  const content = JSON.parse(jsonMatch[0]);

  // Ensure categories
  const primary = creator.categories[0];
  if (!content.categories.includes(primary)) content.categories.unshift(primary);
  if (!content.categories.includes("feed")) content.categories.push("feed");

  // Validate mediaSpec
  if (!content.mediaSpec?.prompt) {
    content.mediaSpec = {
      type: "image",
      prompt: `Professional ${primary} content, high quality, 4K, trending`,
      negativePrompt: "blurry, text, watermark, low quality",
      style: "photorealistic",
      aspectRatio: "9:16",
      mood: "vibrant",
    };
  }

  console.log(`  📝 [${creator.name}] ${content.mediaSpec.type} post: "${content.description.substring(0, 60)}..."`);
  return content;
}

// ============================================================
// PHASE 3A: IMAGE — Imagen 3 via Vertex AI
// ============================================================

async function generateImage(mediaSpec, postId) {
  console.log(`  🎨 Generating image with Imagen 3...`);

  const token = await getAccessToken();
  const model = "imagen-3.0-generate-002";
  const url = `https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${model}:predict`;

  // Build enhanced prompt
  let prompt = mediaSpec.prompt;
  if (mediaSpec.style === "photorealistic") {
    prompt += ", photorealistic, high resolution, professional photography, sharp focus, beautiful lighting";
  }

  // Map aspect ratio
  let aspectRatio = "9:16"; // default vertical mobile
  if (mediaSpec.aspectRatio === "1:1") aspectRatio = "1:1";
  else if (mediaSpec.aspectRatio === "16:9") aspectRatio = "16:9";
  else if (mediaSpec.aspectRatio === "4:3") aspectRatio = "4:3";

  const body = {
    instances: [{ prompt }],
    parameters: {
      sampleCount: 1,
      aspectRatio: aspectRatio,
      safetyFilterLevel: "block_medium_and_above",
      personGeneration: "allow_adult",
      addWatermark: false,
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Imagen 3 error ${resp.status}: ${errText.substring(0, 300)}`);
  }

  const data = await resp.json();
  const b64 = data.predictions?.[0]?.bytesBase64Encoded;
  if (!b64) throw new Error("No image data in Imagen response");

  console.log(`  📸 Image generated with Imagen 3`);
  return { buffer: Buffer.from(b64, "base64"), mimeType: "image/png" };
}

// ============================================================
// PHASE 3B: VIDEO — Veo 2 via Vertex AI (async long-running)
// ============================================================

async function generateVideo(mediaSpec, postId) {
  console.log(`  🎬 Generating video with Veo 2...`);

  const token = await getAccessToken();
  const model = "veo-2.0-generate-exp";

  // Step 1: Start video generation (returns a long-running operation)
  const generateUrl = `https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${model}:predictLongRunning`;

  let prompt = mediaSpec.prompt;
  if (mediaSpec.style === "cinematic") {
    prompt += ", cinematic quality, smooth camera movement, professional color grading";
  }

  // Aspect ratio
  let aspectRatio = "9:16";
  if (mediaSpec.aspectRatio === "16:9") aspectRatio = "16:9";

  const body = {
    instances: [{ prompt }],
    parameters: {
      aspectRatio: aspectRatio,
      sampleCount: 1,
      durationSeconds: 6,
      storageUri: `gs://driba-os.firebasestorage.app/ai-video/${postId}/`,
    },
  };

  const resp = await fetch(generateUrl, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Veo 2 error ${resp.status}: ${errText.substring(0, 300)}`);
  }

  const opData = await resp.json();
  const operationName = opData.name;

  if (!operationName) throw new Error("No operation name returned from Veo 2");
  console.log(`  ⏳ Video operation started: ${operationName}`);

  // Step 2: Poll until done (max 5 minutes)
  const pollUrl = `https://${REGION}-aiplatform.googleapis.com/v1/${operationName}`;
  const maxPolls = 30; // 30 * 10s = 5 minutes
  let pollCount = 0;

  while (pollCount < maxPolls) {
    await new Promise((r) => setTimeout(r, 10000)); // wait 10s
    pollCount++;

    const pollResp = await fetch(pollUrl, {
      headers: { Authorization: `Bearer ${await getAccessToken()}` },
    });
    const pollData = await pollResp.json();

    if (pollData.done) {
      console.log(`  ✅ Video generated after ${pollCount * 10}s`);

      // Get the video from Storage URI or response
      const videoUri = pollData.response?.generatedSamples?.[0]?.video?.gcsUri
        || pollData.response?.predictions?.[0]?.gcsUri;

      if (videoUri) {
        // Download from GCS
        const gcsPath = videoUri.replace(`gs://${bucket.name}/`, "");
        const file = bucket.file(gcsPath);
        const [buffer] = await file.download();
        return { buffer, mimeType: "video/mp4", gcsUri: videoUri };
      }

      // Or maybe b64 response
      const b64 = pollData.response?.predictions?.[0]?.bytesBase64Encoded;
      if (b64) {
        return { buffer: Buffer.from(b64, "base64"), mimeType: "video/mp4" };
      }

      throw new Error("Video generated but no data found in response");
    }

    console.log(`  ⏳ Polling video... (${pollCount * 10}s)`);
  }

  throw new Error("Video generation timed out after 5 minutes");
}

// ============================================================
// PHASE 4: VOICE — Cloud Text-to-Speech
// Each creator has a unique WaveNet/Neural2 voice.
// ============================================================

async function voicePhase(voiceoverScript, creatorVoice, postId) {
  if (!voiceoverScript || voiceoverScript.length < 10) {
    console.log(`  🔇 No voiceover script — skipping`);
    return null;
  }

  console.log(`  🎙️  Generating voiceover (${voiceoverScript.length} chars)...`);

  const token = await getAccessToken();
  const url = "https://texttospeech.googleapis.com/v1/text:synthesize";

  // Convert "..." pauses to SSML breaks
  const ssmlText = voiceoverScript
    .replace(/\.\.\./g, '<break time="500ms"/>')
    .replace(/\n/g, '<break time="300ms"/>');

  const body = {
    input: {
      ssml: `<speak>${ssmlText}</speak>`,
    },
    voice: {
      languageCode: creatorVoice.languageCode || "en-US",
      name: creatorVoice.name || "en-US-Neural2-D",
      ssmlGender: creatorVoice.ssmlGender || "NEUTRAL",
    },
    audioConfig: {
      audioEncoding: "MP3",
      speakingRate: 0.95, // slightly slower for clarity
      pitch: 0.0,
      volumeGainDb: 2.0,
      effectsProfileId: ["headphone-class-device"],
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    console.error(`  ⚠️ TTS error ${resp.status}: ${errText.substring(0, 200)}`);
    return null; // non-fatal — post still publishes without audio
  }

  const data = await resp.json();
  if (!data.audioContent) {
    console.warn(`  ⚠️ No audio content in TTS response`);
    return null;
  }

  console.log(`  🎙️  Voiceover generated`);
  return Buffer.from(data.audioContent, "base64");
}

// ============================================================
// PHASE 5: UPLOAD — Firebase Storage
// Uploads image/video + audio, returns public URLs.
// ============================================================

async function uploadPhase(postId, mediaResult, audioBuffer) {
  const urls = {};

  // Upload image or video
  if (mediaResult?.buffer) {
    const ext = mediaResult.mimeType === "video/mp4" ? "mp4" : "png";
    const mediaPath = `ai-content/${postId}.${ext}`;
    const mediaFile = bucket.file(mediaPath);

    await mediaFile.save(mediaResult.buffer, {
      contentType: mediaResult.mimeType,
      metadata: {
        cacheControl: "public, max-age=31536000",
        metadata: { generatedBy: "driba-agent", model: mediaResult.mimeType.includes("video") ? "veo-2" : "imagen-3" },
      },
    });
    await mediaFile.makePublic();
    urls.media = `https://storage.googleapis.com/${bucket.name}/${mediaPath}`;
    console.log(`  ☁️  Media uploaded: ${urls.media}`);
  }

  // Upload audio
  if (audioBuffer) {
    const audioPath = `ai-content/${postId}-voice.mp3`;
    const audioFile = bucket.file(audioPath);

    await audioFile.save(audioBuffer, {
      contentType: "audio/mpeg",
      metadata: {
        cacheControl: "public, max-age=31536000",
        metadata: { generatedBy: "driba-agent", model: "cloud-tts" },
      },
    });
    await audioFile.makePublic();
    urls.audio = `https://storage.googleapis.com/${bucket.name}/${audioPath}`;
    console.log(`  ☁️  Audio uploaded: ${urls.audio}`);
  }

  return urls;
}

// ============================================================
// PHASE 6: PUBLISH — Complete Firestore document
// ============================================================

async function publishPhase(creator, content, urls, research, postId) {
  console.log(`  📤 Publishing...`);

  const isVideo = content.mediaSpec?.type === "video";

  const doc = {
    // Core
    author: creator.id,
    authorName: creator.name,
    authorAvatar: creator.avatar,
    description: content.description,
    hashtags: content.hashtags || [],
    categories: content.categories || creator.categories,
    engagementHook: content.engagementHook || null,

    // Media
    mediaUrl: urls.media || "",
    mediaType: isVideo ? "video" : "image",

    // Audio voiceover
    audioUrl: urls.audio || "",
    voiceoverScript: content.voiceoverScript || "",
    hasVoiceover: !!urls.audio,

    // Video prompt (for re-generation or extension)
    ...(isVideo && {
      videoPrompt: content.mediaSpec.prompt,
      videoStyle: content.mediaSpec.style,
      videoDuration: 6,
    }),

    // Generation metadata (how this was made — stored for regeneration)
    mediaGeneration: {
      model: isVideo ? "veo-2.0-generate-exp" : "imagen-3.0-generate-002",
      provider: "vertex_ai",
      prompt: content.mediaSpec.prompt,
      negativePrompt: content.mediaSpec.negativePrompt || "",
      style: content.mediaSpec.style,
      aspectRatio: content.mediaSpec.aspectRatio,
      mood: content.mediaSpec.mood || "",
      generatedAt: FV.serverTimestamp(),
    },

    // Content provenance
    contentMeta: {
      researchHeadline: research.headline || "",
      researchSource: research.source || "",
      researchSourceUrl: research.sourceUrl || "",
      groundedSources: research.groundedSources || [],
      factChecked: content.contentMeta?.factChecked || false,
      confidence: content.contentMeta?.confidence || 0.8,
      topic: content.contentMeta?.topic || "",
    },

    // Engagement
    likes: 0, comments: 0, shares: 0, saves: 0, views: 0,
    engagementScore: 0,

    // AI metadata
    isAIGenerated: true,
    pipeline: "vertex-ai-all-google",
    researchModel: "gemini-2.0-flash",
    writerModel: "gemini-2.5-pro",
    imageModel: isVideo ? "veo-2" : "imagen-3",
    voiceModel: "cloud-tts-neural2",

    status: "published",
    createdAt: FV.serverTimestamp(),
    updatedAt: FV.serverTimestamp(),
  };

  await db.collection("posts").doc(postId).set(doc);

  // Creator content log
  await db.collection("users").doc(creator.id).collection("generated_content").doc(postId).set({
    postId, topic: content.contentMeta?.topic || research.headline,
    mediaType: isVideo ? "video" : "image", hasVoiceover: !!urls.audio,
    createdAt: FV.serverTimestamp(),
  });

  console.log(`  ✅ Published: ${postId}`);
}

// ============================================================
// ORCHESTRATOR — Runs full pipeline for one creator
// ============================================================

async function runCreatorPipeline(creatorKey) {
  const creator = CREATORS[creatorKey];
  if (!creator) throw new Error(`Unknown creator: ${creatorKey}`);

  console.log(`\n🤖 ═══ ${creator.name} ════════════════════════════`);
  const startTime = Date.now();
  const postId = db.collection("posts").doc().id;

  try {
    // 1. Research
    const research = await researchPhase(creator);
    console.log(`  📊 Research: "${research.headline?.substring(0, 60)}"`);

    // 2. Write
    const content = await contentPhase(creator, research);

    // 3. Generate media (image or video)
    let mediaResult = null;
    try {
      if (content.mediaSpec.type === "video") {
        mediaResult = await generateVideo(content.mediaSpec, postId);
      } else {
        mediaResult = await generateImage(content.mediaSpec, postId);
      }
    } catch (mediaErr) {
      console.error(`  ⚠️ Media gen failed: ${mediaErr.message}`);
      // Try image as fallback if video failed
      if (content.mediaSpec.type === "video") {
        console.log(`  🔄 Falling back to image...`);
        try {
          content.mediaSpec.type = "image";
          content.mediaSpec.prompt = `Cinematic still frame: ${content.mediaSpec.prompt}`;
          mediaResult = await generateImage(content.mediaSpec, postId);
        } catch (e2) {
          console.error(`  ❌ Image fallback also failed: ${e2.message}`);
        }
      }
    }

    // 4. Voice
    let audioBuffer = null;
    try {
      audioBuffer = await voicePhase(content.voiceoverScript, creator.voice, postId);
    } catch (voiceErr) {
      console.error(`  ⚠️ Voice gen failed: ${voiceErr.message}`);
    }

    // 5. Upload
    const urls = await uploadPhase(postId, mediaResult, audioBuffer);

    // 6. Publish
    await publishPhase(creator, content, urls, research, postId);

    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`  ⏱️  Complete in ${elapsed}s`);

    return {
      success: true, postId, creator: creator.name,
      description: content.description,
      mediaType: content.mediaSpec?.type, mediaUrl: urls.media,
      hasVoiceover: !!urls.audio, elapsed: `${elapsed}s`,
    };
  } catch (error) {
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    console.error(`  ❌ Pipeline failed for ${creator.name}: ${error.message}`);

    await db.collection("agent_logs").add({
      creator: creatorKey, creatorName: creator.name,
      status: "failed", error: error.message,
      stack: error.stack?.substring(0, 500),
      elapsed: `${elapsed}s`, createdAt: FV.serverTimestamp(),
    });

    return { success: false, creator: creator.name, error: error.message, elapsed: `${elapsed}s` };
  }
}

// ============================================================
// FREQUENCY GATE
// ============================================================

async function shouldCreatorPost(creatorKey) {
  const creator = CREATORS[creatorKey];
  if (!creator) return false;

  const last = await db.collection("posts")
    .where("author", "==", creator.id)
    .orderBy("createdAt", "desc").limit(1).get();

  if (last.empty) return true;

  const lastTime = last.docs[0].data().createdAt?.toDate();
  if (!lastTime) return true;

  const hoursSince = (Date.now() - lastTime.getTime()) / 3600000;
  const match = creator.schedule.match(/every (\d+) hours?/);
  const minHours = match ? parseInt(match[1]) : 4;

  if (hoursSince < minHours) {
    console.log(`  ⏸️  ${creator.name} posted ${hoursSince.toFixed(1)}h ago (min: ${minHours}h)`);
    return false;
  }
  return true;
}

// ============================================================
// CLOUD FUNCTION EXPORTS
// ============================================================

/** Scheduled: every 2 hours */
exports.agentsCron = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .pubsub.schedule("every 2 hours")
  .onRun(async () => {
    console.log("🚀 ═══ AUTONOMOUS AGENTS CYCLE ═══════════════");
    const results = [];
    for (const key of Object.keys(CREATORS)) {
      try {
        if (await shouldCreatorPost(key)) {
          results.push(await runCreatorPipeline(key));
        }
      } catch (e) {
        results.push({ success: false, creator: key, error: e.message });
      }
    }
    await db.collection("agent_logs").add({
      type: "cycle", results,
      successCount: results.filter((r) => r.success).length,
      createdAt: FV.serverTimestamp(),
    });
    console.log(`✅ ${results.filter((r) => r.success).length}/${results.length} succeeded`);
  });

/** HTTP: Run ALL creators */
exports.runAgents = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    const force = req.query.force === "true";
    const results = [];
    for (const key of Object.keys(CREATORS)) {
      if (force || (await shouldCreatorPost(key))) {
        results.push(await runCreatorPipeline(key));
      } else {
        results.push({ success: true, creator: CREATORS[key].name, skipped: true });
      }
    }
    res.json({ timestamp: new Date().toISOString(), results });
  });

/** HTTP: Run ONE creator */
exports.runAgent = functions
  .runWith({ timeoutSeconds: 300, memory: "1GB" })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    const key = req.query.creator;
    if (!key || !CREATORS[key]) {
      res.status(400).json({ error: "Invalid creator", available: Object.keys(CREATORS) });
      return;
    }
    res.json(await runCreatorPipeline(key));
  });

/** HTTP: Regenerate media for a post */
exports.regenerateMedia = functions
  .runWith({ timeoutSeconds: 120, memory: "512MB" })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");

    const postId = req.query.postId;
    if (!postId) { res.status(400).json({ error: "postId required" }); return; }

    const doc = await db.collection("posts").doc(postId).get();
    if (!doc.exists) { res.status(404).json({ error: "Not found" }); return; }

    const post = doc.data();
    const mg = post.mediaGeneration;
    if (!mg?.prompt) { res.status(400).json({ error: "No prompt stored" }); return; }

    try {
      const mediaSpec = { type: post.mediaType || "image", prompt: mg.prompt, negativePrompt: mg.negativePrompt, style: mg.style, aspectRatio: mg.aspectRatio };
      const result = await generateImage(mediaSpec, postId);
      const urls = await uploadPhase(postId, result, null);
      await doc.ref.update({ mediaUrl: urls.media, "mediaGeneration.regeneratedAt": FV.serverTimestamp(), updatedAt: FV.serverTimestamp() });
      res.json({ success: true, postId, mediaUrl: urls.media });
    } catch (e) {
      res.status(500).json({ success: false, error: e.message });
    }
  });

/** HTTP: Creator status dashboard */
exports.agentStatus = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

  const status = {};
  for (const [key, creator] of Object.entries(CREATORS)) {
    const last = await db.collection("posts").where("author", "==", creator.id).orderBy("createdAt", "desc").limit(1).get();
    const count = await db.collection("posts").where("author", "==", creator.id).count().get();
    status[key] = {
      name: creator.name, categories: creator.categories, schedule: creator.schedule,
      voice: creator.voice.name, totalPosts: count.data().count,
      lastPost: last.empty ? null : {
        id: last.docs[0].id,
        description: last.docs[0].data().description?.substring(0, 80),
        mediaType: last.docs[0].data().mediaType,
        hasVoiceover: last.docs[0].data().hasVoiceover || false,
        createdAt: last.docs[0].data().createdAt?.toDate()?.toISOString(),
      },
    };
  }
  res.json({ pipeline: "vertex-ai-all-google", creators: status, timestamp: new Date().toISOString() });
});
