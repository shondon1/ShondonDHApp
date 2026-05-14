#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Running auth/upload/realtime smoke assertions..."

grep -q "validateCurrentUserIsAdmin" "${ROOT_DIR}/ShondonDHApp/Features/Auth/AuthenticationManager.swift"
grep -q "You must be signed in with an admin account" "${ROOT_DIR}/ShondonDHApp/main/UploadView.swift"
grep -q "addSnapshotListener" "${ROOT_DIR}/ShondonDHApp/main/RadioFlowView.swift"
grep -q "addSnapshotListener" "${ROOT_DIR}/ShondonDHApp/View/ScheduleView.swift"

echo "App smoke checks passed."
