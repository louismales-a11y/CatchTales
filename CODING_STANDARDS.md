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
| **Follow existing patterns** | Before adding anything new, look at how similar things are done elsewhere on the site or in the code. Match the existing convention — don't invent new styles, formats, or structures unless there's a clear reason to break from the pattern. |
| **Check callers when changing shared code** | When changing a getter, function, or field used across the app, check every caller first. Use "find references" or grep to see how it's consumed. The context where it's *used* may not match your assumption about the change. |
| **Check file sizes before integrating assets** | Before copying any new asset (image, map, video, etc.), run `ls -lh` on it. If it's over 1 MB for a web image or over 10 MB for anything else, stop and ask if there's a lighter format. Don't assume SVG = small — government topo SVGs can be 80+ MB. Recommend the right format upfront. |
| **Match site UI on every page** | Every new page must match the site's visual identity: underwater background with swimming fish, the full header nav (Home, Features, Blog, Pro Login, About, FAQ, Contact, Privacy, Terms) with hamburger menu on mobile, consistent footer links, and the same dark aquatic color scheme. The Canada landing page and province/region pages must look like they belong to the same site — no orphans without underwater backgrounds or missing nav. |
| **Every new page starts from an existing page** | Never write a new page's HTML from scratch. Copy the homepage or blog's HTML structure and adapt it. This guarantees UI consistency — the right nav, footer, underwater background, meta tags, and icon links are all inherited automatically. |
| **When fixing a bug, check ALL pages of that type** | If species are missing in the new region pages, the old ones likely have the same problem. If a footer is wrong in one hub, check every hub. Never assume only your work has the issue — grep for the pattern and fix them all in one pass. |
| **Verify after every bulk operation** | After running sed or Python across many files, spot-check at least one page for every transformation. A wrong regex can double text, break links, produce empty tags, or corrupt HTML. A 10-second check saves a 10-minute revert. |
| **When building a new section, use the existing equivalent as a template** | When building US pages, open the Canada page side-by-side and match EVERYTHING: card sizes, descriptions, link paths, nav, footer, responsive breakpoints, spotlight classes. Don't invent new class names or structures — copy the exact pattern. |
| **When a user reports something broken, ask what they see first** | Don't assume you know the problem. Ask "what page are you looking at?" and "what do you expect to see?" before making changes. The issue might be different from what you guessed. |
| **Verify the live site after every push** | Run `curl -s https://catchtales.com/[page]` after pushing to confirm the deployed HTML has the expected content. A page that looks right locally can be wrong on the live site.

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

### 2a. Version Bump Discipline

| Rule | Details |
|------|---------|
| **Set the version once, build all flavors from it** | Before building, manually set `pubspec.yaml` to the target version. Use `build.sh` for the first build (it bumps). Then revert `pubspec.yaml` back to the target version before building the remaining flavors. This keeps all three flavors at the same version. |
| **Plan the full flavor build before starting** | Don't build dev, then free, then pro sequentially with build.sh — each run bumps the version. Instead, decide the target version upfront, build all three flavors without intermediate bumps. |

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
| **All version strings** | Update the version number on EVERY page that mentions it: `/index.html`, `/dev/`, `/free/`, `/pro/`, `/version.json`, and any feature pages. A single missed page means a broken download link. |
| **Verification** | Before pushing, grep for the OLD version string to catch stale references: `grep -rn 'OLD_VERSION' --include='*.html' --include='*.json' ~/catchtales-site/` — every match must be updated or confirmed intentional. |
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
   f. **Verify** — `grep -rn 'OLD_VERSION' --include='*.html' --include='*.json' ~/catchtales-site/` — confirm zero stale references remain before proceeding
   g. Place new APKs in website download/ directory
   h. Place new APKs in ~/CatchTales/releases/
   i. Push website changes (git add, commit, push → auto-deploys)
