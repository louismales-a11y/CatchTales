const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const { Timestamp, getFirestore, FieldValue } = require('firebase-admin/firestore');
const stripe = require('stripe');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

admin.initializeApp();
const db = getFirestore();

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
// Set these via: firebase functions:config:set stripe.secret="sk_live_..."
//                                stripe.webhook_secret="whsec_..."
//                                email.user="louis.males@gmail.com"
//                                gmail.password="<app-password>"
// ---------------------------------------------------------------------------
const stripeSecretKey = functions.params.defineString('STRIPE_SECRET', {
  default: process.env.STRIPE_SECRET || '',
});
const stripeWebhookSecret = functions.params.defineString('STRIPE_WEBHOOK_SECRET', {
  default: process.env.STRIPE_WEBHOOK_SECRET || '',
});
const emailUser = functions.params.defineString('EMAIL_USER', {
  default: process.env.EMAIL_USER || 'louis.males@gmail.com',
});
const emailPass = functions.params.defineString('EMAIL_PASS', {
  default: process.env.EMAIL_PASS || '',
});

// Pro code price in cents (e.g., $4.99 = 499)
const PRO_PRICE_CENTS = 499;
// Stripe Price ID (created in Stripe Dashboard)
// Set via: firebase functions:config:set stripe.price_id="price_xxxxx"
const stripePriceId = functions.params.defineString('STRIPE_PRICE_ID', {
  default: process.env.STRIPE_PRICE_ID || '',
});

// ---------------------------------------------------------------------------
// Nodemailer transporter (Gmail SMTP)
// ---------------------------------------------------------------------------
function createTransporter() {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: emailUser.value(),
      pass: emailPass.value(),
    },
  });
}

// ---------------------------------------------------------------------------
// Generate a unique Pro code in format PRO-XXXX-XXXX
// ---------------------------------------------------------------------------
function generateProCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I, O, 0, 1 to avoid confusion
  const part1 = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  const part2 = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `PRO-${part1}-${part2}`;
}

// ---------------------------------------------------------------------------
// Ensure the generated code is unique in Firestore
// ---------------------------------------------------------------------------
async function generateUniqueCode(maxAttempts = 10) {
  for (let i = 0; i < maxAttempts; i++) {
    const code = generateProCode();
    const doc = await db.collection('pro_licenses').doc(code).get();
    if (!doc.exists) {
      return code;
    }
  }
  throw new Error('Failed to generate a unique Pro code after max attempts');
}

