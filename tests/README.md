# Unit / fixture placeholders

Contract tests live next to modules (e.g.
`modules/cursor-worker-pool/tests/*.tftest.hcl`).

Integration tests against a live GCP project are organization-specific and are
not run in public CI without credentials.
