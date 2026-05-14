# Monthly Release Checklist

## 1) Branch and scope control
- Create `release/YYYY-MM` from `main`.
- Freeze non-critical feature merges during release window.
- Confirm release notes include risk and rollback notes for each merged PR.

## 2) Required CI gates
- `xcodebuild` build must pass on `main`.
- `scripts/ci/firebase_rules_smoke.sh` must pass.
- `scripts/ci/app_smoke_checks.sh` must pass.

## 3) Firebase release sequence
- Deploy to **dev** first (use `npx -y firebase-tools@latest` per Firebase skill):
  - `npx -y firebase-tools@latest use dev`
  - `npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes,storage`
- Verify core flows in dev app:
  - Admin sign-in succeeds for a role-enabled admin user.
  - Upload writes to `radioFlow` and queue notifications.
  - Realtime lists update (radio flow, schedule, update messages).
- Promote to **prod** only after dev smoke checks pass:
  - `npx -y firebase-tools@latest use prod`
  - `npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes,storage`

## 4) Mobile release sequence
- Build a release candidate archive.
- Install on internal devices and run smoke checks.
- Publish to TestFlight with release notes.
- Monitor first 60 minutes before broad rollout.

## 5) Post-release checks
- Check Crashlytics crash-free sessions.
- Check Firestore permission denied trends.
- Check upload failure count and push queue pending backlog.
