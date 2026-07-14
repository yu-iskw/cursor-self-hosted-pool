# Secrets

## Rules

- Never put secret values in Terraform variables, tfvars committed to git, or module outputs.
- Reference Secret Manager by secret ID + version.
- Prefer pinned versions; use exception `allow_secret_version_latest` only temporarily.
- Bind IAM at secret resource scope via `modules/secret-bindings`.

## Cursor credentials

Prefer Enterprise **service account API keys** for pool workers (see pool docs).
If one key is shared across pools, document blast radius and compensate with
network controls and fast disablement.

## Rotation

1. Add new Secret Manager version
2. Update Terraform version reference
3. Apply → new Worker Pool revision
4. Validate
5. Disable old version
