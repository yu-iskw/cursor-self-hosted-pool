# Security Controls

## Module-enforced

- SHA-256 image digests
- Rejection of default Compute Engine service accounts
- Restricted network profile requires VPC + egress attestation
- Secret version pinning (default)
- Deletion protection (default)
- Time-bounded policy exceptions (`exceptions` map)

## Organization-enforced (external)

- VPC / Shared VPC / egress proxy allowlists
- Organization policies
- Artifact Registry admission / Binary Authorization policy content
- Branch protection and CODEOWNERS
- SIEM correlation of audit logs

## Checklist

See the production adoption checklist in the project README and RFC §30.
