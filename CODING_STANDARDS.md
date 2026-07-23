# CatchTales — Coding & Operations Standards

> **Every session starts by reading this file.** These rules are non-negotiable and have been established through repeated corrections.

---

## 0. How pi Must Operate

| Rule | Details |
|------|---------|
| **Slow down** | Don't rush. Read carefully before acting. Rushing causes rework. |
| **Every redo costs time and trust** | Getting it right the first time is faster than fixing mistakes later. |
| ⭐ **Read the standards — on repeat, before EVERY action** | Not just at session start. **Before EVERY action** (build, install, edit, add feature, deploy), grep the relevant section first:
  - `grep -A10 "Build & Release\|build.sh" CODING_STANDARDS.md` before building
  - `grep -A10 "ADB install\|Working ADB" CODING_STANDARDS.md` before installing
  - `grep -A5 "App Changes\|Rule 3\|Walkthrough" CODING_STANDARDS.md` after code changes
  - `grep -A5 "Website Updates\|version" CODING_STANDARDS.md` before deploying
  If Louis says "read the standards", stop everything and do it immediately — no excuses. The rules exist because they were learned through costly mistakes. Skipping them guarantees repeating those mistakes. |
| **Search before asking** | Look in the code, docs, and standards first. The answer is often already there. |
| **Think things through** | Consider the full impact before making changes. Trace through all affected files. |
| **Work together step-by-step** | Don't charge ahead alone. Navigate together: propose → confirm → act → verify. One screen at a time. |
| **Confirm before acting** | One step at a time: you say what to do, I ask to confirm, you confirm, I act. No assumptions. |
| **Be precise with edits** | Match exact text. Verify file paths before running commands. A wrong path or fuzzy match breaks things. |
| **Double-check before finalizing** | Verify nothing is broken — check imports, references, type consistency, and that the app still makes sense. |
| **Cut redundancy** | Remove repetitive content. Don't have multiple logos, taglines, or buttons saying the same thing. |
| **Ask when unsure** | If a rule isn't clear or a change might violate a standard, stop and ask. |
| **Answer directly** | When Louis asks a question, provide the answer only. No follow-up questions, no suggestions, no clarifications. Just answer what was asked. |
| **Check ALL pages, not just one** | When a user says "the website" or "the site" has a broken link, search EVERY page that could contain that link. Homepage, /free/, /pro/, /dev/, features — all of them. Don't fixate on one page. |
| **Trace the user's path** | When investigating a bug, start from where the user actually clicks, not where you assume they click. Read the page they're on. |
| **Document solutions as rules** | When you solve a tricky problem (ADB, build issues, config, etc.), write the working procedure into this document immediately so it becomes the default method forever. |
| **What's New discipline** | Only list major new features in the What's New dialog. Bug fixes, minor tweaks, and performance work should be summarized as "Bug fixes and performance improvements" — not listed individually. Keep it short and scannable. |
| **Consistent nav on every page** | ALL pages — homepage, USA hub, Canada hub, state/province hubs, and region pages — must have the EXACT same navigation bar with all 11 links: Home, Features, US Fishing, Canada Fishing, Blog, Pro Login, About, FAQ, Contact, Privacy, Terms. Same order, same hrefs, no omissions. The footer should be minimal: Contact, Privacy, Terms links only (the nav is already at the top). Run a cross-page grep before any deploy to verify consistency: `grep -c 'US Fishing\|Canada Fishing'` on every page type. |
| **Keep the desktop note in sync** | Whenever `CODING_STANDARDS.md` is updated, also update `~/Desktop/CatchTales-Rules.txt` to match. The desktop note is the quick-reference version. |
| **Follow existing patterns** | Before adding anything new, look at how similar things are done elsewhere on the site or in the code. Match the existing convention — don't invent new styles, formats, or structures unless there's a clear reason to break from the pattern. |
| **Walkthrough order matches 3-dot menu** | The onboarding/walkthrough pages must follow the same order as items appear in the 3-dot menu. If you add a new feature to the menu, add it to the walkthrough in the same position. This keeps the user learning experience consistent with the app navigation. |
| **Check callers when changing shared code** | When changing a getter, function, or field used across the app, check every caller first. Use "find references" or grep to see how it's consumed. The context where it's *used* may not match your assumption about the change. |
| **Check file sizes before integrating assets** | Before copying any new asset (image, map, video, etc.), run `ls -lh` on it. If it's over 1 MB for a web image or over 10 MB for anything else, stop and ask if there's a lighter format. Don't assume SVG = small — government topo SVGs can be 80+ MB. Recommend the right format upfront. |
| **Match site UI on every page** | Every new page must match the site's visual identity: underwater background with swimming fish, the full header nav (Home, Features, US Fishing, Canada Fishing, Blog, Pro Login, About, FAQ, Contact, Privacy, Terms) shown as horizontal text links centered below the logo on mobile (no hamburger menu), consistent footer links, and the same dark aquatic color scheme. All pages must have max-width:960px content container. The Canada landing page and province/region pages must look like they belong to the same site — no orphans without underwater backgrounds or missing nav. |
| **Every new page starts from an existing page** | Never write a new page's HTML from scratch. Copy the homepage or blog's HTML structure and adapt it. This guarantees UI consistency — the right nav, footer, underwater background, meta tags, and icon links are all inherited automatically. |
| **Check inline styles before CSS changes** | Before changing CSS properties (height, padding, alignment, etc.), check if the live HTML has `style="..."` on the element. Inline styles override CSS class rules. Use `curl` or grep to verify the actual rendered HTML before declaring a fix done. After every push, verify the live site with `curl` to confirm changes took effect. Don't assume — verify. |
| **When fixing a bug, check ALL pages of that type** | If species are missing in the new region pages, the old ones likely have the same problem. If a footer is wrong in one hub, check every hub. Never assume only your work has the issue — grep for the pattern and fix them all in one pass. |
| **Verify after every bulk operation** | After running sed or Python across many files, spot-check at least one page for every transformation. A wrong regex can double text, break links, produce empty tags, or corrupt HTML. A 10-second check saves a 10-minute revert. |
| **When building a new section, use the existing equivalent as a template** | When building US pages, open the Canada page side-by-side and match EVERYTHING: card sizes, descriptions, link paths, nav, footer, responsive breakpoints, spotlight classes. Don't invent new class names or structures — copy the exact pattern. |
| **Landing page cards must display data** | Every province/state card on the Canada and US landing pages must include a descriptive line showing region count and spot count (e.g., "5 regions, 150+ spots mapped"). Never show just a name with no data — the card looks empty without it.
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
| **End of session** | Run SEO checklist (Section 9) — verify nothing regressed |

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
5. ⚠️  **Update QR code download URL** — the free APK URL embedded in the QR code must match the new version. Two places:
   - App: `lib/screens/about_screen.dart` — `QrImageView(data: '...')`
   - Website: every HTML page — `grep -rl 'qrserver.*data=' ~/catchtales-site/` then update the `data=` URL
   Skipping this = broken QR code. Make it part of every release.
