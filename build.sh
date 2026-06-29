#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

# ─── 1. Bump version in pubspec.yaml ──────────────────────────────────────
echo "📦 Bumping version..."

VERSION_LINE=$(grep -E '^version: ' pubspec.yaml)
echo "   Current: $VERSION_LINE"

VERSION=$(echo "$VERSION_LINE" | sed 's/version: //' | cut -d+ -f1)

MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)
PATCH=$(echo "$VERSION" | cut -d. -f3)

NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

echo "   New:     version: $NEW_VERSION"

sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# ─── 2. Read API key ──────────────────────────────────────────────────────
# Set GOOGLE_MAPS_API_KEY env var or create a .env file:
#   GOOGLE_MAPS_API_KEY=AIzaSy...
if [ -z "$GOOGLE_MAPS_API_KEY" ] && [ -f .env ]; then
  GOOGLE_MAPS_API_KEY=$(grep '^GOOGLE_MAPS_API_KEY=' .env | cut -d= -f2-)
fi

DART_DEFINES=""
if [ -n "$GOOGLE_MAPS_API_KEY" ]; then
  echo "🔑 Google Places API key found"
  DART_DEFINES="--dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
else
  echo "⚠️  GOOGLE_MAPS_API_KEY not set. Place search won't work."
  echo "   Set it as an env var or create a .env file."
fi

# ─── 3. Build APK ─────────────────────────────────────────────────────────
echo "🏗️  Building APK..."

export PATH="$HOME/bin:$HOME/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export JAVA_HOME="$HOME/jdk-17.0.12+7"
export ANDROID_HOME="$HOME/android-sdk"

flutter build apk --release $DART_DEFINES

# ─── 4. Rename output APK ─────────────────────────────────────────────────
APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_DST="build/app/outputs/flutter-apk/BestFishBuddy-v${NEW_VERSION}.apk"

cp "$APK_SRC" "$APK_DST"
ln -sf "BestFishBuddy-v${NEW_VERSION}.apk" "build/app/outputs/flutter-apk/BestFishBuddy.apk"

echo ""
echo "✅ BestFishBuddy v$NEW_VERSION built!"
echo "   📱 $APK_DST"
ls -lh "$APK_DST"
echo "   📎 build/app/outputs/flutter-apk/BestFishBuddy.apk -> BestFishBuddy-v${NEW_VERSION}.apk"
