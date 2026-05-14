# ShondonDHApp architecture

## Folder map (under `ShondonDHApp/`)

| Folder | Purpose |
|--------|---------|
| `App/` | App entry (`ShondonDHAppApp.swift`) — optional; may live at bundle root |
| `Core/Auth/` | Admin authorization helpers (`DreamHouseAdminAuth`) |
| `Core/Firestore/` | Shared Firestore error formatting |
| `Features/Auth/` | Login UI + `AuthenticationManager` |
| `Features/Ticker/` | Quick ticker feature screens |
| `Features/RadioStatus/` | Radio status dashboard |
| `main/` | Radio flow, upload, and related screens |
| `View/` | Additional SwiftUI views |
| `ViewModel/` | Observable view models |
| `Model/` | Data models |

Xcode uses a synchronized folder for `ShondonDHApp/`, so new files under these paths are picked up automatically.

## Admin access model

1. User signs in with Firebase **Email/Password**.
2. The app treats the session as admin if **any** of these are true (see `DreamHouseAdminAuth.swift`):
   - **Legacy email allowlist** — same addresses as `isAdmin()` in `firestore.rules` / `storage.rules` (`rashyslop@outlook.com`, `rashon_hyslop@outlook.com`). Checked first so the gate does not depend on Firestore (avoids App Check / network timeouts blocking the UI).
   - **Custom claim** `admin: true` on the ID token.
   - **Firestore** `adminUsers/{uid}` exists and `active` is not `false`.

3. **Firestore rules** allow each signed-in user to **read** their own `adminUsers/{uid}` document for the optional role path. Writes to `adminUsers` still require `isAdmin()` (email or future claim-based rules).

When you add new admins by email, update **both** `DreamHouseAdminAuth.legacyAdminEmails` and the `isAdmin()` function in `firestore.rules` and `storage.rules`, then deploy rules.

## Related files

- Rules: `firestore.rules`, `storage.rules`
- Ops docs: `docs/RELEASE_CHECKLIST.md`, `docs/ROLLBACK_RUNBOOK.md`, `docs/FIREBASE_ENVIRONMENTS.md` (CLI via `npx -y firebase-tools@latest`, App Check, dev/prod plist)