6. Build all three flavors:
   flutter build apk --release --dart-define=APP_VERSION=dev
   flutter build apk --release --dart-define=APP_VERSION=free
   flutter build apk --release --dart-define=APP_VERSION=pro
7. Install dev APK on phone, test
8. If good:
   a. Delete old APK files from ~/catchtales-site/download/
   b. Delete old APKs from ~/CatchTales/releases/
   c. Clean old backup APKs from ~/Desktop/apk backups/
   d. Copy latest APKs (dev, free, pro) into ~/Desktop/apk backups/
   e. Update website (version.json, download pages, features)
   f. ⚠️  **Update QR code URLs** — run `grep -rn 'qrserver.*data=' ~/catchtales-site/` and update all `data=` URLs to point to the new free APK filename. Also update `lib/screens/about_screen.dart` if needed.
   g. **Verify** — `grep -rn 'OLD_VERSION' --include='*.html' --include='*.json' ~/catchtales-site/` — confirm zero stale references remain before proceeding
   h. Place new APKs in website download/ directory
   i. Place new APKs in ~/CatchTales/releases/
   j. Push website changes (git add, commit, push → auto-deploys)
9. Commit and push code changes
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
- **Header standard (ALL pages):** Logo centered on page, navigation horizontally centered below logo. CSS: `header {flex-direction:column;align-items:center}` + `.header-logo img {margin:0 auto}` + `header nav {width:100%;justify-content:center}`
- **Nav standard (ALL pages):** 11 links in exact order: Home, Features, US Fishing, Canada Fishing, Blog, Pro Login, About, FAQ, Contact, Privacy, Terms
- **Footer standard (ALL pages):** Minimal — Contact, Privacy, Terms links only. Copyright notice. The full nav is already at the top of every page, so the footer should not repeat it.
- **Download section (ALL pages):** A "Get CatchTales" section with download buttons (Pro + Free) must appear before the footer on EVERY page. CSS classes required: `.download`, `.download h2`, `.download p`, `.download-buttons`, `.version-note`, `.btn`, `.btn-primary`, `.btn-secondary` — verify these exist in the page style before deploying.
- **Content container:** `max-width: 960px` on ALL pages — never use narrower widths (800px causes nav wrapping)
- **UI consistency checklist before any deploy:**
  1. `grep -r 'align-items: flex-end' --include='*.html' .` — should return ZERO results
  2. `grep -r 'max-width: 800px' --include='*.html' .` — should return ZERO results
  3. Spot-check 3 pages: homepage, a hub, a region — nav has all 11 links, footer matches, header is centered
- Title: "Fishing Near [City]" or "Fishing in [Region Name]"
- Numbered entries (1 through 20-40+ per region)
- Each entry: `<h2>` heading with name + species in parentheses, `<span class="distance">` for location/distance, `<p>` description
- Footer CTA (standard format):
  - Fishing Tips section: `<h2 style="margin-top:32px;">Fishing Tips for the [Region]</h2>` followed by a `<ul>` with 5 regional tips
  - CTA card: `<div class="card" style="padding:24px;text-align:center;background:rgba(0,188,212,0.08);border:2px solid rgba(0,188,212,0.25);">`
  - CTA heading: `<p style="font-size:clamp(19px,1.8vw,26px);color:#76FF03;font-weight:800;text-transform:uppercase;">Plan Smarter Fishing Trips &#8212; <span style="color:#fff;">CatchTales</span></p>`
  - CTA description: `<p style="font-size:clamp(15px,1.3vw,18px);color:#E0E8F0;font-weight:500;">Solunar forecasts &bull; Real-time weather &bull; Fish identification &bull; Catch logging &mdash; all in one app.</p>`
  - Back button: `<a href="/fishing-in-united-states/[state-slug]/" class="btn" style="display:inline-block;padding:12px 24px;background:#4CAF50;color:#fff;border-radius:10px;font-weight:700;text-decoration:none;">&larr; Back to [State Name]</a>`
