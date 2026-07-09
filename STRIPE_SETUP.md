# 🐟 CatchTales — Stripe Payment Link Setup

This guide walks you through setting up automatic Pro code delivery using **Stripe Payment Links** + **Firebase Cloud Functions**.

---

## 📋 Overview

```
User clicks "Buy Pro" in app
        ↓  opens pay.catchtales.com
Stripe Payment Link (hosted checkout page)
        ↓  user pays $4.99
Stripe sends webhook to Firebase Cloud Function
        ↓
Cloud Function generates a unique Pro code (e.g. PRO-A7X3-K9M2)
        ↓
Saves code to Firestore (pro_licenses collection)
        ↓
Emails code to customer via Gmail
        ↓
User opens app → enters code → Pro unlocked! 🎉
```

---

## Step 1: Create a Stripe Account

1. Go to [stripe.com](https://stripe.com) and sign up
2. Choose **Canada** or **USA** as your country (both work)
3. Complete the onboarding (bank account, etc.)
4. Go to **Dashboard → Developers → API keys**
5. Copy your **Secret key** (starts with `sk_live_` or `sk_test_`)

> 💡 Start in **Test mode** first! Use `sk_test_...` keys and test card `4242 4242 4242 4242`.

---

## Step 2: Create a Product & Price in Stripe

1. In Stripe Dashboard → **Products** → **Add Product**
2. **Name:** `CatchTales Pro`
3. **Description:** `Unlock unlimited catches, cloud sync, advanced stats, badges, and more!`
4. **Price:** `$4.99` (or whatever you choose)
5. Click **Save**
6. Copy the **Price ID** (starts with `price_...`)

---

## Step 3: Enable Gmail App Password

Since the Cloud Function sends emails using your Gmail account:

1. Go to [Google App Passwords](https://myaccount.google.com/apppasswords)
2. Select **Mail** and your device, then **Generate**
3. Copy the 16-character app password (looks like `abcd efgh ijkl mnop`)

> ⚠️ You need **2-Step Verification** enabled on your Google account first.

---

## Step 4: Install Firebase CLI & Deploy

Open a terminal on your computer:

```bash
# 1. Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# 2. Log in to Firebase (use the same Google account as your Firebase project)
firebase login

# 3. Navigate to your project
cd ~/CatchTales

# 4. Install function dependencies
cd functions
npm install
cd ..

# 5. Set the config values
firebase functions:config:set stripe.secret="sk_live_xxxxxxxxxxxxx"
firebase functions:config:set stripe.webhook_secret="whsec_xxxxxxxxxxxxx"
firebase functions:config:set stripe.price_id="price_xxxxxxxxxxxxx"
firebase functions:config:set gmail.email="catchtales@yahoo.com"
firebase functions:config:set gmail.password="your-16-char-gmail-app-password"

# 6. Deploy the functions
firebase deploy --only functions
```

After deploying, you'll see output like:

```
✔  functions[stripeWebhook(gen2)]: Successful create operation.
  Function URL (stripeWebhook): https://stripeWebhook-<region>-catchtales-prod.cloudfunctions.net/stripeWebhook
```

📋 **Copy this Function URL** — you'll need it in the next step.

---

## Step 5: Configure Stripe Webhook

1. Go to **Stripe Dashboard → Developers → Webhooks → Add endpoint**
2. **Endpoint URL:** Paste the Firebase Function URL from Step 4
3. **Events to send:** Select `checkout.session.completed`
4. Click **Add endpoint**
5. Under **Signing secret**, click **Reveal** and copy the `whsec_...` string
6. Go back to terminal and run:

```bash
firebase functions:config:set stripe.webhook_secret="whsec_xxxxxxxxxxxxx"
firebase deploy --only functions
```

---

## Step 6: Create the Payment Link

1. In Stripe Dashboard → **Payment Links** → **Create Payment Link**
2. **Product:** Select "CatchTales Pro" ($4.99)
3. **Customer information:** Toggle **Collect email address** ON (required!)
4. **Confirmation page:** 
   - Check ✅ **Show payment confirmation**
   - (Optional) Add a message like "Check your email for your Pro code!"
5. **After payment:** Customize success page or redirect (leave as default)
6. Click **Create Link**
7. Copy the generated link — it looks like `https://buy.stripe.com/xxxxx`

---

## Step 7: Set Up pay.catchtales.com

While on the phone with GoDaddy, tell them to set up a **subdomain redirect**:

1. In GoDaddy DNS settings, add a **CNAME record**:
   - **Host/Name:** `pay`
   - **Target/Value:** `buy.stripe.com`
   - **TTL:** 600 (or default)
2. Or set up a **Domain Redirect (Forwarding)**:
   - **From:** `pay.catchtales.com`
   - **To:** `https://buy.stripe.com/xxxxx` (your Stripe Payment Link)
   - **Type:** Permanent (301)
   - **Forward settings:** Forward only (or with masking if needed)

> ⏱ DNS changes can take up to 48 hours to propagate, but usually work within minutes.

---

## Step 8: Update the Pay Link in the App

Once you have your Stripe Payment Link URL, update it in `pro_service.dart`:

```dart
// In lib/services/pro_service.dart — find this line:
static const String _payLink = 'https://pay.catchtales.com';

// Either keep it as pay.catchtales.com (if DNS works) OR
// replace with the direct Stripe link:
static const String _payLink = 'https://buy.stripe.com/xxxxx';
```

If `pay.catchtales.com` isn't working yet (DNS propagation), using the direct Stripe link as a fallback is fine — you can switch later.

---

## Step 9: Test the Flow

### Test Mode (recommended first):

1. Make sure your Stripe keys are in **Test mode** (`sk_test_...`)
2. Open the app and tap **Buy Pro — $4.99**
3. On the checkout page, use test card: `4242 4242 4242 4242`
   - Expiry: any future date
   - CVC: any 3 digits
   - ZIP: any 5 digits
4. Complete payment
5. Check the customer's email for the Pro code
6. Open the app → **I have a Pro Code** → enter the code → verify Pro unlocks

### Live Mode:

1. Switch to live keys (`sk_live_...`) in Firebase config
2. Deploy again: `firebase deploy --only functions`
3. Test with a real card

---

## 🔧 Troubleshooting

### Webhook not firing?
Check **Stripe Dashboard → Developers → Webhooks → Your endpoint → "Webhook attempts"**
Look for the HTTP status returned by your function.

### Function errors?
```bash
firebase functions:log
```

### Email not sending?
- Check Gmail app password is correct
- Check "Less secure apps" or "App passwords" settings
- Check spam folder

### Code not working in app?
Check Firestore console → `pro_licenses` collection — the document should exist with `used: false`

---

## 🗺 Architecture Summary

```
┌─────────────────┐     opens      ┌──────────────────────┐
│  App             │ ──────────→   │  pay.catchtales.com│
│  (User taps Buy) │               │  (Stripe Payment Link)│
└─────────────────┘               └──────────┬───────────┘
                                              │ user pays $4.99
                                              ▼
                                    ┌──────────────────┐
                                    │  Stripe           │
                                    │  Webhook Request  │
                                    └──────────┬───────┘
                                               │ POST /stripeWebhook
                                               ▼
                                    ┌──────────────────┐
                                    │  Firebase Cloud   │
                                    │  Function         │
                                    │                   │
                                    │  • Verify sig     │
                                    │  • Gen code       │
                                    │  • Save to        │
                                    │    Firestore      │
                                    │  • Send email     │
                                    └──────────────────┘
                                               │
                                    ┌──────────┴──────────┐
                                    ▼                     ▼
                            ┌──────────────┐    ┌──────────────┐
                            │  Firestore   │    │  Gmail       │
                            │  pro_licenses│    │  (code email)│
                            └──────────────┘    └──────────────┘
```

---

## 📄 Files Created

| File | Purpose |
|---|---|
| `functions/index.js` | Stripe webhook handler + Pro code generator |
| `functions/package.json` | Node.js dependencies |
| `firebase.json` | Firebase Functions config |
| `.firebaserc` | Project alias (`catchtales-prod`) |
| `lib/services/pro_service.dart` | Updated with Pay Link button |

---

## 💰 Pricing Comparison

| Service | Fee | Webhooks? | Auto-deliver codes? | Tax handled? |
|---|---|---|---|---|
| **GoDaddy Pay Links** | ~2.9% + $0.30 | ❌ No | ❌ No | ❌ No |
| **Stripe Payment Links** | 2.9% + $0.30 | ✅ Yes | ✅ Yes (via this setup) | ❌ No |
| **Paddle** | ~5% + $0.50 | ✅ Yes | ✅ Yes | ✅ Yes |
| **Lemon Squeezy** | ~5% + $0.50 | ✅ Yes | ✅ Yes (built-in) | ✅ Yes |

**Stripe + this Cloud Function** gives you the lowest fees with full automation. 🎯
