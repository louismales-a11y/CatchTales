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

### What's in progress
- Nothing — session complete

### Rules established this session
- **Single codebase**: `~/CatchTales/` is the ONLY source. Build flavors via `--dart-define=APP_VERSION=dev|free|pro`
- **No more "Best Fish Buddy"**: Pro directory was fully replaced with branded code
- **Old GitHub repos** (CatchTales-Dev, CatchTales-Free) should be archived on GitHub to prevent confusion

### Current state
| Item | Value |
|------|-------|
| Source | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| Version | 2.14.32 |
| Website | catchtales.com (remote: `louismales-a11y/catchtales-site.git`) |
| APK downloads | `~/catchtales-site/download/` (3 flavors) |
| APK backups | `~/Desktop/apk backups/` (3 flavors) |
| Cloud functions | `~/CatchTales/functions/` + `~/catchtales_cloud/` |
