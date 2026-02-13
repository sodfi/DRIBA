# DRIBA OS — Product Requirements Document
## Complete System Architecture & Development Status
### Last updated: February 13, 2026

---

## TABLE OF CONTENTS

1. [Core Vision & Problem Statement](#1-core-vision--problem-statement)
2. [Tech Stack](#2-tech-stack)
3. [Project Structure](#3-project-structure)
4. [Design System](#4-design-system)
5. [Navigation & Shell Architecture](#5-navigation--shell-architecture)
6. [Screens System](#6-screens-system)
7. [Content Pipeline — Autonomous AI Agents](#7-content-pipeline--autonomous-ai-agents)
8. [AI Studio — Pro Feature](#8-ai-studio--pro-feature)
9. [Dual Aspect Ratio Media System](#9-dual-aspect-ratio-media-system)
10. [User Post Creation](#10-user-post-creation)
11. [Firestore Data Models](#11-firestore-data-models)
12. [Cloud Functions](#12-cloud-functions)
13. [Authentication](#13-authentication)
14. [AI Router & Service Layer](#14-ai-router--service-layer)
15. [Chat & Messaging](#15-chat--messaging)
16. [Food Ordering](#16-food-ordering)
17. [Commerce / Shopping](#17-commerce--shopping)
18. [Travel & Booking](#18-travel--booking)
19. [Profile System](#19-profile-system)
20. [Settings & Theming](#20-settings--theming)
21. [What's Built vs What's Remaining](#21-whats-built-vs-whats-remaining)
22. [Deployment Guide](#22-deployment-guide)
23. [File Manifest](#23-file-manifest)

---

## 1. CORE VISION & PROBLEM STATEMENT

### What is Driba OS?

Driba OS is a **super app** designed to replace 10+ standalone apps with a single experience. It's the "WeChat of everywhere" — a platform where content, commerce, communication, and utility live in one place.

### Problems it solves:

| Problem | Driba's Answer |
|---------|---------------|
| App fatigue (30+ apps installed, 10 used) | One app, 8 screens, each replacing a category |
| Platform fees destroy small businesses (30% App Store, 15-30% Uber Eats, 20% Shopify) | **0% transaction fees** — users keep 100% |
| Content is fragmented (TikTok for video, Instagram for photos, Twitter for text) | Unified content feed where posts can be products, services, or stories |
| AI is bolted on as a feature | **Invisible AI** — Claude, GPT, Gemini work behind every action without being visible |
| Social profiles are shallow | LinkedIn + Website in one — profile IS your business page |
| Separate apps for each country/vertical | Single platform localizable per market |

### Core Principles:

1. **Content is King** — Every screen opens on fullscreen immersive content (TikTok-style vertical swipe). Personal tools are one filter-tap away.
2. **0% Fees** — Driba monetizes via Pro subscriptions and ads, never via transaction fees on creators/merchants.
3. **Invisible AI** — AI powers everything (content creation, recommendations, moderation, smart replies) but users never see "AI" unless they seek it out.
4. **Glass OS Design** — Premium dark glassmorphism aesthetic throughout. Deep space background (#050B14), cyan accent (#00E1FF), frosted glass surfaces.
5. **Posts = Products** — A post can simultaneously be content AND a purchasable product/service/booking.
6. **Autonomous Content** — 6 AI creators produce real, researched content 24/7 so the platform always has fresh material.

### Target Users:

- **Consumers**: People tired of switching between 10 apps. Want discovery + utility in one place.
- **Creators/Merchants**: Small businesses who can't afford platform fees. Their profile IS their storefront.
- **Initial Market**: Africa → Europe → Global

### Business Model:

- Free tier: Full access to all screens, posting, messaging
- **Pro tier** ($9.99/mo): AI Studio (photo/video enhancement), priority placement, advanced analytics, business tools
- Advertising: Non-intrusive native ads in content feeds
- **Never**: Transaction fees on purchases, orders, or bookings

---

## 2. TECH STACK

| Layer | Technology | Details |
|-------|-----------|---------|
| **Frontend** | Flutter 3.41+ / Dart | Single codebase → iOS, Android, Web, Desktop |
| **State** | Riverpod | Typed providers, stream-based, no boilerplate |
| **Backend** | Firebase | Firestore, Auth, Storage, Functions, Hosting |
| **AI (Agents)** | Google Cloud Vertex AI | Gemini 2.0 Flash (research), Gemini 2.5 Pro (writing), Imagen 3 (images), Veo 2 (video), Cloud TTS Neural2 (voice) |
| **AI (Client)** | AI Router | Routes to Claude / GPT / Gemini based on task type via Cloud Functions proxy |
| **Auth** | Firebase Auth | Email/password, Google Sign-In, Apple Sign-In |
| **Payments** | Stripe Connect (planned) | Direct payouts, 0% platform fee |
| **Project** | driba-os (Firebase project ID) | Region: us-central1 |

### Key Dependencies (pubspec.yaml):
```yaml
flutter_riverpod, firebase_core, firebase_auth, cloud_firestore,
firebase_storage, cloud_functions, cached_network_image,
image_picker, video_player, google_sign_in, sign_in_with_apple,
shimmer, vibration, url_launcher
```

### Cloud Functions Dependencies (package.json):
```json
firebase-admin, firebase-functions, google-auth-library,
@anthropic-ai/sdk, openai, @google/generative-ai
```

---

## 3. PROJECT STRUCTURE

```
driba_os/
├── lib/
│   ├── main.dart                          # App entry, Firebase init
│   ├── main_shell.dart                    # Root shell with navigation dock
│   ├── firebase_options.dart              # Firebase config (auto-generated)
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── driba_colors.dart          # Color palette, gradients, shadows, spacing
│   │   │   ├── driba_theme.dart           # Material 3 ThemeData with Space Grotesk
│   │   │   └── theme.dart                 # Barrel export
│   │   ├── animations/
│   │   │   └── driba_animations.dart      # Like particles, shimmer, stagger, SlideToAction
│   │   ├── providers/
│   │   │   ├── app_state.dart             # Screen configs, utility modules
│   │   │   ├── app_state_v2.dart          # V2 with dynamic screen ordering
│   │   │   ├── content_providers.dart     # DribaPost model + Firestore streams (LATEST)
│   │   │   └── theme_provider.dart        # Accent color, theme mode persistence
│   │   ├── widgets/
│   │   │   ├── glass_container.dart       # GlassContainer, AnimatedGlass, GlassPill
│   │   │   ├── glass_header.dart          # Unified screen header with dynamic icons
│   │   │   ├── glass_dock.dart            # Floating navigation dock (fades when inactive)
│   │   │   ├── screen_shell.dart          # DribaScreenShell — shared scaffold for ALL screens
│   │   │   ├── post_card.dart             # Responsive DribaPostCard (portrait + landscape)
│   │   │   ├── polish_widgets.dart        # Loading skeletons, empty states, error widgets
│   │   │   └── widgets.dart               # Barrel export
│   │   ├── utils/
│   │   │   ├── driba_haptics.dart         # Haptic feedback patterns
│   │   │   ├── driba_polish.dart          # Polish utilities
│   │   │   └── responsive_utils.dart      # Breakpoints, adaptive layouts
│   │   ├── navigation/
│   │   │   └── page_transitions.dart      # Custom route transitions
│   │   └── shell/
│   │       ├── shell_state.dart           # Navigation state, screen ordering
│   │       ├── content_chrome.dart        # Header/footer chrome overlay
│   │       ├── engagement_overlay.dart    # Like/comment/share/save sidebar
│   │       └── masonry_overview.dart      # Pinterest-style screen selection grid
│   │
│   ├── modules/
│   │   ├── auth/                          # Firebase Auth flow (6 files)
│   │   ├── onboarding/                    # Screen selection onboarding
│   │   ├── feed/                          # Main discovery feed
│   │   ├── chat/                          # Messaging system (6 files)
│   │   ├── food/                          # Restaurant ordering (5 files)
│   │   ├── commerce/                      # Shopping & products (5 files)
│   │   ├── travel/                        # Destinations & booking (3 files)
│   │   ├── health/                        # Wellness dashboard
│   │   ├── news/                          # News feed
│   │   ├── learn/                         # Courses & AI tutor
│   │   ├── profile/                       # LinkedIn-style profile (4 files)
│   │   ├── settings/                      # App settings (3 files)
│   │   ├── screens_view/                  # Pinterest masonry screen selector
│   │   ├── utility/                       # Digital life & tools
│   │   ├── creator/                       # Content creation
│   │   └── post/                          # Create Post + AI Studio (2 files)
│   │
│   └── shared/
│       ├── ai/                            # AI Router (7 files)
│       └── models/                        # Firestore models (8 files)
│
├── functions/
│   ├── index.js                           # Cloud Functions entry point
│   ├── autonomous_agents.js               # 6 AI content creators (all-Google pipeline)
│   ├── ai_media_process.js                # AI Studio backend + dual-ratio generation
│   ├── ai_functions.js                    # Client-facing AI proxy (Claude/GPT/Gemini)
│   ├── seed_data.js                       # Initial demo content
│   ├── seed_data_v2.js                    # Cross-vertical content with utility posts
│   ├── DUAL_RATIO_PATCH.js               # Instructions to patch agents for dual-ratio
│   ├── .env.template                      # Environment variables template
│   └── package.json                       # Dependencies
│
├── pubspec.yaml                           # Flutter dependencies
├── firebase.json                          # Firebase project config
├── firestore.rules                        # Security rules
├── firestore.indexes.json                 # Composite indexes
└── PRD.md                                 # This document
```

**Total: 97 files, ~36,000 lines of code**

---

## 4. DESIGN SYSTEM

### Color Palette (`driba_colors.dart`)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | #050B14 | Deep space canvas |
| `backgroundLight` | #0A1628 | Layered surfaces |
| `surface` | #0F1C2E | Card backgrounds |
| `surfaceElevated` | #152238 | Elevated elements |
| `primary` | #00E1FF | Cyan — brand accent |
| `secondary` | #FF2E93 | Magenta — highlights |
| `tertiary` | #8B5CF6 | Purple — premium elements |
| `success` | #00D68F | Green — confirmations |
| `warning` | #FFAA00 | Amber — caution |
| `error` | #FF3D71 | Red — errors |

### Screen-Specific Accents

Each screen has its own accent color for identity:
```
Feed:     #00E1FF (Cyan)      Chat:     #00D68F (Green)
Food:     #FF6B35 (Orange)    Commerce: #FFD700 (Gold)
Travel:   #00B4D8 (Ocean)     Health:   #00D68F (Green)
News:     #FF3D71 (Red)       Learn:    #8B5CF6 (Purple)
Utility:  #00E1FF (Cyan)
```

### Glass Morphism

All surfaces use frosted glass with blur:
- `glassFill`: 5% white fill
- `glassBorder`: 10% white border
- Blur intensities: light (10), medium (20), heavy (40), intense (60)
- Glass gradient: subtle white top-left to bottom-right

### Typography

Font: **Space Grotesk** (loaded via Google Fonts)
- Headings: w700, tracking -0.5
- Body: w400/w500, height 1.4-1.5
- Captions: w500, 12-13px

### Animations (`driba_animations.dart`)

- `LikeParticles` — Exploding particle effect on like
- `SlideToAction` — Swipe-to-confirm gesture for purchases
- `ShimmerEffect` — Loading placeholders
- `StaggeredList` — Items animate in sequentially
- `AnimatedGlassContainer` — Glass panels that scale on press

---

## 5. NAVIGATION & SHELL ARCHITECTURE

### How Navigation Works

The app uses a **TikTok-meets-Netflix** navigation model:

```
┌──────────────────────────────────┐
│  StatusBar                        │
├──────────────────────────────────┤
│                                   │
│   FULLSCREEN CONTENT              │
│   (vertical PageView swipe)       │
│                                   │
│   ┌──────────────────────────┐   │
│   │  Header (fades on scroll) │   │
│   │  Screen name + filters    │   │
│   └──────────────────────────┘   │
│                                   │
│   Each card = full viewport       │
│   Swipe up/down to navigate       │
│                                   │
│   ┌───┐                          │
│   │ ♥ │  Engagement rail (right)  │
│   │ 💬│                          │
│   │ ↗ │                          │
│   │ 🔖│                          │
│   └───┘                          │
│                                   │
│   [Author] [Caption] [Tags]      │
│                                   │
├──────────────────────────────────┤
│  ● ● ● [DOCK] ● ●               │
│  (fades to 30% when inactive)     │
└──────────────────────────────────┘
```

### Shell State (`shell_state.dart`)

```dart
shellScreenIndexProvider  // Current screen index
shellVisibleProvider      // Whether chrome is visible
shellScreenOrderProvider  // User-customized screen order
```

### DribaScreenShell (`screen_shell.dart`)

Every content screen wraps `DribaScreenShell` which provides:
1. Unified glass header with screen name and accent color
2. Filter chips (e.g., "For You", "Trending", "🛒 Orders")
3. Fullscreen PageView for posts (vertical swipe)
4. Personal/tool view toggle (one filter switches to dashboard)
5. Firestore-backed content via `screenPostsProvider`

Usage:
```dart
DribaScreenShell(
  screenId: 'food',
  screenLabel: 'Food',
  accent: Color(0xFFFF6B35),
  filters: [
    DribaFilter('Trending', '🔥'),
    DribaFilter('Near Me', '📍'),
    DribaFilter('Orders', '🛒'),   // personalFilterIndex: 2
  ],
  personalFilterIndex: 2,
  personalView: MyOrdersWidget(),
)
```

### Responsive Behavior

The `AdaptivePostLayout` widget in `post_card.dart` handles layout:
- **Mobile portrait** (`width < 700 && portrait`): Fullscreen vertical swipe PageView using 9:16 images
- **Desktop/tablet** (`width >= 700`): 2-3 column grid of 16:9 landscape cards
- **Landscape phone**: 2-column grid
- Tapping a grid card opens fullscreen viewer

---

## 6. SCREENS SYSTEM

### 8 Standard Screens

| # | Screen | File | Purpose | Filter Chips |
|---|--------|------|---------|-------------|
| 1 | **Feed** | `feed/feed_screen.dart` | Main discovery — all verticals mixed | For You, Trending, Following |
| 2 | **Chat** | `chat/chat_list_screen.dart` | Messaging (horizontal avatar carousel) | All, Unread, Groups, Business |
| 3 | **News** | `news/news_screen.dart` | Breaking news, scoops | Top Stories, My Feed |
| 4 | **Food** | `food/food_screen.dart` | Restaurant discovery + ordering | Trending, Near Me, 🛒 Orders |
| 5 | **Travel** | `travel/travel_screen.dart` | Destinations + booking | Trending, Near Me, 🧳 My Trips |
| 6 | **Commerce** | `commerce/commerce_screen.dart` | Product discovery + shopping | Trending, Deals, 💛 Wishlist |
| 7 | **Health** | `health/health_screen.dart` | Wellness content | Trending, Fitness, 📊 My Health |
| 8 | **Utility** | `utility/utility_screen.dart` | Digital life + tools | Trending, AI, ⚡ Toolbox |

### Content-First Pattern

Every screen follows the same pattern:
1. **Default view**: Fullscreen AI-generated or user posts (PageView swipe)
2. **Filter chips**: Toggle between content categories
3. **Personal filter**: One chip (always last) switches to personal dashboard/tools
4. **Cross-vertical**: A food post tagged `["food", "health"]` appears on BOTH screens all posts

### Optional Screens (Planned)

Learn, Movies, Local, Sports, Music, Gaming, Jobs — each would follow the same DribaScreenShell pattern.

---

## 7. CONTENT PIPELINE — AUTONOMOUS AI AGENTS

### Overview

6 AI creator personas run on Cloud Functions every 2-4 hours, producing fully autonomous content:

```
Research (Gemini 2.0 Flash + Google Search)
    ↓
Write (Gemini 2.5 Pro — post text + media prompt + voice script)
    ↓
Generate Image (Vertex AI Imagen 3 — 9:16 + 16:9)
    ↓
Generate Video (Vertex AI Veo 2 — when content suits video)
    ↓
Generate Voice (Cloud TTS Neural2 — unique voice per creator)
    ↓
Upload (Firebase Storage — all media)
    ↓
Publish (Firestore — complete document)
```

### The 6 Creators

| Creator | ID | Screen | Schedule | Voice | Personality |
|---------|-----|--------|----------|-------|------------|
| **Chef Aiden** | `chef_aiden` | Food | 4h | Neural2-D (M) | Warm, passionate, global cuisine |
| **Nova Wanderer** | `travel_nova` | Travel | 4h | Neural2-F (F) | Poetic, adventurous, hidden gems |
| **Pulse** | `news_pulse` | News | 2h | Neural2-A (M) | Sharp, factual, no sensationalism |
| **Vita** | `health_vita` | Health | 4h | Neural2-C (F) | Evidence-based, encouraging wellness |
| **Mira Style** | `style_mira` | Commerce | 6h | Neural2-E (F) | Tastemaker, artisan champion |
| **Arc** | `tech_arc` | Utility | 4h | Neural2-J (M) | Practical tech friend, hype-skeptic |

### Creator Profile Schema (in `autonomous_agents.js`)

```javascript
{
  id: "chef_aiden",
  name: "Chef Aiden",
  author: "ai_chef_aiden",
  avatar: "https://ui-avatars.com/...",
  screen: "food",
  categories: ["food", "health", "feed"],
  scheduleHours: 4,
  researchTopics: ["trending recipes", "food science", "World cuisine"],
  voice: { languageCode: "en-US", name: "en-US-Neural2-D", ssmlGender: "MALE" },
  personality: "You are Chef Aiden, a passionate culinary creator..."
}
```

### Pipeline Implementation

**File**: `functions/autonomous_agents.js` (938 lines)

**Phase 1 — Research**: Gemini 2.0 Flash with Google Search grounding. Returns headline, summary, source, grounded web sources, and confidence score.

**Phase 2 — Write**: Gemini 2.5 Pro with personality prompt. Returns JSON:
```json
{
  "description": "The secret to a perfect tagine...",
  "hashtags": ["MoroccanFood", "Tagine"],
  "categories": ["food", "health", "feed"],
  "engagementHook": "What's your comfort dish?",
  "mediaDecision": "photo",
  "mediaSpec": {
    "type": "photo",
    "prompt": "Overhead shot of steaming Moroccan tagine...",
    "style": "photorealistic",
    "aspectRatio": "9:16"
  },
  "voiceoverScript": "Hey everyone, here's something incredible..."
}
```

**Phase 3 — Generate Image**: Vertex AI Imagen 3 (imagen-3.0-generate-002). Base64 PNG output. If video is chosen, Veo 2 with async polling (max 5 min). Fallback: if video fails → cinematic still frame.

**Phase 4 — Generate Voice**: Cloud TTS Neural2. Converts voiceover script to SSML, generates MP3. Non-fatal if fails.

**Phase 5 — Upload**: All assets to Firebase Storage → public URLs.

**Phase 6 — Publish**: Complete Firestore document with all metadata.

### Authentication

- Gemini API: `GEMINI_API_KEY` environment variable
- Vertex AI / Cloud TTS: Service account (automatic in Cloud Functions, no key needed)
- `google-auth-library` package for access token retrieval

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `agentsCron` | Scheduled (2h) | Auto-run eligible creators |
| `runAgents?force=true` | HTTP GET | Force run all creators |
| `runAgent?creator=chef_aiden` | HTTP GET | Run single creator |
| `regenerateMedia?postId=X` | HTTP GET | Re-generate failed image |
| `agentStatus` | HTTP GET | Dashboard: all creators + last posts |

---

## 8. AI STUDIO — PRO FEATURE

### Overview

User-facing AI enhancement for photos/videos. Available via bottom sheet when creating a post. Calls `aiMediaProcess` Cloud Function.

**File (Frontend)**: `lib/modules/post/ai_studio_sheet.dart` (684 lines)
**File (Backend)**: `functions/ai_media_process.js` (514 lines)

### 4 Tabs

#### ✨ Scene — Place subject in new environment
12 presets + custom text input:
- Beach Sunset, Mountain Peak, Tropical Garden, City Rooftop
- Cozy Café, Art Gallery, Modern Living Room, Spring Garden
- Studio Glow, Rustic Table, Holiday, Custom

Backend: Imagen 3 Edit API — keeps subject, replaces background/environment.

#### 🎨 Style — Artistic style transfer
8 presets:
- Magazine Editorial, Cinematic Film, Oil Painting, Pencil Sketch
- Watercolor, Cyberpunk, Golden Hour, Noir B&W

Backend: Imagen 3 Edit API with style prompts.

#### 🎬 Video — Generate 6s video from photo
6 camera modes + custom direction:
- Cinematic (pull-out), Orbit (360°), Zoom In
- Time-lapse, Parallax (3D depth), Scene Morph

Backend: Veo 2 long-running operation. Polls every 10s, max 5 min.

#### 📸 Enhance — One-tap improvement
4 modes:
- Auto Enhance (lighting, color, sharpness)
- HDR Effect (dynamic range expansion)
- Portrait Mode (background blur, subject enhancement)
- Expand Frame (outpaint — extend image borders)

Backend: Imagen 3 Edit API with mode-specific prompts.

### Cloud Function: `aiMediaProcess`

Callable HTTPS function. Accepts:
```javascript
{
  action: "enhance" | "scene" | "style" | "video",
  imageBase64: "...",  // User's photo
  params: { mode, scenePrompt, stylePrompt, ... }
}
```

Returns:
```javascript
{
  success: true,
  imageUrl: "https://storage.googleapis.com/...",
  videoUrl: "https://..." | null,
  actionLabel: "Scene: Beach Sunset"
}
```

---

## 9. DUAL ASPECT RATIO MEDIA SYSTEM

### The Problem

Mobile users hold phones vertically (9:16). Desktop/tablet users view horizontally (16:9). A single image can't look great in both.

### The Solution

Every post stores three media URLs:

| Field | Ratio | Used When |
|-------|-------|-----------|
| `mediaUrl` | Original/fallback | Always available |
| `mediaUrlPortrait` | 9:16 | Mobile portrait view |
| `mediaUrlLandscape` | 16:9 | Desktop, tablet, landscape |

### How Ratios Are Generated

**AI Agent posts**: Imagen 3 generates both ratios in parallel. Landscape version gets "wide angle, panoramic composition" appended to prompt.

**User uploads**: Firestore `onCreate` trigger (`processUserMedia`) downloads the user's original image and uses Imagen 3 Edit API to outpaint it into both ratios.

### Responsive Post Card (`post_card.dart`)

```dart
// Auto-selects correct URL based on device
final imageUrl = post.getMediaUrl(isPortrait: usePortraitMedia);
```

- `DribaPostCard` — Fullscreen card for mobile PageView
- `DribaPostCardLandscape` — Grid card for desktop/tablet
- `AdaptivePostLayout` — Wrapper that auto-switches between layouts
- `_FullscreenPostViewer` — Opens when tapping landscape grid card

---

## 10. USER POST CREATION

**File**: `lib/modules/post/create_post_screen.dart` (711 lines)

### Flow

```
Pick Media → Write Caption → Select Categories → (Optional) AI Studio → Publish
```

### Features

1. **Media picker**: Camera photo, gallery photo, camera video, gallery video
2. **Caption editor**: 500 char limit, hashtag auto-detection (#hashtags become metadata)
3. **Category selector**: Multi-select chips (Food, Travel, News, Health, Shop, Digital Life, Feed)
4. **AI Studio toggle**: Opens AI Studio bottom sheet (Pro feature)
5. **Publish**: Uploads media to Firebase Storage, writes Firestore document
6. **Responsive**: Side-by-side layout on desktop, stacked on mobile

### Post Document Created

```javascript
{
  author: "user_uid",
  authorName: "Display Name",
  authorAvatar: "...",
  description: "Caption text #hashtag",
  mediaUrl: "https://storage.googleapis.com/...",
  mediaType: "image",  // or "video"
  hashtags: ["hashtag"],
  categories: ["food", "feed"],
  isAIGenerated: false,
  isAIEnhanced: true,  // if AI Studio was used
  aiEnhancement: { action: "Scene: Beach Sunset", ... },
  status: "pending_review",  // goes through moderation
  likes: 0, comments: 0, shares: 0, saves: 0, views: 0,
}
```

After creation, `moderateContent` trigger runs Gemini moderation, and `processUserMedia` trigger generates dual-ratio versions.

---

## 11. FIRESTORE DATA MODELS

### Posts Collection (`posts/`)

The central document. Fields for AI-generated and user posts:

```typescript
{
  // Identity
  author: string,           // uid or "ai_chef_aiden"
  authorName: string,
  authorAvatar: string,
  
  // Content
  description: string,      // 100-500 chars
  hashtags: string[],
  categories: string[],     // ["food", "health", "feed"]
  engagementHook: string?,  // CTA question
  
  // Media — dual ratio
  mediaUrl: string,              // Primary / fallback
  mediaUrlPortrait: string,      // 9:16
  mediaUrlLandscape: string,     // 16:9
  mediaType: "image" | "video",
  
  // Audio voiceover
  audioUrl: string,
  voiceoverScript: string,
  hasVoiceover: boolean,
  
  // Commerce (optional)
  price: number?,
  
  // Engagement
  likes: number,
  comments: number,
  shares: number,
  saves: number,
  views: number,
  engagementScore: number,       // Calculated hourly
  
  // Flags
  isAIGenerated: boolean,
  isAIEnhanced: boolean,
  status: "published" | "pending_review" | "rejected",
  
  // AI metadata
  pipeline: string,              // "vertex-ai-all-google"
  researchModel: string,
  writerModel: string,
  imageModel: string,
  voiceModel: string,
  mediaGeneration: {
    model: string,
    provider: string,
    prompt: string,
    negativePrompt: string,
    style: string,
    aspectRatio: string,
  },
  contentMeta: {
    researchHeadline: string,
    researchSource: string,
    groundedSources: [{title, uri}],
    confidence: number,
  },
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

### Users Collection (`users/`)

Defined in `lib/shared/models/user_model.dart`:

```typescript
{
  uid: string,
  displayName: string,
  email: string,
  photoUrl: string,
  coverPhotoUrl: string,
  bio: string,
  profession: string,
  location: { city, country, coordinates },
  socialLinks: [{ platform, url, label }],
  selectedScreens: string[],
  interests: string[],
  followers: number,
  following: number,
  postCount: number,
  isPro: boolean,
  isVerified: boolean,
  createdAt: Timestamp,
}
```

### Other Collections

- **`chats/`** — Chat rooms with participants, last message, unread counts
- **`chats/{id}/messages/`** — Individual messages with reactions, read receipts
- **`orders/`** — Food/commerce orders with status tracking
- **`agent_logs/`** — AI agent execution logs
- **`global/trending`** — Trending post IDs per screen, updated every 24h

Full typed models in `lib/shared/models/` (8 files, covering user, post, chat, order, activity, business, and common models).

---

## 12. CLOUD FUNCTIONS

### All Functions

| Function | Trigger | File | Purpose |
|----------|---------|------|---------|
| `agentsCron` | Schedule (2h) | autonomous_agents.js | Run eligible AI creators |
| `runAgents` | HTTP | autonomous_agents.js | Force run all creators |
| `runAgent` | HTTP | autonomous_agents.js | Run single creator |
| `regenerateMedia` | HTTP | autonomous_agents.js | Re-gen failed image |
| `agentStatus` | HTTP | autonomous_agents.js | Creator dashboard |
| `aiMediaProcess` | Callable | ai_media_process.js | AI Studio (user photos) |
| `processUserMedia` | Firestore onCreate | ai_media_process.js | Auto dual-ratio for uploads |
| `aiComplete` | Callable | ai_functions.js | Client AI proxy |
| `aiModerate` | Callable | ai_functions.js | Content moderation proxy |
| `calculateEngagement` | Schedule (1h) | index.js | Score all published posts |
| `curateTrending` | Schedule (24h) | index.js | Pick top 20 per screen |
| `moderateContent` | Firestore onCreate | index.js | Auto-moderate new posts |
| `seedData` | Callable | seed_data.js | Seed demo content |
| `seedDataV2` | Callable | seed_data_v2.js | Seed cross-vertical content |

### Required GCP APIs

```bash
gcloud services enable \
  aiplatform.googleapis.com \
  texttospeech.googleapis.com \
  generativelanguage.googleapis.com \
  --project=driba-os
```

### Environment Variables

Only one required: `GEMINI_API_KEY` in `functions/.env`

Vertex AI and Cloud TTS use the Cloud Functions service account automatically.

---

## 13. AUTHENTICATION

**Files**: `lib/modules/auth/` (6 files, ~2,400 lines)

### Flow

```
AuthGate (checks state)
  ├── Not logged in → AuthScreen (login/signup)
  │     ├── Email/Password
  │     ├── Google Sign-In
  │     └── Apple Sign-In
  ├── Logged in, no profile → PersonalizationScreen
  │     ├── Step 1: Select screens
  │     ├── Step 2: Choose interests
  │     └── Step 3: Welcome + profile basics
  └── Logged in, has profile → MainShell
```

### Key Files

- `auth_service.dart` — Firebase Auth wrapper (email, Google, Apple)
- `auth_screen.dart` — Login/signup UI with glass design
- `personalization_screen.dart` — 3-step onboarding wizard
- `auth_gate.dart` — StreamBuilder on auth state, routes accordingly
- `auth_providers.dart` — Riverpod providers for auth state

---

## 14. AI ROUTER & SERVICE LAYER

**Files**: `lib/shared/ai/` (7 files, ~2,500 lines)

### How It Works

The AI Router intelligently selects the best model for each task:

```dart
final router = ref.read(aiRouterProvider);
final result = await router.route(AiTask(
  type: AiTaskType.writeCaption,
  input: "Generate a food post caption",
));
```

### Routing Rules

| Task Type | Primary Model | Fallback |
|-----------|--------------|----------|
| `writeCaption` | Claude Sonnet | GPT-4 |
| `smartReply` | GPT-4 Mini | Claude Haiku |
| `generateBio` | Claude Sonnet | GPT-4 |
| `analyzeImage` | Gemini Pro Vision | GPT-4V |
| `translateText` | GPT-4 Mini | Claude Haiku |
| `summarizeNews` | Gemini Flash | GPT-4 Mini |
| `moderateContent` | Claude Haiku | Gemini Flash |

### Architecture

```
Flutter App
    → AiRouter (selects model)
        → AiService (sends request)
            → Cloud Functions proxy (aiComplete)
                → Claude API / OpenAI API / Gemini API
```

All API keys stay server-side in Cloud Functions. Client never sees keys.

---

## 15. CHAT & MESSAGING

**Files**: `lib/modules/chat/` (6 files, ~3,000 lines)

### Features Built

- **Chat list** with horizontal avatar carousel (unique UX — not vertical like WhatsApp)
- **Conversation screen** with message bubbles, reactions, reply-to
- **Typing indicators** and read receipts
- **AI Smart Replies** — context-aware suggestions via AI Router
- **Group chats** and business chats with verification badges
- **Demo data** for development (10 chats, multi-user conversations)

### Firestore Schema

```
chats/{chatId}/
  participants: [uid1, uid2]
  lastMessage: { text, senderId, timestamp }
  unreadCount: { uid1: 0, uid2: 3 }

chats/{chatId}/messages/{msgId}/
  senderId, senderName, text, timestamp
  status: "sending" | "sent" | "delivered" | "read"
  reactions: { userId: "❤️" }
  replyTo: { messageId, text, senderName }
```

---

## 16. FOOD ORDERING

**Files**: `lib/modules/food/` (5 files, ~2,400 lines)

### Features Built

- Restaurant discovery with categories (Moroccan, Sushi, Italian, etc.)
- Restaurant detail sheet with full menu, ratings, delivery time
- Menu item detail with customizations
- Cart management with quantity controls
- Checkout flow with order summary
- 6 demo restaurants with complete menus (40+ items)
- **0% service fee** (displayed prominently)

### Models

```dart
class Restaurant { name, cuisine, rating, deliveryTime, menu... }
class MenuItem { name, description, price, category, image, customizations }
class CartItem { menuItem, quantity, customizations, total }
```

---

## 17. COMMERCE / SHOPPING

**Files**: `lib/modules/commerce/` (5 files, ~2,900 lines)

### Features Built

- Product grid with categories
- Product detail sheet with image gallery
- Size/color/variant selection
- Shopping cart with quantity management
- Checkout with payment method selection
- Wishlist/save functionality
- Demo products with full metadata

---

## 18. TRAVEL & BOOKING

**Files**: `lib/modules/travel/` (3 files, ~2,500 lines)

### Features Built

- Destination carousel with hero images
- Destination detail sheet with:
  - Photo gallery
  - Description and highlights
  - Date picker for booking
  - Guest count selector
  - Price calculator
  - Hotel listings for destination
- Demo destinations (Chefchaouen, Santorini, Bali, etc.)

---

## 19. PROFILE SYSTEM

**Files**: `lib/modules/profile/` (4 files, ~2,400 lines)

### Features Built

- LinkedIn-style profile layout:
  - Parallax cover photo
  - Avatar with verification badge
  - Stats row (followers, following, posts)
  - Highlights section
  - Tabbed content (Posts, Products, About)
- **AI Bio Generation** — uses Claude to write bio from bullet points
- Edit sheet for all profile fields
- Social links management
- Demo data for development

---

## 20. SETTINGS & THEMING

**Files**: `lib/modules/settings/` (3 files, ~1,400 lines)

### Features Built

- Settings screen with sections:
  - Account, Appearance, Privacy, Notifications, Support
- **Appearance sheet**: Accent color picker (12 colors), theme mode (dark/light/system)
- **Screen customizer**: Drag-to-reorder screens, toggle visibility
- Theme persistence via SharedPreferences

---

## 21. WHAT'S BUILT VS WHAT'S REMAINING

### ✅ BUILT (Production-Ready Code Exists)

| Feature | Status | Notes |
|---------|--------|-------|
| Design system (colors, typography, glass) | ✅ Complete | 317 lines |
| Navigation shell + dock | ✅ Complete | Fading dock, masonry overview |
| DribaScreenShell (shared scaffold) | ✅ Complete | Used by all 8 screens |
| Content-first screens (all 8) | ✅ Complete | PageView + filter chips |
| Dual-ratio post card | ✅ Complete | Portrait + landscape auto-switch |
| Firestore data models (typed) | ✅ Complete | 8 model files |
| Content providers (Riverpod + Firestore) | ✅ Complete | Stream-based |
| Authentication flow | ✅ Complete | Email, Google, Apple + onboarding |
| Chat messaging | ✅ Complete | With demo data |
| Food ordering | ✅ Complete | With 6 demo restaurants |
| Commerce shopping | ✅ Complete | With demo products |
| Travel booking | ✅ Complete | With demo destinations |
| Profile (LinkedIn-style) | ✅ Complete | With AI bio generation |
| Settings + theming | ✅ Complete | Color picker, screen reorder |
| AI Router | ✅ Complete | Claude/GPT/Gemini routing |
| AI Agents (6 creators) | ✅ Complete | All-Google Vertex AI pipeline |
| AI Studio (Pro feature) | ✅ Complete | Scene, Style, Video, Enhance |
| Post creation screen | ✅ Complete | Camera, gallery, categories, AI |
| Cloud Functions (14 functions) | ✅ Complete | Agents, moderation, engagement |
| Seed data (v1 + v2) | ✅ Complete | Cross-vertical content |
| Content moderation | ✅ Complete | Gemini-based auto-mod |
| Engagement scoring | ✅ Complete | Hourly recalculation |
| Trending curation | ✅ Complete | Daily top 20 per screen |

### 🔲 NOT YET BUILT (Planned)

| Feature | Priority | Complexity | Notes |
|---------|----------|------------|-------|
| **Stripe Connect payments** | P1 | High | 0% fee model requires Stripe Connect for direct payouts |
| **Push notifications** | P1 | Medium | FCM integration, notification preferences |
| **Video player integration** | P1 | Medium | Proper video playback for Veo 2 content + user videos. `video_player` or `chewie` package |
| **Audio player for voiceovers** | P1 | Low | `just_audio` package, play/pause button already in UI |
| **Real-time chat with Firestore** | P1 | Medium | Demo data exists, needs wiring to real Firestore streams |
| **Order tracking** | P2 | Medium | Real-time order status updates for food/commerce |
| **Search (global)** | P2 | Medium | Algolia or Firestore full-text search across posts, users, products |
| **Deep linking** | P2 | Medium | Share post/profile URLs that open directly in app |
| **Image/video upload from user posts** | P2 | Medium | `firebase_storage` upload with progress indicator |
| **Like/save/share actually writing to Firestore** | P2 | Low | UI exists, needs Firestore writes + auth check |
| **Follow/unfollow users** | P2 | Low | Following collection, feed filtering |
| **Comments system** | P2 | Medium | Comments subcollection on posts, threaded replies |
| **Pro subscription (IAP)** | P2 | High | RevenueCat or in_app_purchase, gate AI Studio |
| **Business tools (POS, CRM, Invoicing)** | P3 | High | Utility screen modules, full CRUD |
| **Booking module** | P3 | Medium | Calendar, appointment slots, confirmation |
| **Learn screen courses** | P3 | Medium | Course player, progress tracking, AI tutor |
| **Health dashboard with real data** | P3 | Medium | Connect to HealthKit/Google Fit |
| **News aggregation from real APIs** | P3 | Medium | NewsAPI or RSS parsing |
| **Localization (Arabic, French)** | P3 | Medium | RTL support, translations |
| **Analytics dashboard (BigQuery)** | P4 | High | Creator/business analytics |
| **Video calls (Agora/Twilio)** | P4 | High | 1:1 and group video |
| **Maps integration** | P4 | Medium | Restaurant/destination locations |
| **Offline support** | P4 | Medium | Firestore persistence + cached images |

### 🔧 KNOWN ISSUES TO FIX

1. **CORS on web**: Avatar images may fail on Flutter web due to Firebase Storage CORS. Fix: `gsutil cors set cors.json gs://driba-os.firebasestorage.app`
2. **Video player disposal**: Race condition when navigating away from video posts. Needs lifecycle management.
3. **Deprecated APIs**: Some Material Design classes need migration to latest Flutter 3.41 equivalents.
4. **Auth gate navigation**: After onboarding, may need hard navigation reset to main shell.
5. **Screen shell content_providers.dart**: Two versions exist — `app_state.dart` (original) and `content_providers.dart` (latest with dual-ratio). Make sure imports are consistent.

---

## 22. DEPLOYMENT GUIDE

### Prerequisites

1. Flutter SDK 3.41+
2. Firebase CLI (`npm install -g firebase-tools`)
3. Google Cloud SDK (for gcloud commands)
4. Node.js 22+

### Step 1: Firebase Setup

```bash
firebase login
firebase use driba-os
```

### Step 2: Enable GCP APIs

```bash
gcloud services enable \
  aiplatform.googleapis.com \
  texttospeech.googleapis.com \
  generativelanguage.googleapis.com \
  --project=driba-os
```

### Step 3: Configure Environment

```bash
cd functions
cp .env.template .env
# Edit .env: add GEMINI_API_KEY from https://aistudio.google.com/apikey
```

### Step 4: Deploy Cloud Functions

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

### Step 5: Seed Initial Content

```bash
curl https://us-central1-driba-os.cloudfunctions.net/seedData
curl https://us-central1-driba-os.cloudfunctions.net/runAgents?force=true
```

### Step 6: Run Flutter

```bash
flutter pub get
flutter run -d chrome   # Web
flutter run              # Connected device
```

### Step 7: Storage CORS (for web)

```bash
echo '[{"origin":["*"],"method":["GET","HEAD"],"maxAgeSeconds":3600}]' > cors.json
gsutil cors set cors.json gs://driba-os.firebasestorage.app
```

---

## 23. FILE MANIFEST

### Flutter (Dart) — 83 files

**Core Design System (17 files)**:
`driba_colors.dart`, `driba_theme.dart`, `theme.dart`, `driba_animations.dart`, `app_state.dart`, `app_state_v2.dart`, `content_providers.dart`, `theme_provider.dart`, `glass_container.dart`, `glass_header.dart`, `glass_dock.dart`, `screen_shell.dart`, `post_card.dart`, `polish_widgets.dart`, `widgets.dart`, `driba_haptics.dart`, `driba_polish.dart`, `responsive_utils.dart`, `page_transitions.dart`, `shell_state.dart`, `content_chrome.dart`, `engagement_overlay.dart`, `masonry_overview.dart`

**Modules (54 files)**:
Auth (6), Onboarding (1), Feed (1), Chat (6), Food (5), Commerce (5), Travel (3), Health (1), News (1), Learn (1), Profile (4), Settings (3), Screens View (1), Utility (1), Creator (1), Post (2)

**Shared (15 files)**:
AI Router (7), Firestore Models (8)

**Root (3 files)**: `main.dart`, `main_shell.dart`, `firebase_options.dart`

### Cloud Functions (JS) — 8 files

`index.js` (144), `autonomous_agents.js` (938), `ai_media_process.js` (514), `ai_functions.js` (369), `seed_data.js` (402), `seed_data_v2.js` (174), `DUAL_RATIO_PATCH.js` (157), `package.json`

### Config (5 files)

`pubspec.yaml`, `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `.env.template`

---

*This document is the complete source of truth for Driba OS as of February 13, 2026. It can be provided to any LLM along with the codebase for development continuation.*
