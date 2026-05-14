/**
 * When the admin app adds a doc to `notifications_queue`, send an FCM message
 * to the listener topic and update status to `sent` or `failed`.
 *
 * Deploy: from repo root, `npx firebase-tools@latest deploy --only functions`
 * (after `cd functions && npm install`).
 */
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const DEFAULT_TOPIC = "dreamhouse_radio";

exports.sendQueuedNotification = functions.firestore
  .document("notifications_queue/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    if (data.status && data.status !== "pending") {
      return null;
    }

    const topic = typeof data.topic === "string" && data.topic.length > 0
      ? data.topic
      : DEFAULT_TOPIC;
    const title = data.title || "DreamHouse Radio";
    const body = data.body || "";

    const message = {
      topic,
      notification: { title, body },
      data: {
        category: String(data.category || ""),
        interruptionLevel: String(data.interruptionLevel || "active"),
        sourceType: String(data.sourceType || "manual"),
        sourceId: String(data.sourceId || ""),
      },
    };

    try {
      await admin.messaging().send(message);
      await snap.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      functions.logger.info("FCM sent", { docId: context.params.docId, topic });
    } catch (err) {
      functions.logger.error("FCM failed", err);
      await snap.ref.update({
        status: "failed",
        error: String(err.message || err),
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return null;
  });
