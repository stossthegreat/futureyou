#!/bin/bash
# Generate test messages for Future You OS

USER_ID="${1:-test-user-felix}"
BACKEND_URL="${2:-https://futureyou-production.up.railway.app}"

echo "🧪 Generating test messages for user: $USER_ID"
echo "📡 Backend: $BACKEND_URL"
echo ""

# Generate all messages
echo "⏳ Generating morning brief, evening debrief, nudge, and insights..."
RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/v1/test/generate-all" \
  -H "x-user-id: $USER_ID" \
  -H "Content-Type: application/json" \
  -d '{}')

if echo "$RESPONSE" | grep -q "ok.*true"; then
  echo "✅ Messages generated successfully!"
  echo ""
  echo "📨 Brief excerpt:"
  echo "$RESPONSE" | grep -o '"brief":"[^"]*"' | head -c 150
  echo "..."
  echo ""
  echo "🔍 Check messages API:"
  curl -s "$BACKEND_URL/api/v1/coach/messages" \
    -H "x-user-id: $USER_ID" | jq '.messages | length' 2>/dev/null || echo "Install jq to see message count"
  echo ""
  echo "📱 Now open your app and:"
  echo "   1. Go to Reflections tab"
  echo "   2. Pull down to refresh"
  echo "   3. Messages should appear!"
  echo ""
  echo "💡 Your user ID: $USER_ID"
else
  echo "❌ Failed to generate messages"
  echo "Response: $RESPONSE"
  exit 1
fi

