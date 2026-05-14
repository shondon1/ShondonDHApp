# Push notifications (admin app → listeners)

## How it is supposed to work

1. **Admin app** (`PushNotificationService`) adds a document to Firestore collection `notifications_queue` with `status: "pending"`, plus `title`, `body`, `topic` (default `dreamhouse_radio`), etc.
2. **Cloud Function** `sendQueuedNotification` (in `functions/index.js`) runs on each new document, sends an **FCM message to that topic**, then sets `status` to `sent` or `failed`.
3. **Listener app** (DreamHouse Radio / public app) must **subscribe to the same FCM topic** at runtime, e.g. `Messaging.messaging().subscribe(toTopic: "dreamhouse_radio")` (iOS) or the Android equivalent.

If step 2 is missing or not deployed, queue items stay **`pending` forever** — that is the usual reason “it doesn’t work like it needs to.”

The **admin UI** will still say the notification was **queued** (that only means Firestore accepted the write). Until the function runs, **Firestore `status` will remain `pending`** — that is expected, not a second bug.

If **Firestore writes** fail (often with **App Check** errors in Xcode), fix App Check first (see [FIREBASE_ENVIRONMENTS.md](FIREBASE_ENVIRONMENTS.md)); otherwise the queue document may never be created or clients may not read it reliably.

## What you need to do

### 1) Deploy the function (one-time per Firebase project)

```bash
cd ShondonDHApp/functions
npm install
cd ..
npx firebase-tools@latest use prod   # or `dev`
npx firebase-tools@latest deploy --only functions
```

Ensure the Firebase project has the **Blaze** plan if required for your region (FCM from functions is generally available on Spark for moderate use; confirm in Firebase pricing docs for your case).

### 2) Confirm FCM / Apple Push

- In Firebase Console: **Project settings → Cloud Messaging**. iOS: upload **APNs key** (or cert) so FCM can deliver to Apple devices.
- Listener app must have the correct **GoogleService-Info.plist** and push capability enabled.

### 3) Listener app subscribes to the topic

Topic name must match `PushNotificationService.listenerTopic` (`dreamhouse_radio`). If the listener app uses a different topic string, either change one side to match or make the admin UI send a configurable topic later.

### 4) Verify in Console

- **Functions → Logs**: look for `FCM sent` or `FCM failed` after you queue a notification.
- **Firestore → `notifications_queue`**: documents should move from `pending` to `sent` or `failed` with an `error` field if something went wrong.

## Optional improvements

- Map `interruptionLevel` to APNS `interruption-level` headers (requires richer FCM payload).
- Add retry / dead-letter for `failed` rows.
- Rate-limit or dedupe bursts of queue writes.
