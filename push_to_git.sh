#!/bin/bash

# Future You OS - Git Push Script
# Usage: ./push_to_git.sh "your_github_pat_token_here"

if [ -z "$1" ]; then
    echo "❌ Error: Please provide your GitHub Personal Access Token"
    echo "Usage: ./push_to_git.sh YOUR_PAT_TOKEN"
    echo ""
    echo "To create a PAT:"
    echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens"
    echo "2. Generate new token (classic) with 'repo' scope"
    echo "3. Copy the token and use it here"
    exit 1
fi

PAT_TOKEN="$1"

echo "🔧 Configuring git..."
git config user.name "Future You OS"
git config user.email "stossthegreat@users.noreply.github.com"

echo "📦 Adding all changes..."
git add -A

echo "💾 Committing changes..."
git commit -m "feat: complete Future You OS Flutter app

✅ Fixed home screen rendering and layout
✅ Fixed habit creation and deletion
✅ Fixed scheduling logic (Daily, Weekdays, etc.)
✅ Added streak system with live updates
✅ Added alarm notifications
✅ Added onboarding flow
✅ Added GitHub Actions APK workflow
✅ All tabs working (Home, Planner, Chat, Mirror, Streak, Settings)

Ready for production deployment!"

echo "🚀 Setting up remote with PAT..."
git remote remove origin 2>/dev/null || true
git remote add origin https://${PAT_TOKEN}@github.com/stossthegreat/futureyou.git

echo "📤 Pushing to GitHub..."
git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Code pushed to https://github.com/stossthegreat/futureyou"
    echo "🔨 GitHub Actions will automatically build APK files"
    echo "📱 Check the Actions tab for build progress"
else
    echo ""
    echo "❌ Push failed. Check your PAT token and try again."
fi
