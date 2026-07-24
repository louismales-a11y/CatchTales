# Session Log

> Update this at the end of every session so the next session starts with full context.

---

## 2025-07-20 — Session 13 — Complete US 50-State Fishing Guide + App Integration

### What we did

**Built all remaining 24 US states with fishing region pages:**
- Built Nebraska, Nevada, New Hampshire, New Jersey, New Mexico (hand-crafted real entries)
- Built New York (all 6 regions with 40 curated entries each)
- Built North Carolina, North Dakota, Ohio, Oklahoma, Oregon, Pennsylvania, Rhode Island, South Carolina, South Dakota, Tennessee, Texas, Utah, Vermont, Virginia, Washington, West Virginia, Wisconsin, Wyoming
- 267 region pages total with standardized formatting
- All topo maps copied and converted to WebP

**Standardized website UI across ALL pages:**
- Centered logo + centered horizontal nav below (no hamburger menu anywhere)
- All 11 nav links consistent: Home, Features, US Fishing, Canada Fishing, Blog, Pro Login, About, FAQ, Contact, Privacy, Terms
- Footer matches nav with all 11 links
- max-width:960px on all pages
- Region page footer format: Fishing Tips → CTA → Back button
- Fixed CSS brace issues on all auto-generated pages
- Fixed twitter:card from "summary" to "summary_large_image" on 458 pages
- Canada Fishing listed before US Fishing in nav
- Removed hidden nav CSS on Canada/US landing pages

**Fishing Guides integrated into app:**
- Added Fishing Guides feature (14th feature) to features page
- Converted all website content to JSON (~6.2 MB): 63 hubs, 337 regions, 13,059 spots
- Fixed country detection bug (was marking US as Canada)
- Fixed region screen text wrapping (distance now below name)
- Fixed splash screen: replaced CTOTGA catfish with CatchTales logo
- Updated What's New: only major features listed, rest = "Bug fixes and performance improvements"
- Version bumped to 2.14.64, all APKs built and deployed

**SEO:**
- Fixed twitter:card on all pages
- Cleaned up sitemap (removed broken /download/ URL)
- Verified all SEO checks pass

### Current state
| Item | Value |
|------|-------|
| Source | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| Version | 2.14.64 |
| Website | catchtales.com (remote: `louismales-a11y/catchtales-site.git`) |
| US States | **COMPLETE — 50/50 with 267 region pages** |
| Canada | **COMPLETE — 13/13 provinces with ~70 region pages** |
| Total fishing spots | 10,541 on website, 13,059 in app |
| APK downloads | `~/catchtales-site/download/` (free + pro + dev) |
| APK backups | `~/Desktop/apk backups/` |

---

## 2026-07-21 — Session 14 — Fixed duplicate logo on cloud dashboard + debugging mock page technique

### What we did

**Diagnosed layer issue on cloud dashboard page:**
- User reported a "layer covering page that includes part of the new logo"
- Created `cloud-mock.html` — a standalone diagnostic page with colored outlines on each element
- Used `data-layer-name` attributes + CSS `::before` pseudo-elements to label layers
- Identified that the `prologinbook.webp` logo appeared in TWO layers:
  - **Element B:** HTML fixed site header (`z-index: 200`)
  - **Element E:** Flutter Login Screen (inside canvas)

**Fixed duplicate logo:**
- Removed `Image.network('/images/prologinbook.webp')` from:
  - `lib/screens/login_screen.dart` — login form
  - `lib/screens/dashboard_screen.dart` — dashboard header
  - `lib/screens/about_tab.dart` — about section
- Rebuilt Flutter web app (`flutter build web --release`)
- Deployed to `~/catchtales-site/cloud/`
- Committed and pushed to GitHub

**Added debugging technique to docs:**
- Added "Debugging with Mock Pages" section to `CANONICAL-SITE.md` (website docs)
- Added same section to `CODING_STANDARDS.md` (Flutter app standards)

### Current state
| Item | Value |
|------|-------|
| Source | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| Version | 2.14.64 |
| Website | catchtales.com (remote: `louismales-a11y/catchtales-site.git`) |
| Cloud dashboard | Logo removed from Flutter app — only HTML header shows it |