// ---------------------------------------------------------------------------
// Send the Pro code via email
// ---------------------------------------------------------------------------
async function sendProCodeEmail(recipientEmail, proCode, customerName) {
  const transporter = createTransporter();
  const greeting = customerName ? `Hi ${customerName},` : 'Hi there,';
  
  const mailOptions = {
    from: `"CatchTales" <${emailUser.value()}>`,
    to: recipientEmail,
    subject: 'Your CatchTales Pro Code',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #0D47A1; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
          <h1 style="margin: 0;">🐟 CatchTales</h1>
        </div>
        <div style="padding: 30px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 0 0 8px 8px;">
          <p>${greeting}</p>
          <p>Thank you for upgrading to <strong>Pro</strong>! Here is your license code:</p>
          <div style="text-align: center; margin: 30px 0;">
            <div style="display: inline-block; background: #0D47A1; color: white; font-size: 24px; 
                        font-weight: bold; letter-spacing: 4px; padding: 15px 30px; 
                        border-radius: 8px; font-family: 'Courier New', monospace;">
              ${proCode}
            </div>
          </div>
          <p>To activate Pro:</p>
          <ol>
            <li>Open CatchTales</li>
            <li>Tap the <strong>Upgrade to Pro</strong> button (or go to Settings)</li>
            <li>Choose <strong>"I have a Pro Code"</strong></li>
            <li>Enter the code above</li>
          </ol>
          <p style="color: #666; font-size: 12px; margin-top: 30px;">
            If you didn't make this purchase, please ignore this email or contact us at louis.males@gmail.com
          </p>
        </div>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
}

// ---------------------------------------------------------------------------
// Stripe Webhook — called when a payment succeeds
// ---------------------------------------------------------------------------
exports.stripeWebhook = functions.https.onRequest({ cors: true }, async (req, res) => {
  // Only allow POST
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const sig = req.headers['stripe-signature'];
  if (!sig) {
    res.status(400).send('Missing stripe-signature header');
    return;
  }

  let event;
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      stripeWebhookSecret.value(),
    );
  } catch (err) {
    functions.logger.error('Stripe webhook signature verification failed:', err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object;

      // Make sure it's a payment (not a subscription setup)
      if (session.mode !== 'payment' && session.mode !== undefined) {
        functions.logger.log('Skipping non-payment session:', session.mode);
        break;
      }

      // Only process if the amount matches our Pro price
      if (session.amount_total && session.amount_total !== PRO_PRICE_CENTS) {
        functions.logger.log(
          `Skipping session with non-matching amount: ${session.amount_total} (expected ${PRO_PRICE_CENTS})`
        );
        break;
      }

      const customerEmail = session.customer_details?.email;
      const customerName = session.customer_details?.name;

      if (!customerEmail) {
        functions.logger.error('Checkout session has no customer email:', session.id);
        break;
      }

      try {
        // Generate a unique Pro code
        const proCode = await generateUniqueCode();

        // Save to Firestore
        await db.collection('pro_licenses').doc(proCode).set({
          used: false,
          createdAt: FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          customerEmail: customerEmail,
          customerName: customerName || '',
        });

        functions.logger.log(`Pro code ${proCode} created for ${customerEmail}`);

        // Send the code via email
        await sendProCodeEmail(customerEmail, proCode, customerName);

        functions.logger.log(`Pro code email sent to ${customerEmail}`);
      } catch (err) {
        functions.logger.error('Error processing payment:', err);
      }
      break;
    }

    case 'checkout.session.expired': {
      functions.logger.log('Checkout session expired:', event.data.object.id);
      break;
    }

    default:
      functions.logger.log(`Unhandled event type: ${event.type}`);
  }

  // Acknowledge receipt
  res.json({ received: true });
});

// ---------------------------------------------------------------------------
// (Optional) Admin endpoint to create a custom Pro code manually
// ---------------------------------------------------------------------------
exports.createProCode = functions.https.onCall(async (data, context) => {
  // Only allow authenticated admin users
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be signed in to create a Pro code.',
    );
  }

  // Check if the user is an admin (you can customize this)
  const uid = context.auth.uid;
  const adminDoc = await db.collection('admins').doc(uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'You are not authorized to create Pro codes.',
    );
  }

  const { email, name } = data;
  if (!email) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email is required.',
    );
  }

  const proCode = await generateUniqueCode();
  await db.collection('pro_licenses').doc(proCode).set({
    used: false,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: uid,
    customerEmail: email,
    customerName: name || '',
    note: 'Manually created by admin',
  });

  await sendProCodeEmail(email, proCode, name);

  return { success: true, code: proCode };
});

// ---------------------------------------------------------------------------
// Stripe Payment Link creation helper
// (Run this locally or via a one-off Firebase Function call)
// ---------------------------------------------------------------------------
// To create a Payment Link in Stripe that calls our webhook:
//
// 1. Go to https://dashboard.stripe.com/products → Add Product
//    - Name: "CatchTales Pro"
//    - Price: $4.99 (or whatever you choose)
//    - Copy the Price ID (starts with "price_...")
//
// 2. Set the config:
//    firebase functions:config:set stripe.secret="sk_live_..." 
//    firebase functions:config:set stripe.webhook_secret="whsec_..."
//    firebase functions:config:set stripe.price_id="price_xxxxx"
//    firebase functions:config:set gmail.password="<gmail-app-password>"
//
// 3. Deploy:
//    firebase deploy --only functions
//
// 4. Get the webhook URL:
//    https://stripeWebhook-<region>-<project>.cloudfunctions.net/stripeWebhook
//
// 5. In Stripe Dashboard → Developers → Webhooks → Add endpoint
//    - URL: (the URL from step 4)
//    - Events: checkout.session.completed
//    - Copy the signing secret (whsec_...)
//
// 6. Configure Stripe to point your Payment Link's webhook:
//    - In Stripe Dashboard → Payment Links → Edit your link
//    - Or create a new Payment Link using the price ID above
//    - Enable "Require email" for customer info
//
// Done! When a customer pays, the webhook fires, creates a Pro code,
// saves it to Firestore, and emails the customer.

