# Session Log

> Update this at the end of every session so the next session starts with full context.

---

## 2025-07-16 — Session 4 — Consolidation + Full Deploy

### What we did
- **Consolidated** three separate repos into a **single codebase** at `~/CatchTales/`
- Deleted `~/CatchTales-Dev/` and `~/CatchTales-Free/`
- Branded everything as **CatchTales** — zero remaining "Best Fish Buddy" references
- Cleaned all tracked build artifacts from git
- Updated `CODING_STANDARDS.md`, `build.sh`, desktop note for single-source workflow
- Built **all three flavors** at v2.14.32:
  - `CatchTales-v2.14.32-dev.apk` (88.7MB)
  - `CatchTales-v2.14.32-free.apk` (88.7MB)
  - `CatchTales-v2.14.32-pro.apk` (88.7MB)
- Cleaned old v2.14.29 APKs from website downloads, releases/, and backups/
- Updated website: homepage, /free/, /pro/, /dev/, version.json
- Pushed website (catchtales-site) and code (CatchTales) to GitHub

### How to build
```bash
cd ~/CatchTales
./build.sh dev    # dev flavor (unlocked + debug tools)
./build.sh free   # free flavor (ProService gated)
./build.sh pro    # pro flavor (all unlocked)
# Or directly (no version bump):
flutter build apk --release --dart-define=APP_VERSION=dev
flutter build apk --release --dart-define=APP_VERSION=free
flutter build apk --release --dart-define=APP_VERSION=pro
```

### What we also did (Session 4 continued)
- Thorough audit: checked codebase, website, GitHub, filesystem, APKs, .env — all clean
- Fixed `CODING_STANDARDS.md` sections 1, 2, 5, 6, 6a that still referenced old structure
- Restored **fixed site header + underwater background** to cloud dashboard (`/cloud/`)
  - Added to Flutter source template so it survives rebuilds
  - Added transparent canvas CSS so HTML background shows through Flutter
  - Added 56px top padding to login screen for fixed header
  - Rebuilt Flutter web app and redeployed
- Deleted old `CatchTales-Dev` and `CatchTales-Free` repos from GitHub
- Cleaned temp files, old archives, build artifacts (~1.6GB recovered)
- **Fixed weather forecast** — rebuilt dev APK with OpenWeatherMap API key injected
- **ADB installed** v2.14.32-dev on Louis's phone (push+pm-install workaround)

### What's in progress
- Nothing — session complete

### Session 7 final state
- **Version: 2.14.41** — all 3 flavors built and deployed
- **Admin panel** at catchtales.com/admin/ (Firebase Auth protected, no public links)
  - Pro Key Manager: generate, filter, search, assign keys
  - Activity tracking: totalSessions + daily activityLog
  - Mobile-friendly layout with larger fonts
  - Details popup with 30-day breakdown
- **Key activation fixed**: Firestore rules updated to allow any authenticated user to mark a key as used
- **Session tracking**: WidgetsBindingObserver tracks app foreground events, records daily opens
- **Pro Pricing updated**: $8.99/year or $19.99 lifetime in app and website
- **50+ website pages**: mobile-optimized CSS with clamp(), touch targets, safe area insets
- **Cloud dashboard**: rebuilt with weather API key, emoji cleanup, mobile-optimized HTML chrome
- **Standards updated**: no emojis/gradients, mobile-first responsive, push ADB as default install, duplicate profile cleanup

### What we did in Session 5 (Website & Blog)
- **Fixed cloud dashboard** — restored missing header + underwater background to `/cloud/`
- **Rebuilt APKs with API keys** — weather, maps, and AI now work on all flavors
- **New article: Fishing Knots Every Angler Should Know** — 12 knots with SVG diagrams + real YouTube videos
- **Fixed blog index** — removed duplicate entries, fixed broken video embeds
- **Added 6 new articles**: Kayak Fishing, Safety Tips, Fishing with Kids, Night Fishing, Fish Behavior, Ice Fishing Gear
- **Updated standards** — added rules for: follow existing patterns, one tag per card, verify no blog duplicates, always use build.sh for production
- **Deleted old GitHub repos** — CatchTales-Dev and CatchTales-Free removed from GitHub
- **Room cleanup features** — Clear Chat button, owner can delete any message, system messages collapsed
- **Built + installed v2.14.33** on phone (dev) and deployed to website (free + pro)

