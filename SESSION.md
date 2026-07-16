# Session Log

> Update this at the end of every session so the next session starts with full context.

---

## 2025-07-16 — Session 4 — Consolidation

### What we did
- **Consolidated** three separate repos (Dev, Free, Pro) into a **single codebase** at `~/CatchTales/`
- Deleted `~/CatchTales-Dev/` and `~/CatchTales-Free/`
- Branded everything as **CatchTales** — zero remaining "Best Fish Buddy" references
- Cleaned up all tracked build artifacts (classes.dex, .so, META-INF, kotlin builtins, res/)
- Updated `build.sh` to output flavor-specific APK names (`CatchTales-v{version}-{flavor}.apk`)
- Updated `CODING_STANDARDS.md` for single-source workflow
- Updated git remote to point to `louismales-a11y/CatchTales.git` (canonical repo)
- Preserved `.env` with GEMINI_API_KEY and `functions/.env` with Stripe/email config

### How to build
```bash
cd ~/CatchTales
./build.sh dev    # dev flavor (unlocked + debug tools)
./build.sh free   # free flavor (ProService gated)
./build.sh pro    # pro flavor (all unlocked)
# Or directly:
flutter build apk --release --dart-define=APP_VERSION=dev
flutter build apk --release --dart-define=APP_VERSION=free
flutter build apk --release --dart-define=APP_VERSION=pro
```

### What's in progress
- Website pages still reference old v2.14.29 APKs (homepage, /free/, /pro/, /dev/)
- Website `version.json` has stale pro/dev APK paths
- Old v2.14.29 APKs in `~/catchtales-site/download/`, `~/CatchTales/releases/`, and `~/Desktop/apk backups/`

### Rules established this session
- **Single codebase rule**: Only one source directory (`~/CatchTales/`). No more syncing between three repos.
- **Flavor rule**: `--dart-define=APP_VERSION=dev|free|pro` selects the flavor at build time.
- **Branding resolved**: Pro directory was found to still have "bestfishbuddy" branding. Fixed by consolidation.

### Lessons learned
- Pro directory (`~/CatchTales/`) was the original `bestfishbuddy` codebase that was never rebranded to CatchTales.
- Having three separate directories guaranteed they'd diverge. Single source prevents this.
- The Dev codebase already had the flavor infrastructure built in (`ApiConfig.appVersion`), just needed to be the single source.
