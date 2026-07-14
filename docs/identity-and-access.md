# Identity and Access

## Separation

- **Deployment identity** (CI via WIF): create/update pools, attach runtime SA, bind secrets when using support modules.
- **Runtime identity**: dedicated per repository/environment; secret accessor only as granted; no pool update; no IAM admin; no keys.

## Autoscaler identity

Separate SA with permission to update the target worker pool
(`google_cloud_run_v2_worker_pool_iam_member` or custom role with
`run.workerPools.update`). Prefer resource-scoped grants over project-wide
Cloud Run Admin.

## Impersonation

Optional: grant runtime SA `roles/iam.serviceAccountTokenCreator` on one target
SA. See `examples/service-account-impersonation`.