### What we did in Session 6 (Emoji & Gradient Cleanup)
- **Website cleanup**: Removed all 🔒 from nav links (99 instances), removed ❤️🎣 from footers (49 files), replaced all gradients with solid colors, removed heading/button/blog emojis, replaced 6 feature card emojis with inline SVGs, cleaned blog content emojis (checkboxes, ✅❌⚠️, star ratings → 5/5)
- **App cleanup**: Replaced all LinearGradient with solid colors (10 files), removed emojis from What's New, notifications, badges, screen UI, stripped emojis from help text and translations (447 across 5 languages), moon phases now use abbreviations (NM, WC, FQ, FM)
- **Fixed layout**: Tightened solunar screen spacers, fixed moon phase text overflow
- **Built v2.14.39**: All three flavors built with API keys, installed dev on phone
- **Deployed**: Updated website APK downloads to v2.14.39, pushed all changes

## 2025-07-18 — Session 8 — CTOTGA Mascot, Update Checker & In-App Download

### What we did

**Native splash & icons:**
- Added CatchTales logo to native Android splash (replaced plain white/black screen)
- Regenerated launcher icons from `assets/logo.png` (replaced old bestfishbuddy icons)
- Cleaned all remaining bestfishbuddy references across codebase, website, and assets

**CTOTGA mascot splash:**
- Added user's catfish illustration ("The One That Got Away") to Flutter splash screen
- Replaced the old logo + app name at top with the CTOTGA image as hero
- Adjusted image height from 320px → 240px for better screen fit
- Removed flag emojis ("CA  US" text per no-emojis standard)

**Update checker:**
- Added `_checkUpdate()` to SplashScreen — fetches `version.json` on launch
- Shows amber "Update vX.Y.Z available" banner above CONTINUE button if newer version exists
- Banner text is hardcoded English (needs translation)

**In-app APK download & install:**
- Created `FileProvider` config at `res/xml/file_paths.xml`
- Added `REQUEST_INSTALL_PACKAGES` permission and `FileProvider` to `AndroidManifest.xml`
- Added `installApk` MethodChannel in `MainActivity.kt` — opens APK via `Intent.ACTION_INSTALL_PACKAGE`
- Added `_downloadAndInstall()` on Dart side — downloads APK via HTTP to temp dir, triggers install channel
- Update banner now downloads + installs entirely in-app (no browser redirect)
- URL logic uses direct APK download path from version.json per app flavor

**Builds & releases:**
- Built and pushed v2.14.42 through v2.14.55 across all flavors
- Updated website version.json, download pages, and pushed after each release
- Verified update flow on phone 2 (v2.14.50 → v2.14.54 via in-app download)

### ADB workaround discovered
When `adb push + pm install -r` fails with "Unable to open file", it's usually because a previous attempt left a stale file. Workaround: separate the commands — push first, then run `adb shell pm install -r` as a separate step.

### Current state
| Item | Value |
|------|-------|
| Source | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| Version | 2.14.55 |
| Website | catchtales.com (remote: `louismales-a11y/catchtales-site.git`) |
| APK downloads | `~/catchtales-site/download/` (free + pro) |
| APK backups | `~/Desktop/apk backups/` (3 flavors) |
| Cloud functions | `~/CatchTales/functions/` + `~/catchtales_cloud/` |

### Where we left off (July 18)
- Built province hubs + region pages for: Manitoba (194), Saskatchewan (168), Ontario (249), British Columbia (272), Alberta (102), Quebec (195)
- Nova Scotia hub + region pages built (175 entries) but NOT linked from Canada page or sitemap yet — pending completion
- **Next to do:** New Brunswick, Prince Edward Island, Newfoundland & Labrador, Yukon, Northwest Territories, Nunavut
- Canada page needs to link to `/fishing-in-canada/` from homepage/main nav when all provinces are ready
- Standards updated with region page numbering rules, cross-referencing guidelines, saltwater tagging

### What's missing (per Rule 3)
- **Help text** — update checker feature not documented in `help_text.dart`
- **Translations** — "Update vX.Y.Z available" banner text is hardcoded English
