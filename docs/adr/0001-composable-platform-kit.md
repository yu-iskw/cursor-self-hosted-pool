# ADR 0001: Composable Terraform platform kit for Cursor Cloud Run Worker Pools

- **Status:** Accepted
- **Date:** 2026-07-14
- **Deciders:** Project maintainers

## Context

We need an enterprise-grade paved road for deploying Cursor self-hosted agent
pools on Google Cloud Run Worker Pools. Alternatives considered: thin provider
wrapper, monolithic enterprise module, custom control plane, and a composable
platform kit.

Cursor’s Cloud Run guidance requires **two** Worker Pools (workers + custom
autoscaler) and **customer-built** images (no official digest-published image).

## Decision

Adopt a **refined composable platform kit** (Approach 5 from the RFC analysis):

1. Core module `cursor-worker-pool` owns **one** `google_cloud_run_v2_worker_pool`.
2. Supporting modules own identity, secret bindings, network profiles, observability, optional WIF and project bootstrap.
3. Reference compositions (especially `secure-default`) wire **worker + autoscaler** and document `lifecycle.ignore_changes` for scaler-owned instance counts.
4. Image build/attest/push remains outside the core module (`images/` + docs).
5. No custom control plane in the initial product.
6. This repository is a Terraform platform kit (not a TypeScript application template).

## Consequences

### Positive

- Clear ownership boundaries and testable module surface
- Matches Cursor dual-pool reality without hiding the autoscaler
- Compatible with existing enterprise VPC, AR, and CI foundations

### Negative

- Consumers need a composition (or example) for a complete stack
- Platform team must maintain image-factory guidance and compatibility docs
- Strict egress allowlisting depends on external network controls
