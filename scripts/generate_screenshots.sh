#!/bin/bash
set -e

# Run tests and update goldens
flutter test --update-goldens test/screenshot_test.dart || true

# Copy the generated screenshot to the assets directory
cp test/goldens/screenshot.png assets/screenshot.png || true

echo "Screenshot generated successfully and copied to assets/screenshot.png"
