#!/bin/bash

# Retro Fun Crate - Release Build Script
# This script automates the generation of the production .aab bundle for Google Play.

echo "🚀 Starting Production Build Phase..."

# 1. Clean and get dependencies
echo "📦 Cleaning and fetching packages..."
flutter clean
flutter pub get

# 2. Run final audit
echo "🔍 Running final static analysis..."
flutter analyze

if [ $? -ne 0 ]; then
  echo "❌ Error: Static analysis failed. Please fix lints before building."
  exit 1
fi

# 3. Build App Bundle (.aab)
echo "💎 Generating production App Bundle (.aab)..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

if [ $? -eq 0 ]; then
  echo "✅ Success! Release bundle generated at: build/app/outputs/bundle/release/app-release.aab"
  echo "👉 You can now upload this file to the Google Play Console."
else
  echo "❌ Build failed. Please check the logs above."
fi
