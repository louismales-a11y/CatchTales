# CatchTales — Coding & Operations Standards

> **Every session starts by reading this file.** These rules are non-negotiable and have been established through repeated corrections.

---

## 0. How pi Must Operate

| Rule | Details |
|------|---------|
| **Slow down** | Don't rush. Read carefully before acting. Rushing causes rework. |
| **Every redo costs time and trust** | Getting it right the first time is faster than fixing mistakes later. |
| **Read the standards first** | Every session starts with `CODING_STANDARDS.md` + `SESSION.md`. |
| **Search before asking** | Look in the code, docs, and standards first. The answer is often already there. |
| **Think things through** | Consider the full impact before making changes. Trace through all affected files. |
| **Work together step-by-step** | Don't charge ahead alone. Navigate together: propose → confirm → act → verify. One screen at a time. |
| **Confirm before acting** | One step at a time: you say what to do, I ask to confirm, you confirm, I act. No assumptions. |
| **Be precise with edits** | Match exact text. Verify file paths before running commands. A wrong path or fuzzy match breaks things. |
| **Double-check before finalizing** | Verify nothing is broken — check imports, references, type consistency, and that the app still makes sense. |
| **Cut redundancy** | Remove repetitive content. Don't have multiple logos, taglines, or buttons saying the same thing. |
| **Ask when unsure** | If a rule isn't clear or a change might violate a standard, stop and ask. |
| **Check ALL pages, not just one** | When a user says "the website" or "the site" has a broken link, search EVERY page that could contain that link. Homepage, /free/, /pro/, /dev/, features — all of them. Don't fixate on one page. |
| **Trace the user's path** | When investigating a bug, start from where the user actually clicks, not where you assume they click. Read the page they're on. |
| **Document solutions as rules** | When you solve a tricky problem (ADB, build issues, config, etc.), write the working procedure into this document immediately so it becomes the default method forever. |
| **Keep the desktop note in sync** | Whenever `CODING_STANDARDS.md` is updated, also update `~/Desktop/CatchTales-Rules.txt` to match. The desktop note is the quick-reference version. |

### 📋 Standards Check Cadence

| When | What to Check |
|------|---------------|
| **Session start** | Read `CODING_STANDARDS.md` + `SESSION.md` fully |
| **Before every action** | Scan the relevant section (workflow, conventions, etc.) |
| **After every change** | Re-check Rule 3 — did I update What's New, Walkthrough, Help, Translations, Version, Website? |
| **Before finalizing** | Full double-check — nothing broken, not rushing, old files cleaned |
| **When stuck** | Rule 0 — slow down, search first, ask if still unsure |
| **End of session** | Update `SESSION.md` + desktop note if rules changed |

---

## 1. Workspace — Single Codebase, Three Flavors

