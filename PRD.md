# **DRIBA: THE CIVILIZATION OPERATING SYSTEM**

**Product Requirements Document (Master Blueprint)**

| Document Details |  |
| --- | --- |
| **Version:** | 1.0 (The "Mother of All Apps" Edition) |
| **Status:** | **APPROVED FOR EXECUTION** |
| **Classification:** | Confidential / Proprietary |
| **Architecture:** | Local-First (Offline) + Global Federation (Borderless) |
| **Core Philosophy:** | **"Substitution. Sovereignty. Flourishing."** |

---

## **1. EXECUTIVE VISION & STRATEGY**

### **1.1 The Thesis**

The current digital economy is extractive. Users pay "App Taxes" (15-30% fees to Uber/Airbnb/Upwork) and "Attention Taxes" (Ads/Algorithms that monetize outrage). Identities are fragmented across LinkedIn (Work), Instagram (Social), and Hospital Databases (Health).

### **1.2 The Solution: Driba**

Driba is not a "Super App"; it is a **Personal Operating System** that centralizes identity, context, and utility.

1. **Radical Substitution:** We replace rent-seeking middlemen with **Zero-Tax** AI infrastructure.
2. **The Prism Identity:** One human, multiple viewing angles (Professional vs. Personal).
3. **Sovereign Data:** The user owns the record (Health, Education, Assets). Service providers are merely "Editors" of the user's ledger.
4. **Borderless Production:** Work is found, executed, and paid for within the ecosystem, removing geographical friction.

### **1.3 The "North Star" Constitution (The Law)**

*Before any code is written, the AI Agents must subscribe to these immutable laws:*

* **Rule 1 (The Anti-Doom Loop):** "If a user dwells on negative content for >5 minutes, do not block it. Instead, **create** and inject 'High-Agency' content (Solutions, Humor, Innovation)."
* **Rule 2 (The Invisible Coach):** "Never lecture. Steer subtly. If they are broke, show them gigs. If they are sick, show them data trends."
* **Rule 3 (The Sovereign Truth):** "The User owns the record. No entity can lock a user out of their own history."

---

## **2. SYSTEM ACTORS: THE AI WORKFORCE**

We do not use "Algorithms"; we use **Agents** with specific jobs and personas.

| Agent Name | Role | Behavior & Capabilities |
| --- | --- | --- |
| **Agent A: The Creator** | **Content Factory** | **Scout:** Scans global APIs (RSS, Crypto, Local Events).<br>

<br>**Synthesize:** Writes 15s scripts based on facts, stripping clickbait.<br>

<br>**Produce:** Generates vertical video/news cards.<br>

<br>**Publish:** Populates the "For You" feed to kill the Cold Start problem. |
| **Agent B: The Coach** | **Moderator** | **Watch:** Monitors "Vibe" (Sentiment Analysis).<br>

<br>**Mix:** If Vibe < -0.5 (Toxic), downranks rage-bait and upranks "Solution" content.<br>

<br>**Nudge:** Adds micro-delays to "Send" button if user types aggressively. |
| **Agent C: The Twin** | **User Proxy** | **Negotiate:** Talks to other Twins to book appointments or haggle prices.<br>

<br>**Analyst:** Scans Sovereign Records (Health + Work) to find patterns (e.g., "High Stress = Migraine").<br>

<br>**Anticipate:** Triggers "Smart Pill" UI (e.g., "Order Coffee?") based on habits. |

---

## **3. TECHNICAL ARCHITECTURE (FUTURE-PROOF)**

### **3.1 The "Local-First" Stack (Offline Sovereignty)**

* **Database:** **Isar** (NoSQL, Ultra-Fast). All data (Chats, Posts, Medical Records) is written to the device first.
* **Sync Engine:** **WorkManager** + **Conflict-Free Replicated Data Types (CRDTs)**. Data syncs to the cloud in the background. The app works perfectly on an airplane.
* **Storage:** **IPFS** (InterPlanetary File System) or Encrypted Blob Storage for heavy assets (X-Rays, Contracts).

