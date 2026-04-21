// Cloud Functions for Roomr — push notifications for matches and messages.
//
// Triggers:
//   onMatchCreated   — fires when matches/{matchId} is written
//   onMessageCreated — fires when matches/{matchId}/messages/{msgId} is written
//
// The client (NotificationService) expects these data payloads:
//   type=match    matchId, otherUserId, otherUserName, otherUserPhoto
//   type=message  matchId, senderId, senderName, senderPhoto

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');

initializeApp();
const db = getFirestore();
const fcm = getMessaging();

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Sends a multicast FCM message and prunes tokens that came back as invalid
 * from the user's Firestore document.
 */
async function sendAndCleanupTokens(userId, tokens, message) {
  if (!tokens || tokens.length === 0) return;
  const response = await fcm.sendEachForMulticast({ ...message, tokens });
  const invalid = [];
  response.responses.forEach((res, i) => {
    if (!res.success) {
      const code = res.error && res.error.code;
      if (
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/registration-token-not-registered'
      ) {
        invalid.push(tokens[i]);
      }
    }
  });
  if (invalid.length > 0) {
    await db.collection('users').doc(userId).update({
      fcmTokens: FieldValue.arrayRemove(...invalid),
    });
  }
}

// ─── New match ──────────────────────────────────────────────────────────────

exports.onMatchCreated = onDocumentCreated('matches/{matchId}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const match = snap.data();
  const matchId = event.params.matchId;
  const userIds = match.userIds || [];
  if (userIds.length < 2) return;

  const userSnaps = await Promise.all(
    userIds.map((uid) => db.collection('users').doc(uid).get()),
  );
  const users = {};
  userSnaps.forEach((doc, i) => {
    if (doc.exists) users[userIds[i]] = { id: userIds[i], ...doc.data() };
  });

  await Promise.all(
    userIds.map(async (uid) => {
      const user = users[uid];
      if (!user || user.notifyOnMatch === false) return;
      const tokens = user.fcmTokens || [];
      if (tokens.length === 0) return;

      const otherId = userIds.find((id) => id !== uid);
      const other = users[otherId];
      if (!other) return;

      try {
        await sendAndCleanupTokens(uid, tokens, {
          notification: {
            title: "It's a match!",
            body: `You and ${other.name || 'someone'} liked each other.`,
          },
          data: {
            type: 'match',
            matchId,
            otherUserId: otherId,
            otherUserName: String(other.name || ''),
            otherUserPhoto:
              (Array.isArray(other.photoUrls) && other.photoUrls[0]) || '',
          },
          android: { priority: 'high' },
          apns: { payload: { aps: { sound: 'default' } } },
        });
      } catch (err) {
        logger.error(`match notify failed for ${uid}`, err);
      }
    }),
  );
});

// ─── New message ────────────────────────────────────────────────────────────

exports.onMessageCreated = onDocumentCreated(
  'matches/{matchId}/messages/{msgId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data();
    const { matchId } = event.params;
    const senderId = msg.senderId;
    if (!senderId) return;

    const matchDoc = await db.collection('matches').doc(matchId).get();
    if (!matchDoc.exists) return;
    const userIds = matchDoc.data().userIds || [];
    const recipientId = userIds.find((id) => id !== senderId);
    if (!recipientId) return;

    const [recipientDoc, senderDoc] = await Promise.all([
      db.collection('users').doc(recipientId).get(),
      db.collection('users').doc(senderId).get(),
    ]);
    if (!recipientDoc.exists) return;
    const recipient = recipientDoc.data();
    const sender = senderDoc.exists ? senderDoc.data() : {};

    if (recipient.notifyOnMessage === false) return;
    // Skip if the recipient is actively viewing this chat.
    if (recipient.activeChatId === matchId) return;
    // Skip if the recipient has blocked the sender (mutual block hides chats).
    const blocked = recipient.blockedUsers || [];
    if (blocked.includes(senderId)) return;

    const tokens = recipient.fcmTokens || [];
    if (tokens.length === 0) return;

    try {
      await sendAndCleanupTokens(recipientId, tokens, {
        notification: {
          title: sender.name || 'New message',
          body: msg.text || '',
        },
        data: {
          type: 'message',
          matchId,
          senderId,
          senderName: String(sender.name || ''),
          senderPhoto:
            (Array.isArray(sender.photoUrls) && sender.photoUrls[0]) || '',
        },
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } catch (err) {
      logger.error(`message notify failed for ${recipientId}`, err);
    }
  },
);
