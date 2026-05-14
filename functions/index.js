const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore('qrkni');

// ── RevenueCat webhook ────────────────────────────────────────────────────────
// Nastav URL této funkce v RevenueCat: Project Settings → Integrations → Webhooks
exports.revenueCatWebhook = onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.sendStatus(405);

  const event = req.body?.event;
  if (!event) return res.sendStatus(400);

  const userId = event.app_user_id;
  if (!userId) return res.sendStatus(400);

  const entitlements = event.entitlement_ids ?? [];
  const type = event.type;

  let plan = 'none';
  let status = 'none';

  const activeTypes = ['INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'TRIAL_STARTED', 'TRIAL_CONVERTED'];
  const expiredTypes = ['EXPIRATION', 'CANCELLATION', 'SUBSCRIBER_ALIAS'];

  if (activeTypes.includes(type)) {
    status = type === 'TRIAL_STARTED' ? 'trialing' : 'active';
    if (entitlements.includes('pro')) plan = 'pro';
    else if (entitlements.includes('basic')) plan = 'basic';
  } else if (expiredTypes.includes(type)) {
    plan = 'none';
    status = 'expired';
  } else {
    return res.sendStatus(200);
  }

  await db.collection('users').doc(userId).set(
    { subscription: { plan, status, updatedAt: FieldValue.serverTimestamp() } },
    { merge: true }
  );

  res.sendStatus(200);
});

// ── Worker count — increment při přidání ─────────────────────────────────────
exports.onWorkerCreated = onDocumentCreated({
  document: 'users/{userId}/workers/{workerId}',
  database: 'qrkni',
}, async (event) => {
  const userId = event.params.userId;
  await db.collection('users').doc(userId).set(
    { workerCount: FieldValue.increment(1) },
    { merge: true }
  );
});

// ── Worker count — decrement při smazání ─────────────────────────────────────
exports.onWorkerDeleted = onDocumentDeleted({
  document: 'users/{userId}/workers/{workerId}',
  database: 'qrkni',
}, async (event) => {
  const userId = event.params.userId;
  await db.collection('users').doc(userId).set(
    { workerCount: FieldValue.increment(-1) },
    { merge: true }
  );
});
