# Agent instructions (source of truth)

Treat this file as the **canonical** description of how to work in this repository.

## Project overview

**Terraform platform kit** for deploying Cursor self-hosted agent pools to Google
Cloud Run Worker Pools.

- **IaC:** Terraform modules under `modules/`
- **Examples:** `examples/`
- **Docs:** `docs/` (compatibility, threat model, runbooks)
- **Images:** Reference Dockerfiles under `images/` (BYO; no vendor image)
- **Tests:** Terraform tests under `tests/`
- **CI:** `.github/workflows/` (Terraform fmt/validate/tflint + security)

Primary consumer: central platform team. Default isolation: **one worker pool per
repository and environment**. Core module owns one Worker Pool; dual-pool
(worker + autoscaler) compositions live in examples.

## Quick commands

```bash
./scripts/validate.sh          # fmt, validate, tflint across modules/examples
./scripts/generate-docs.sh     # regenerate module docs if terraform-docs is installed
./scripts/release-check.sh     # pre-release sanity checks
```

## Code style

- Terraform HCL for infrastructure modules
- kebab-case module and example directory names
- Conventional commits: `type(scope): description`
- Never accept plaintext secrets in module variables
- Digest-pin container images by default

## Testing

- Static: `terraform fmt`, `terraform validate`, TFLint, Checkov (CI)
- Contract: `tests/` Terraform test files where present
- Integration: disposable GCP project (org-specific; not required for every PR)

## Architecture

See [docs/architecture.md](docs/architecture.md), [docs/compatibility.md](docs/compatibility.md),
and [docs/adr/0001-composable-platform-kit.md](docs/adr/0001-composable-platform-kit.md).

## Session closure and postmortems

For non-trivial sessions, capture learnings per the postmortem skill. Prefer
updating `docs/compatibility.md` when Cursor or provider behavior changes.
