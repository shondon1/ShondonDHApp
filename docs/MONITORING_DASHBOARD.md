# Monitoring Dashboard Signals

Track these signals in Firebase Console (and alerts where possible):

## Reliability KPIs
- **Crash-free sessions** (Crashlytics)
- **Auth failure rate** (`AuthErrorCode` in sign-in path)
- **Upload failure rate** (storage/upload + Firestore save errors)
- **Permission-denied writes** (`FIRFirestoreErrorDomain` code 7)
- **Notification queue backlog** (`notifications_queue` where `status == pending`)

## Realtime health checks
- Snapshot listeners active for:
  - `radioFlow`
  - `scheduledContent`
  - `updateMessages`
- Cache fallback indicator rate (how often views are cache-backed).

## Alert thresholds (starter)
- Crash-free sessions < 99.0%
- Permission-denied writes > 5 in 15 minutes
- Upload failures > 3 in 10 minutes
- Notification queue pending > 50 for 15 minutes

## Weekly ops review
- Review top crashes and top failed operations.
- Review rules/index changes and whether they were tested in dev first.
- Prune noisy alerts and tighten thresholds.