### **3.2 The "Hydra" Frontend (Global Resilience)**

* **Core:** Headless logic (`driba_core`) containing the Twin, Auth, and Payment rails.
* **Shells:** Region-specific UIs dynamically loaded based on IP.
* *Shell A (Global):* Unrestricted Feed + Crypto Wallet.
* *Shell B (Restricted):* Curated Feed + Fiat Wallet (China/UAE compliant).



### **3.3 The "Sovereign Record" Protocol**

* **Encryption:** Zero-Knowledge Proofs. Only the user holds the decryption key.
* **Handshake:** **Cryptographic QR Codes**.
* *Scenario:* Doctor scans User's QR to *read* history. Doctor signs a new entry to *write* diagnosis.



---

## **4. THE "PRISM IDENTITY" & "OMNI-POST" ENGINE**

### **4.1 The Prism Identity**

Abolishes the gap between LinkedIn and Instagram.

* **The Profile:** One URL, dynamic rendering.
* *Viewer = Recruiter:* Sees Skills, Portfolio, Endorsements.
* *Viewer = Friend:* Sees Travel Logs, Memes.
* *Viewer = Public:* Curated highlights.



### **4.2 The "Omni-Post" Architecture (The Chameleon)**

Every post is a "Polymorphic" container. The user applies a **Business Wrapper** that transforms its utility.

**Data Structure (JSON Schema):**

```json
{
  "id": "post_789",
  "type": "BUSINESS_ASSET",
  "media": [{"url": "video.mp4", "type": "VIDEO"}],
  "business_context": {
    "mode": "RENTAL", // Enum: SOCIAL, PRODUCT, RENTAL, INVOICE, SERVICE, MEDICAL_RECORD
    "rental_data": {
      "price": 1200,
      "calendar_id": "cal_123",
      "availability": "OPEN"
    },
    "medical_data": { // Only visible if mode = MEDICAL_RECORD
      "diagnosis": "Hypertension",
      "doctor_id": "dr_55",
      "encrypted_attachment": "xray_blob_hash"
    }
  },
  "ai_tags": { "intent": "COMMERCIAL", "sentiment": "POSITIVE" }
}

```

### **4.3 The Creative Studio (The Input)**

* **Mode 1 (Creator):** In-app editing, filters, AI Voiceover.
* **Mode 2 (Pro):** Import 4K video/PDFs. No compression (Paid).
* **AI Auto-Tag:** Vision API detects "House"  Suggests "Rental Mode."

---

## **5. THE "GLOBAL WORKBENCH" (BORDERLESS PRODUCTION)**

**Concept:** Work is not just *found*; it is *performed* here.

### **5.1 The "Work Room"**

* **Trigger:** Contract Signed.
* **Features:**
* **Escrow:** Funds held by Driba until delivery.
* **Live Translation:** Chat/Video translated in real-time (English  Arabic/French).
* **Smart Whiteboard:** AI summarizes meetings into tasks.



### **5.2 Cross-Border Discovery**

* **Search:** "Find me a cardiologist."
* **Result:** The Twin ranks global experts based on *Sovereign Outcomes* (Success rates in their patient logs), not just SEO.

---

## **6. MONETIZATION: THE "GROWTH TAX"**

**Philosophy:** "The Tool is Free. The Scale is Paid." (Freemium on Volume).

| Feature / Vertical | **Free Tier (Starter)** | **Pro Tier (Hustler)** | **Business Tier (Empire)** |
| --- | --- | --- | --- |
| **COMMERCE** | 3 Active Products | 15 Active Products | **Unlimited** |
| **RENTALS** | 1 Property | 3 Properties | **Unlimited + OTA Sync** |
| **INVOICING** | 3 per Month | 10 per Month | **Unlimited + White Label** |
| **CRM** | 50 Contacts | 500 Contacts | **Unlimited + API Access** |
| **AI TWIN** | Standard (Reactive) | Pro (Proactive Analysis) | **God Mode (Auto-Booking)** |
| **PRICE** | **FREE** | **$5 / Month** | **$20 / Month** |

