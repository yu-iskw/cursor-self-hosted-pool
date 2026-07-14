# Compatibility Matrix and Phase 0 Feasibility

This document captures verified answers to the RFC open questions (Phase 0).
A live GCP/Cursor PoC must still be run in a disposable project before production
adoption; provider and vendor fields below are validated against public docs as of
2026-07-14.

## Compatibility matrix

| Component                 | Minimum                               | Tested / recommended                                  | Constraint                     |
| ------------------------- | ------------------------------------- | ----------------------------------------------------- | ------------------------------ |
| Terraform                 | `>= 1.6`                              | `1.9+` (CI-pinned)                                    | `< 2.0`                        |
| `hashicorp/google`        | `>= 6.38.0`                           | `~> 7.39`                                             | `< 8.0`                        |
| `hashicorp/google-beta`   | Not required for core                 | Avoid unless needed                                   | Minimize                       |
| Cursor agent CLI          | Version installed via org image build | Org-built digest set                                  | No vendor-published image      |
| Cloud Run Worker Pool API | GA fields used by modules             | Direct VPC, secrets, Binary Auth, deletion protection | MANUAL scaling for Cursor path |

Resource type: **`google_cloud_run_v2_worker_pool`**.

First documented in `hashicorp/google` **v6.38.0** (resource docs present; absent in v6.36.0).

## Architecture confirmed by Cursor docs

Cursor’s Cloud Run guide requires **two** Worker Pools:

1. **Worker pool** — runs `agent worker start --pool` with outbound HTTPS to Cursor.
2. **Autoscaler pool** — typically one instance; polls `https://api.cursor.com/v0/private-workers/summary` and updates `scaling.manual_instance_count` on the worker pool.

Native Cloud Run Worker Pool autoscaling is **not** the Cursor-supported path. Terraform should use `scaling_mode = "MANUAL"` and, when an autoscaler owns capacity, `lifecycle.ignore_changes` on `scaling[0].manual_instance_count`.

## RFC §33 answers

| #   | Question                               | Status                     | Answer                                                                                                                                                                 |
| --- | -------------------------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Exact TF resource + min provider       | **Resolved**               | `google_cloud_run_v2_worker_pool`; min `hashicorp/google` **6.38.0**                                                                                                   |
| 2   | Required fields in stable provider     | **Resolved**               | Scaling, env/secrets, VPC (connector or Direct VPC), Binary Auth, deletion protection, instance splits available in stable provider                                    |
| 3   | Direct VPC egress in Terraform         | **Resolved**               | Yes — `template.vpc_access.network_interfaces.{network,subnetwork,tags}`                                                                                               |
| 4   | Revision / rollback controls           | **Partial**                | Revisions immutable; `instance_splits` can target latest or a named revision; operational rollback = redeploy prior digest / split                                     |
| 5   | Deletion protection                    | **Resolved**               | `deletion_protection` (Terraform default `true`)                                                                                                                       |
| 6   | Binary Authorization                   | **Resolved**               | `binary_authorization` block on the resource                                                                                                                           |
| 7   | Health signals without HTTP service    | **Resolved**               | Agent `--management-addr` exposes `/healthz`, `/readyz`, `/metrics`; bind to Cloud Run `PORT` for TCP checks                                                           |
| 8   | Endpoints / protocols                  | **Resolved**               | HTTPS to `api2.cursor.sh`, `api2direct.cursor.sh`, optional `cloud-agent-artifacts.s3.us-east-1.amazonaws.com`, `api.cursor.com` (fleet), git host, package registries |
| 9   | Credentials scoped per pool            | **Open / limited**         | Pool workers require a **service account API key** (Enterprise; see pool docs). Keys may span pools; use pool **names/labels** for routing. Document blast radius      |
| 10  | Credential rotation                    | **Partial**                | Secret Manager version pin + new Worker Pool revision. Long-lived worker re-read behavior needs live validation; prefer revision rollout                               |
| 11  | CPU / memory / workspace               | **Partial**                | No fixed vendor size; size like a CI/devbox. CWD must be a git repo. Sample uses `/workspace`                                                                          |
| 12  | Write access outside ephemeral storage | **Likely required**        | Local clone and caches need writable FS; prefer emptyDir / container FS; persistent volumes deferred                                                                   |
| 13  | Task distribution                      | **Resolved**               | One session claims one idle pool worker; routing via `repo=` / `pool=` labels                                                                                          |
| 14  | External metric for autoscaling        | **Resolved (Cursor path)** | Fleet summary utilization via custom autoscaler; GCP WP has no Cursor-native autoscaler                                                                                |
| 15  | Logs that may contain code/secrets     | **Open**                   | No vendor log-redaction contract; assume code/prompt leakage risk; sanitize platform logs                                                                              |
| 16  | Versioned Cursor images + digests      | **Resolved (negative)**    | **No official image.** Organizations build and pin digests in Artifact Registry                                                                                        |
| 17  | Internally rebuilt image licensing     | **Open**                   | Not stated in public docs; confirm with Cursor support before production                                                                                               |

