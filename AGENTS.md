# Agent Instructions

## Package Manager

Use **Yarn 4** (Corepack): `yarn install`, `yarn test`, `yarn build`, `yarn lint`, `yarn format`

- `yarn test` - run vitest
- `yarn build` - compile all sub-actions via ncc
- `yarn all` - format + lint + test + build

## Key Conventions

- Sub-actions live in `<service>/` dirs (redis, postgres, mongodb, nats, kafka, tcp, android-emulator)
- Each sub-action has its own `action.yml` and `dist/index.js` (built via `yarn build`)
- Shared code in `src/shared/` (inputs, wait loop, TCP, types, logging)
- Tests in `__tests__/` mirroring `src/` structure
- Pre-commit hook runs `yarn format` and `yarn build` automatically

## CI Workflows

- Each service has a test workflow in `.github/workflows/test-<service>.yml`
- Docker tests use `./` with patched `action.yml`; Node tests use `./<service>/` sub-actions
- Node sub-action tests must use `host: localhost` with explicit `ports:` mappings (services are not DNS-resolvable from the host runner)
- **Node version:** sourced from `.nvmrc` (single source of truth). Workflows must use `node-version-file: .nvmrc`, never a hardcoded `node-version:`. Renovate's `nvm` manager bumps `.nvmrc` automatically.
- **Workflow scripting:** prefer `actions/github-script` over shell for GitHub API calls and logic; reserve `run:` shell for simple commands. Pass untrusted/interpolated values via `env:` and read them from `process.env` (never inline `${{ }}` into a script body).

## General Patterns

- **JSON processing:** Use `jq` in shell, never `python3`
- **YAML processing/validation:** Use `yq` in shell, never `python3`

## Compaction

After every compaction operation, read this file again to ensure all guidelines are followed and up to date.
