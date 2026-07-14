# Supply Chain

## Reality

Cursor does **not** publish an official worker image with enterprise digests.
Organizations build images (see `images/`), push to Artifact Registry, and pin
`repository@sha256:...` in Terraform.

## Controls

| Control                       | Where                                             |
| ----------------------------- | ------------------------------------------------- |
| Digest format                 | Module validation                                 |
| Registry allowlist            | `security.allowed_image_registry_prefixes`        |
| Signature / SBOM / vuln gates | CI + Binary Authorization (optional module input) |
| Base image updates            | Org image factory process                         |

## Image factory sketch

1. Build worker + autoscaler from `images/`
2. Scan and attest
3. Push by digest
4. Open consumer PRs updating digests
5. Quarantine old digests on critical CVEs