* **The Upsell:** Users hit a "Soft Wall" (e.g., trying to send the 4th invoice) and are prompted to upgrade to finish the task.

---

## **7. SECURITY & PRIVACY**

* **App Lock:** Cold Start requires FaceID/Password.
* **Granular Lock:** Specific screens (Wallet, Medical, Hidden) require re-authentication.
* **Ghost Protocol:** Typing `##7788` in Search + FaceID reveals hidden screens (Secret Projects/Dating).
* **Zero-Knowledge:** Driba (the company) cannot read encrypted Sovereign Records.

---

## **8. DESIGN SYSTEM: "THE INVISIBLE INTERFACE"**

**Philosophy:** "Content is King. UI is a Ghost."

* **Visuals:** "Native Glass" (BackdropFilter).
* **Navigation:** Spatial (Center=Feed, Left=Vault, Right=Utility).
* **Anticipatory UI:**
* **Smart Pills:** "Book Now" slides up *only* when intent is high.
* **Input Fields:** Slide up pre-filled with AI suggestions to reduce friction.



---

## **9. EXECUTION ROADMAP**

### **Phase 1: The Foundation (Infrastructure)**

* [ ] **Task:** Initialize Flutter + **Isar** (Offline DB) + Firebase.
* [ ] **Task:** Implement `Constitution.dart` (North Star).
* [ ] **Task:** Build "Glass" Shell & Ghost Protocol navigation.

### **Phase 2: The Intelligence (AI Workforce)**

* [ ] **Task:** Build **Agent A (Creator)**. *Prompt: "Scrape News/Events, generate video."*
* [ ] **Task:** Build **Agent B (Coach)**. *Prompt: "Monitor Sentiment, re-rank feed."*
* [ ] **Task:** Build **Agent C (Twin)**. *Prompt: "Analyze User History, suggest actions."*

### **Phase 3: The Utility (Commerce & Sovereignty)**

* [ ] **Task:** Build **The Vault** (Chat + Sovereign Record Storage).
* [ ] **Task:** Build **Omni-Post Engine** (Social  Business conversion).
* [ ] **Task:** Implement **"Growth Tax"** Quota System.

---

## **10. INSTRUCTIONS FOR ANTIGRAVITY (THE IGNITION)**

*To start building, copy and paste the following command into your Agent:*

> **ACT AS:** Senior Architect & DevOps Engineer.
> **CONTEXT:** You have read the `PRD.md`.
> **MISSION:** Initialize the "Mother of All Apps."
> **STEP 1: SCAFFOLDING**
> 1. Initialize Flutter project `driba_os`.
> 2. Dependencies: `isar`, `flutter_riverpod`, `go_router`, `workmanager` (Sync), `flutter_animate`, `local_auth`.
> 3. Create Folder Structure:
> * `lib/core/constitution/` (North Star Logic).
> * `lib/core/sovereign/` (Record Encryption & QR Handshake).
> * `lib/core/agents/` (The Workforce: Creator, Coach, Twin).
> * `lib/modules/prism/` (Identity Profile).
> * `lib/modules/feed/` (AI Content).
> * `lib/modules/workbench/` (Global Work Room).
> 
> 
> 
> 
> **STEP 2: THE CONSTITUTION**
> * Create `lib/core/constitution/north_star.dart`. Define the 3 Rules (Anti-Doom, Coach, Sovereign) as abstract constraints that all Agents must implement.
> 
> 
> **STEP 3: THE OMNI-POST**
> * Create the `Post` model in Isar with the `business_context` polymorphic map (Social, Rental, Medical, Product).
> 
> 
> **GO.** Start with Step 1.