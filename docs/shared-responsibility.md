# Shared Responsibility

| Responsibility | Maintainers | Platform team | Repository team | Security | Cursor |
| --- | :---: | :---: | :---: | :---: | :---: |
| Module correctness | P | R | C | R | — |
| Secure defaults | P | Customize | Honor | Approve | — |
| GCP foundation | — | P | Use | Govern | — |
| Secret values | Never | Optional admin | P | Govern | Issues keys |
| Egress enforcement | Integration | P | Declare endpoints | Approve | Publishes hosts |
| Image trust | Interface | Build/approve | Pin digest | Policy | CLI source |
| Repo code safety | — | Guardrails | P | Oversight | Agent runtime |
| Incident response | Runbooks | Infra | Repo context | Coord | Vendor support |

P = primary, R = review, C = consume.
