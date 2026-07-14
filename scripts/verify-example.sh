#!/usr/bin/env bash
set -euo pipefail

EXAMPLE="${1:-examples/secure-default}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/$EXAMPLE"
terraform init -backend=false -input=false
terraform validate
echo "Verified $EXAMPLE"
