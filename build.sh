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

# ─── 2. Read API keys ────────────────────────────────────────────────────
# Keys are read from (in order of priority):
#   1. Already-set environment variables (CI/CD override)
#   2. pass password-store (local dev, recommended)
#   3. .env file (legacy fallback — avoid using)
#
# To set a key in pass:
#   pass insert api/google-maps
#   pass insert api/openweather

if [ -z "$GOOGLE_MAPS_API_KEY" ] && command -v pass &>/dev/null; then
  GOOGLE_MAPS_API_KEY=$(pass show api/google-maps 2>/dev/null || true)
fi
if [ -z "$OPENWEATHER_API_KEY" ] && command -v pass &>/dev/null; then
  OPENWEATHER_API_KEY=$(pass show api/openweather 2>/dev/null || true)
fi

# Legacy .env fallback (only if pass didn't have the key)
if [ -f .env ]; then
  if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY:-$(grep '^GOOGLE_MAPS_API_KEY=' .env | cut -d= -f2-)}
  fi
  if [ -z "$OPENWEATHER_API_KEY" ]; then
    OPENWEATHER_API_KEY=${OPENWEATHER_API_KEY:-$(grep '^OPENWEATHER_API_KEY=' .env | cut -d= -f2-)}
  fi
fi

DART_DEFINES=""
if [ -n "$GOOGLE_MAPS_API_KEY" ]; then
  echo "🔑 Google Places API key found"
  DART_DEFINES="--dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
else
  echo "⚠️  GOOGLE_MAPS_API_KEY not set. Place search won't work."
  echo "   Set it as an env var or create a .env file."
fi

if [ -n "$OPENWEATHER_API_KEY" ]; then
  echo "🌤️  OpenWeatherMap API key found"
  DART_DEFINES="$DART_DEFINES --dart-define=OPENWEATHER_API_KEY=$OPENWEATHER_API_KEY"
fi

# ─── 3. Select flavor ──────────────────────────────────────────────────────
FLAVOR="${1:-dev}"
echo "🏗️  Building $FLAVOR APK..."
DART_DEFINES="$DART_DEFINES --dart-define=APP_VERSION=$FLAVOR"
if [ -n "$GEMINI_API_KEY" ]; then
  echo "🤖 Gemini AI key found"
  DART_DEFINES="$DART_DEFINES --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY"
else
  echo "⚠️  GEMINI_API_KEY not set. AI features disabled."
  echo "   Set it as an env var or create a .env file."
fi

export PATH="$HOME/bin:$HOME/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export JAVA_HOME="$HOME/jdk-17.0.12+7"
export ANDROID_HOME="$HOME/android-sdk"

flutter build apk --release $DART_DEFINES

# ─── 4. Rename output APK ─────────────────────────────────────────────────
APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_DST="build/app/outputs/flutter-apk/CatchTales-v${NEW_VERSION}.apk"

cp "$APK_SRC" "$APK_DST"
ln -sf "CatchTales-v${NEW_VERSION}.apk" "build/app/outputs/flutter-apk/CatchTales.apk"

echo ""
echo "✅ CatchTales v$NEW_VERSION built!"
echo "   📱 $APK_DST"
ls -lh "$APK_DST"
echo "   📎 build/app/outputs/flutter-apk/CatchTales.apk -> CatchTales-v${NEW_VERSION}.apk"
