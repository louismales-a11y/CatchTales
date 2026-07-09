#!/usr/bin/env bash
set -e

echo "🚀 Setting up CatchTales Firebase project..."
echo ""

# ─── 1. Create Firebase project ───────────────────────────────────────
echo "📦 Creating Firebase project: catchtales-prod..."
firebase projects:create catchtales-prod --display-name "CatchTales" || true

echo "   Linking local directory to project..."
firebase use --add catchtales-prod

# ─── 2. Register Android apps ──────────────────────────────────────────
echo ""
echo "📱 Registering Android app: com.catchtales.catchtales..."
firebase apps:create android com.catchtales.catchtales --app-name "CatchTales"

echo "📱 Registering Android app: com.catchtales.catchtales.dev..."
firebase apps:create android com.catchtales.catchtales.dev --app-name "CatchTales (Dev)"

# ─── 3. Download google-services.json ──────────────────────────────────
echo ""
echo "📄 Downloading google-services.json for release..."
APP_ID=$(firebase apps:list android --json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for app in data.get('result', []):
    if app['appId'].endswith(':android:7c5fd250214d9da3b81343') or app['displayName'] == 'CatchTales':
        sys.stdout.write(app['appId'])
        break
" 2>/dev/null || echo "")

if [ -n "$APP_ID" ]; then
  firebase apps:sdkconfig android "$APP_ID" > /tmp/google-services.json
  cp /tmp/google-services.json /home/louis/CatchTales/android/app/google-services.json
  cp /tmp/google-services.json /home/louis/CatchTales-Free/android/app/google-services.json
  echo "   ✅ google-services.json saved to both projects"
fi

# ─── 4. Set Cloud Functions secrets ────────────────────────────────────
echo ""
echo "🔐 Set your Stripe & email secrets (you can skip this for now):"
echo "   firebase functions:config:set stripe.secret=\"sk_live_...\""
echo "   firebase functions:config:set stripe.webhook_secret=\"whsec_...\""
echo "   firebase functions:config:set email.user=\"catchtales@yahoo.com\""
echo "   firebase functions:config:set email.pass=\"<yahoo-app-password>\""

# ─── 5. Deploy Hosting & Firestore Rules ───────────────────────────────
echo ""
echo "🌐 Deploying hosting (privacy & terms pages)..."
firebase deploy --only hosting

echo "🔥 Deploying Firestore rules & indexes..."
firebase deploy --only firestore

echo ""
echo "✅ Done! Firebase project 'catchtales-prod' is set up."
echo ""
echo "Next: deploy Cloud Functions when you've set the secrets:"
echo "   firebase deploy --only functions"
echo ""
echo "Or deploy everything:"
echo "   firebase deploy"
