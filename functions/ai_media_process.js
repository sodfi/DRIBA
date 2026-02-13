/**
 * ============================================================
 * DRIBA OS — AI MEDIA PROCESSING (Vertex AI)
 * ============================================================
 *
 * Handles two concerns:
 *
 * A) AI STUDIO (user-facing)
 *    Called from Flutter via FirebaseFunctions.httpsCallable('aiMediaProcess')
 *    Actions: enhance, scene, style, video, background
 *
 * B) DUAL-RATIO GENERATION (used by autonomous agents & user uploads)
 *    generateDualRatio() creates both 9:16 (portrait) and 16:9 (landscape)
 *    versions of an image from a single prompt.
 *
 * Auth: Cloud Functions service account → Vertex AI (no key needed).
 * Required APIs: aiplatform.googleapis.com, texttospeech.googleapis.com
 *
 * ============================================================
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleAuth } = require("google-auth-library");

if (!admin.apps.length) admin.initializeApp();
const bucket = admin.storage().bucket("driba-os.firebasestorage.app");
const db = admin.firestore();

const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "driba-os";
const REGION = "us-central1";
const GEMINI_KEY = process.env.GEMINI_API_KEY || process.env.GOOGLE_AI_KEY || functions.config().ai?.google_key;

const auth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

async function getAccessToken() {
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token || token;
}

// ============================================================
// IMAGEN 3 — Image Generation / Editing
// ============================================================

/**
 * Generate an image with Imagen 3.
 * @param {string} prompt - Text prompt
 * @param {object} opts - { aspectRatio, style, negativePrompt }
 * @returns {{ buffer: Buffer, mimeType: string }}
 */
async function imagenGenerate(prompt, opts = {}) {
  const token = await getAccessToken();
  const model = "imagen-3.0-generate-002";
  const url = `https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${model}:predict`;

  // Enhance prompt based on style
  let enhancedPrompt = prompt;
  if (opts.style === "photorealistic" || !opts.style) {
    enhancedPrompt += ", photorealistic, high resolution, professional photography, sharp focus, beautiful lighting";
  } else if (opts.style === "cinematic") {
    enhancedPrompt += ", cinematic, film grain, dramatic lighting, color graded, anamorphic";
  }

  const body = {
    instances: [{ prompt: enhancedPrompt }],
    parameters: {
      sampleCount: 1,
      aspectRatio: opts.aspectRatio || "9:16",
      safetyFilterLevel: "block_medium_and_above",
      personGeneration: "allow_adult",
      addWatermark: false,
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Imagen 3 error ${resp.status}: ${errText.substring(0, 300)}`);
  }

  const data = await resp.json();
  const b64 = data.predictions?.[0]?.bytesBase64Encoded;
  if (!b64) throw new Error("No image data in Imagen response");

  return { buffer: Buffer.from(b64, "base64"), mimeType: "image/png" };
}

/**
 * Edit an image with Imagen 3 (scene change, style transfer, etc.)
 * Uses the edit API with mask-free inpainting.
 * @param {Buffer} imageBuffer - Source image bytes
 * @param {string} prompt - Edit instruction
 * @param {object} opts - { aspectRatio }
 * @returns {{ buffer: Buffer, mimeType: string }}
 */
async function imagenEdit(imageBuffer, prompt, opts = {}) {
  const token = await getAccessToken();
  const model = "imagen-3.0-capability-001";
  const url = `https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${model}:predict`;

  const b64Image = imageBuffer.toString("base64");

  const body = {
    instances: [{
      prompt,
      image: { bytesBase64Encoded: b64Image },
    }],
    parameters: {
      sampleCount: 1,
      safetyFilterLevel: "block_medium_and_above",
      personGeneration: "allow_adult",
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Imagen edit error ${resp.status}: ${errText.substring(0, 300)}`);
  }

  const data = await resp.json();
  const b64 = data.predictions?.[0]?.bytesBase64Encoded;
  if (!b64) throw new Error("No edited image in response");

  return { buffer: Buffer.from(b64, "base64"), mimeType: "image/png" };
}

// ============================================================
// VEO 2 — Video Generation from Image
// ============================================================

/**
 * Generate a video from an image + prompt using Veo 2.
 * Returns the GCS URI of the generated video.
 * This is async (long-running operation) — we poll until done.
 */