// ---------------------------------------------------------------------------
// Brag Board Report Notification
// Fires when a new brag_reports document is created, emails the admin.
// ---------------------------------------------------------------------------
exports.onBragReport = functions.firestore
  .onDocumentCreated('brag_reports/{reportId}', async (event) => {
    const report = event.data?.data();
    if (!report) return;

    const targetType = report.targetType || 'unknown';
    const targetId = report.targetId || 'unknown';
    const reason = report.reason || 'Not specified';
    const reporterId = report.reporterId || 'anonymous';

    // Build a helpful email
    const subject = `[CatchTales Report] ${targetType} reported for: ${reason}`;
    const body = `
A new brag board report has been submitted:

  Target Type: ${targetType}
  Target ID:   ${targetId}
  Reason:      ${reason}
  Reporter:    ${reporterId} (anonymous to reporter, visible to you)

To view this report in Firebase Console:
https://console.firebase.google.com/project/catchtales-prod/firestore/data/brag_reports/${event.params.reportId}

To view the reported content in Firebase Console:
https://console.firebase.google.com/project/catchtales-prod/firestore/data/brag_${targetType === 'post' ? 'posts' : 'comments'}/${targetId}

To manage the reporting user in Firebase Auth:
https://console.firebase.google.com/project/catchtales-prod/authentication/users
    `.trim();

    // Send via nodemailer using Gmail SMTP
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: emailUser.value(), pass: emailPass.value() },
    });

    try {
      await transporter.sendMail({
        from: emailUser.value(),
        to: emailUser.value(), // sends to yourself (louis.males@gmail.com)
        subject,
        text: body,
      });
      console.log(`Report email sent for ${targetType} ${targetId}`);
    } catch (e) {
      console.error('Failed to send report email:', e);
    }
  });

// ---------------------------------------------------------------------------
// Brag Board Push Notifications
// Fires when a like or comment is added to a brag post.
// Sends an FCM push notification to the post owner.
// ---------------------------------------------------------------------------
exports.onBragLike = functions.firestore
  .onDocumentCreated('brag_likes/{likeId}', async (event) => {
    const like = event.data?.data();
    if (!like) return;

    const postId = like.postId;
    const likerId = like.userId;
    if (!postId || !likerId) return;

    try {
      // Get the post to find the owner
      const postDoc = await db.collection('brag_posts').doc(postId).get();
      if (!postDoc.exists) return;
      const post = postDoc.data();
      const ownerId = post?.userId;
      if (!ownerId || ownerId === likerId) return; // don't notify self-likes

      // Get the liker's name
      const likerDoc = await db.collection('users').doc(likerId).get();
      const likerName = likerDoc.data()?.name || 'Someone';

      // Get the owner's FCM token
      const ownerDoc = await db.collection('users').doc(ownerId).get();
      const fcmToken = ownerDoc.data()?.fcm_token;
      if (!fcmToken) return;

      // Send via Firebase Admin SDK FCM
      const message = {
        token: fcmToken,
        notification: {
          title: '👍 New Like',
          body: `${likerName} liked your catch photo!`,
        },
        data: {
          type: 'brag_like',
          postId: postId,
          route: '/brag-board',
        },
        android: {
          priority: 'high',
        },
      };

      await admin.messaging().send(message);
      console.log(`Like notification sent to ${ownerId} for post ${postId}`);
    } catch (e) {
      console.error('Failed to send like notification:', e.message);
    }
  });

