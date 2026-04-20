---
name: github-actions-setup
description: Set up GitHub Actions CI workflow for Node.js/TypeScript projects. Use when asked to add CI, configure GitHub Actions, set up GitHub workflow, or automate tests on push/PR.
---

# GitHub Actions Setup

Create a production-ready CI workflow in `.github/workflows/ci.yml`.

## Step 1 — Detect project

Check `package.json`:
- No `dependencies` with Node runtime → skip or ask
- Node.js project → proceed

Check lockfile:
- `pnpm-lock.yaml` → pnpm
- `yarn.lock` → yarn
- `package-lock.json` → npm
- nothing → default to npm

Check existing workflows:
- `.github/workflows/*.yml` exists → extend or merge, do not overwrite blindly

## Step 2 — Create workflow directory

```bash
mkdir -p .github/workflows
```

## Step 3 — Create `ci.yml`

**npm:**
```yaml
name: CI

on:
  push:
    branches: [$default-branch]
    paths-ignore:
      - '**.md'
      - 'docs/**'
  pull_request:
    branches: [$default-branch]
    paths-ignore:
      - '**.md'
      - 'docs/**'

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  ci:
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'
          cache: 'npm'

      - run: npm ci

      - run: npm run build --if-present

      - run: npm test
```

**pnpm:**
```yaml
      - uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'
          cache: 'pnpm'

      - run: corepack enable && pnpm install --frozen-lockfile
```

**yarn:**
```yaml
      - uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'
          cache: 'yarn'

      - run: yarn install --immutable  # or --frozen-lockfile for Yarn 1
```

If the project has multiple Node versions to test, add a matrix:

```yaml
jobs:
  ci:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    strategy:
      matrix:
        node-version: ['18', '20']

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - run: npm ci
      - run: npm run build --if-present
      - run: npm test
```

If the project uses ESLint or Prettier and already has `lint` script in `package.json`, add a lint step before build:

```yaml
      - run: npm run lint
```

## Step 4 — Verify

1. Open the repository on GitHub → Actions tab
2. Push a small change or create a PR
3. Confirm the workflow runs and passes

## Done

- `.github/workflows/ci.yml` created
- workflow triggers on push and PR to `$default-branch`
- redundant runs are cancelled
- permissions are minimal
- cache is configured for the detected package manager
