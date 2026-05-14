# Rollback Runbook

## Trigger conditions
- Spike in upload failures or permission denials.
- Realtime content not updating after release.
- Crash-free sessions drop below target.

## Fast rollback steps

### 1) App rollback
- Stop promotion to wider audience.
- Revert to previous TestFlight/App Store build if rollout started.
- Announce rollback in team channel with impact summary.

### 2) Firebase rules/index rollback
- Identify last known-good git commit on `main`.
- Run:
  - `git checkout <good_commit> -- firestore.rules storage.rules firestore.indexes.json firebase.json`
  - `npx -y firebase-tools@latest use prod`
  - `npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes,storage`
- Validate admin sign-in + upload + realtime listeners.

### 3) Data-path mitigation
- If `counters/*` values are corrupted, patch the relevant counter doc with current max order + 1.
- If notification queue is stuck, inspect `notifications_queue` statuses and resume worker/function.

## Verification after rollback
- Upload one audio item and one YouTube item from admin app.
- Confirm item appears in realtime `radioFlow` list.
- Confirm no new permission denied errors for admin writes.
- Confirm queue item appears in `notifications_queue`.

## Incident follow-up
- Open a postmortem issue within 24 hours.
- Capture root cause, user impact, and permanent fix.
- Add a new CI smoke check for the failure mode.
