/**
 * ============================================================
 * DRIBA OS — CLAUDE-POWERED CONTENT AGENT
 * ============================================================
 *
 * Simplified pipeline that ACTUALLY WORKS:
 *   1. Claude writes the post (personality + research prompt)
 *   2. Unsplash provides the image (search by topic)
 *   3. Published directly to Firestore
 *
 * No Vertex AI, no Imagen, no TTS dependency.
 * Just Claude + Unsplash → Firestore.
 *
 * Also: In-app Claude assistant endpoint.
 * ============================================================
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Anthropic = require("@anthropic-ai/sdk").default;
const { FieldValue: FV } = require("firebase-admin/firestore");

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const CLAUDE_KEY = process.env.ANTHROPIC_API_KEY;

// ─── Creator Personalities ──────────────────────────────────

const CREATORS = {
  chef_aiden: {
    id: "ai_chef_aiden",
    name: "Chef Aiden",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=chef_aiden&backgroundColor=ff6b35",
    personality: "You are Chef Aiden — a warm, passionate food creator. You discover trending recipes, restaurant stories, street food culture globally. Casual, vivid, mouth-watering. 1-2 emojis max.",
    categories: ["food", "feed"],
    crossCategories: ["food", "health", "feed"],
    imageSearch: ["gourmet food plating", "street food market", "cooking process", "restaurant dish", "fresh ingredients", "food photography"],
  },
  travel_nova: {
    id: "ai_travel_nova",
    name: "Nova Wanderer",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=travel_nova&backgroundColor=00b4d8",
    personality: "You are Nova — a poetic, adventurous travel creator. Hidden gems, off-the-beaten-path places, travel hacks. Vivid imagery, practical tips, wanderlust-inducing. Short punchy sentences.",
    categories: ["travel", "feed"],
    crossCategories: ["travel", "feed"],
    imageSearch: ["hidden travel destination", "beautiful landscape", "ancient temple", "tropical beach sunset", "mountain trail", "city skyline"],
  },
  news_pulse: {
    id: "ai_news_pulse",
    name: "Pulse",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=news_pulse&backgroundColor=ff3d71",
    personality: "You are Pulse — a sharp, objective news creator. Breaking stories, tech developments, science breakthroughs. Factual, concise, no sensationalism. Always cite context.",
    categories: ["news", "feed"],
    crossCategories: ["news", "health", "feed"],
    imageSearch: ["technology innovation", "science laboratory", "global business", "renewable energy", "space exploration", "artificial intelligence"],
  },
  health_vita: {
    id: "ai_health_vita",
    name: "Vita",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=vita_health&backgroundColor=00d68f",
    personality: "You are Vita — a knowledgeable, supportive wellness creator. Evidence-based health tips, fitness, nutrition science, mental wellness. Encouraging but never preachy.",
    categories: ["health", "feed"],
    crossCategories: ["health", "food", "feed"],
    imageSearch: ["yoga meditation", "healthy food bowl", "morning routine fitness", "nature wellness", "running exercise", "sleep wellness"],
  },
  style_mira: {
    id: "ai_style_mira",
    name: "Mira Style",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=mira_style&backgroundColor=ffd700",
    personality: "You are Mira — a tastemaker lifestyle creator. Artisan products, fashion trends, home decor, design stories. Curated, aspirational but accessible. Champion independent artisans.",
    categories: ["commerce", "feed"],
    crossCategories: ["commerce", "feed"],
    imageSearch: ["artisan handmade products", "fashion style", "home decor interior", "ceramic pottery", "vintage market", "designer jewelry"],
  },
  tech_arc: {
    id: "ai_tech_arc",
    name: "Arc",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=arc_tech&backgroundColor=8b5cf6",
    personality: "You are Arc — a sharp, practical tech creator. App recommendations, privacy tips, AI tools, productivity hacks. No jargon, practical value. Skeptical of hype, enthusiastic about what works.",
    categories: ["utility", "feed"],
    crossCategories: ["utility", "feed"],
    imageSearch: ["tech workspace setup", "coding programming", "smartphone apps", "cybersecurity digital", "productivity desk", "futuristic technology"],
  },
};

// ─── Unsplash Image Fetcher ──────────────────────────────────

async function getUnsplashImage(searchTerms) {
  const query = searchTerms[Math.floor(Math.random() * searchTerms.length)];
  const url = `https://api.unsplash.com/photos/random?query=${encodeURIComponent(query)}&orientation=portrait&content_filter=high&client_id=YOUR_UNSPLASH_KEY_OR_USE_DIRECT`;

  // Use direct Unsplash source URLs (no API key needed)
  const CURATED = {
    "gourmet food plating": "photo-1504674900247-0877df9cc836",
    "street food market": "photo-1555939594-58d7cb561ad1",
    "cooking process": "photo-1556910103-1c02745aae4d",
    "restaurant dish": "photo-1414235077428-338989a2e8c0",
    "fresh ingredients": "photo-1512621776951-a57141f2eefd",
    "food photography": "photo-1476224203421-9ac39bcb3327",
    "hidden travel destination": "photo-1553522991-71f5b39e5c8a",
    "beautiful landscape": "photo-1506905925346-21bda4d32df4",
    "ancient temple": "photo-1545569341-9eb8b30979d9",
    "tropical beach sunset": "photo-1507525428034-b723cf961d3e",
    "mountain trail": "photo-1464822759023-fed622ff2c3b",
    "city skyline": "photo-1477959858617-67f85cf4f1df",
    "technology innovation": "photo-1677442136019-21780ecad995",
    "science laboratory": "photo-1532094349884-543bc11b234d",
    "global business": "photo-1522071820081-009f0129c71c",
    "renewable energy": "photo-1509391366360-2e959784a276",
    "space exploration": "photo-1446776811953-b23d57bd21aa",
    "artificial intelligence": "photo-1555255707-c07966088b7b",
    "yoga meditation": "photo-1544367567-0f2fcb009e0b",
    "healthy food bowl": "photo-1490645935967-10de6ba17061",
    "morning routine fitness": "photo-1571019613454-1cb2f99b2d8b",
    "nature wellness": "photo-1506126613408-eca07ce68773",
    "running exercise": "photo-1552674605-db6ffd4facb5",
    "sleep wellness": "photo-1495474472287-4d71bcdd2085",
    "artisan handmade products": "photo-1553062407-98eeb64c6a62",
    "fashion style": "photo-1445205170230-053b83016050",
    "home decor interior": "photo-1600166898405-da9535204843",
    "ceramic pottery": "photo-1565193566173-7a0ee3dbe261",
    "vintage market": "photo-1556742049-0cfed4f6a45d",
    "designer jewelry": "photo-1515562141589-67f0d727b750",
    "tech workspace setup": "photo-1555066931-4365d14bab8c",
    "coding programming": "photo-1461749280684-dccba630e2f6",
    "smartphone apps": "photo-1512941937669-90a1b58e7e9c",
    "cybersecurity digital": "photo-1563013544-824ae1b704d3",
    "productivity desk": "photo-1516321318423-f06f85e504b3",
    "futuristic technology": "photo-1485827404703-89b55fcc595e",
  };

  const photoId = CURATED[query];
  if (photoId) {
    return `https://images.unsplash.com/${photoId}?w=1080&q=80`;
  }
  // Fallback: use Unsplash source (random from query)
  return `https://source.unsplash.com/1080x1920/?${encodeURIComponent(query)}`;
}

// ─── Claude Content Generator ────────────────────────────────

async function generatePostWithClaude(creatorKey) {
  const creator = CREATORS[creatorKey];
  if (!creator) throw new Error(`Unknown creator: ${creatorKey}`);
  if (!CLAUDE_KEY) throw new Error("ANTHROPIC_API_KEY not set in .env");

  const anthropic = new Anthropic({ apiKey: CLAUDE_KEY });

  // Pick whether to use cross-categories sometimes
  const useCross = Math.random() > 0.7;
  const categories = useCross ? creator.crossCategories : creator.categories;

  const msg = await anthropic.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 800,
    system: creator.personality,
    messages: [{
      role: "user",
      content: `Create a NEW social media post. Think of something fresh, interesting, and specific.

Requirements:
- Description: 80-250 characters, authentic to your voice, engaging
- 2-3 relevant hashtags (no # symbol)
- An engagement hook (question or call to action)
- Pick a specific topic (not generic)

Return ONLY valid JSON:
{
  "description": "Your post text here",
  "hashtags": ["Tag1", "Tag2"],
  "engagementHook": "Question or CTA for comments"
}`
    }],
  });

  const text = msg.content[0].text;
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error("Claude didn't return valid JSON");

  const content = JSON.parse(jsonMatch[0]);
  const imageUrl = await getUnsplashImage(creator.imageSearch);

  // Write to Firestore
  const post = {
    author: creator.id,
    authorName: creator.name,
    authorAvatar: creator.avatar,
    description: content.description,
    mediaUrl: imageUrl,
    mediaType: "image",
    categories: categories,
    hashtags: content.hashtags || [],
    engagementHook: content.engagementHook || "",
    likes: Math.floor(Math.random() * 500) + 50,
    comments: Math.floor(Math.random() * 50) + 5,
    shares: Math.floor(Math.random() * 30) + 2,
    saves: Math.floor(Math.random() * 40) + 5,
    views: Math.floor(Math.random() * 5000) + 500,
    engagementScore: Math.random() * 200 + 50,
    isAIGenerated: true,
    isAIEnhanced: false,
    status: "published",
    aiModel: "claude-sonnet-4",
    createdAt: FV.serverTimestamp(),
    updatedAt: FV.serverTimestamp(),
  };

  const ref = await db.collection("posts").add(post);
  console.log(`✅ [${creator.name}] Published: "${content.description.substring(0, 60)}..." (${ref.id})`);

  return { success: true, creator: creator.name, postId: ref.id, description: content.description };
}

// ─── Should Post Check (5-min cooldown) ──────────────────────

async function shouldPost(creatorKey) {
  const creator = CREATORS[creatorKey];
  if (!creator) return false;

  const last = await db.collection("posts")
    .where("author", "==", creator.id)
    .orderBy("createdAt", "desc").limit(1).get();

  if (last.empty) return true;

  const lastTime = last.docs[0].data().createdAt?.toDate();
  if (!lastTime) return true;

  const minutesSince = (Date.now() - lastTime.getTime()) / 60000;
  return minutesSince >= 5;
}

// ============================================================
// CLOUD FUNCTION EXPORTS
// ============================================================

/** Scheduled: every 5 minutes — Claude agent cycle */
exports.claudeAgentsCron = functions
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .pubsub.schedule("every 5 minutes")
  .onRun(async () => {
    if (!CLAUDE_KEY) { console.error("❌ ANTHROPIC_API_KEY not set"); return; }

    console.log("🤖 ═══ CLAUDE AGENTS CYCLE ═══════════════════");
    const results = [];
    for (const key of Object.keys(CREATORS)) {
      try {
        if (await shouldPost(key)) {
          results.push(await generatePostWithClaude(key));
        } else {
          console.log(`  ⏸️  ${CREATORS[key].name} — too recent, skipping`);
        }
      } catch (e) {
        console.error(`  ❌ ${CREATORS[key]?.name || key}: ${e.message}`);
        results.push({ success: false, creator: key, error: e.message });
      }
    }
    await db.collection("agent_logs").add({
      type: "claude_cycle", results,
      successCount: results.filter(r => r.success).length,
      createdAt: FV.serverTimestamp(),
    });
    console.log(`✅ Claude cycle: ${results.filter(r => r.success).length}/${results.length} succeeded`);
  });

