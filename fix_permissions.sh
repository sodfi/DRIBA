#!/bin/bash
# ============================================
# DRIBA OS — Fix Cloud Functions Permissions
# Run this ONCE to allow public access to HTTP functions
# ============================================

PROJECT="driba-os"
REGION="us-central1"

FUNCTIONS=(
  "runAgents"
  "runAgent"
  "runClaudeAgents"
  "runClaudeAgent"
  "claudeChat"
  "aiMediaProcess"
  "regenerateMedia"
  "agentStatus"
  "seedData"
  "seedDataV2"
)

echo "🔓 Fixing permissions for $PROJECT..."
echo ""

for fn in "${FUNCTIONS[@]}"; do
  echo "  → $fn"
  gcloud functions add-iam-policy-binding "$fn" \
    --member="allUsers" \
    --role="roles/cloudfunctions.invoker" \
    --project="$PROJECT" \
    --region="$REGION" \
    --quiet 2>/dev/null && echo "    ✅ Done" || echo "    ⚠️ Skipped (may not exist yet)"
done

echo ""
echo "✅ All permissions updated!"
echo ""
echo "Test with:"
echo "  curl https://us-central1-driba-os.cloudfunctions.net/agentStatus"
