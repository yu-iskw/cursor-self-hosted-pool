# Threat Model

## Assumptions

- Repository code executed by the worker is potentially hostile.
- Cursor credentials and git tokens are high-value secrets.
- Outbound HTTPS is required; inbound HTTP is not a security boundary.

## Major threats and mitigations

| Threat                  | Mitigation                                               |
| ----------------------- | -------------------------------------------------------- |
| Credential exfiltration | Dedicated secrets, restricted egress, least-privilege SA |
| Lateral movement        | Per-repo/env identity; secret-level IAM                  |
| Supply-chain compromise | Digest pinning, org image factory, scanning/attestation  |
| Cost abuse              | Capacity policy, alerts, instance caps                   |
| Infrastructure mutation | Separate deployer vs runtime; no runtime pool/IAM admin  |
| Terraform state leakage | Secret references only; no payloads in variables         |
| Unauthorized deployment | WIF, protected branches, scoped deployer                 |

## Explicit non-claims

Terraform validations cannot prove egress allowlists or cryptographic image
signatures by themselves. Use CI verification and/or Binary Authorization.

Full RFC threat discussion lives in the project RFC; keep this doc operational.