8. Commit and push code changes
```

## 6a. Build & ADB Troubleshooting

> **Lesson learned July 16:** `build.sh` re-runs `flutter pub get` every time and timed out at 300s. Direct `flutter build` is faster.

### Build rules

| Rule | Details |
|------|---------|
| **Always build via `build.sh` for production** | It reads API keys from `pass` (password-store) and injects them via `--dart-define`. Direct `flutter build` commands are for testing only and will produce APKs with broken API features (weather, maps, AI). |
| **After every build: verify on a real device** | Install the APK via ADB (see workaround below if it times out) and confirm the feature you changed actually works before deploying. |

### Working build commands
```bash
cd ~/CatchTales
./build.sh dev    # builds dev flavor with all API keys
./build.sh free   # builds free flavor with all API keys
./build.sh pro    # builds pro flavor with all API keys
```

### After deploying a new APK version — update ALL download links

Check every page that has download buttons and update them simultaneously:
- `/index.html` (homepage — both Free and Pro buttons)
- `/free/index.html`
- `/pro/index.html`
- `/dev/index.html`
- `/version.json`

Failure to update all pages means some download buttons will point to deleted files.

### Working ADB install (preferred — fast and reliable)
```bash
adb push build/app/outputs/flutter-apk/app-release.apk /data/local/tmp/ct.apk
adb shell pm install -r /data/local/tmp/ct.apk
adb shell rm /data/local/tmp/ct.apk
```
Push+install completes in seconds regardless of APK size (~57MB/s via USB bypasses the streaming install timeout entirely). This is the default method — always use it.

### If push+install fails with "Unable to open file"
A stale file from a previous timed-out command causes this. Remove it first, then run commands separately:
```bash
adb shell rm /data/local/tmp/ct.apk
adb push build/app/outputs/flutter-apk/app-release.apk /data/local/tmp/ct.apk
adb shell pm install -r /data/local/tmp/ct.apk
```

### Fallback if push method fails
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
May time out at 60s for large APKs (85MB+). Retry if it fails — can take up to 180s.

### In-app update requirements
When modifying the in-app update feature, these files must be kept in sync:
- `android/app/src/main/AndroidManifest.xml` — needs `REQUEST_INSTALL_PACKAGES` permission + `FileProvider` provider block
- `android/app/src/main/res/xml/file_paths.xml` — FileProvider paths config
- `android/app/src/main/kotlin/.../MainActivity.kt` — `installApk` MethodChannel using `Intent.ACTION_INSTALL_PACKAGE`
- `lib/app.dart` — `_downloadAndInstall()` method + `_updateUrl` logic

### Why build.sh can stall
- It runs `flutter pub get` every time (resolving all 40+ deps)
- If deps are already resolved and you're testing only (no API keys needed), you can run `flutter build` directly
- For production builds, always use `build.sh` — it injects API keys from pass. If it times out, increase the timeout or install deps first with `flutter pub get`

## 6b. Blog Index — No Duplicates, Consistent Pattern

| Rule | Details |
|------|---------|
| **Every blog card gets exactly one category tag** | The existing pattern is one tag per card (Bass Fishing, Fish ID, Game Fish, Gear, Locations, Panfish, Planning, Salmon & Trout, Tips & How-To). Never add multiple tags. |
| **Verify no duplicates before adding** | When adding a new article to `blog/index.html`, search for its slug first. If it's already listed, don't add it again. |
| **Check the full listing after any blog edit** | Run `grep -o 'href="/blog/[^"]*/"' blog/index.html \| sort \| uniq -d` to catch duplicates before committing. |
| **Blog post footer format** | Every blog post ends with a CTA box (teal border, rounded corners) containing "Track Your Fishing with CatchTales" heading + description + "← Back to Blog" link. No download buttons, no app links, no external URLs in the CTA. |

## 6d. Provincial Fishing Pages — Structure & Content Rules

When building province guides and region pages, follow this structure:

### Directory layout
```
/fishing-in-canada/                          ← Canada landing page
/fishing-in-canada/[province]/               ← Province hub (map + region list)
/fishing-near/[region]/                      ← Region page (detailed lake/river entries)
```

### Canada landing page (`/fishing-in-canada/`)
- Grid of province cards with abbreviation, name, short description
- Spotlight (green border) province that has region pages built
- Provinces with region pages link to `/fishing-in-canada/[province]/`
- Provinces without region pages link to their blog article `/blog/fishing-in-[province]-top-species-and-spots/`

### Province hub page (`/fishing-in-canada/[province]/`)
- Back link to `/fishing-in-canada/`
- Stats bar: number of regions, number of spots (e.g., "150+"), number of species — centered row of stat boxes
- **Layout:** flex container with `justify-content: center`, `gap: clamp(16px, 2.5vw, 32px)`, wrapped on mobile
- **Left column (map):** `flex: 0 1 clamp(280px, 40vw, 450px)`, text-align center
- **Right column (region list):** `flex: 0 1 clamp(260px, 35vw, 400px)`
- Topographic map image inside left column: clickable to full size, `max-height: 420px`, rounded corners 12px
- Region cards: `padding: clamp(10px, 1.5vw, 14px)`, border-radius 12px, colored dot 14x14px
- Region card hover: border-color changes to `--clr`, translateX(4px), darker background
- Region card headings: `font-size: clamp(17px, 1.6vw, 20px)`, color uses `--clr` variable
- Region card descriptions: `font-size: clamp(14px, 1.2vw, 15px)`, color #99B0CC
- **Must include base `.region-item` class** with `display:flex`, `align-items:center`, `gap:12px`, `padding: clamp(10px, 1.5vw, 14px)`, `background: rgba(14,20,34,0.5)`, `border`, `border-radius:12px`, `margin-bottom:8px`. This is easily lost during edits — if the region list appears as plain text without boxes, add the missing base rule back.
- Footer links include "Canada Fishing Guide" link

### Region page (`/fishing-near/[region]/`)
- Full article format with underwater background (same CSS as blog)
- Title: "Fishing Near [City]" or "Fishing in [Region Name]"
- Numbered entries (1 through 20-40+ per region)
- Each entry: `<h2>` heading with name + species in parentheses, `<span class="distance">` for location/distance, `<p>` description
- Footer CTA: "For a complete overview of fishing across [Province], see our Fishing in [Province] guide" + **"← Back to [Province]"** link (not back to blog)
- No download buttons in footer CTA

### Region page entry numbering rules
- **Every entry MUST have a number prefix** — `{i}. Name` in the `<h2>` tag. Never add entries without numbers.
- **First entry:** `<h2 style="margin-top:0;">1. Name</h2>` — no top margin on the first entry
- **All other entries:** `<h2 style="margin-top:32px;">2. Name</h2>` — 32px top margin on subsequent entries
- **Fishing Tips heading:** matches the exact format used in each page — either `<h2>Fishing Tips</h2>` or `<h2 style="margin-top:32px;">Fishing Tips for [Region]</h2>`. Always check before inserting new entries.
- **Python batch insertion:** when adding entries via script, use `re.findall(r'<h2[^>]*>(\d+)\.', content)` to find the last number, then append new numbered entries before the Fishing Tips heading.
- **After every batch:** run audit — `grep -cP '<h2[^>]*>\d+\.'` vs total `<h2>` count. Only the Fishing Tips heading should remain unnumbered.
- **Target:** 30-40 entries per region for thorough coverage

### Cross-referencing major lakes
- **If we don't have the large, well-known lakes, the guide fails.** People search for big-name lakes first. Missing them destroys credibility.
- Before finalizing a province, check Wikipedia's "List of lakes of [Province]" for major lakes
- Cross-reference each major lake against what's listed in the region pages
- Add any missing major lakes — prioritize by size and fishing significance
- For Ontario: check Great Lakes, Lake Nipigon, Lake of the Woods, Lac Seul, Rainy Lake, Lake Nipissing, Lake Simcoe, Lake Abitibi, Big Trout Lake, Lake St. Joseph
- For Manitoba: check Lake Winnipeg, Lake Winnipegosis, Lake Manitoba, Southern Indian Lake, Gods Lake, Cross Lake, Clearwater Lake, Athapapuskow
- For Saskatchewan: check Lake Athabasca, Reindeer Lake, Wollaston Lake, Cree Lake, Lac la Ronge, Peter Pond Lake, Doré Lake, Churchill Lake, Montreal Lake

### Content conventions
- Species listed in parentheses after each lake name: "(Walleye, Northern Pike)"
- Distance/area tag as `<span class="distance">` before each description
- Region cards use `--clr` CSS variable for colored dot matching map colors
- No emojis anywhere
- Each new page added to `sitemap.xml`

## 6c. Cloud Dashboard — HTML Chrome Lives in Source Template

| Rule | Details |
|------|---------|
| **HTML chrome (header, nav, underwater background, fish) goes in `~/catchtales_cloud/web/index.html`** | This is the Flutter web app's source template. The built output (`build/web/index.html`) is regenerated from it. Any changes to the header, background, or nav MUST be made in the source template, not in the built output. |
| **Verify chrome survives rebuild** | After every `flutter build web --base-href=/cloud/`, check that `build/web/index.html` still contains the `.site-header` and `.underwater-bg` elements before copying to `~/catchtales-site/cloud/`. |
| **The deployed `~/catchtales-site/cloud/` is a copy of `build/web/`** | Never edit `~/catchtales-site/cloud/index.html` directly — it will be overwritten on the next rebuild. Always edit `~/catchtales_cloud/web/index.html` and rebuild. |

## 7. Code Conventions

| Rule | Details |
|------|---------|
| **Services are singletons** | `static final X instance = X._(); X._();` pattern |
| **Translation** | Use `tr('key')` for all user-facing strings. Never hardcode English. |
| **Pro gating** | Locked features show `ProService.showUpgradeDialog(context)` — never crash or silently fail |
| **Error handling** | Show user-facing messages. No silent failures. |
| **State management** | Provider pattern (ChangeNotifierProvider) |
| **Async context** | Always check `if (!context.mounted) return` after async gaps |
| **No emojis or gradients** | Zero emojis and zero gradients anywhere — app UI, website, help text, translations, blog posts, notifications. Use solid colors, icons (SVG or Material), and text-only labels. No exceptions. |
| **Mobile-first responsive design** | Every web element must render correctly on all device sizes (320px phones to widescreen desktop). Use `clamp()` for fluid typography and spacing, `min-height: 44px` for touch targets, `env(safe-area-inset-*)` for notched phones, and animated hamburger menus on mobile. Test on a real phone before deploying. |
| **Duplicate user profiles** | When testing account creation (delete + recreate), old Firestore profile documents can accumulate under the same email. If the admin panel shows stale data or missing tracking, ask pi to check the `users` collection for duplicates. pi can query Firestore directly and clean up old profiles. |

## 8. File Locations

| What | Path |
|------|------|
| **Single source of truth** | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| **Website** | `~/catchtales-site/` (remote: `louismales-a11y/catchtales-site.git`) — push to main auto-deploys to catchtales.com |
| **Cloud dashboard source** | `~/catchtales_cloud/` |
| **APK downloads** | `~/catchtales-site/download/` |
| **APK backups** | `~/Desktop/apk backups/` |

> ✅ **Consolidated July 16:** The old separate Dev, Free, and Pro directories have been merged into a single codebase at `~/CatchTales/`. Use `--dart-define=APP_VERSION=dev|free|pro` to build each flavor. The old `CatchTales-Dev` and `CatchTales-Free` repos have been **deleted** from GitHub. Only `CatchTales` (code) and `catchtales-site` (website) remain.

> ⚠️ **Lesson July 16:** Direct `flutter build` commands omit API keys → weather, maps, and AI features silently fail. Always use `build.sh` for production builds, and always verify on a real device after deploying.
> ⚠️ **Lesson July 16:** The cloud dashboard's HTML chrome (header, background) was lost because it only existed in the built output. It now lives in the source template `~/catchtales_cloud/web/index.html` so it survives rebuilds.

---

*Last updated: 2025-07-17 (added: no emojis or gradients rule, mobile-first responsive design rule, push ADB as default install method, duplicate user profiles rule)*
*If Louis corrects a behavior, add it here immediately.*
