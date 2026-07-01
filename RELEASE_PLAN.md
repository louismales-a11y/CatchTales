# Best Fish Buddy - Release & Website Plan

## 🌐 Free Website Options
- **GitHub Pages** — free, custom domain possible
- **Google Sites** — free, drag & drop
- **Netlify** — free tier, forms, analytics
- **Wix** — free with ads, paid without

Domain ~$12/yr (Namecheap, Google Domains)

## 💰 Selling the App
1. **Google Play Store** — $25 one-time fee, upload APK, set price
2. **Direct sales** — LemonSqueezy or Gumroad (~5% fee vs Google's 30%)

## 🎯 Free vs Pro Strategy

### Free Version
- **Voice tally & recording** — Say "fish buddy jason caught a pike" to tally. Record full catches with photo, weight, length.
- **Selfie camera** — Front-facing camera with 3-second countdown. Snap and save.
- **Basic weather & solunar** — Current conditions, 5-day forecast, moon phase, best fishing times with timeline.
- **Fish ID** — First 10 species only. Full field guide locked.
- **Tackle Box** — Max 5 tackle items. Catalog browsing locked.
- **Catches log** — Max **10 catches**. No delete button — prevents swapping old catches for new.
- **Basic statistics** — Total count, species names. Advanced insights & badges locked.
- **Ads** — Small banner at bottom. Optional — can upgrade to remove.

### Pro Version ($4.99 one-time or $2.99/yr)
- **Unlimited catches** — No cap. Full edit/delete. Keep your entire fishing history.
- **Cloud Sync** — Backup all catches to Firebase. Restore on any device. Auto-sync optional.
- **Fish Together** — Real-time chat sessions with buddies. Share catches as they happen.
- **Photo backup** — Catch photos upload to cloud storage. Never lose a fish photo.
- **Push notifications** — Get alerts: "Solunar major period in 30 min", "Wind picking up", storm warnings.
- **Advanced statistics & badges** — Species charts, monthly trends, top angler. Achievements: Master Angler, Species Collector, Big Catch, and more.
- **Export / Share** — Share your stats as an image. Export catches to CSV.
- **No ads** — No banners, no interstitials, no interruptions.
- **Offline weather** — Weather data caches automatically. Works without signal.

### Implementation Options
1. **Two separate apps** — Free and Pro on Play Store (manage two codebases)
2. **In-app purchase** — Single app, unlock Pro via Google Play Billing (recommended)
3. **Subscription** — Recurring revenue via Google Play Billing

### Where Ads Come From

**Ad Networks for Apps:**
| Network | Payout | Best For |
|---------|--------|----------|
| **Google AdMob** | Highest | Fishing apps — well-targeted outdoor ads |
| **Facebook Audience Network** | Good | Works alongside AdMob |
| **Unity Ads** | Good | Gaming-style rewarded ads ("watch ad to unlock") |

**Recommended:** **Google AdMob**
- Industry standard for apps
- Integrates with Flutter via `google_mobile_ads` package
- Pays per impression (CPM) or per click (CPC)
- Outdoor/fishing ads pay well because gear is expensive

**Ad Types for Best Fish Buddy:**
- **Small banner** at bottom of catch list (non-intrusive)
- **Interstitial** between screens (only for free users)
- **Rewarded video** — "Watch an ad to unlock cloud sync for 24 hours"

**Estimated Revenue:**
- 1,000 banner impressions ≈ $1-5
- 1,000 interstitial impressions ≈ $10-50
- Not enough to live on, but covers server costs

### Recommended: In-app Purchase
- Single app download
- Free features work immediately
- Pro features unlock via one-time purchase
- Use `in_app_purchase` Flutter package
- Feature flags in code: `bool get isPro => _purchaseCompleted;`

## 📱 Distribution
- **Android:** Google Play Store APK
- **iOS:** App Store (requires buddy with Mac)
- **Windows:** Microsoft Store or direct .exe download
- **Website:** Landing page with download links

## ℹ️ Branding
- Studio: **Maison Louis Design**
- Email: **BestfishBuddy@gmail.com**
- GitHub: github.com/louismales-a11y/BestFishBuddy

## 💰 Ad Implementation Notes (from 7/1/2026 conversation)

### Cost to implement ads
- AdMob account: Free
- google_mobile_ads package: Free
- Showing ads: Free
- Getting paid: Free ($100 minimum payout threshold)
- Sign up: https://admob.google.com

### Ad Types for Fishing App
- Banner: $1-5 CPM (bottom of catch list, non-intrusive)
- Interstitial: $10-50 CPM (between screens, free users only)
- Rewarded Video: $15-100 CPM (best payout — user chooses to watch)

### Rewarded Video Ideas
- "Watch ad to unlock Cloud Sync for 24h"
- "Watch ad to backup photos today"
- "Watch ad to remove ads for a week"

### Free vs Pro Strategy
- Free: Voice tally, selfie cam, basic weather/solunar, fish ID, tackle, 50 catches max, basic stats, optional banner ad
- Pro ($4.99 one-time or $2.99/yr): Unlimited catches, Cloud Sync, Fish Together, photo backup, push notifications, advanced stats & badges, export/share, no ads, offline caching

### Recommended: Single app with in-app purchase (Google Play Billing)
- Use `in_app_purchase` Flutter package
- Feature flags: `bool get isPro => _purchaseCompleted;`
- User upgrades without reinstalling

## 🌐 Alternative Distribution (Outside Play Store & App Store)

### Sideloading (Android)
- **Direct APK download** from your website (already have this!)
- **GitHub Releases** — free, already set up, easy download
- **Amazon Appstore** — alternative Android store, low competition for fishing apps
- **F-Droid** — free open-source app store (if you make the app open source)

### Sideloading (iOS)
- **TestFlight** — Apple's own beta testing (free, up to 10,000 testers)
- **Enterprise certificate** — expensive and risky (not recommended)

### Free Marketing Channels
| Channel | Type | Effort |
|---------|------|--------|
| **Facebook Groups** — fishing groups, lake-specific groups | Social | Low |
| **Reddit** — r/Fishing, r/FishingForBeginners, local subs | Community | Low |
| **YouTube** — fishing content creators, review channels | Video | Medium |
| **TikTok** — short fishing clips with app demo | Short video | Medium |
| **Instagram** — fishing photos with "tracked with BestFishBuddy" | Visual | Low |
| **Google Business Profile** — free listing when searched | Search | Low |
| **Product Hunt** — launch day traffic (if polished enough) | Launch | High |
| **Fishing forums** — BassResource, WalleyeCentral, etc. | Niche | Low |
| **Local tackle shops** — flyer with QR code to download | Offline | Low |

### Recommended Free Strategy
1. Host APK on **GitHub Releases** (already done)
2. Create **short URL** (already have https://tinyurl.com/2xrmumt9)
3. Share in **Facebook fishing groups** + **Reddit fishing subs**
4. Put QR code on a flyer at **local bait & tackle shops**
5. When ready, launch on **Product Hunt** for free traffic

## 🔒 Feature Gating (Free vs Pro)

### Pro Features to Lock
- 🗺️ **Map screen** — show lock overlay with upgrade button
- ☁️ **Cloud Sync** — upload/download catches (can view status, can't sync)
- 🎣 **Fish Together** — sessions & chat (can see screen, can't create)
- 📸 **Photo Backup** — Firebase Storage upload
- 🔔 **Push Notifications** — weather alerts & reminders
- 📤 **Share Stats** — export as image
- 📊 **Advanced Insights** — personal records, badges, monthly averages
- 📈 **Catch limit** — free users capped at **10 catches max**. No delete button in free — prevents deleting old catches to make room for new ones.
- 📱 **Anglers** — free capped at 3 anglers

### What Stays Free
- Voice tally & recording
- Selfie camera
- Basic weather & solunar
- Basic statistics (total count, species names only)
- Calendar heatmap (limited view)

### What Gets Limited in Free
- **Fish ID** — show first 10 species, rest locked with upgrade prompt
- **Fish ID** — first 10 species visible, full catalog + details + Wikipedia lookup locked
- **Tackle Box & Catalog** — max 5 tackle items, catalog browsing locked 

### Implementation Pattern
```dart
// Feature gate helper
bool hasAccess(String feature) {
  if (isPro) return true;
  switch (feature) {
    case 'map': return false;
    case 'cloud_sync': return false;
    case 'catch_limit': return _catches.length < 50;
    default: return true;
  }
}
```

### Upgrade Prompts
- Show lock icons (🔒) on Pro features in menus
- Grayed-out buttons that open upgrade dialog on tap
- Banner at top of free-limited screens: "Upgrade to Pro for unlimited access"
- After saving catch #48, 49: show "Only 1-2 catches left in free version"
- At catch #50: block saving, show upgrade screen

## 💵 Ongoing Costs to Run the App

### Free Services
| Service | Notes |
|---------|-------|
| Voice recognition | On-device, no API calls |
| SQLite database | Local on phone |
| OpenStreetMap tiles | Free map tiles, no API key |
| Fish ID data | Built into the app |
| Selfie camera | Phone hardware |
| GitHub source code & releases | Free hosting |
| Firebase Auth (anonymous) | No cost |

### Paid Services
| Service | Free Tier | Overage Cost |
|---------|-----------|--------------|
| **OpenWeatherMap API** | 1,000 calls/day | ~$0.001/call after limit |
| **Google Places API** | $200/mo free credit | Unlikely to exceed with light use |
| **Firebase Firestore** | 1GB stored, 50K reads/day, 20K writes/day | $0.108/read, $0.018/write, $0.20/GB after free tier |
| **Firebase Storage (photos)** | 5GB storage, 20K downloads/day | **$0.026/GB/month** — biggest potential cost |
| **Firebase Cloud Messaging** | Free | $0 |
| **Domain name** | ~$12/year | $12/yr |

### Biggest Cost Drivers
1. **Photo backup** — 1 photo = ~2-3MB. 100 users × 20 photos = 4-6GB (near free limit)
2. **OpenWeatherMap** — Heavy users checking weather multiple times daily could exceed 1,000 calls
3. **Firestore reads** — Loading catch lists, syncing sessions

### Estimated Monthly Cost
- **0-100 users:** ~$0 (all within free tiers)
- **100-1,000 users:** ~$5-20/mo (storage & API overages)
- **1,000-10,000 users:** ~$50-200/mo (scaling up)

## 🤖 AI Fish ID (Photo Recognition)

### How It Would Work
1. User takes a photo (selfie camera or gallery)
2. Photo sent to AI recognition service
3. Service returns predicted species with confidence scores
4. App auto-fills the species field, user confirms/corrects

### Options

**Option 1: Google Cloud Vision API**
- Cost: **$1.50/1,000 images** (first 1,000/month free)
- Can detect common objects but not trained specifically for fish species
- Would need custom model training for accurate fish ID
- Setup: Enable Cloud Vision API in Google Cloud Console

**Option 2: Custom TensorFlow Lite Model**
- Cost: **Free** (runs on-device, no server)
- Requires training a model with thousands of labeled fish photos
- Would need a dataset of ~100+ images per species
- Runs offline, no latency, no privacy concerns
- Setup: Collect training data → train model → embed in app (~2-4 weeks work)

**Option 3: Third-party API (iNaturalist / FishAI)**
- iNaturalist API: Free, uses community ID + AI
- Accuracy varies by region and species
- Requires internet connection

### Recommended Path
1. Start with **Google Cloud Vision** — quickest to implement, zero training needed
2. If it becomes popular, train a **custom TFLite model** for offline use
3. Show top 3 predictions, let user pick or correct

### Estimated Timeline
- Google Cloud Vision integration: **2-4 hours**
- Custom model training: **2-4 weeks** (data collection + training)
- Full implementation with UI: **4-6 hours**

## 🗺️ Fishing Regulations (Canada)

### Current Public Sources
Each province/territory publishes a free PDF or web guide:

| Province/Territory | Source | Format |
|-------------------|--------|--------|
| **Manitoba** | gov.mb.ca/fishing | PDF + Web |
| **Ontario** | ontario.ca/fishing | PDF + Web |
| **Saskatchewan** | saskatchewan.ca/fishing | PDF + Web |
| **Alberta** | alberta.ca/fishing | PDF + Web |
| **British Columbia** | gov.bc.ca/fishing | PDF + Web |
| **Quebec** | quebec.ca/peche | PDF + Web (French) |
| **New Brunswick** | gnb.ca/fishing | PDF + Web |
| **Nova Scotia** | novascotia.ca/fishing | PDF + Web |
| **PEI** | princeedwardisland.ca/fishing | PDF + Web |
| **Newfoundland** | gov.nl.ca/fishing | PDF + Web |
| **Yukon** | yukon.ca/fishing | PDF + Web |
| **NWT** | nwt.ca/fishing | PDF + Web |
| **Nunavut** | gov.nu.ca/fishing | PDF + Web |

### Implementation Options

**Option 1: Link to Government PDFs (easiest)**
- Add a "Regulations" section in Fish ID or a new screen
- List provinces/territories
- Tap opens the PDF in a browser
- Pro: Free, always up-to-date, no maintenance
- Con: Requires internet, leaves the app

**Option 2: Embed Key Rules (medium effort)**
- Extract common limits, sizes, seasons into the app
- Show relevant rules based on GPS location
- Pro: Works offline, in-app experience
- Con: Manual data entry, needs annual updates

**Option 3: Regulations API (if available)**
- Some provinces offer open data APIs
- Would need research per province
- Pro: Automatic updates
- Con: Inconsistent availability

### Recommended Start
- **Option 1** for all 13 provinces/territories — quick links to official PDFs
- **Option 2** later for Manitoba only (your home province) — embed key rules
- Expand to other provinces based on user demand
