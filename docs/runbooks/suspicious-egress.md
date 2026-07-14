# Runbook: Suspicious Egress

1. Disable the pool immediately.
2. Preserve proxy, NAT, DNS, and runtime logs.
3. Rotate Cursor and git credentials.
4. Identify repository revision and agent task.
5. Inspect dependencies and install hooks.
6. Determine whether data left the approved boundary.
7. Review other pools sharing the same image digest.
8. Update allowlists / detection as needed.
