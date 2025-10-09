#!/bin/bash

# Future You OS - Git Push Script
# Repository: https://github.com/stossthegreat/futureyou.git
# Usage: ./push_to_git.sh "your_github_pat_token_here"

if [ -z "$1" ]; then
    echo "❌ Error: Please provide your GitHub Personal Access Token"
    echo "Usage: ./push_to_git.sh YOUR_PAT_TOKEN"
    echo ""
    echo "🔑 To create a PAT:"
    echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens"
    echo "2. Generate new token (classic) with 'repo' scope"
    echo "3. Copy the token and use it here"
    echo ""
    echo "📱 Repository: https://github.com/stossthegreat/futureyou"
    exit 1
fi

PAT_TOKEN="$1"

echo "🔧 Configuring git..."
git config user.name "stossthegreat"
git config user.email "stossthegreat@users.noreply.github.com"

echo "📦 Adding all changes..."
git add -A

echo "💾 Committing changes..."
git commit -m "feat: complete Future You OS Flutter app

🚀 PRODUCTION READY - Premium Flutter Habit Tracker

✅ Home Screen - Exact React layout with date selection, progress bars
✅ Planner Screen - Full CRUD with scheduling (Daily/Weekdays/Custom/Every N)
✅ Habit Management - Create, edit, delete with live updates
✅ Streak System - Auto-increment on completion, live XP tracking
✅ Alarm Notifications - Android alarm manager + local notifications
✅ Onboarding Flow - Persistent state, beautiful animations
✅ GitHub Actions - Automated APK builds on push
✅ All 6 Tabs - Home, Planner, Chat, Mirror, Streak, Settings
✅ State Management - Riverpod with Hive local storage
✅ Visual Parity - Matches React version exactly

🎯 Features:
- Habit scheduling with repeat patterns
- Real-time streak tracking with XP system
- Local notifications and alarms
- Glassmorphism UI with neon accents
- Cross-platform (Android/iOS/Web/Desktop)
- Offline-first with backend sync ready

📱 Ready for App Store deployment!"

echo "🚀 Setting up remote repository..."
git remote remove origin 2>/dev/null || true
git remote add origin https://${PAT_TOKEN}@github.com/stossthegreat/futureyou.git

echo "📤 Pushing to GitHub..."
git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Future You OS pushed to GitHub!"
    echo "📱 Repository: https://github.com/stossthegreat/futureyou"
    echo "🔨 GitHub Actions will build APK automatically"
    echo "📥 Check Actions tab for download links"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Go to repository Actions tab"
    echo "   2. Wait for APK build to complete"
    echo "   3. Download debug/release APK artifacts"
    echo "   4. Install on Android device"
else
    echo ""
    echo "❌ Push failed. Check your PAT token and try again."
    echo "💡 Make sure token has 'repo' scope permissions"
fi
