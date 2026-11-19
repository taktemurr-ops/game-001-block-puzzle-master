#!/usr/bin/env bash
set -euo pipefail

# Independent alternative to GitHub Actions, intended for a Flutter/Android SDK Codespace.
cd "$(dirname "$0")/.."
echo "=== Flutter / Android build diagnostics ==="
flutter --version
flutter doctor -v
echo "=== Generate missing Android scaffold ==="
flutter create --no-pub --platforms=android --project-name game_001_block_puzzle_master .
echo "=== Dependencies ==="
flutter pub get
echo "=== Analyze ==="
flutter analyze
echo "=== Tests ==="
flutter test --reporter expanded
echo "=== Build Android debug APK ==="
flutter build apk --debug
APK="build/app/outputs/flutter-apk/app-debug.apk"
test -s "$APK"
sha256sum "$APK" | tee build/app/outputs/flutter-apk/SHA256SUMS.txt
printf '\nAPK READY: %s\n' "$APK"
