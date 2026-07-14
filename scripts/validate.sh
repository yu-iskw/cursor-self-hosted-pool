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

# Portable directory discovery (Bash 3.2+ / macOS stock bash)
while IFS= read -r d; do
  if ! find "$d" -maxdepth 1 -name '*.tf' | grep -q .; then
    continue
  fi
  echo "==> validate $d"
  (
    cd "$d"
    terraform init -backend=false -input=false >/dev/null
    terraform validate
  )
done < <(
  {
    find modules -mindepth 1 -maxdepth 1 -type d
    find examples -mindepth 1 -maxdepth 1 -type d
  } | sort
)

if command -v tflint >/dev/null 2>&1; then
  echo "==> tflint"
  for d in modules/*/; do
    echo "  tflint $d"
    (cd "$d" && tflint --init >/dev/null && tflint -f compact)
  done
else
  echo "==> tflint skipped (not installed)"
fi

echo "==> terraform test (modules with tests/)"
for d in modules/*/; do
  if [[ -d "${d}tests" ]] && find "${d}tests" -name '*.tftest.hcl' | grep -q .; then
    echo "  test $d"
    (cd "$d" && terraform init -backend=false -input=false >/dev/null && terraform test)
  fi
done

echo "==> OK"
