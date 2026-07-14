# Networking

## Profiles

| Profile | Intent |
| --- | --- |
| `unrestricted` | Explicit exception only |
| `nat-logged` | VPC-routed via logged NAT |
| `restricted` | Secure default; requires egress attestation |
| `private-only` | Private Google / internal only |
| `custom` | Advanced passthrough |

## Required destinations (Cursor)

- `api2.cursor.sh`
- `api2direct.cursor.sh`
- `cloud-agent-artifacts.s3.us-east-1.amazonaws.com` (artifacts; optional)
- `api.cursor.com` (fleet summary for autoscaler)
- Git host and package registries used by agents

Endpoint lists change; keep an operations allowlist document outside Terraform
validation.

## Direct VPC

Supported via `template.vpc_access.network_interfaces` on
`google_cloud_run_v2_worker_pool`.
