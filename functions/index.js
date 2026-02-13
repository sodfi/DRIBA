/**
 * Driba OS — Cloud Functions Index (v4 — Claude Agents + In-App Assistant)
 *
 * Functions:
 *   CLAUDE:     claudeAgentsCron, runClaudeAgents, runClaudeAgent, claudeChat
 *   AGENTS:     agentsCron, runAgents, runAgent, regenerateMedia, agentStatus
 *   AI STUDIO:  aiMediaProcess (callable from Flutter)
 *   MEDIA:      processUserMedia (auto dual-ratio on user upload)
 *   ENGAGE:     calculateEngagement, curateTrending
 *   MODERATE:   moderateContent
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

admin.initializeApp();

// ─── Claude-Powered Agents + In-App Assistant ────────────
const claude = require("./claude_agent");
exports.claudeAgentsCron = claude.claudeAgentsCron;
exports.runClaudeAgents = claude.runClaudeAgents;
exports.runClaudeAgent = claude.runClaudeAgent;
exports.claudeChat = claude.claudeChat;

// ─── Autonomous Content Agents (Gemini pipeline) ─────────
const agents = require("./autonomous_agents");
exports.agentsCron = agents.agentsCron;
exports.runAgents = agents.runAgents;
exports.runAgent = agents.runAgent;
exports.regenerateMedia = agents.regenerateMedia;
exports.agentStatus = agents.agentStatus;

// ─── AI Studio + Dual Ratio Media Processing ────────────
const aiMedia = require("./ai_media_process");
exports.aiMediaProcess = aiMedia.aiMediaProcess;
exports.processUserMedia = aiMedia.processUserMedia;

// ─── AI API Proxy (client-facing — legacy) ──────────────
try {
  const aiFunctions = require("./ai_functions");
  exports.aiComplete = aiFunctions.aiComplete;
  exports.aiModerate = aiFunctions.aiModerate;
} catch (e) {
  // ai_functions.js may not exist if only deploying agents
}

// ─── Engagement & Curation ──────────────────────────────

const db = admin.firestore();

exports.calculateEngagement = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const posts = await db.collection("posts").where("status", "==", "published").get();
    const batch = db.batch();
    const now = new Date();
    posts.forEach((doc) => {
      const p = doc.data();
      const ageH = (now - (p.createdAt?.toDate() || now)) / 3600000;
      const score =
        ((p.likes || 0) +
          (p.comments || 0) * 3 +
          (p.shares || 0) * 5 +
          (p.saves || 0) * 4 +
          (p.views || 0) * 0.1) /
        Math.pow(ageH + 2, 1.5);
      batch.update(doc.ref, { engagementScore: score });
    });
    await batch.commit();
    console.log(`Engagement updated: ${posts.size} posts`);
  });

exports.curateTrending = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    for (const screen of ["food", "commerce", "travel", "health", "news", "utility"]) {
      const top = await db
        .collection("posts")
        .where("status", "==", "published")
        .where("categories", "array-contains", screen)
        .orderBy("engagementScore", "desc")
        .limit(20)
        .get();
      await db.collection("global").doc("trending").set(
        {
          [screen]: top.docs.map((d) => d.id),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  });

// ─── Content Moderation ─────────────────────────────────

exports.moderateContent = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap) => {
    const post = snap.data();
    // Auto-approve AI-generated posts (they're already moderated by the pipeline)
    if (post.isAIGenerated && post.status === "published") return null;
    // Moderate user posts
    if (!post.isAIGenerated || post.status === "pending_review") {
      try {
        // Use Gemini for moderation (keeps everything in Google ecosystem)
        const GEMINI_KEY = process.env.GEMINI_API_KEY || functions.config().ai?.google_key;
        if (!GEMINI_KEY) {
          console.warn("No GEMINI_API_KEY for moderation — auto-approving");
          await snap.ref.update({ status: "published" });
          return null;
        }

        const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_KEY}`;
        const body = {
          contents: [{
            parts: [{
              text: `You are a content moderator. Review this social media post and determine if it's safe.
Post: "${post.description}"
Return ONLY JSON: {"safe":true/false,"flags":[],"action":"approve"|"reject"|"review"}`,
            }],
          }],
          generationConfig: { temperature: 0.1, maxOutputTokens: 200 },
        };

        const resp = await fetch(url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });
        const data = await resp.json();
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text || '{"safe":true,"action":"approve"}';
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        const result = jsonMatch ? JSON.parse(jsonMatch[0]) : { safe: true, action: "approve" };

        await snap.ref.update({
          status: result.safe ? "published" : "rejected",
          moderationResult: result,
          moderatedAt: FieldValue.serverTimestamp(),
        });
      } catch (e) {
        console.error("Moderation error:", e.message);
        await snap.ref.update({ status: "pending_review" });
      }
    }
    return null;
  });

// ─── Seed Data (optional) ───────────────────────────────
try { const s = require("./seed_data"); exports.seedData = s.seedData; } catch (e) {}
try { const s2 = require("./seed_data_v2"); exports.seedDataV2 = s2.seedDataV2; } catch (e) {}

module.exports = exports;
