# Firebase Environments (Dev + Prod)

## Cursor / agent workflow

When you use the **Firebase** Cursor plugin or agent skills, follow **`firebase-basics`**: use **`npx -y firebase-tools@latest`** for CLI commands (always current CLI), stay logged in (`npx -y firebase-tools@latest login`), and set an active project with `use`. Prefer **Firebase MCP** tools for console-style operations instead of ad hoc API calls when the plugin exposes them.

## Project aliases

Defined in `.firebaserc`:

- `dev` → `dreamhouseapp-dev`
- `prod` → `dreamhouseapp-a73ba`

## iOS config files

- Debug builds read `GoogleService-Info-Dev.plist` (via `FIREBASE_PLIST_NAME` in the target).
- Release builds read `GoogleService-Info-Prod.plist`.
- If that file is missing from the app bundle, the app falls back to `FirebaseApp.configure()` (typically `GoogleService-Info.plist`).

Create local files from templates:

- `GoogleService-Info-Dev.plist.example` → `GoogleService-Info-Dev.plist`
- `GoogleService-Info-Prod.plist.example` → `GoogleService-Info-Prod.plist`

## App Check (ShondonDHApp admin)

Register **PMC.ShondonDHApp** in Firebase Console → **Build** → **App Check** with the **App Attest** provider.

Client behavior (see `ShondonDHAppCheckProviderFactory.swift`):

- **Simulator** and **Debug on device**: App Check **debug** provider. Copy the UUID from the Xcode console and add it under App Check → your iOS app → **Manage debug tokens**, or create a token in the console and set the Xcode Run scheme environment variable **`FIRAAppCheckDebugToken`** (see [debug provider](https://firebase.google.com/docs/app-check/ios/debug-provider)).
- **Release** (TestFlight / App Store): **App Attest** on iOS / visionOS.

If **Firestore** or **Auth** has App Check **enforcement** on, failed or unregistered tokens show up as permission errors until the above is correct.

### If you see `exchangeDebugToken` HTTP 403 and `"App attestation failed"`

That response often appears when the **debug token exchange** is rejected, not only when App Attest is wrong. Work through this list:

1. **Use the exact app in Firebase Console**  
   The log line `GOOGLE_APP_ID=1:1059505472705:ios:4ac24f82cdd73157ad4040` must match the **iOS app** you open under **App Check** (same Firebase project, e.g. `dreamhouseapp-a73ba`).

2. **Register the exact token string**  
   Copy the UUID from the console line `App Check debug token: '…'` **including hyphens**, no spaces. In **Firebase Console → Build → App Check → your iOS app → (three dots) Manage debug tokens**, add that token.  
   After **delete/reinstall** the app, the token can change — remove the old one and add the new one, or use a **fixed** token from the console and set the Xcode scheme environment variable **`FIRAAppCheckDebugToken`** to that value (see [Debug provider](https://firebase.google.com/docs/app-check/ios/debug-provider)).

3. **Google Cloud API key restrictions**  
   In **Google Cloud Console → APIs & Services → Credentials**, open the **API key** from your `GoogleService-Info*.plist`. Under **API restrictions**, ensure **Firebase App Check API** is allowed (or temporarily “Don’t restrict key” to confirm this is the cause).

4. **Simulator haptic / keyboard noise**  
   Lines about `hapticpatternlibrary.plist` or Auto Layout on the simulator are unrelated to Firebase; you can ignore them.

## Deploy commands

Use the pinned CLI via `npx` (recommended by Firebase agent skills):

**Dev**

```bash
npx -y firebase-tools@latest use dev
npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes,storage
```

**Prod**

```bash
npx -y firebase-tools@latest use prod
npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes,storage
```