### Standards updated this session
- Debugging with Mock Pages (added to CANONICAL-SITE.md and CODING_STANDARDS.md)
- Header standard: centered logo, nav below centered
- Nav standard: 11 links, Canada before US
- Footer standard: matches nav
- Region page CTA format
- What's New discipline (only major features)
- UI consistency checklist (grep commands before deploy)

---

## 2026-07-22 — Session 15 — YouTube Channel Setup

### What we did

**Created CatchTales YouTube channel:**
- Channel URL: https://www.youtube.com/@CatchTales-y9c
- Channel banner: underwater background with logo + "For Bragging Rights!" / "Canada & United States" / "catchtales.com"
- Avatar: CatchTales logo at 35% zoom, offset (-4,-9)
- Video watermark: 150×150 catchtales.png

**Uploaded 2 videos:**
1. **CatchTales App Walkthrough** — 20 onboarding screenshots walkthrough (100+ views on day 1)
2. **Top 5 Walleye Fishing Spots in Ontario** — featuring Lake of the Woods, Lac Seul, Bay of Quinte, Rainy Lake, Lake Erie Western Basin

**YouTube assets prepared (screenshots cleaned up from working directory):**
- 20 walkthrough screenshots (app onboarding)
- Feature & demo screenshots
- Channel banner, avatar, watermark, thumbnail

**Added YouTube links to website (commit pending):**
- Footer on all pages: Home, Features, About, Contact
- About page: "Subscribe on YouTube" link in Designed By section
- Contact page: YouTube listed as contact method

---

## 2026-07-23 — Session 16 — YouTube Video Concept Preview + Voiceover Demo

### What we did

**Created How to Catch Walleye video concept:**
- Wrote script based on blog post: `~/catchtales-site/blog/how-to-catch-walleye-tips-for-beginners/`
- Built storyboard page: `how-to-walleye-storyboard.html` (scene-by-scene with image thumbnails)
- Built interactive video preview: `how-to-walleye-video.html` (playable with scenes, captions, timeline)

**Captured phone screenshots via ADB:**
- 8 screenshots from the live app (catches, solunar, weather, map, fish ID, tackle, brag board, menu)
- Saved to `~/catchtales-site/images/walkthrough/`

**Generated AI voiceover narration:**
- Used gTTS (Google Text-to-Speech) to generate 28 MP3 files
- Synced audio to scene progression in the interactive preview
- Voiceovers saved to `~/catchtales-site/audio/`

**Fixed video timing bugs:**
- First attempt used `requestAnimationFrame` delta incorrectly (interprets absolute timestamp as ms/frame)
- Second attempt used `setTimeout` chaining (fired erratically)
- Final working approach: `setInterval` + `performance.now()` for wall-clock-based timing

**Documented process:**
- Added "Video Concept Preview Workflow" section to CODING_STANDARDS.md (Section 9)
- Includes: script writing, interactive HTML preview, ADB screenshot capture, voiceover generation, deployment

### Current state
| Item | Value |
|------|-------|
| Source | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| Version | 2.14.68 |
| Website | catchtales.com (remote: `louismales-a11y/catchtales-site.git`) |
| YouTube | https://www.youtube.com/@CatchTales-y9c |
| YouTube Channel ID | UCOa2lPPcIJwbanmW1XX1eBA |
| YouTube User ID | Oa2lPPcIJwbanmW1XX1eBA |
| Videos | 2 (Walkthrough + Top 5 Walleye Ontario) |
| Video concept preview | https://catchtales.com/how-to-walleye-video.html |
| Storyboard | https://catchtales.com/how-to-walleye-storyboard.html |
| US States | **COMPLETE — 50/50 with 267 region pages** |
| Canada | **COMPLETE — 13/13 provinces with ~70 region pages** |
| Total fishing spots | 10,541 on website, 13,059 in app |
| APK downloads | `~/catchtales-site/download/` (free + pro + dev) |
| APK backups | `~/Desktop/apk backups/` |

---

## 2026-07-23 — Session 16 (continued) — Video Concept to Published

### What we did

**Created and published How to Catch Walleye video:**
- Wrote script based on blog post, built interactive preview page
- Captured phone screenshots via ADB
- Generated AI voiceover with gTTS (28 MP3 files)
- Fixed timing bugs (setInterval + performance.now() approach)
- Downloaded 10+ free stock photos from Pexels + Pixabay APIs
- Updated all 28 slides with real photos (no repetitive illustrations)
- Removed all emojis, adjusted text positioning per feedback
- Created dedicated asset folder: `~/catchtales-site/images/how-to-walleye-video/`
- Exported and published to YouTube

