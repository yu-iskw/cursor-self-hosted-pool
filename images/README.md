# Image Factory References

These Dockerfiles are **starting points** for organization-owned images.

- `worker/` — Cursor agent pool worker (based on Cursor Cloud Run guide)
- `autoscaler/` — Fleet polling autoscaler with health endpoint on `PORT`

Build, scan, attest, and push **by digest** to your Artifact Registry. Never
deploy `:latest` in production profiles.

Pin digests into Terraform module `image` inputs.
