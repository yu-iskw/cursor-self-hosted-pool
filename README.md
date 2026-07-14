# cursor-self-hosted-pool

Enterprise-grade **Terraform platform kit** for deploying [Cursor self-hosted agent pools](https://cursor.com/docs/cloud-agent/self-hosted-pool) on **Google Cloud Run Worker Pools**.

## Product thesis

- **One worker pool per repository and environment**
- **Composable modules**, not a monolith or custom control plane
- **Secure defaults** (digest-pinned images, dedicated runtime SA, Secret Manager refs, restricted network profile)
- Integrates with — but does not own — enterprise VPC, org policy, Artifact Registry governance, or fleet control planes

Cursor’s Cloud Run path uses **two** Worker Pools: agent workers plus a custom autoscaler. See [docs/compatibility.md](docs/compatibility.md) and [examples/secure-default](examples/secure-default).

## Quick start

```hcl
module "runtime_identity" {
  source = "git::https://github.com/yu-iskw/cursor-self-hosted-pool.git//modules/runtime-identity?ref=v0.1.0"

  project_id  = var.project_id
  repository  = "example-org/example-service"
  environment = "development"
}

module "cursor_pool" {
  source = "git::https://github.com/yu-iskw/cursor-self-hosted-pool.git//modules/cursor-worker-pool?ref=v0.1.0"

  project_id = var.project_id
  region     = var.region

  repository = {
    owner = "example-org"
    name  = "example-service"
  }

  environment = "development"

  image = {
    repository = "us-docker.pkg.dev/platform-agents/cursor/worker"
    digest     = "sha256:..."
  }

  runtime_service_account_email = module.runtime_identity.email

  secret_environment_variables = {
    CURSOR_API_KEY = {
      secret_id = "projects/${var.project_id}/secrets/cursor-example-service-dev"
      version   = "1"
    }
  }

  network = {
    profile           = "restricted"
    network_id        = var.network_id
    subnetwork_id     = var.subnetwork_id
    route_all_traffic = true
    approved_egress_control = {
      resource_id = var.egress_policy_id
      owner       = "platform-networking"
    }
  }

  capacity = {
    instance_count = 1
    cpu            = "4"
    memory         = "8Gi"
  }
}
```

Pin module versions with a git `ref=`. Do **not** track `main`.

## Repository layout

```text
modules/           # Published Terraform modules
examples/          # Reference compositions (including dual-pool secure-default)
docs/              # Architecture, threat model, compatibility, runbooks
images/            # Reference Dockerfiles for worker and autoscaler (BYO image factory)
tests/             # Terraform tests and fixtures
scripts/           # validate / docs / release helpers
```

## Modules

| Module | Purpose |
| --- | --- |
| [`cursor-worker-pool`](modules/cursor-worker-pool) | One Cloud Run Worker Pool |
| [`runtime-identity`](modules/runtime-identity) | Dedicated user-managed service account |
| [`secret-bindings`](modules/secret-bindings) | Secret-level IAM for the runtime SA |
| [`network-profile`](modules/network-profile) | Validated network profile → pool settings |
| [`observability`](modules/observability) | Dashboards / alert policies |
| [`workload-identity`](modules/workload-identity) | Narrow CI → GCP federation helpers |
| [`project-bootstrap`](modules/project-bootstrap) | Optional API enablement |

## Prerequisites

- Terraform `>= 1.6`
- `hashicorp/google` `>= 6.38.0`
- GCP project with billing; APIs listed in [docs/compatibility.md](docs/compatibility.md)
- Cursor **Enterprise** self-hosted pool capability and a **service account API key**
- Org-built worker (and optional autoscaler) images in Artifact Registry

## Local validation

```bash
./scripts/validate.sh
```

## Documentation

- [Compatibility / Phase 0](docs/compatibility.md)
- [Architecture](docs/architecture.md)
- [Threat model](docs/threat-model.md)
- [Shared responsibility](docs/shared-responsibility.md)
- [Operations & runbooks](docs/operations.md)
- [Upgrades](docs/upgrades.md)
- [ADR 0001](docs/adr/0001-composable-platform-kit.md)

## License

Apache-2.0. See [LICENSE](LICENSE).
