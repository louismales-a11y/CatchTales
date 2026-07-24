# CatchTales — Web & App Glossary

Terms I use when we're working together, explained simply.

---

## 🎨 Frontend (What You See)

| Term | Meaning | Example |
|------|---------|---------|
| **HTML** | The structure/content of a webpage. Think: bones. | `<h1>Hello</h1> <p>Some text</p>` |
| **CSS** | The styling of a webpage. Think: skin, clothes, makeup. Colors, sizes, layout. | `color: blue; font-size: 20px;` |
| **Class** | A reusable CSS label you put on HTML elements. | `<button class="nav-toggle">` — the class `nav-toggle` gets styled in CSS |
| **Inline style** | CSS written directly on the HTML element, not in a class. Overrides everything else. | `style="height: 60px;"` — we had this bug! |
| **`clamp()`** | A CSS function that sets a min, preferred, and max value. Makes things responsive. | `height: clamp(80px, 16vw, 200px)` — at least 80px, prefers 16% of viewport, at most 200px |
| **`@media` query** | CSS that only applies at certain screen sizes. | `@media (max-width: 600px) { ... }` — only on phones |
| **Viewport** | The visible area of the browser window. | 1920×1080 on a desktop, 390×844 on an iPhone |
| **Responsive** | The site adapts to any screen size automatically. | Our site works on both 27" monitors and iPhones |
| **Flexbox** | A CSS layout mode for arranging items in a row or column. | `display: flex; justify-content: space-between;` — pushes logo left, nav right |
| **Breakpoint** | The screen width where layout changes (e.g., 600px). | Below 600px = mobile layout, above = desktop |
| **Hamburger menu** | The ☰ icon that opens a hidden menu on mobile. We used to have one, now we show text links instead. |
| **WebP** | A modern image format that's much smaller than PNG/JPG. | `catchtales-logo.webp` is 58KB vs `catchtales-logo.png` at 328KB |
| **Lazy loading** | Images load only when they're about to appear on screen. Saves bandwidth. | `loading="lazy"` on images |
| **CDN** | Content Delivery Network — servers worldwide that cache your site for fast loading. GitHub Pages uses one. |
| **Cache** | Your browser saves files locally so it doesn't re-download them. Sometimes causes old content to show. | `Ctrl+F5` = hard refresh to clear cache |

## 🧠 Backend & Hosting

| Term | Meaning | Example |
|------|---------|---------|
| **Git** | Version control — tracks every change to the code. | `git add`, `git commit`, `git push` |
| **GitHub** | Website that hosts Git repositories. | `github.com/louismales-a11y/catchtales-site` |
| **GitHub Pages** | Free hosting service — push to `main` branch and your site goes live at catchtales.com |
| **Push** | Upload your local changes to GitHub. | `git push` |
| **Deploy** | Make your code live on the internet. Our site auto-deploys when we push. |
| **Repo** | Repository — the folder that holds all your project's files and history. |
| **Commit** | A saved snapshot of changes with a message describing what was done. | `git commit -m "Fix logo size"` |
| **Remote** | The GitHub copy of your repo (as opposed to your local copy). | `origin	git@github.com:louismales-a11y/...` |
| **Service Worker** | A script that runs in the browser for offline support / caching. We don't use one on the main site. |
| **JSON** | A simple data format for storing structured info. | `version.json`, `manifest.json` |
| **Schema / JSON-LD** | Structured data that tells Google what your page is about. Helps with search rankings. | `BreadcrumbList`, `Article` schemas |

## 📱 Flutter / App

| Term | Meaning | Example |
|------|---------|---------|
| **Flutter** | Google's toolkit for building mobile apps from one codebase. |
| **Dart** | The programming language Flutter apps are written in. |
| **Widget** | A building block in Flutter — buttons, text, images, layouts are all widgets. |
| **Provider** | A pattern for sharing data across the app (theme, auth, catches). |
| **Service** | A singleton class that handles one thing (auth, translation, etc.). |
| **pubspec.yaml** | The file listing your app's name, version, and dependencies. |
| **Flavor** | A variant of the app with different features. We have 3: dev, free, pro. |
| **APK** | Android Package — the installable file for Android phones. |
| **ADB** | Android Debug Bridge — a tool to install APKs via USB. |
| **MethodChannel** | A bridge between Dart (Flutter) and native code (Java/Kotlin). Used for the in-app APK installer. |

## 🌐 Things That Bite Us

| Term | The Problem |
|------|-------------|
| **CSS Specificity** | Inline `style="..."` beats class rules. We lost an hour to this. |
| **Browser Cache** | Your browser saves old files. Changes don't show until you hard refresh. |
| **CDN Cache** | GitHub Pages caches files too — can take 1-2 minutes after push. |
| **`sed` + `&`** | The `&` character in sed means "the whole match", not the literal "&" symbol. Broke our HTML entities. Use Python instead. |

## 🔧 Tools We Use

| Tool | What It Does |
|------|-------------|
| **pi** | Me! The coding agent you're talking to. |
| **curl** | Fetches a webpage from the command line so we can check the live HTML. |
| **grep** | Searches for text in files. `grep -r "logo" *.html` |
| **Python** | Used for batch updates across many HTML files (safer than sed). |
| **ImageMagick / Pillow** | Resizes and optimizes images. |
| **DevTools (F12)** | Chrome's built-in inspector — see HTML, CSS, network requests, console errors. |
