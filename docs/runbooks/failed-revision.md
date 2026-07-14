# Runbook: Failed Revision

1. Inspect Worker Pool revision status and logs.
2. Confirm image availability and digest pull IAM.
3. Confirm secret reference and accessor bindings.
4. Confirm runtime service account.
5. Confirm network path to Cursor and git.
6. Compare resource limits with the prior revision.
7. Roll back to the prior digest/configuration via Terraform apply.
8. Open provider/vendor issues when platform behavior is implicated.
