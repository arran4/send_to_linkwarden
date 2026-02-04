#!/bin/bash

# Exit on error
set -e

# Define paths
BUILD_DIR="build/web"
EXTENSION_DIR="build/extension"
CHROME_DIR="$EXTENSION_DIR/chrome"
FIREFOX_DIR="$EXTENSION_DIR/firefox"

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "$EXTENSION_DIR"
mkdir -p "$CHROME_DIR"
mkdir -p "$FIREFOX_DIR"

# Build Flutter Web (HTML renderer is safer for extensions due to CSP)
echo "Building Flutter Web..."
flutter build web --csp --no-tree-shake-icons

# Prepare Chrome Extension
echo "Preparing Chrome Extension..."
cp -r "$BUILD_DIR/"* "$CHROME_DIR/"
cp web/manifest_chrome.json "$CHROME_DIR/manifest.json"
# Remove unnecessary files
rm -f "$CHROME_DIR/manifest_chrome.json" "$CHROME_DIR/manifest_firefox.json"

# Prepare Firefox Extension
echo "Preparing Firefox Extension..."
cp -r "$BUILD_DIR/"* "$FIREFOX_DIR/"
cp web/manifest_firefox.json "$FIREFOX_DIR/manifest.json"
# Remove unnecessary files
rm -f "$FIREFOX_DIR/manifest_chrome.json" "$FIREFOX_DIR/manifest_firefox.json"

# Zip Extensions
echo "Zipping Extensions..."
cd "$EXTENSION_DIR"
zip -r chrome_extension.zip chrome
zip -r firefox_extension.zip firefox

echo "Build complete! Extensions are in $EXTENSION_DIR"
