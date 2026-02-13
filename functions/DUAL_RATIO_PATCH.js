/**
 * ============================================================
 * AUTONOMOUS AGENTS — DUAL RATIO PATCH
 * ============================================================
 *
 * Apply these changes to autonomous_agents.js (v2) to add:
 *   1. Dual-ratio image generation (9:16 + 16:9)
 *   2. Audio URL in Firestore document
 *   3. Portrait/landscape URL fields
 *
 * OPTION A: Import the shared functions
 *   const { _generateDualRatio } = require("./ai_media_process");
 *
 * OPTION B: Replace the existing mediaPhase (shown below)
 * ============================================================
 */

// ── At the top of autonomous_agents.js, add: ──────────────
// const aiMedia = require("./ai_media_process");

// ── Replace the existing generateImage function with: ─────

/**
 * PHASE 3: MEDIA — Dual Ratio Generation
 * Generates BOTH 9:16 (portrait/mobile) and 16:9 (landscape/desktop)
 * from the same content prompt.
 */
async function mediaPhase(mediaSpec, postId) {
  console.log(`  🎨 [DUAL RATIO] Generating portrait + landscape images...`);

  const token = await getAccessToken();
  const model = "imagen-3.0-generate-002";
  const baseUrl = `https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${model}:predict`;

  // Enhance prompt
  let prompt = mediaSpec.prompt;
  if (mediaSpec.style === "photorealistic" || !mediaSpec.style) {
    prompt += ", photorealistic, high resolution, professional photography, sharp focus, beautiful lighting";
  }

  // Generate BOTH ratios in parallel
  const [portraitResp, landscapeResp] = await Promise.allSettled([
    // 9:16 — mobile portrait
    fetch(baseUrl, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        instances: [{ prompt }],
        parameters: { sampleCount: 1, aspectRatio: "9:16", safetyFilterLevel: "block_medium_and_above", personGeneration: "allow_adult", addWatermark: false },
      }),
    }).then(async (r) => {
      if (!r.ok) throw new Error(`Portrait: ${r.status}`);
      const d = await r.json();
      return Buffer.from(d.predictions[0].bytesBase64Encoded, "base64");
    }),

    // 16:9 — desktop landscape
    fetch(baseUrl, {
      method: "POST",
      headers: { Authorization: `Bearer ${await getAccessToken()}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        instances: [{ prompt: prompt + ", wide angle, panoramic composition" }],
        parameters: { sampleCount: 1, aspectRatio: "16:9", safetyFilterLevel: "block_medium_and_above", personGeneration: "allow_adult", addWatermark: false },
      }),
    }).then(async (r) => {
      if (!r.ok) throw new Error(`Landscape: ${r.status}`);
      const d = await r.json();
      return Buffer.from(d.predictions[0].bytesBase64Encoded, "base64");
    }),
  ]);

  const result = { portrait: null, landscape: null, primary: null };

  if (portraitResp.status === "fulfilled") {
    result.portrait = portraitResp.value;
    result.primary = portraitResp.value; // primary = portrait
    console.log(`  📱 Portrait image generated`);
  } else {
    console.warn(`  ⚠️ Portrait failed: ${portraitResp.reason?.message}`);
  }

  if (landscapeResp.status === "fulfilled") {
    result.landscape = landscapeResp.value;
    if (!result.primary) result.primary = landscapeResp.value;
    console.log(`  🖥️  Landscape image generated`);
  } else {
    console.warn(`  ⚠️ Landscape failed: ${landscapeResp.reason?.message}`);
  }

  if (!result.primary) throw new Error("Both portrait and landscape generation failed");

  return result;
}

// ── Replace uploadPhase with: ─────────────────────────────

async function uploadPhase(postId, mediaResult, audioBuffer) {
  const urls = {};

  // Upload portrait (9:16) — mobile
  if (mediaResult?.portrait) {
    const path = `ai-content/${postId}-portrait.png`;
    const file = bucket.file(path);
    await file.save(mediaResult.portrait, {
      contentType: "image/png",
      metadata: { cacheControl: "public, max-age=31536000", metadata: { ratio: "9:16", model: "imagen-3" } },
    });
    await file.makePublic();
    urls.portrait = `https://storage.googleapis.com/${bucket.name}/${path}`;
    urls.media = urls.portrait; // primary URL = portrait
    console.log(`  ☁️  Portrait uploaded: ${urls.portrait}`);
  }

  // Upload landscape (16:9) — desktop
  if (mediaResult?.landscape) {
    const path = `ai-content/${postId}-landscape.png`;
    const file = bucket.file(path);
    await file.save(mediaResult.landscape, {
      contentType: "image/png",
      metadata: { cacheControl: "public, max-age=31536000", metadata: { ratio: "16:9", model: "imagen-3" } },
    });
    await file.makePublic();
    urls.landscape = `https://storage.googleapis.com/${bucket.name}/${path}`;
    if (!urls.media) urls.media = urls.landscape;
    console.log(`  ☁️  Landscape uploaded: ${urls.landscape}`);
  }

  // Upload audio voiceover
  if (audioBuffer) {
    const audioPath = `ai-content/${postId}-voice.mp3`;
    const audioFile = bucket.file(audioPath);
    await audioFile.save(audioBuffer, {
      contentType: "audio/mpeg",
      metadata: { cacheControl: "public, max-age=31536000", metadata: { model: "cloud-tts" } },
    });
    await audioFile.makePublic();
    urls.audio = `https://storage.googleapis.com/${bucket.name}/${audioPath}`;
    console.log(`  ☁️  Audio uploaded: ${urls.audio}`);
  }

  return urls;
}

// ── Update the Firestore document in publishPhase: ────────
// Add these fields to the doc object:

/*
  // Dual-ratio media URLs
  mediaUrl: urls.media || "",              // primary (portrait fallback)
  mediaUrlPortrait: urls.portrait || "",   // 9:16 for mobile
  mediaUrlLandscape: urls.landscape || "", // 16:9 for desktop

  // Audio voiceover
  audioUrl: urls.audio || "",
  voiceoverScript: content.voiceoverScript || "",
  hasVoiceover: !!urls.audio,
*/
