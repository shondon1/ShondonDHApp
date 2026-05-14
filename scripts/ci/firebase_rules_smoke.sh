#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Validating Firebase rule files exist..."
test -f "${ROOT_DIR}/firestore.rules"
test -f "${ROOT_DIR}/storage.rules"

echo "Checking rules use admin role/claim (not hardcoded emails)..."
grep -q "request.auth.token.admin == true" "${ROOT_DIR}/firestore.rules"
grep -q "adminUsers" "${ROOT_DIR}/firestore.rules"
grep -q "request.auth.token.admin == true" "${ROOT_DIR}/storage.rules"
grep -q "adminUsers" "${ROOT_DIR}/storage.rules"

echo "Firebase rules smoke checks passed."
