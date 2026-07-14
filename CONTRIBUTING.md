# Contributing

## Development

1. Fork and branch from `main`.
2. Make changes under `modules/`, `examples/`, `docs/`, or `tests/`.
3. Run `./scripts/validate.sh`.
4. Open a draft PR; keep it draft until CI is green.

## Commit messages

Use Conventional Commits: `type(scope): description`
(e.g. `feat(cursor-worker-pool): enforce digest pinning`).

## Module guidelines

- Core must not instantiate optional modules.
- Prefer validations and preconditions over silent unsafe defaults.
- Never accept plaintext secret values.
- Update `docs/compatibility.md` when provider or Cursor behavior changes.
- Add or update examples for user-facing input changes.

## Releases

Maintainers cut semantic version tags. See [docs/upgrades.md](docs/upgrades.md).
