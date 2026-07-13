# Security Policy

## Reporting a vulnerability

Do not open a public issue for suspected vulnerabilities, exposed credentials, or exploitable misconfigurations. Use GitHub private vulnerability reporting when enabled, or contact the repository owner privately.

Include the affected version or commit, reproduction steps, impact, and suggested remediation. Never include live secrets or customer data.

## Threat model

The primary protected assets are:

- the Cursor pool/API credential;
- source code and repositories reachable by an agent;
- cloud and SaaS credentials available to the runtime;
- build artifacts and Terraform state;
- audit evidence and execution logs.

Primary threats include credential exfiltration, prompt-driven tool abuse, supply-chain compromise, over-privileged workload identities, cross-environment lateral movement, untrusted repository code, and leakage through logs or Terraform state.

## Security invariants

- Secret values are never accepted as Terraform variables.
- Runtime identity uses Google-managed credentials rather than service-account keys.
- Container image digest pinning is enabled by default.
- The module grants access only to the selected Cursor secret.
- Data-plane permissions are not bundled into the infrastructure module.
- Destructive changes are protected by default.

## Operator responsibilities

Consumers must independently enforce repository trust, sandboxing, egress policy, least-privilege access to source systems, secret rotation, log retention/redaction, image provenance, vulnerability management, and incident response.

Treat agent-executed repository content as untrusted code. Isolate pools by environment and trust boundary, and avoid mounting or granting credentials that are not required for the current task.
