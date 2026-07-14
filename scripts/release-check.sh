#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> release-check"

test -f README.md
test -f CHANGELOG.md
test -f SECURITY.md
test -f docs/compatibility.md
test -f docs/adr/0001-composable-platform-kit.md
test -d modules/cursor-worker-pool
test -d examples/secure-default
test -d images/worker
test -d images/autoscaler

./scripts/validate.sh

if grep -R "YOUR_CURSOR_API_KEY\|AKIA[0-9A-Z]\\{16\\}" --include='*.tf' --include='*.md' modules examples docs 2>/dev/null; then
	echo "Possible secret-like placeholders found; review before release."
	exit 1
fi

echo "==> release-check OK"
