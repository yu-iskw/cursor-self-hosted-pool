#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FMT_ONLY=false
if [[ "${1:-}" == "--fmt-only" ]]; then
  FMT_ONLY=true
fi

echo "==> terraform fmt"
terraform fmt -recursive -check=true -diff=true modules examples || {
  echo "Run: terraform fmt -recursive modules examples"
  exit 1
}

if [[ "$FMT_ONLY" == "true" ]]; then
  exit 0
fi

DIRS=(modules/cursor-worker-pool modules/runtime-identity modules/secret-bindings modules/network-profile modules/observability modules/workload-identity modules/project-bootstrap)
for d in examples/*/; do
  DIRS+=("${d%/}")
done

for d in "${DIRS[@]}"; do
  if [[ ! -d "$d" ]]; then
    continue
  fi
  if ! find "$d" -maxdepth 1 -name '*.tf' | grep -q .; then
    continue
  fi
  echo "==> validate $d"
  (
    cd "$d"
    terraform init -backend=false -input=false >/dev/null
    terraform validate
  )
done

if command -v tflint >/dev/null 2>&1; then
  echo "==> tflint"
  for d in modules/*/; do
    (cd "$d" && tflint --init >/dev/null 2>&1 || true && tflint || true)
  done
else
  echo "==> tflint skipped (not installed)"
fi

echo "==> OK"
