# Cursor Worker Pool

Terraform module that provisions a single [`google_cloud_run_v2_worker_pool`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_worker_pool) suitable for Cursor self-hosted workers **or** a Cursor autoscaler container.

## Features

- Digest-pinned images only
- Dedicated runtime service account (default Compute SA rejected)
- Secret Manager environment variables and mounts (no plaintext secrets)
- Network profiles including `restricted` (secure default expectations)
- Manual scaling; optional ignore of `manual_instance_count` for autoscaler-owned capacity
- Required inventory labels

This module does **not** create VPCs, secret values, or the autoscaler companion pool.
Use `examples/secure-default` for a dual-pool composition.

## Usage

See the root [README](../../README.md) and [examples](../../examples).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| google | >= 6.38.0, < 8.0.0 |