// ---------------------------------------------------------------------------
// Pro License Expiry Reminder
// Runs daily at 8:00 AM, checks for yearly licenses expiring in 7 days,
// and sends a reminder email.
// ---------------------------------------------------------------------------
exports.proExpiryReminder = functions.scheduler
  .onSchedule('0 8 * * *', async () => {
    const now = new Date();
    const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    try {
      // Find used yearly licenses expiring within 7 days that haven't been reminded yet
      const snapshot = await db.collection('pro_licenses')
        .where('used', '==', true)
        .where('type', '==', 'yearly')
        .where('expiresAt', '>=', now)
        .where('expiresAt', '<=', in7Days)
        .get();

      if (snapshot.empty) {
        console.log('No expiring licenses found today');
        return;
      }

      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: { user: emailUser.value(), pass: emailPass.value() },
      });

      let sentCount = 0;
      for (const doc of snapshot.docs) {
        const data = doc.data();
        const recipientEmail = data.activatedByEmail;
        if (!recipientEmail) {
          console.log(`No email for license ${doc.id}, skipping`);
          continue;
        }

        const expiresDate = data.expiresAt?.toDate ? data.expiresAt.toDate() : data.expiresAt;
        const dateStr = expiresDate ? expiresDate.toLocaleDateString('en-CA', {
          year: 'numeric', month: 'long', day: 'numeric'
        }) : 'soon';

        try {
          await transporter.sendMail({
            from: `"CatchTales" <${emailUser.value()}>`,
            to: recipientEmail,
            subject: 'Your CatchTales Pro license expires soon',
            html: `
              <div style="font-family: Arial; max-width: 600px; margin: 0 auto;">
                <div style="background: #0D47A1; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                  <h2>CatchTales Pro</h2>
                </div>
                <div style="padding: 30px; background: #f8f9fa; border: 1px solid #ddd;">
                  <p>Hi there,</p>
                  <p>Your CatchTales <strong>Pro Yearly</strong> license is expiring on <strong>${dateStr}</strong>.</p>
                  <p>To renew, reply to this email or visit <a href="https://catchtales.com/contact/">catchtales.com/contact</a>.</p>
                  <p style="color: #666; font-size: 12px; margin-top: 30px;">
                    Thank you for being a Pro user!<br>
                    — The CatchTales Team
                  </p>
                </div>
              </div>
            `,
          });

          // Mark as reminded
          await doc.ref.update({ remindedAt: FieldValue.serverTimestamp() });
          sentCount++;
          console.log(`Renewal reminder sent to ${recipientEmail} for license ${doc.id}`);
        } catch (e) {
          console.error(`Failed to send reminder for license ${doc.id}:`, e.message);
        }
      }

      console.log(`Sent ${sentCount} renewal reminders`);
    } catch (e) {
      console.error('Pro expiry reminder function failed:', e);
    }
  });

exports.onBragComment = functions.firestore
  .onDocumentCreated('brag_comments/{commentId}', async (event) => {
    const comment = event.data?.data();
    if (!comment) return;

    const postId = comment.postId;
    const commenterId = comment.userId;
    if (!postId || !commenterId) return;

    try {
      // Get the post to find the owner
      const postDoc = await db.collection('brag_posts').doc(postId).get();
      if (!postDoc.exists) return;
      const post = postDoc.data();
      const ownerId = post?.userId;
      if (!ownerId || ownerId === commenterId) return; // don't notify own comments

      // Get the commenter's name
      const commenterDoc = await db.collection('users').doc(commenterId).get();
      const commenterName = commenterDoc.data()?.name || 'Someone';

      // Truncate comment text
      const text = (comment.text || '').substring(0, 80);

      // Get the owner's FCM token
      const ownerDoc = await db.collection('users').doc(ownerId).get();
      const fcmToken = ownerDoc.data()?.fcm_token;
      if (!fcmToken) return;

      // Send via Firebase Admin SDK FCM
      const message = {
        token: fcmToken,
        notification: {
          title: '💬 New Comment',
          body: `${commenterName}: ${text}`,
        },
        data: {
          type: 'brag_comment',
          postId: postId,
          route: '/brag-board',
        },
        android: {
          priority: 'high',
        },
      };

      await admin.messaging().send(message);
      console.log(`Comment notification sent to ${ownerId} for post ${postId}`);
    } catch (e) {
      console.error('Failed to send comment notification:', e.message);
    }
  });