### Doc conflict: API key type

| Source                                                                       | Claim                                                                     |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| [Self-Hosted Pool](https://cursor.com/docs/cloud-agent/self-hosted-pool)     | Service account API key; personal/team/org keys cannot start pool workers |
| [Cloud Run guide](https://cursor.com/docs/cloud-agent/self-hosted-cloud-run) | Mentions “team-level API key”                                             |

**Platform kit stance:** Prefer the pool page (service account API key / Enterprise). Treat Cloud Run guide wording as stale until Cursor reconciles docs.

## Required APIs

- `run.googleapis.com`
- `secretmanager.googleapis.com`
- `artifactregistry.googleapis.com` (image hosting)
- `cloudbuild.googleapis.com` (optional; image builds)
- `iam.googleapis.com` / `iamcredentials.googleapis.com` (identities / WIF)
- `logging.googleapis.com` / `monitoring.googleapis.com` (observability)

## Required environment variables (worker)

| Name                          | Source         | Notes                                |
| ----------------------------- | -------------- | ------------------------------------ |
| `CURSOR_API_KEY`              | Secret Manager | Required                             |
| `REPO_URL`                    | Plain env      | Required by Cursor sample entrypoint |
| `GIT_TOKEN`                   | Secret Manager | Recommended for private repos        |
| `PORT`                        | Cloud Run      | Default `8080`; management server    |
| `CURSOR_WORKER_POOL_NAME`     | Plain env      | Optional pool name for routing       |
| `HTTPS_PROXY` / `https_proxy` | Plain env      | When org egress proxy is required    |

## Autoscaler environment variables

| Name                   | Required | Default          |
| ---------------------- | -------- | ---------------- |
| `GOOGLE_CLOUD_PROJECT` | Yes      | —                |
| `CLOUD_RUN_LOCATION`   | Yes      | —                |
| `WORKER_SERVICE_NAME`  | Yes      | Worker pool name |
| `CURSOR_API_KEY`       | Yes      | Fleet API        |
| `TARGET_UTILIZATION`   | No       | `0.5`            |
| `MIN_INSTANCES`        | No       | `1`              |
| `MAX_INSTANCES`        | No       | `50`             |
| `POLLING_INTERVAL_MS`  | No       | `30000`          |

Autoscaler runtime SA needs permission to update the worker pool (`run.workerPools.update` or Cloud Run Admin / custom role).

## Image factory (BYO)

Organizations must:

1. Build worker and autoscaler images (see `images/`).
2. Scan, attest, and push by digest to an approved Artifact Registry.
3. Pass `image.repository` + `image.digest` into modules.
4. Never deploy mutable tags (`latest`) in production profiles.

Installing the CLI via `curl https://cursor.com/install | bash` at **build** time is acceptable for the image factory; runtime must not depend on live install.

## Known limitations

- Live PoC (worker connects, receives task, destroy) is **organization-specific** and not executed in this repository’s CI without credentials.
- Fleet autoscaler sample equates “connected workers” with desired instance count; failed registrations can skew scaling — monitor `/metrics` and fleet summary.
- Strict domain allowlisting is **not** enforceable in Terraform alone; use org egress controls and the `restricted` network profile attestation.
- `AUTOMATIC` scaling mode exists on the provider but is **not** used by the Cursor reference path.

## Phase 0 exit criteria checklist

Use this before declaring a consumer environment production-ready:

- [ ] Worker connects to Cursor control plane
- [ ] Worker receives and completes a test task
- [ ] Dedicated user-managed runtime SA attached
- [ ] Secrets resolved from Secret Manager (no plaintext in TF state)
- [ ] Logs emitted; no seeded credentials in CI logs
- [ ] Pool destroyed cleanly with `deletion_protection = false` override
- [ ] (Optional) Autoscaler adjusts `manual_instance_count`
- [ ] Direct VPC / restricted egress path validated if required by policy

## References

- [Cursor Self-Hosted Pool](https://cursor.com/docs/cloud-agent/self-hosted-pool)
- [Cursor Self-Hosted Cloud Run](https://cursor.com/docs/cloud-agent/self-hosted-cloud-run)
- [Terraform `google_cloud_run_v2_worker_pool`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_worker_pool)
- [Cloud Run Worker Pools](https://cloud.google.com/run/docs/deploy-worker-pools)
