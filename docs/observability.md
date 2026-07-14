# Observability

Correlate logs/metrics/alerts by project, region, pool, repository, environment,
team, image digest, module version, and runtime SA.

## Baseline alerts

- Zero healthy workers (see `modules/observability`)
- Revision start failure
- Secret access denied
- Unexpected instance-count growth
- Runtime SA token anomalies
- Critical image vulnerability (external scanner)
- Cost anomaly

## Logs to collect

Cloud Run runtime, admin activity audit, IAM, Secret Manager access, VPC/proxy,
Artifact Registry findings.

Do not intentionally collect plaintext credentials or unrestricted source dumps.
