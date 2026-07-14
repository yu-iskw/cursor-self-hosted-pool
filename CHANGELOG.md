# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial composable Terraform platform kit for Cursor Cloud Run Worker Pools
- Modules: `cursor-worker-pool`, `runtime-identity`, `secret-bindings`, `network-profile`, `observability`, `workload-identity`, `project-bootstrap`
- Examples including dual-pool `secure-default`
- Phase 0 compatibility documentation and operational runbooks
- Reference worker and autoscaler Dockerfiles under `images/`

### Security

- Image digests are always required (`var.image.digest`); there is no `security.require_image_digest` escape hatch
- Critical identity/network/secret policy rules are enforced via `lifecycle.precondition` (apply blockers), not check warnings alone