- No download buttons in footer CTA

### Region page entry numbering rules
- **Every entry MUST have a number prefix** — `{i}. Name` in the `<h2>` tag. Never add entries without numbers.
- **First entry:** `<h2 style="margin-top:0;">1. Name</h2>` — no top margin on the first entry
- **All other entries:** `<h2 style="margin-top:32px;">2. Name</h2>` — 32px top margin on subsequent entries
- **Fishing Tips heading:** matches the exact format used in each page — either `<h2>Fishing Tips</h2>` or `<h2 style="margin-top:32px;">Fishing Tips for [Region]</h2>`. Always check before inserting new entries.
- **Python batch insertion:** when adding entries via script, use `re.findall(r'<h2[^>]*>(\d+)\.', content)` to find the last number, then append new numbered entries before the Fishing Tips heading.
- **After every batch:** run audit — `grep -cP '<h2[^>]*>\d+\.'` vs total `<h2>` count. Only the Fishing Tips heading should remain unnumbered.
- **Target:** 30-40 entries per region for thorough coverage

### App CTA pattern (all hub + region pages)
- **Hub pages:** Full CTA card before footer — uppercase headline in bright green `#76FF03` (19-26px, 800 weight), feature bullets in gold `#E0E8F0` (15-18px, 500 weight), "Get the App →" button (green, uppercase, 14-17px, 800 weight, 14px padding).
- **Region pages:** Text-only statement inside existing CTA box (no button) — uppercase `#76FF03` "Plan Smarter Fishing Trips — CatchTales —" followed by feature list in gold `#E0E8F0` (15-20px, 700 weight).
- **Always use Python batch scripts** for CTA updates — never sed (special chars like &mdash;, &bull;, # colors will break).

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
| **Mobile-first responsive design** | Every web element must render correctly on all device sizes (320px phones to widescreen desktop). Use `clamp()` for fluid typography and spacing, `min-height: 44px` for touch targets, `env(safe-area-inset-*)` for notched phones. On mobile, header nav links display as horizontal text below the logo (no hamburger menu). Test on a real phone before deploying. |
| **Duplicate user profiles** | When testing account creation (delete + recreate), old Firestore profile documents can accumulate under the same email. If the admin panel shows stale data or missing tracking, ask pi to check the `users` collection for duplicates. pi can query Firestore directly and clean up old profiles. |

## 9. SEO Maintenance — End-of-Session Checklist

> Run through this checklist at the **end of every session** that touches the website.
> For major SEO changes, also verify with Google Search Console after deployment.

### ✅ Meta Tags (every new or edited page)

| Check | Why |
|-------|-----|
| `<title>` is unique and descriptive | Each page needs its own title, ideally under 60 chars |
| `<meta name="description">` is unique | 120-160 chars, includes target location/keyword |
| `<meta property="og:type">` is present | `website` for hubs/landing, `article` for posts/regions |
| `<meta property="og:url">` matches page URL | Must match canonical URL |
| `<meta property="og:title">` matches `<title>` | Social sharing preview title |
| `<meta property="og:description">` matches meta description | Social sharing preview text |
| `<meta property="og:image">` points to `/images/og-image.jpg` | The 1200×630 branded image, NOT the old 192px logo |
| `<meta property="og:locale">` is `en_US` | Language/locale declaration |
| `<meta property="og:site_name">` is `CatchTales` | Brand consistency |
| `<meta name="twitter:card">` is `summary_large_image` | Bigger social preview cards (NOT `summary`) |
| `<meta name="twitter:title">` matches `<title>` | Twitter card title |
| `<meta name="twitter:description">` matches description | Twitter card description |
| `<meta name="twitter:image">` points to `/images/og-image.jpg` | Twitter card image (NOT the old 192px logo) |
| `<link rel="canonical">` points to the correct URL | Prevents duplicate content issues |
| `<meta name="robots" content="index, follow">` is present | Allows indexing unless intentionally noindex |
| `<link rel="manifest">` points to `/manifest.json` | PWA support — every page needs this |
| `<link rel="alternate" type="application/rss+xml">` on blog index | RSS discovery link |
| `<link rel="alternate" hreflang="en-CA">` on Canada landing | International targeting |
| `<link rel="alternate" hreflang="en-US">` on US landing | International targeting |

**Also check static pages** (about, features, privacy, terms, contact, download, free, pro, dev, 404): these need the same meta tags as everything else. Don't skip them.

### ✅ Structured Data (JSON-LD)

| Check | Where | Details |
|-------|-------|---------|
| BreadcrumbList schema | **Every page** | Must include all visible breadcrumb items. Run `grep -c 'BreadcrumbList'` — should be **exactly 1** per page |
| Article schema (enriched) | **Every blog post + region page** | Must include `datePublished`, `dateModified`, `image`, `author.url`, `publisher.url`. Run `grep 'datePublished'` to verify |
| WebSite schema | **Homepage only** | Includes site name, URL, search action |
| Organization schema | **Homepage only** | Includes name, URL, logo, description |
| FAQPage schema | **/faq/ only** | One entry per Q&A pair, properly escaped |
| **No duplicate schema types** | All pages | Each `@type` should appear **exactly once** per page. Run: `grep -o '"@type": "[^"]*"' page.html \| sort \| uniq -c` |
| **Valid JSON** | All pages | Run: `python3 -c "import re,json; [json.loads(s) for s in re.findall(r'<script type=.application/ld\+json.>(.*?)</script>', open('page.html').read(), re.DOTALL)]"` |
| **Breadcrumb schema matches visible breadcrumb** | All pages | The schema's `itemListElement` should match the visible breadcrumb links in the HTML. If you change one, change both. |

**Common mistakes:**
- Forgetting to add BreadcrumbList to new pages
- Using the old 192px image in og:image (should be `/images/og-image.jpg`)
- Article schema missing `datePublished`/`image`/`author.url` (not enriched)
- Adding a new schema type without checking if one already exists (causes duplicates)

### ✅ Images

| Check | Command |
|-------|---------|
| New images converted to WebP? | `ls *.webp` — originals should have a corresponding .webp |
| HTML references WebP, not JPG/PNG? | `grep 'src="[^"]*\.\(jpg\|png\)"'` should return **zero** results for images that have WebP versions |
| Lazy loading on content images? | `grep '<img' page.html \| grep -v 'loading='` should only show hero/bg images (underwater, logo, animated fish, splash) |
| Animated/decorative images NOT lazy? | Animated fish (`tfish*.webp`), logo, background (`underwater.webp`), and splash should load eagerly |
| Alt text on meaningful images? | Screenshots, topo maps should have descriptive `alt` like "Topographic map of Florida" |
| Decorative images have `alt=""`? | Fish animations, background overlay should have empty alt |

### ✅ Performance

| Check | Why |
|-------|-----|
| No render-blocking external CSS? | Google Fonts with `&display=swap` is fine. Anything else? |
| `loading="lazy"` on below-fold images | Adds ~30% faster initial paint on mobile |
| Image sizes reasonable? | Check with `ls -lh` — topo maps under 500KB, icons under 50KB |
| WebP savings significant? | Original JPG/PNG should be 50-80% larger than WebP version. If not, re-compress. |

### ✅ Sitemap & Discovery

| Check | How |
|-------|-----|
| New pages in sitemap.xml? | Every new hub, region, and blog post needs a `<url>` entry |
| sitemap.xml is valid XML? | `python3 -c "import xml.etree.ElementTree as ET; ET.parse('sitemap.xml')"` |
| RSS feed exists and includes new blog posts? | `grep '<item>' blog/feed.xml \| wc -l` should match blog post count |
| robots.txt references sitemap? | `grep 'Sitemap' robots.txt` should show `https://catchtales.com/sitemap.xml` |
| No broken internal links? | New pages should link to each other — trace hub → region → spot |
| `/blog/feed.xml` linked in blog index `<head>`? | Should have `<link rel="alternate" type="application/rss+xml">` |

### ✅ Quick Verification Script

```bash
cd ~/catchtales-site

# 1. Check ALL pages have basic SEO meta (exclude google verification)
for f in $(find . -name 'index.html' -o -name '*.html' | grep -v googlefa); do
  grep -q 'og-image.jpg' "$f" || echo "MISSING og:image: $f"
  grep -q 'rel=\"canonical\"' "$f" || echo "MISSING canonical: $f"
  grep -q 'BreadcrumbList' "$f" || echo "MISSING BreadcrumbList: $f"
  grep -q 'summary_large_image' "$f" || echo "MISSING twitter:card: $f"
  grep -q 'manifest.json' "$f" || echo "MISSING manifest: $f"
  grep -q 'index, follow' "$f" || echo "MISSING robots: $f"
done

# 2. Check enriched Article schema on blog/region pages
for f in $(find ./fishing-near ./blog -name 'index.html'); do
  grep -q 'datePublished' "$f" || echo "MISSING datePublished: $f"
  grep -q 'author.*url.*catchtales' "$f" || echo "MISSING author.url: $f"
done

# 3. Check no pages use old 192px og:image
if grep -r 'catchtales-192.png' --include='*.html' . | grep -q 'og:image'; then
  echo "❌ Some pages still reference old 192px og:image"
  grep -r 'catchtales-192.png' --include='*.html' . | grep 'og:image'
fi

# 4. Count pages vs sitemap entries
html_count=$(find . -name 'index.html' | grep -v googlefa | wc -l)
sm_count=$(grep -c '<url>' sitemap.xml)
echo "HTML pages: $html_count, Sitemap URLs: $sm_count"
if [ "$html_count" -ne "$sm_count" ]; then
  echo "❌ MISMATCH: $html_count pages vs $sm_count sitemap URLs"
fi

# 5. Check all referenced images exist
for img in $(grep -roh 'src="[^"]*\.\(jpg\|png\|webp\)"' . | sed 's/src="//;s/"$//' | sort -u); do
  [ -f ".$img" ] || echo "MISSING IMAGE: $img"
done

# 6. Check hreflang on Canada/US landing pages
grep -q 'hreflang="en-CA"' ./fishing-in-canada/index.html || echo "MISSING hreflang CA"
grep -q 'hreflang="en-US"' ./fishing-in-united-states/index.html || echo "MISSING hreflang US"

# 7. Check RSS feed has all blog posts
blog_count=$(find ./blog -mindepth 2 -name 'index.html' | wc -l)
rss_count=$(grep -c '<item>' ./blog/feed.xml 2>/dev/null || echo 0)
echo "Blog posts: $blog_count, RSS items: $rss_count"

# 8. Regenerate app guide data if states/provinces changed
cd ~/CatchTales && python3 scripts/convert_guides_to_json.py
```

### When to Run Full SEO Audit

| Trigger | Action |
|---------|--------|
| **Every session end** | Run the quick verification script above |
| **After adding 5+ new pages** | Check sitemap + internal links manually |
| **After any bulk HTML operation** | Spot-check 3 pages for broken meta/schema |
| **Before push to main** | Run full checklist — no exceptions |

---

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

> ⚠️ **Lesson July 19:** **sed + `&` = corruption.** The `&` character in sed replacement text is interpreted as "the entire matched pattern". When replacing text containing HTML entities like `&larr;`, `&amp;`, `&mdash;`, the `&` in the *replacement* string will duplicate the entire match. **Always use Python (or escape `&` as `\&`) when the replacement text contains HTML entities.** For batch HTML edits with special characters, Python's `str.replace()` is safer and more predictable than sed.

---

## 10. Region Page Standards (Winnipeg model)

Every region page (`/fishing-near/[region]/`) must follow this exact structure, modeled after the Winnipeg page:

### Page structure (top to bottom)
```
1. Underwater background + swimming fish
2. Header with logo + 11-link nav
3. Page title area:
   - Back to [State/Province] link (blue text, 22px, bold)
   - h1: "Fishing in the [Region Name] Region"
   - p: "The [region area] of [state/province], featuring [key species]."
4. Content card (.content-page > .container > .card):
   - Numbered entries (1 through 20-40)
   - Each: h2 with name + species, span.distance with location name, p description
   - Card closes BEFORE Fishing Tips section
5. Fishing Tips section (outside card, no background box)
   - h2: "Fishing Tips for the [Region Name] Region"
   - ul with 5 regional tips
6. Back to [State/Province] button (green #4CAF50, between Tips and Download)
7. Download section (full-width blur, Pro + Free buttons)
8. Footer (Contact, Privacy, Terms only)
```

### Div nesting rules
- `.content-page`, `.container`, `.card` MUST close before the Fishing Tips heading
- Fishing Tips, Back button, Download section are OUTSIDE the card (no background box)
- Correct:
```html
</div></div></div>  <!-- closes card, container, content-page -->
<h2>Fishing Tips for the [Region]</h2>
...
<div style="text-align:center;..."><a href="..." class="btn" style="...">&larr; Back to [State/Province]</a></div>
<!-- Download -->
<div class="download">...</div>
```

### Title format
- `<title>`: `"Fishing in the [Region Name] Region | CatchTales"`
- `<h1>`: `"Fishing in the [Region Name] Region"`
- Meta description: `"Explore fishing in the [region area] of [state/province]. [Key waters] and nearby waters for [species]."`

### Distance tag format
- Contents of `<span class="distance">` must be location-based, NOT drive-time-based
- Correct: `"Mille Lacs Lake Inlet, Minnesota"` or `"Gimli & Winnipeg Beach, Manitoba"`
- Wrong: `"45 min north of Winnipeg"` or `"0 km — in the city"`

### Back buttons
- **Top:** Text link in page-title div pointing to parent state/province hub
  - `<a href="/fishing-in-united-states/[state]/" style="...">&larr; Back to [State]</a>`
- **Bottom:** Green button between Fishing Tips and Download section
  - `<div style="text-align:center;margin-top:16px;"><a href="..." class="btn" style="display:inline-block;padding:12px 24px;background:#4CAF50;color:#fff;border-radius:10px;font-weight:700;text-decoration:none;">&larr; Back to [State/Province]</a></div>`

### Download buttons
- Both `.btn-primary` (Pro) and `.btn-secondary` (Free) CSS classes must be defined in the page style
- `.btn-primary`: teal filled button
- `.btn-secondary`: transparent border button

### Div nesting rules (CRITICAL — broken nesting causes overlay bugs)

Every region page MUST have this exact div structure:
```html
<div class="content-page">           ← opens content-page
  <div class="container">             ← opens container (REQUIRED!)
    <div class="card">               ← opens card
      ...numbered entries...
    </div>                             ← closes card
  </div>                               ← closes container
</div>                                 ← closes content-page

<h2>Fishing Tips for the...</h2>      ← Fishing Tips OUTSIDE card
```

**WARNING:** If `.container` is missing, the closing `</div>` that would close it becomes an orphan tag. This causes the browser to close the parent `.content` div prematurely, putting everything below (Fishing Tips, Back button, Download section) **behind the background overlay** — creating an invisible "transparent layer" on top of those elements.

**Verification commands to run after any batch edit on region pages:**
```bash
# 1. Check all pages have .container div
for f in fishing-near/*/index.html; do
  if grep -q 'content-page' "$f" && ! grep -q 'class="container"' <(grep -A3 'content-page' "$f" 2>/dev/null); then
    echo "MISSING container: $f"
  fi
done

# 2. Check for orphan closing divs (more closes than opens before Fishing Tips)
for f in fishing-near/*/index.html; do
  tips=$(grep -b -o 'Fishing Tips' "$f" | cut -d: -f1)
  before=$(head -c "$tips" "$f" | grep -c '</div>')
  opens=$(head -c "$tips" "$f" | grep -c '<div ')
  if [ "$before" -gt "$opens" ]; then
    echo "ORPHAN DIVS: $f (closes=$before, opens=$opens)"
  fi
done

# 3. Check .content-page padding has 3 values (should be: top right bottom left or top right left bottom)
for f in fishing-near/*/index.html; do
  padding=$(grep -oP '\.content-page \{ padding: [^;]+' "$f")
  values=$(echo "$padding" | grep -oP 'clamp\([^)]+\)' | wc -l)
  if [ "$values" -lt 3 ]; then
    echo "WRONG padding format: $f"
  fi
done
```

---

## 🐛 Debugging with Mock Pages

When investigating visual issues on the **website** (overlapping elements, wrong z-index, duplicate content, clipping):

1. **Create a standalone mock page** that mirrors the real page's structure exactly
2. **Wrap each major element** in a colored outline with a `data-layer-name` attribute
3. **Add a toggle button** that adds a CSS class (e.g. `diag-active`) to `<body>` which uses `::before` pseudo-elements to display the layer name on each outlined element
4. **Disable JavaScript/Flutter** if the app overwrites the DOM — keep the page static so layers stay visible
5. **Use distinct colors** for each layer so stacking order is clear
6. **Show z-index and position info** on each element
7. **Delete the mock page** once the bug is fixed (or keep it as a reusable diagnostic)

This technique isolates each element so you can visually pinpoint which layer is causing the issue.

---

---

## 🖼️ Image Rules (Cloud Dashboard & Site)

1. **Never duplicate images across layers.** If the HTML header shows a logo, the Flutter app should NOT also render that logo — pick one layer.
2. **Browser renders images best.** For crisp quality, put images in the HTML layer (not Flutter's CanvasKit). The browser's native downscaling is far superior to CanvasKit's.
3. **Flutter → HTML communication:** Directly set `img.src` via `dart:html` (e.g., `html.document.getElementById('book-image')?.src = '/path.jpg'`). Avoid CSS class toggling or URL hash tricks — they're unreliable.
4. **WebP quality:** Always use `quality=95` when converting from PNG to WebP. This is near-lossless at ~75% smaller files.
5. **When resizing images in Flutter** (if they must be in Flutter), always add `filterQuality: FilterQuality.high` to prevent aliasing.
6. **If an image looks bad in Flutter but clean in the browser,** the issue is CanvasKit downscaling. Move the image to the HTML layer.

---

## 📐 Dashboard Header Layout (Cloud Page)

The cloud dashboard header uses a **side-by-side layout**:

```
┌──────────┬──────────────────────────────────────┐
│  Book    │  Nav Links                          │
│  Image   │  Home  Features  Blog  Dashboard ...│
│  150x150 │                                      │
└──────────┴──────────────────────────────────────┘
┌──────────────────────────────────────────────────┐
│  Flutter Canvas (below header)                   │
└──────────────────────────────────────────────────┘
```

1. **Book image is in the HTML layer** (not Flutter) — browser renders it crisp
2. **Image size: 150×150 px** — this keeps the header compact while remaining clear
3. **Nav sits to the right** of the image, vertically centered
4. **Flutter padding must match** the total header height (150px image + padding ≈ 170px)
5. **Image swaps** are done by Flutter directly setting `img.src` on the HTML element

---

## 🎨 Site Design System (Style Guide)

Maintained for unity across all pages. If you add a style, match these values exactly.

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Dark navy | `#0A1628` | Body background, header bg (rgba) |
| Cyan | `#00BCD4` | Primary accent (buttons, links, highlights) |
| Neon green | `#76FF03` | Secondary accent (hover, active nav, stats) |
| Light steel | `#B0C4DE` | Nav links, secondary text |
| Muted steel | `#8899AA` | Stats labels |
| Steel blue | `#99B0CC` | Card text, footer links |
| White | `#FFFFFF` | Main text, headings |
| Dark teal | `#003544` | Text on cyan buttons |
| Gold | `#FFD54F` | Badge text |

### Cloud Dashboard Colors (Flutter)

| Color | Hex | Usage |
|-------|-----|-------|
| Near-black | `0xCC000000` | Dashboard body bg |
| Dark surface | `0xCC0A0A0A` | Card/section bg |
| Sidebar | `0xFF050505` | Sidebar bg |
| Border | `0xFF1A1A1A` | Dividers, borders |
| Muted text | `0xFF666666` | Secondary labels |
| Neon green | `0xFF76FF03` | Active tab, accents |
| Green dim | `0xFF4CAF50` | Sub-accent |
| White | `0xFFFFFFFF` | Primary text |

### Typography

| Property | Value |
|----------|-------|
| Font stack | `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif` |
| Headings (hero) | `'Bungee', sans-serif` |
| Body size | `clamp(15px, 1.1vw, 17px)` |
| Nav link size | `clamp(13px, 1.1vw, 14px)` |
| Footer link size | `clamp(14px, 1.5vw, 18px)` |
| Card title size | `clamp(0.9em, 2.5vw, 1em)` |
| Card text size | `clamp(12px, 1.8vw, 13px)` |
| Button size | `clamp(14px, 1.2vw, 16px)` |
| Min height (touch) | `44px` for all nav links and buttons |

### Header (Main Site — All Pages)

| Property | Value |
|----------|-------|
| Layout | Logo centered above, nav centered below |
| Logo size | `clamp(80px, 16vw, 200px)` height, auto width |
| Logo border-radius | `6px` |
| Header padding | `clamp(16px,2.5vw,24px) top, 8px bottom` |
| Nav link spacing | `margin-right: 18px` (desktop), `gap: 4px 12px` (mobile) |
| Nav hover underline | `::after` pseudo-element, 2px, green, grows on hover |
| Mobile breakpoint | `600px` — nav stays inline (no hamburger) |
| Responsive logo | `clamp(80px, 16vw, 200px)` — shrinks on mobile |

### Header (Cloud Dashboard Page)

| Property | Value |
|----------|-------|
| Position | Fixed at top, `z-index: 200` |
| Layout | Book image **left**, nav **right**, side-by-side |
| Book image size | **150×150 px**, `border-radius: 16px` |
| Background | `rgba(10,22,40,0.85)` with `backdrop-filter: blur(12px)` |
| Bottom border | `1px solid rgba(255,255,255,0.06)` |
| Flutter top padding | **170px** to clear header |

### Underwater Background

| Property | Value |
|----------|-------|
| Position | Fixed, full-screen |
| Z-index | `0` (main site), `-1` (cloud page) |
| Image | `underwater.webp` |
| Image opacity | `0.6` |
| Overlay | `rgba(10,22,40,0.45)` on top of image |
| Fish (swim-fish) | 3-5 fish, `position: absolute`, animated `swim` keyframe |

### Cards

| Property | Value |
|----------|-------|
| Background | `rgba(14,20,34,0.45)` with `backdrop-filter: blur(12px)` |
| Border | `1px solid rgba(255,255,255,0.05)` |
| Border-radius | `14px` |
| Hover | `transform: translateY(-4px)`, stronger border/shadow |
| Icon size | `clamp(28px, 3.5vw, 32px)` |

### Buttons

| Property | Value |
|----------|-------|
| Border-radius | `12px` |
| Font-weight | `600` |
| Min-height | `48px` |
| Padding | `clamp(12px,2vw,14px) clamp(24px,3vw,32px)` |
| `.btn-primary` | Background `#00BCD4`, text `#003544`, shadow glow |
| `.btn-secondary` | Transparent bg with cyan border, cyan text |
| Hover | `translateY(-3px)`, stronger shadow |

### Footer

| Property | Value |
|----------|-------|
| Padding | `clamp(20px, 3vw, 30px) 0` |
| Border-top | `1px solid rgba(255,255,255,0.06)` |
| Link color | `#99B0CC` |
| Link hover | `#00BCD4` |
| Link gap | `clamp(14px, 2.5vw, 28px)` |
| Copyright color | `#667` |

### Responsive Breakpoints

| Breakpoint | Changes |
|------------|---------|
| `≤ 960px` | Content max-width container |
| `≤ 700px` | Stats grid → 2 columns; nav link spacing reduced |
| `≤ 600px` | Nav stays inline (no hamburger), smaller tap targets |
| `≤ 480px` | Photo strip aspect ratio changes |

### Region/Fishing Pages

| Property | Value |
|----------|-------|
| Layout | `.content` max-width `960px`, centered |
| Card background | `rgba(14,20,34,0.5)`, `backdrop-filter: blur(12px)` |
| Card border-radius | `16px` |
| Distance label | `.distance`, color `#76FF03`, above entry name |
| Content text | `clamp(14px, 1.2vw, 15px)`, color `#B0C4DE` |
| Section title | `<h2>`, color white, margin-top `clamp(20px,3vw,28px)` |

### Image Standards

| Property | Value |
|----------|-------|
| Format | Prefer **WebP** over PNG (except small favicons/icons) |
| WebP quality | **95** for near-lossless quality |
| Book images (header) | **150×150 px**, in HTML layer (not Flutter) |
| Screenshots | Use WebP, match phone frame aspect ratio |
| Topo maps | WebP, converted from JPG source

---

## 🔄 Debugging Workflow (from real session)

When investigating visual issues (overlapping elements, wrong z-index, duplicate content, clipping, poor image quality):

1. **Create a standalone mock page** that mirrors the real page's structure exactly
2. **Wrap each major element** in a colored outline with a `data-layer-name` attribute
3. **Add a toggle button** that adds a CSS class (e.g. `diag-active`) to `<body>` which uses `::before` pseudo-elements to display the layer name on each outlined element
4. **Disable JavaScript/Flutter** if the app overwrites the DOM — keep the page static so layers stay visible
5. **Use distinct colors** for each layer so stacking order is clear
6. **Show z-index and position info** on each element
7. **Have the user identify the problematic element by letter label** — don't guess
8. **Delete the mock page** once the bug is fixed

---

*Last updated: 2026-07-23 (added video concept preview workflow)*
*If Louis corrects a behavior, add it here immediately.*

---

## 9. Video Concept Preview Workflow

When creating a video concept/preview for YouTube, use this repeatable process:

### Step 1: Write Script from Existing Content
- Pull content from the blog (`~/catchtales-site/blog/`) or app features
- Break into scenes with timecodes, narration text, and visual descriptions
- Keep each scene 4-8 seconds for preview pacing

### Step 2: Create an Interactive HTML Preview Page
- Build a single self-contained HTML page that acts like a video player
- Structure: scene array with `{id, start, duration, bg, fg, fgClass, text, caption, ts}`
- Include: play/pause, progress bar, prev/next scene, speed control, keyboard shortcuts (space=play, arrows=skip)
- Use `setInterval` with `performance.now()` for accurate wall-clock timing (NOT `setTimeout` chaining or `requestAnimationFrame` delta — those have proven unreliable)
- Timing formula: `elapsedTotal = (performance.now() - playStartTime) / 1000 * speed`
- Scene lookup: iterate scenes array accumulating durations to find current scene

### Step 3: Capture Phone Screenshots via ADB
```bash
# Check device
adb devices
# Get screen size
adb shell wm size
# Navigate using taps (adjust coordinates for 1080x2316 screen)
adb shell input tap X Y
# Capture screenshot
adb shell screencap -p /sdcard/screen_name.png
adb pull /sdcard/screen_name.png ~/catchtales-site/images/walkthrough/screen-name.png
# Navigate app:
# - 3-dot menu: tap 1040 40
# - Bottom nav labels (Catches=1, Counter=2, Brag Board=3, Map=4): tap X 2270 where X ≈ 270*index+135
# - Menu items: tap 950 Y where Y increases by ~80 per item
# - Back: adb shell input keyevent KEYCODE_BACK
```

### Step 4: Add Voiceover Narration
```bash
# Install gTTS in temp venv
cd /tmp && python3 -m venv tts_env
source tts_env/bin/activate
pip install gtts

# Generate audio for each scene
python3 -c "
from gtts import gTTS
text = 'Your narration text'
tts = gTTS(text=text, lang='en', slow=False)
tts.save('/home/louis/catchtales-site/audio/scene-name.mp3')
"
```

### Step 4b: Download Free Stock Photos/Videos (Pexels + Pixabay APIs)
Two free stock APIs are available:

**Pexels API** (photos + videos):
```bash
# Search
curl -s -H "Authorization: YCW80jSVlXkqDx7XuSxOZVQja6aXSXdgaW9OaafCXEbdhmb7jIHfqpDN" \
  "https://api.pexels.com/v1/search?query=walleye+fish&per_page=5" | python3 -m json.tool
# Download
curl -sL "<large_image_url>" -o ~/catchtales-site/images/name.webp
```

**Pixabay API** (photos + videos + vectors):
```bash
# Search
curl -s "https://pixabay.com/api/?key=56823444-e87c08005b791f9749a63f80b&q=walleye+fishing&image_type=photo&per_page=5"
# Download
curl -sL "<image_url>" -o ~/catchtales-site/images/name.jpg
```
- Save MP3s to `~/catchtales-site/audio/`
- Map audio files to scenes by index (01-intro.mp3, 02-scene-name.mp3, etc.)
- Add `<audio id="voAudio" preload="auto"></audio>` to the player HTML
- In `renderScene()`: set `audio.src`, call `audio.play()`
- In `stopPlayback()`: call `audio.pause()`

### Step 5: Deploy & Share
```bash
cd ~/catchtales-site
git add -A
git commit -m "Add video preview: [video name]"
git push
# Wait ~1 min for GitHub Pages deploy
```
Share URL: `https://catchtales.com/[page-name].html`

### Key Lessons (from debugging)
- `requestAnimationFrame` passes absolute timestamp, NOT delta — using it as delta causes instant playback
- `setTimeout` chaining can fire erratically — use `setInterval` + `performance.now()` for reliable timing
- Always reset `playStartTime` when resuming from pause
- Keep preview total under 3 minutes for quick iteration

### Video Watermark Standard
- **Always use** `/images/catchtales-logo-video.png` (source: `~/CatchTales/assets/catchtales.png`) for the top-left watermark
- **Size: 2x** — CSS height of `clamp(72px, 12vw, 108px)`
- Apply to both the interactive preview page AND the outro/end screen scene

### Video Asset Organization Standard
- **Every video project gets its own folder** at `~/catchtales-site/images/[video-name]/`
- Copy ALL assets into that folder: photos, screenshots, audio, logos
- No mixing with other project files — the folder is self-contained
- Include an `audio/` subfolder with all narration MP3s
- This makes importing into CapCut drag-and-drop simple with no hunting for files
- Example: `~/catchtales-site/images/how-to-walleye-video/`
