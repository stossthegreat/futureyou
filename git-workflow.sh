#!/bin/bash

# Future You OS - Simplified Git Workflow
# This script provides a simple way to commit and push changes

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository. Please run this from the project root."
    exit 1
fi

# Get commit message from user or use default
if [ -z "$1" ]; then
    COMMIT_MSG="feat: update Future You OS app"
    print_warning "No commit message provided. Using default: '$COMMIT_MSG'"
    print_status "Usage: $0 'your commit message here'"
else
    COMMIT_MSG="$1"
fi

print_status "Starting git workflow..."

# Check for changes
if git diff --quiet && git diff --cached --quiet; then
    print_warning "No changes to commit."
    exit 0
fi

# Show status
print_status "Current changes:"
git status --short

# Add all changes
print_status "Adding all changes..."
git add -A

# Commit changes
print_status "Committing changes with message: '$COMMIT_MSG'"
git commit -m "$COMMIT_MSG"

# Check if remote exists
if ! git remote get-url origin > /dev/null 2>&1; then
    print_warning "No remote origin found. You'll need to add one manually:"
    print_status "git remote add origin https://github.com/yourusername/yourrepo.git"
    print_status "Then run: git push -u origin main"
    exit 0
fi

# Push to remote
print_status "Pushing to remote..."
if git push; then
    print_success "Changes pushed successfully!"
    print_status "Repository: $(git remote get-url origin)"
else
    print_error "Push failed. You may need to:"
    print_status "1. Check your internet connection"
    print_status "2. Verify your git credentials"
    print_status "3. Run 'git push' manually to see detailed error"
    exit 1
fi

print_success "Git workflow completed!"