#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v terraform-docs >/dev/null 2>&1; then
	echo "terraform-docs not installed; skipping generation."
	echo "Install: https://terraform-docs.io/"
	exit 0
fi

for d in modules/*/; do
	echo "Generating docs for $d"
	terraform-docs markdown table --output-file README.md --output-mode inject "$d" ||
		terraform-docs markdown table "$d" >"${d}README.generated.md"
done
