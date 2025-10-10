#!/bin/bash

# Future You OS - Development Setup Script
# This script helps set up the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_status "Setting up Future You OS development environment..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    print_status "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    print_status "Make sure to add Flutter to your PATH"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -n1)"

# Check Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Generate code (if needed)
if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    print_status "Generating code..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi

# Analyze code
print_status "Analyzing code..."
flutter analyze

# Run tests
print_status "Running tests..."
flutter test

print_success "Development environment setup complete!"
print_status "You can now:"
print_status "  - Run the app: flutter run"
print_status "  - Build APK: flutter build apk"
print_status "  - Use git workflow: ./git-workflow.sh 'your message'"