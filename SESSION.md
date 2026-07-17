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
- All 49 website pages have mobile-optimized CSS (clamp() for typography/spacing, touch targets, safe area insets, animated nav)
- Fish use fixed px sizes (clamp() caused rendering issues on Android tablets)
- Photo strip aspect-ratio breakpoint at 480px (not 768px) to avoid oversized photos on tablets
- /free/, /pro/, /dev/ pages have proper HTML structure (footer inside .content)
- Cloud dashboard rebuilt with OpenWeather API key (weather/forecast now load)
- Standards updated: no emojis/gradients rule + mobile-first responsive design rule

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

## 2025-07-17 — Session 7 — Mobile Optimization

### What we did
- Added **no emojis or gradients** rule to `CODING_STANDARDS.md` + desktop note
- **Full mobile optimization** of all 49 website pages:
  - Fluid typography with `clamp()` — text scales naturally from 320px to desktop
  - Touch-friendly nav — `min-height: 44px` targets, smooth hamburger animation
  - Safe area insets for notched phones
  - Tap highlight removal + `:active` states for touch feedback
  - Photo strip: `aspect-ratio` instead of fixed 300px height
  - Fluid spacing with `clamp()` throughout
  - Fish animation sizes scale with viewport
  - Phone frame screenshots use `min(240px, 70vw)` to prevent overflow
  - Buttons have `min-height: 48px` and `touch-action: manipulation`
  - Grid columns use `minmax(min(260px, 100%), 1fr)` for overflow prevention
- **Fixed structural issues**: /free/, /pro/, /dev/ pages had footer outside `.content` and after `</body></html>` — corrected
- Pushed website to GitHub (auto-deploys to catchtales.com)
- **Fixed cloud dashboard weather/forecast**: rebuilt Flutter web app with OpenWeather API key injected (was missing `--dart-define`)
- Removed 🔒 emoji from cloud dashboard nav (per standards)
- **Fixed photo strip on tablets**: changed `max-width: 768px` breakpoint to `480px` so 4:3 aspect ratio only applies on phones, not tablets (was making photo strip 576px tall on 768px-wide tablets)
- **Reverted fish to fixed px sizes** — `clamp()` on animated elements causes rendering quirks on some Android tablets (fish appeared to grow as they swam)
- **Fixed broken `top:` values on fish** — regex from fish revert accidentally wrote `top: auto; 12%` instead of `top: 12%`, killing the animation

### Current state
| Item | Value |
|------|-------|
| Source | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| Version | 2.14.39 |
| Website | catchtales.com (remote: `louismales-a11y/catchtales-site.git`) |
| APK downloads | `~/catchtales-site/download/` (free + pro) |
| APK backups | `~/Desktop/apk backups/` (3 flavors) |
| Cloud functions | `~/CatchTales/functions/` + `~/catchtales_cloud/` |