async function veoGenerateFromImage(imageBuffer, prompt, opts = {}) {
  const token = await getAccessToken();
  const model = "veo-2.0-generate-exp";
  const postId = opts.postId || `vid_${Date.now()}`;
  const outputUri = `gs://${bucket.name}/ai-video/${postId}/`;

  const url = `https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${model}:predictLongRunning`;

  const b64Image = imageBuffer.toString("base64");

  const body = {
    instances: [{
      prompt,
      image: { bytesBase64Encoded: b64Image, mimeType: "image/png" },
    }],
    parameters: {
      aspectRatio: opts.aspectRatio || "9:16",
      sampleCount: 1,
      durationSeconds: 6,
      storageUri: outputUri,
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Veo 2 error ${resp.status}: ${errText.substring(0, 300)}`);
  }

  const opData = await resp.json();
  const operationName = opData.name;
  if (!operationName) throw new Error("No operation name from Veo 2");

  // Poll until complete (max 5 min)
  const pollUrl = `https://${REGION}-aiplatform.googleapis.com/v1/${operationName}`;
  const maxPolls = 30;
  let pollCount = 0;

  while (pollCount < maxPolls) {
    await new Promise((r) => setTimeout(r, 10000));
    pollCount++;

    const pollResp = await fetch(pollUrl, {
      headers: { Authorization: `Bearer ${await getAccessToken()}` },
    });
    const pollData = await pollResp.json();

    if (pollData.done) {
      const videoUri = pollData.response?.generatedSamples?.[0]?.video?.gcsUri
        || pollData.response?.predictions?.[0]?.gcsUri;

      if (videoUri) {
        // Make the video file public
        const gcsPath = videoUri.replace(`gs://${bucket.name}/`, "");
        const file = bucket.file(gcsPath);
        try { await file.makePublic(); } catch (e) { console.warn("Could not make video public:", e.message); }
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${gcsPath}`;
        return { videoUrl: publicUrl, gcsUri: videoUri };
      }

      throw new Error("Video done but no URI found");
    }
  }

  throw new Error("Video generation timed out (5 min)");
}

// ============================================================
// DUAL-RATIO GENERATION
// Produces both 9:16 and 16:9 from a single prompt.
// Used by autonomous agents AND user post processing.
// ============================================================

/**
 * Generate both portrait and landscape images from a prompt.
 * @param {string} prompt - The image generation prompt
 * @param {string} postId - For file naming
 * @param {object} opts - { style }
 * @returns {{ portrait: { url, buffer }, landscape: { url, buffer } }}
 */
async function generateDualRatio(prompt, postId, opts = {}) {
  console.log(`  🖼️  Dual-ratio generation for ${postId}...`);

  // Generate both in parallel
  const [portraitResult, landscapeResult] = await Promise.allSettled([
    imagenGenerate(prompt, { ...opts, aspectRatio: "9:16" }),
    imagenGenerate(prompt + ", wide angle shot, panoramic composition", { ...opts, aspectRatio: "16:9" }),
  ]);

  const result = { portrait: null, landscape: null };

  // Upload portrait (9:16)
  if (portraitResult.status === "fulfilled") {
    const portraitPath = `ai-content/${postId}-portrait.png`;
    const pFile = bucket.file(portraitPath);
    await pFile.save(portraitResult.value.buffer, {
      contentType: "image/png",
      metadata: { cacheControl: "public, max-age=31536000", metadata: { ratio: "9:16", model: "imagen-3" } },
    });
    await pFile.makePublic();
    result.portrait = {
      url: `https://storage.googleapis.com/${bucket.name}/${portraitPath}`,
      buffer: portraitResult.value.buffer,
    };
    console.log(`  📱 Portrait uploaded`);
  } else {
    console.error(`  ⚠️ Portrait generation failed: ${portraitResult.reason?.message}`);
  }

  // Upload landscape (16:9)
  if (landscapeResult.status === "fulfilled") {
    const landscapePath = `ai-content/${postId}-landscape.png`;
    const lFile = bucket.file(landscapePath);
    await lFile.save(landscapeResult.value.buffer, {
      contentType: "image/png",
      metadata: { cacheControl: "public, max-age=31536000", metadata: { ratio: "16:9", model: "imagen-3" } },
    });
    await lFile.makePublic();
    result.landscape = {
      url: `https://storage.googleapis.com/${bucket.name}/${landscapePath}`,
      buffer: landscapeResult.value.buffer,
    };
    console.log(`  🖥️  Landscape uploaded`);
  } else {
    console.error(`  ⚠️ Landscape generation failed: ${landscapeResult.reason?.message}`);
  }

  return result;
}

// ============================================================
// USER UPLOAD: DUAL-RATIO CROP
// Takes a user-uploaded image and creates both aspect ratios
// via Imagen 3 outpainting / smart crop.
// ============================================================

async function createDualRatioFromUpload(imageBuffer, postId) {
  console.log(`  ✂️  Creating dual-ratio crops for upload ${postId}...`);

  const result = { portrait: null, landscape: null };

  // For portrait: try to outpaint vertically
  try {
    const portraitRes = await imagenEdit(
      imageBuffer,
      "Extend this image vertically to fill a 9:16 portrait frame. Maintain the original subject and style. Seamless expansion of the environment.",
    );
    const portraitPath = `user-content/${postId}-portrait.png`;
    const pFile = bucket.file(portraitPath);
    await pFile.save(portraitRes.buffer, {
      contentType: "image/png",
      metadata: { cacheControl: "public, max-age=31536000" },
    });
    await pFile.makePublic();
    result.portrait = `https://storage.googleapis.com/${bucket.name}/${portraitPath}`;
  } catch (e) {
    console.warn(`  ⚠️ Portrait crop failed, using original: ${e.message}`);
  }

  // For landscape: try to outpaint horizontally
  try {
    const landscapeRes = await imagenEdit(
      imageBuffer,
      "Extend this image horizontally to fill a 16:9 landscape frame. Maintain the original subject and style. Seamless expansion of the environment.",
    );
    const landscapePath = `user-content/${postId}-landscape.png`;
    const lFile = bucket.file(landscapePath);
    await lFile.save(landscapeRes.buffer, {
      contentType: "image/png",
      metadata: { cacheControl: "public, max-age=31536000" },
    });
    await lFile.makePublic();
    result.landscape = `https://storage.googleapis.com/${bucket.name}/${landscapePath}`;
  } catch (e) {
    console.warn(`  ⚠️ Landscape crop failed, using original: ${e.message}`);
  }

  return result;
}

// ============================================================
// AI STUDIO — CALLABLE FUNCTION
// Called by Flutter frontend for Pro AI features.
// ============================================================

exports.aiMediaProcess = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .https.onCall(async (data, context) => {
    // Auth check (uncomment when auth is live)
    // if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');

    const { action, imageBase64, params = {} } = data;
    if (!action) throw new functions.https.HttpsError("invalid-argument", "action required");
    if (!imageBase64) throw new functions.https.HttpsError("invalid-argument", "imageBase64 required");

    const imageBuffer = Buffer.from(imageBase64, "base64");
    const uid = context.auth?.uid || "anonymous";
    const postId = `ai_${uid}_${Date.now()}`;

    try {
      switch (action) {
        // ── ENHANCE ──────────────────────────────────────
        case "enhance": {
          const mode = params.mode || "professional";
          const promptMap = {
            professional: "Professionally enhance this photo: improve lighting, color balance, sharpness, and overall quality. Make it look like it was taken by a professional photographer.",
            hdr: "Apply HDR processing to this image: expand dynamic range, bring out shadow detail, enhance highlights, vivid colors while maintaining natural look.",
            portrait: "Apply professional portrait mode: create natural background blur (bokeh), enhance skin tones, improve lighting on the subject, studio-quality result.",
            outpaint: "Extend this image outward in all directions, expanding the scene naturally. Maintain the original subject and style seamlessly.",
          };

          const prompt = promptMap[mode] || promptMap.professional;
          const result = await imagenEdit(imageBuffer, prompt);

          // Upload
          const path = `user-ai/${postId}-enhanced.png`;
          const file = bucket.file(path);
          await file.save(result.buffer, { contentType: "image/png", metadata: { cacheControl: "public, max-age=31536000" } });
          await file.makePublic();
          const imageUrl = `https://storage.googleapis.com/${bucket.name}/${path}`;

          return { success: true, imageUrl, actionLabel: `${mode.charAt(0).toUpperCase() + mode.slice(1)} Enhanced` };
        }

        // ── SCENE CHANGE ─────────────────────────────────
        case "scene": {
          const scenePrompt = params.scenePrompt;
          if (!scenePrompt) throw new functions.https.HttpsError("invalid-argument", "scenePrompt required");

          const prompt = `Place the main subject from this image into a new scene: ${scenePrompt}. Keep the subject's details, proportions, and identity exactly the same. Only change the background and environment. Professional product photography quality.`;
          const result = await imagenEdit(imageBuffer, prompt);

          const path = `user-ai/${postId}-scene.png`;
          const file = bucket.file(path);
          await file.save(result.buffer, { contentType: "image/png", metadata: { cacheControl: "public, max-age=31536000" } });
          await file.makePublic();
          const imageUrl = `https://storage.googleapis.com/${bucket.name}/${path}`;

          return { success: true, imageUrl, actionLabel: `Scene: ${params.sceneName || 'Custom'}` };
        }

        // ── STYLE TRANSFER ───────────────────────────────
        case "style": {
          const stylePrompt = params.stylePrompt;
          if (!stylePrompt) throw new functions.https.HttpsError("invalid-argument", "stylePrompt required");

          const prompt = `Transform this image with the following artistic style: ${stylePrompt}. Maintain the composition and subject but apply the style consistently.`;
          const result = await imagenEdit(imageBuffer, prompt);

          const path = `user-ai/${postId}-style.png`;
          const file = bucket.file(path);
          await file.save(result.buffer, { contentType: "image/png", metadata: { cacheControl: "public, max-age=31536000" } });
          await file.makePublic();
          const imageUrl = `https://storage.googleapis.com/${bucket.name}/${path}`;

          return { success: true, imageUrl, actionLabel: `Style: ${params.styleName || 'Custom'}` };
        }

        // ── PHOTO TO VIDEO ───────────────────────────────
        case "video": {
          const mode = params.mode || "cinematic";
          const modePrompt = params.modePrompt || "Slow cinematic camera movement";
          const customPrompt = params.customPrompt || "";

          const videoPrompt = `${modePrompt}. ${customPrompt}. High quality, smooth motion, professional video.`.trim();
          const aspectRatio = params.aspectRatio || "9:16";

          const videoResult = await veoGenerateFromImage(imageBuffer, videoPrompt, { postId, aspectRatio });

          // Also create a thumbnail from the original image
          const thumbPath = `user-ai/${postId}-thumb.png`;
          const thumbFile = bucket.file(thumbPath);
          await thumbFile.save(imageBuffer, { contentType: "image/png", metadata: { cacheControl: "public, max-age=31536000" } });
          await thumbFile.makePublic();
          const thumbUrl = `https://storage.googleapis.com/${bucket.name}/${thumbPath}`;

          return {
            success: true,
            imageUrl: thumbUrl,
            videoUrl: videoResult.videoUrl,
            actionLabel: `Video: ${mode.charAt(0).toUpperCase() + mode.slice(1)}`,
          };
        }

        default:
          throw new functions.https.HttpsError("invalid-argument", `Unknown action: ${action}`);
      }
    } catch (error) {
      console.error(`AI Studio error (${action}):`, error.message);
      throw new functions.https.HttpsError("internal", error.message);
    }
  });

// ============================================================
// DUAL-RATIO TRIGGER
// Firestore trigger: when a user post is created, auto-generate
// portrait + landscape versions in the background.
// ============================================================

exports.processUserMedia = functions
  .runWith({ timeoutSeconds: 300, memory: "1GB" })
  .firestore.document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const post = snap.data();

    // Only process user posts that have a mediaUrl but no dual-ratio
    if (post.isAIGenerated) return null; // AI posts handle this themselves
    if (!post.mediaUrl) return null;
    if (post.mediaUrlPortrait || post.mediaUrlLandscape) return null;

    const postId = context.params.postId;
    console.log(`📐 Processing dual-ratio for user post ${postId}`);

    try {
      // Download the user's original media
      const mediaUrl = post.mediaUrl;

      // If it's a Firebase Storage URL, download from bucket
      let imageBuffer;
      if (mediaUrl.includes(bucket.name)) {
        const path = mediaUrl.split(`${bucket.name}/`)[1];
        if (path) {
          const file = bucket.file(path);
          const [buffer] = await file.download();
          imageBuffer = buffer;
        }
      }

      // If it's an external URL, fetch it
      if (!imageBuffer) {
        const resp = await fetch(mediaUrl);
        if (!resp.ok) return null;
        const arrayBuffer = await resp.arrayBuffer();
        imageBuffer = Buffer.from(arrayBuffer);
      }

      // Generate dual-ratio versions
      const dualRatio = await createDualRatioFromUpload(imageBuffer, postId);

      // Update the post document
      const update = {};
      if (dualRatio.portrait) update.mediaUrlPortrait = dualRatio.portrait;
      if (dualRatio.landscape) update.mediaUrlLandscape = dualRatio.landscape;

      if (Object.keys(update).length > 0) {
        await snap.ref.update(update);
        console.log(`✅ Dual-ratio created for ${postId}`);
      }
    } catch (error) {
      console.error(`❌ Dual-ratio error for ${postId}:`, error.message);
      // Non-fatal — post still works with original mediaUrl
    }

    return null;
  });

// Export the utility functions for autonomous agents to use
exports._generateDualRatio = generateDualRatio;
exports._imagenGenerate = imagenGenerate;
exports._veoGenerateFromImage = veoGenerateFromImage;
