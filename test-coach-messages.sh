#!/bin/bash

# 🧪 Test Coach Messages (Briefs, Debriefs, Nudges)

USER_ID="user_1761704284401"  # Your user ID from logs
API="https://futureyou-production.up.railway.app"

echo "🧪 Testing Coach Message System"
echo "================================"
echo ""

echo "1️⃣  Testing Morning Brief..."
curl -X POST "$API/api/v1/test/brief" \
  -H "Content-Type: application/json" \
  -H "x-user-id: $USER_ID" \
  -d '{}' | jq '.'
echo ""
echo ""

echo "2️⃣  Testing Evening Debrief..."
curl -X POST "$API/api/v1/test/debrief" \
  -H "Content-Type: application/json" \
  -H "x-user-id: $USER_ID" \
  -d '{}' | jq '.'
echo ""
echo ""

echo "3️⃣  Testing Nudge..."
curl -X POST "$API/api/v1/test/nudge" \
  -H "Content-Type: application/json" \
  -H "x-user-id: $USER_ID" \
  -d '{"reason": "testing the nudge system"}' | jq '.'
echo ""
echo ""

echo "4️⃣  Fetching All Messages..."
curl -X GET "$API/api/v1/coach/messages" \
  -H "Content-Type: application/json" \
  -H "x-user-id: $USER_ID" | jq '.messages | length'
echo " messages found!"
echo ""

echo "✅ Tests complete! Now restart your Flutter app:"
echo "   flutter run -d chrome"
echo ""
echo "Check Inbox (top right icon) to see your messages!"

