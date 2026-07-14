# Operations

## Day-2 tasks

| Task                  | Guidance                                                               |
| --------------------- | ---------------------------------------------------------------------- |
| Disable pool          | [runbooks/disable-pool.md](runbooks/disable-pool.md)                   |
| Credential compromise | [runbooks/credential-compromise.md](runbooks/credential-compromise.md) |
| Suspicious egress     | [runbooks/suspicious-egress.md](runbooks/suspicious-egress.md)         |
| Image vulnerability   | [runbooks/image-vulnerability.md](runbooks/image-vulnerability.md)     |
| Failed revision       | [runbooks/failed-revision.md](runbooks/failed-revision.md)             |

## Capacity

Start with one worker; size CPU/Memory like a CI/devbox for the repo. Cursor
limits: ≤10 workers/user, ≤50/team unless raised by Cursor.

When using the autoscaler, Terraform must not fight over `manual_instance_count`
(`ignore_manual_instance_count_changes = true`).
