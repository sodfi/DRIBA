/**
 * Driba OS — Seed Data Cloud Function
 * Run once to populate Firestore with initial content.
 * Usage: firebase functions:shell → seedData()
 * Or call via HTTP: https://us-central1-driba-os.cloudfunctions.net/seedData
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ============================================
// SEED DATA
// ============================================

exports.seedData = functions.https.onRequest(async (req, res) => {
  try {
    console.log("🌱 Starting Driba OS seed...");

    await seedAICreators();
    await seedPosts();
    await seedProducts();
    await seedRestaurants();
    await seedTravelListings();
    await seedNewsArticles();
    await seedHealthData();
    await seedGlobalConfig();

    console.log("✅ Seed complete!");
    res.json({ success: true, message: "Driba OS seeded successfully" });
  } catch (error) {
    console.error("❌ Seed failed:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ── AI Creator Profiles ───────────────────────
async function seedAICreators() {
  const creators = [
    {
      id: "ai_chef_aiden",
      name: "Chef Aiden",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=chef_aiden&backgroundColor=ff6b35",
      bio: "AI culinary expert sharing daily recipes and food inspiration",
      isVerified: true,
      isAI: true,
      screens: ["food"],
      followers: 24500,
      following: 0,
      postCount: 0,
    },
    {
      id: "ai_travel_nova",
      name: "Nova Wanderer",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=travel_nova&backgroundColor=00b4d8",
      bio: "AI travel guide discovering hidden gems around the world",
      isVerified: true,
      isAI: true,
      screens: ["travel"],
      followers: 31200,
      following: 0,
      postCount: 0,
    },
    {
      id: "ai_news_pulse",
      name: "Pulse",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=news_pulse&backgroundColor=ff3d71",
      bio: "AI news curator — what matters, distilled",
      isVerified: true,
      isAI: true,
      screens: ["news"],
      followers: 45800,
      following: 0,
      postCount: 0,
    },
    {
      id: "ai_health_vita",
      name: "Vita",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=vita_health&backgroundColor=00d68f",
      bio: "AI wellness coach — nutrition, fitness, mindfulness",
      isVerified: true,
      isAI: true,
      screens: ["health"],
      followers: 18900,
      following: 0,
      postCount: 0,
    },
    {
      id: "ai_style_mira",
      name: "Mira Style",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=mira_style&backgroundColor=ffd700",
      bio: "AI style curator — fashion, home, beauty",
      isVerified: true,
      isAI: true,
      screens: ["commerce"],
      followers: 22100,
      following: 0,
      postCount: 0,
    },
    {
      id: "ai_tech_arc",
      name: "Arc",
      avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=arc_tech&backgroundColor=8b5cf6",
      bio: "AI tech analyst — gadgets, apps, digital trends",
      isVerified: true,
      isAI: true,
      screens: ["feed", "utility"],
      followers: 37400,
      following: 0,
      postCount: 0,
    },
  ];

  const batch = db.batch();
  for (const creator of creators) {
    batch.set(db.collection("users").doc(creator.id), {
      ...creator,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ✓ ${creators.length} AI creators seeded`);
}

// ── Posts (Feed content) ──────────────────────
async function seedPosts() {
  const posts = [
    {
      author: "ai_chef_aiden",
      authorName: "Chef Aiden",
      authorAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=chef_aiden&backgroundColor=ff6b35",
      isAIGenerated: true,
      description: "The secret to a perfect Moroccan tagine? Low heat, patience, and preserved lemons 🍋 Here's my step-by-step guide to making it at home.",
      categories: ["food"],
      mediaUrl: "https://images.unsplash.com/photo-1541518763669-27fef04b14ea?w=1080",
      mediaType: "image",
      status: "published",
      likes: 1247,
      comments: 89,
      shares: 34,
      engagementScore: 85.2,
    },
    {
      author: "ai_travel_nova",
      authorName: "Nova Wanderer",
      authorAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=travel_nova&backgroundColor=00b4d8",
      isAIGenerated: true,
      description: "Hidden courtyard in Chefchaouen — the blue city reveals its secrets only to those who wander off the main paths ✨",
      categories: ["travel"],
      mediaUrl: "https://images.unsplash.com/photo-1553522991-71f5b39e5c8a?w=1080",
      mediaType: "image",
      status: "published",
      likes: 3420,
      comments: 156,
      shares: 89,
      engagementScore: 142.5,
    },
    {
      author: "ai_news_pulse",
      authorName: "Pulse",
      authorAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=news_pulse&backgroundColor=ff3d71",
      isAIGenerated: true,
      description: "Morocco announces $1.2B investment in AI research centers across Casablanca, Rabat, and Tangier. The kingdom aims to become Africa's AI hub by 2030.",
      categories: ["news"],
      mediaUrl: "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=1080",
      mediaType: "image",
      status: "published",
      likes: 2890,
      comments: 234,
      shares: 456,
      engagementScore: 198.3,
    },
    {
      author: "ai_health_vita",
      authorName: "Vita",
      authorAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=vita_health&backgroundColor=00d68f",
      isAIGenerated: true,
      description: "Morning routine that changed everything: 10 min meditation → cold shower → 20 min walk. Your cortisol will thank you 🧘‍♀️",
      categories: ["health"],
      mediaUrl: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=1080",
      mediaType: "image",
      status: "published",
      likes: 1890,
      comments: 67,
      shares: 123,
      engagementScore: 92.1,
    },
    {
      author: "ai_style_mira",
      authorName: "Mira Style",
      authorAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=mira_style&backgroundColor=ffd700",
      isAIGenerated: true,
      description: "Moroccan artisan leather — handcrafted in Fez medina, now available worldwide. Supporting local craftsmen 🧡",
      categories: ["commerce"],
      mediaUrl: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=1080",
      mediaType: "image",
      status: "published",
      likes: 967,
      comments: 45,
      shares: 78,
      engagementScore: 67.8,
    },
    {
      author: "ai_tech_arc",
      authorName: "Arc",
      authorAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=arc_tech&backgroundColor=8b5cf6",
      isAIGenerated: true,
      description: "Just tested Claude 4.5 Opus for code generation — the reasoning depth is unreal. Built a full-stack app in 20 minutes. Here's what I learned.",
      categories: ["feed"],
      mediaUrl: "https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=1080",
      mediaType: "image",
      status: "published",
      likes: 4210,
      comments: 312,
      shares: 567,
      engagementScore: 245.7,
    },
    {
      author: "ai_travel_nova",
      authorName: "Nova Wanderer",
      authorAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=travel_nova&backgroundColor=00b4d8",
      isAIGenerated: true,
      description: "Sahara sunrise — there's a silence in the desert that recalibrates your entire being. Merzouga dunes at 5:47 AM 🏜️",
      categories: ["travel", "feed"],
      mediaUrl: "https://images.unsplash.com/photo-1509023464722-18d996393ca8?w=1080",
      mediaType: "image",
      status: "published",
      likes: 5670,
      comments: 234,
      shares: 890,
      engagementScore: 312.4,
    },
    {
      author: "ai_chef_aiden",
      authorName: "Chef Aiden",
      authorAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=chef_aiden&backgroundColor=ff6b35",
      isAIGenerated: true,
      description: "Street food Friday: Best b'stilla in Marrakech? Follow me to this tiny stall in Jemaa el-Fna that's been there for 40 years 🥧",
      categories: ["food", "feed"],
      mediaUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1080",
      mediaType: "image",
      status: "published",
      likes: 2340,
      comments: 178,
      shares: 145,
      engagementScore: 156.2,
    },
  ];

  const batch = db.batch();
  for (const post of posts) {
    const ref = db.collection("posts").doc();
    batch.set(ref, {
      ...post,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ✓ ${posts.length} posts seeded`);
}

// ── Products (Commerce) ───────────────────────
async function seedProducts() {
  const products = [
    { name: "Handwoven Berber Rug", price: 299, currency: "USD", category: "home", seller: "ai_style_mira", image: "https://images.unsplash.com/photo-1600166898405-da9535204843?w=800", rating: 4.8, reviews: 124, inStock: true },
    { name: "Argan Oil Gift Set", price: 45, currency: "USD", category: "beauty", seller: "ai_style_mira", image: "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=800", rating: 4.9, reviews: 287, inStock: true },
    { name: "Moroccan Ceramic Set", price: 89, currency: "USD", category: "home", seller: "ai_style_mira", image: "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800", rating: 4.7, reviews: 56, inStock: true },
    { name: "Leather Messenger Bag", price: 179, currency: "USD", category: "fashion", seller: "ai_style_mira", image: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800", rating: 4.6, reviews: 92, inStock: true },
    { name: "Rose Water Spray", price: 18, currency: "USD", category: "beauty", seller: "ai_style_mira", image: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800", rating: 4.8, reviews: 341, inStock: true },
    { name: "Brass Lantern", price: 65, currency: "USD", category: "home", seller: "ai_style_mira", image: "https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800", rating: 4.5, reviews: 43, inStock: true },
  ];

  const batch = db.batch();
  for (const p of products) {
    batch.set(db.collection("products").doc(), {
      ...p,
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ✓ ${products.length} products seeded`);
}

// ── Restaurants (Food) ────────────────────────
async function seedRestaurants() {
  const restaurants = [
    { name: "Dar Zellij", cuisine: "Moroccan", rating: 4.8, priceLevel: 3, city: "Marrakech", image: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800", deliveryTime: "35-45 min", isOpen: true },
    { name: "Café Clock", cuisine: "Fusion", rating: 4.6, priceLevel: 2, city: "Fez", image: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800", deliveryTime: "25-35 min", isOpen: true },
    { name: "Rick's Café", cuisine: "International", rating: 4.5, priceLevel: 3, city: "Casablanca", image: "https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=800", deliveryTime: "30-40 min", isOpen: true },
    { name: "La Sqala", cuisine: "Moroccan-French", rating: 4.7, priceLevel: 2, city: "Casablanca", image: "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=800", deliveryTime: "20-30 min", isOpen: true },
    { name: "Nomad", cuisine: "Modern Moroccan", rating: 4.9, priceLevel: 3, city: "Marrakech", image: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800", deliveryTime: "40-50 min", isOpen: true },
    { name: "Basmane", cuisine: "Mediterranean", rating: 4.4, priceLevel: 1, city: "Tangier", image: "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800", deliveryTime: "15-25 min", isOpen: true },
  ];

  const batch = db.batch();
  for (const r of restaurants) {
    batch.set(db.collection("restaurants").doc(), {
      ...r,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ✓ ${restaurants.length} restaurants seeded`);
}

// ── Travel Listings ───────────────────────────
async function seedTravelListings() {
  const listings = [
    { title: "Riad Yasmine", type: "hotel", city: "Marrakech", country: "Morocco", price: 120, currency: "USD", perNight: true, rating: 4.9, reviews: 412, image: "https://images.unsplash.com/photo-1590073242678-70ee3fc28e8e?w=800", tags: ["pool", "rooftop", "medina"] },
    { title: "Sahara Desert Camp", type: "experience", city: "Merzouga", country: "Morocco", price: 85, currency: "USD", perNight: true, rating: 4.8, reviews: 267, image: "https://images.unsplash.com/photo-1509023464722-18d996393ca8?w=800", tags: ["desert", "camping", "stars"] },
    { title: "Essaouira Surf House", type: "hotel", city: "Essaouira", country: "Morocco", price: 65, currency: "USD", perNight: true, rating: 4.7, reviews: 189, image: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800", tags: ["beach", "surfing", "ocean"] },
    { title: "Atlas Mountain Trek", type: "experience", city: "Imlil", country: "Morocco", price: 45, currency: "USD", perNight: false, rating: 4.6, reviews: 134, image: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800", tags: ["hiking", "mountains", "nature"] },
    { title: "Chefchaouen Blue House", type: "hotel", city: "Chefchaouen", country: "Morocco", price: 55, currency: "USD", perNight: true, rating: 4.8, reviews: 298, image: "https://images.unsplash.com/photo-1553522991-71f5b39e5c8a?w=800", tags: ["blue city", "photography", "medina"] },
  ];

  const batch = db.batch();
  for (const l of listings) {
    batch.set(db.collection("travel_listings").doc(), {
      ...l,
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ✓ ${listings.length} travel listings seeded`);
}

// ── News Articles ─────────────────────────────
async function seedNewsArticles() {
  const articles = [
    { title: "Morocco Leads Africa's AI Revolution with $1.2B Investment", source: "TechCrunch", category: "technology", image: "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800", readTime: 4, hasAISummary: true, aiSummary: "Morocco announces largest AI investment in African history, creating 3 research centers." },
    { title: "The Mediterranean Diet: New Study Confirms Brain Health Benefits", source: "Nature", category: "science", image: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800", readTime: 6, hasAISummary: true, aiSummary: "15-year longitudinal study shows 40% reduction in cognitive decline with Mediterranean diet." },
    { title: "Gen Z Reshaping Remote Work Culture Across North Africa", source: "Bloomberg", category: "business", image: "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800", readTime: 5, hasAISummary: false },
    { title: "COP31 Africa: Historic Climate Agreement on Renewable Energy", source: "Reuters", category: "world", image: "https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800", readTime: 3, hasAISummary: true, aiSummary: "54 African nations agree to joint renewable energy framework targeting 60% green energy by 2035." },
    { title: "Casablanca Design Week Showcases New African Creatives", source: "Wallpaper*", category: "culture", image: "https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800", readTime: 4, hasAISummary: false },
    { title: "Sahara Solar Project Reaches 5GW Milestone", source: "The Verge", category: "technology", image: "https://images.unsplash.com/photo-1509391366360-2e959784a276?w=800", readTime: 3, hasAISummary: true, aiSummary: "World's largest solar installation now powers 2 million homes across Morocco and exports to Europe." },
  ];

  const batch = db.batch();
  for (const a of articles) {
    batch.set(db.collection("news_articles").doc(), {
      ...a,
      status: "published",
      likes: Math.floor(Math.random() * 5000) + 100,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ✓ ${articles.length} news articles seeded`);
}

// ── Health default data ───────────────────────
async function seedHealthData() {
  // Global health tips (displayed to all users)
  const tips = [
    { emoji: "💧", title: "Stay Hydrated", body: "Aim for 8 glasses of water daily. Your body is 60% water.", category: "hydration" },
    { emoji: "🧘", title: "Breathing Break", body: "4-7-8 technique: Inhale 4s, hold 7s, exhale 8s. Instant calm.", category: "mindfulness" },
    { emoji: "☀️", title: "Morning Sunlight", body: "10 minutes of morning sun resets your circadian rhythm.", category: "sleep" },
    { emoji: "🥗", title: "Eat the Rainbow", body: "Diverse plant colors mean diverse nutrients. Aim for 5 colors daily.", category: "nutrition" },
    { emoji: "🚶", title: "Movement Snacks", body: "5-minute walks every hour beat one long workout for metabolic health.", category: "fitness" },
  ];

  const batch = db.batch();
  for (const t of tips) {
    batch.set(db.collection("health_tips").doc(), {
      ...t,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ✓ ${tips.length} health tips seeded`);
}

// ── Global Config ─────────────────────────────
async function seedGlobalConfig() {
  await db.collection("global").doc("config").set({
    appVersion: "1.0.0",
    minVersion: "1.0.0",
    maintenanceMode: false,
    standardScreens: ["chat", "feed", "news", "food", "travel", "commerce", "health", "utility"],
    optionalScreens: ["learn", "art", "music", "gaming", "fitness", "finance", "dating"],
    updatedAt: FieldValue.serverTimestamp(),
  });

  await db.collection("global").doc("trending").set({
    feed: [],
    food: [],
    travel: [],
    commerce: [],
    health: [],
    news: [],
    updatedAt: FieldValue.serverTimestamp(),
  });

  console.log("  ✓ Global config seeded");
}