**YouTube channel status:** 3 videos live
| Item | Value |
|------|-------|
| Video 1 | CatchTales App Walkthrough |
| Video 2 | Top 5 Walleye Fishing Spots in Ontario |
| Video 3 | How to fish for Walleye |
| Channel | https://www.youtube.com/@CatchTales-y9c |
| Channel ID | UCOa2lPPcIJwbanmW1XX1eBA |

**Standards created this session:**
- Video Concept Preview Workflow (Section 9 in CODING_STANDARDS.md)
- Video Watermark Standard
- Video Asset Organization Standard (dedicated folder per project)
- Pexels + Pixabay API keys saved for stock photo searches

---

## 2026-07-23 — Session 17 — Fishing Safety Tips Video

### What we did

**Created and published Fishing Safety Tips video:**
- Wrote 15-scene script based on blog post (2:44 target, expanded to ~5:00 for audio sync)
- Downloaded 12 stock photos from Pexels + Pixabay
- Downloaded 5 video clips (storm timelapse, lightning, lake drone, boat, angler)
- Generated 15 voiceover MP3s with gTTS
- Built interactive preview page: https://catchtales.com/fishing-safety-video.html
- Built production reference: https://catchtales.com/fishing-safety-production.md
- Cleaned up old/mismatched audio files
- Published to YouTube

**YouTube channel status:** 4 videos live
| Item | Value |
|------|-------|
| Video 1 | CatchTales App Walkthrough |
| Video 2 | Top 5 Walleye Fishing Spots in Ontario |
| Video 3 | How to fish for Walleye |
| Video 4 | Fishing Safety Tips |
| Channel | https://www.youtube.com/@CatchTales-y9c |
| Channel ID | UCOa2lPPcIJwbanmW1XX1eBA |
| Total views on walkthrough | 100+ (day 1)

---

## 2026-07-24 — Session 18 — Best Fishing Times — Solunar Explained Video

### What we did

**Created full video production for "Best Fishing Times — Solunar Explained":**
- Wrote 17-scene script based on blog post `~/catchtales-site/blog/best-fishing-times-solunar/`
- Downloaded 16 stock photos from Pixabay (verified all distinct after feedback)
- Generated 17 natural-sounding voiceover files using edge-tts (en-US-GuyNeural) — replaced gTTS
- Built interactive preview page: `solunar-video.html` with play/pause, scene nav, speed control
- Captured app screenshot via ADB (solunar screen — asked user first)
- Created production reference: `solunar-production.html` with full scene-by-scene CapCut guide

**Established mandatory intro/outro format:**
- Intro: underwater background + logo + catchtales.com + "Welcome to CatchTales..." (5-6s)
- Outro: underwater background + logo + website + "...Tight Lines!" (8s)

**Updated Video Production Workflow standards (CODING_STANDARDS.md §9):**
- Replaced gTTS → edge-tts (GuyNeural) as default voice
- Documented exact folder structure: `images/[video-name]/audio/` for MP3s
- Added image verification step (check for duplicates)
- Added intro/outro format as mandatory
- Added production reference creation step
- Added rule: ask user before ADB screenshot capture
- Audio naming: `{NN}-{scene-id}.mp3`
- Audio path in HTML: `` `/images/[video-name]/audio/${index+1}-{id}.mp3` ``

### Current state
| Item | Value |
|------|-------|
| Source | `~/CatchTales/` (remote: `louismales-a11y/CatchTales.git`) |
| Version | 2.14.68 |
| Website | catchtales.com (remote: `louismales-a11y/catchtales-site.git`) |
| YouTube | https://www.youtube.com/@CatchTales-y9c |
| Videos | 4 published, 1 in production (Solunar) |
| Video preview | https://catchtales.com/solunar-video.html |
| Production ref | https://catchtales.com/solunar-production.html |
| US States | **COMPLETE — 50/50** |
| Canada | **COMPLETE — 13/13 provinces** |
| Total fishing spots | 10,541 on website, 13,059 in app |

### Next steps for next session
- Create the Solunar video in CapCut using the production reference
- Publish to YouTube
- Pick next blog post for video #6
