# Runbook: Credential Compromise

1. Disable the worker pool (instance count 0) and autoscaler if present.
2. Disable the compromised Secret Manager version.
3. Revoke the Cursor credential in Cursor admin.
4. Revoke git tokens and any impersonation grants.
5. Preserve audit, runtime, and network logs.
6. Identify tasks executed during the exposure window.
7. Create a new secret version with a new credential.
8. Deploy a new worker revision referencing the new version.
9. Validate connectivity.
10. Document root cause and preventive controls.