| Rule | Details |
|------|---------|
| **One source directory** | `~/CatchTales/` is the ONLY workspace. The old separate repos have been consolidated into one. |
| **Build flavors** | `--dart-define=APP_VERSION=dev|free|pro` selects the flavor at build time. See §6 for commands. |
| **Dev flavor** = everything unlocked + debug tools (for Louis's phone) |
| **Free flavor** = `ProService` gates certain features (catch limit, tackle limit, fish ID limit) |
| **Pro flavor** = all features unlocked, no dev tools |
| **Never commit without testing** | Build must be installed and verified on the physical phone first. |

## 2. Versioning

| Rule | Details |
|------|---------|
| **Every change bumps the version** | No exceptions. Even a one-line fix gets a version bump. |
| **Single version number** | One `pubspec.yaml`, one version across all flavors. |
| **Version format** | Follow `pubspec.yaml` semver (e.g., `2.14.30`). |
| **Update `version.json`** | The website's `version.json` must match the app version. |

## 3. App Changes — Always Update These Together

When you change or add anything to the app, **ALL** of these must be updated:

| What | Where | Notes |
|------|-------|-------|
| **What's New dialog** | `app.dart` — `_showWhatsNew()` | Add the new feature to the list |
| **Walkthrough/Onboarding** | `onboarding_screen.dart` | If it's a major feature, add a walkthrough page |
| **Help text** | `services/help_text.dart` | Update help for the affected screen(s) |
| **Translations** | `services/translation_service.dart` | All 5 languages: en, fr, es, de, uk |
| **Version number** | `pubspec.yaml` | Always bump |
| **Website** | `~/catchtales-site/` | See rule 4 |
| **Branding** | Everything is **CatchTales**. No more "Best Fish Buddy" anywhere — code, website, assets. If you find old branding, flag it for replacement. |

## 4. Website Updates

Every app change that affects users requires a website update:

| What on the website | Details |
|--------------------|---------|
| **`version.json`** | Update version number and APK download paths |
| **Download pages** | `/dev/`, `/free/`, `/pro/` — update APK links and feature lists |
| **Feature descriptions** | `/features/` — if the change adds/removes/modifies a feature |
| **Blog** | `/blog/` — consider a blog post for major releases |
| **WhatsApp/auto-update** | The app reads `version.json` to prompt updates — keep it in sync |
| **Site is live, not local** | Never start a localhost server. The real site is at **catchtales.com** via GitHub Pages. Work directly on `~/catchtales-site/` and push to deploy. |

## 5. Download Links — NO GitHub

| Rule | Details |
|------|---------|
| **Never expose GitHub URLs** | No `github.com/louismales-a11y/...` links anywhere on catchtales.com |
| **Direct downloads only** | Links must point directly to APK files (e.g., `/download/CatchTales-v2.14.29-dev.apk`) |
| **No GitHub releases page** | Users should never see GitHub. The website is the sole distribution point. |
| **Clean up old builds** | When deploying a new version, delete old APK files from `~/catchtales-site/download/` and any old build artifacts. No stale files to confuse future work. |
| **Clean local releases/ folder** | Old APKs in `~/CatchTales/releases/` must be deleted when deploying a new version. |
| **Clean build/ directories** | Run `flutter clean` periodically. Build artifacts can exceed 3GB per project and cause confusion. |
| **Manage backups** | Keep backup APKs in one designated folder (e.g., `~/Desktop/apk backups/`). Name them clearly with version + flavor. Delete backups older than the latest version when new version ships. |
| **Dev page has no download link** | The `/dev/` page on the website is intentionally internal-only. No download button for dev APKs. Users should never have access to dev builds. |

## 6. Build & Release Workflow

```
1. Make changes in ~/CatchTales/ (single source)
2. Bump version in pubspec.yaml
3. Update UX copy (What's New, Walkthrough, Help, Translations)
4. Read version.json on website to confirm current live version
5. Build all three flavors:
   flutter build apk --release --dart-define=APP_VERSION=dev
   flutter build apk --release --dart-define=APP_VERSION=free
   flutter build apk --release --dart-define=APP_VERSION=pro
6. Install dev APK on phone, test
7. If good:
   a. Delete old APK files from ~/catchtales-site/download/
   b. Delete old APKs from ~/CatchTales/releases/
   c. Clean old backup APKs from ~/Desktop/apk backups/
   d. Copy latest APKs (dev, free, pro) into ~/Desktop/apk backups/
   e. Update website (version.json, download pages, features)
   f. Place new APKs in website download/ directory
   g. Place new APKs in ~/CatchTales/releases/
   h. Push website changes (git add, commit, push → auto-deploys)
8. Commit and push code changes
```

## 6a. Build & ADB Troubleshooting

> **Lesson learned July 16:** `build.sh` re-runs `flutter pub get` every time and timed out at 300s. Direct `flutter build` is faster.

### Working build commands
```bash
cd ~/CatchTales
export PATH="$HOME/bin:$HOME/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export JAVA_HOME="$HOME/jdk-17.0.12+7"
export ANDROID_HOME="$HOME/android-sdk"

# Build dev flavor (for Louis's phone)
flutter build apk --release --dart-define=APP_VERSION=dev

# Build free flavor (for website)
flutter build apk --release --dart-define=APP_VERSION=free

# Build pro flavor (for website)
flutter build apk --release --dart-define=APP_VERSION=pro
```

### After deploying a new APK version — update ALL download links

Check every page that has download buttons and update them simultaneously:
- `/index.html` (homepage — both Free and Pro buttons)
- `/free/index.html`
- `/pro/index.html`
- `/dev/index.html`
- `/version.json`

Failure to update all pages means some download buttons will point to deleted files.

### Working ADB install
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
If it times out at 60s, retry — it can take up to 180s for a large APK (85MB+).

### If `adb install` keeps timing out (APK >80MB)
```bash
adb push build/app/outputs/flutter-apk/app-release.apk /data/local/tmp/ct.apk
adb shell pm install -r /data/local/tmp/ct.apk
adb shell rm /data/local/tmp/ct.apk
```
Pushing is fast (~57MB/s via USB), then `pm install` completes in seconds. This bypasses the streaming install timeout entirely.

### Why build.sh can stall
- It runs `flutter pub get` every time (resolving all 40+ deps)
- If deps are already resolved, skip the script and run `flutter build` directly
- The script is still useful for API key injection via pass or .env; if you need keys, run the script with a longer timeout

## 7. Code Conventions

| Rule | Details |
|------|---------|
| **Services are singletons** | `static final X instance = X._(); X._();` pattern |
| **Translation** | Use `tr('key')` for all user-facing strings. Never hardcode English. |
| **Pro gating** | Locked features show `ProService.showUpgradeDialog(context)` — never crash or silently fail |
| **Error handling** | Show user-facing messages. No silent failures. |
| **State management** | Provider pattern (ChangeNotifierProvider) |
| **Async context** | Always check `if (!context.mounted) return` after async gaps |

## 8. File Locations

| What | Path |
|------|------|
| **Single source of truth** | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| **Website** | `~/catchtales-site/` (remote: `louismales-a11y/catchtales-site.git`) — push to main auto-deploys to catchtales.com |
| **Cloud dashboard source** | `~/catchtales_cloud/` |
| **APK downloads** | `~/catchtales-site/download/` |
| **APK backups** | `~/Desktop/apk backups/` |

> ✅ **Consolidated July 16:** The old separate Dev, Free, and Pro directories have been merged into a single codebase at `~/CatchTales/`. Use `--dart-define=APP_VERSION=dev|free|pro` to build each flavor. The old `CatchTales-Dev` and `CatchTales-Free` repos have been **deleted** from GitHub. Only `CatchTales` (code) and `catchtales-site` (website) remain.

---

*Last updated: 2025-07-16 (resolved gh-pages conflict, added: keep desktop note in sync)*
*If Louis corrects a behavior, add it here immediately.*