/** HTTP: Run all Claude agents immediately */
exports.runClaudeAgents = functions
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    if (!CLAUDE_KEY) { res.status(500).json({ error: "ANTHROPIC_API_KEY not set" }); return; }

    const force = req.query.force === "true";
    const results = [];
    for (const key of Object.keys(CREATORS)) {
      try {
        if (force || await shouldPost(key)) {
          results.push(await generatePostWithClaude(key));
        }
      } catch (e) {
        results.push({ success: false, creator: key, error: e.message });
      }
    }
    res.json({ results, total: results.length, success: results.filter(r => r.success).length });
  });

/** HTTP: Run single Claude agent */
exports.runClaudeAgent = functions
  .runWith({ timeoutSeconds: 120, memory: "256MB" })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    const creator = req.query.creator;
    if (!creator || !CREATORS[creator]) {
      res.status(400).json({ error: "Invalid creator", valid: Object.keys(CREATORS) });
      return;
    }
    if (!CLAUDE_KEY) { res.status(500).json({ error: "ANTHROPIC_API_KEY not set" }); return; }

    try {
      const result = await generatePostWithClaude(creator);
      res.json(result);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });

// ============================================================
// IN-APP CLAUDE ASSISTANT
// ============================================================

/** HTTP: Chat with Claude — in-app assistant */
exports.claudeChat = functions
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    if (!CLAUDE_KEY) { res.status(500).json({ error: "ANTHROPIC_API_KEY not set" }); return; }

    const { message, history = [], context = {} } = req.body || {};
    if (!message) { res.status(400).json({ error: "message required" }); return; }

    const anthropic = new Anthropic({ apiKey: CLAUDE_KEY });

    const systemPrompt = `You are Driba AI — a helpful, friendly assistant built into the Driba super app.
You help users with:
- Discovering content across Feed, Food, Travel, News, Health, Commerce, Utility
- Finding restaurants, products, travel destinations
- Understanding how Driba works
- Getting personalized recommendations
- Answering questions about posts they've seen

Be concise (2-3 sentences unless they need more). Match the vibe: casual, warm, helpful.
Use 1-2 emojis naturally. Never break character.
${context.screenId ? `The user is currently on the ${context.screenId} screen.` : ""}
${context.postDescription ? `They're viewing a post: "${context.postDescription}"` : ""}`;

    try {
      const messages = [
        ...history.map(h => ({ role: h.role, content: h.content })),
        { role: "user", content: message },
      ];

      const response = await anthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 500,
        system: systemPrompt,
        messages,
      });

      res.json({
        reply: response.content[0].text,
        model: "claude-sonnet-4",
      });
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });
