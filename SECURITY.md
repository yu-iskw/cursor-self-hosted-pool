# Security Policy

## Supported versions

Security fixes are provided for the latest minor release line of this platform kit.
See [CHANGELOG.md](CHANGELOG.md) and GitHub releases for supported tags.

## Reporting a vulnerability

Please open a private security advisory on GitHub, or email the maintainers if
advisories are unavailable. Do not file public issues for credential leaks or
exploitable misconfigurations.

Include:

- Affected module version / tag
- Description and impact
- Reproduction steps (without secret values)
- Whether a fix is already proposed

## Security model (summary)

- No service-account keys created by modules
- No secret payloads in Terraform variables or state (Secret Manager references only)
- Digest-pinned container images; mutable tags rejected by default
- Dedicated runtime identity per repository/environment
- Restricted network profile is the secure default
- Runtime identity must not mutate worker pools or IAM

See [docs/threat-model.md](docs/threat-model.md) and [docs/security-controls.md](docs/security-controls.md).
