# Upgrades

## Semantic versioning

| Change                                                            | Version bump |
| ----------------------------------------------------------------- | ------------ |
| Removed/renamed inputs, resource address moves, breaking defaults | Major        |
| Additive optional features, new examples                          | Minor        |
| Bug/docs/test fixes, non-breaking hardening                       | Patch        |

## Consumer pinning

```hcl
source = "git::https://github.com/yu-iskw/cursor-self-hosted-pool.git//modules/cursor-worker-pool?ref=v0.1.0"
```

Do not track `main`.

## Upgrade procedure

1. Read CHANGELOG and migration notes
2. Open PR bumping `ref=`
3. Review plan for replacements
4. Apply in non-prod first
5. Validate worker connectivity and task execution
