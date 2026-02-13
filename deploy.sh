#!/bin/bash
# ============================================
# DRIBA OS — One-Command Deploy
# Fixes everything and deploys
# ============================================

set -e
echo "🚀 DRIBA OS — Full Deploy"
echo "========================="
echo ""

# 1. Force pull latest code
echo "📥 Step 1: Pulling latest code..."
git fetch origin
git reset --hard origin/main
echo "  ✅ Code synced"
echo ""

# 2. Install function dependencies
echo "📦 Step 2: Installing dependencies..."
cd functions && npm install && cd ..
echo "  ✅ Dependencies installed"
echo ""

# 3. Deploy functions (force)
echo "☁️  Step 3: Deploying functions..."
firebase deploy --only functions --force
echo "  ✅ Functions deployed"
echo ""

# 4. Fix IAM permissions
echo "🔓 Step 4: Fixing HTTP permissions..."
bash fix_permissions.sh
echo ""

# 5. Deploy Firestore indexes + rules
echo "📊 Step 5: Deploying Firestore..."
firebase deploy --only firestore
echo "  ✅ Firestore rules + indexes deployed"
echo ""

# 6. Deploy hosting
echo "🌐 Step 6: Deploying web app..."
firebase deploy --only hosting
echo "  ✅ Web app live at https://driba-os.web.app"
echo ""

# 7. Trigger agents
echo "🤖 Step 7: Triggering agents..."
curl -s "https://us-central1-driba-os.cloudfunctions.net/runAgents?force=true" | head -200
echo ""
echo ""
echo "═══════════════════════════════════════"
echo "✅ DEPLOY COMPLETE"
echo ""
echo "  App:    https://driba-os.web.app"
echo "  Status: https://us-central1-driba-os.cloudfunctions.net/agentStatus"
echo "═══════════════════════════════════════"
