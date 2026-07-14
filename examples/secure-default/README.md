# Secure Default Example

Deploys a **Cursor-accurate dual Worker Pool** stack:

1. Agent **worker** pool with `ignore_manual_instance_count_changes = true`
2. **Autoscaler** pool that updates the worker pool via Cloud Run IAM
3. Dedicated runtime identities and secret-level bindings
4. `restricted` network profile with egress-control attestation
5. Optional monitoring alert

## Prerequisites

- Org-built worker and autoscaler images (see `images/`)
- Secret Manager secrets for `CURSOR_API_KEY` (and optional `GIT_TOKEN`)
- VPC + subnet + approved egress control ID
- Cursor Enterprise service-account API key stored in Secret Manager

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit values — never commit tfvars with secrets
terraform init
terraform plan
```

## Notes

- Terraform sets the worker pool initial `manual_instance_count`; afterward the
  autoscaler owns scale-out/in. Do not manage instance count in both places.
- `roles/run.developer` on the worker pool for the autoscaler SA is a starting
  point; prefer a custom role with `run.workerPools.update` in production.
