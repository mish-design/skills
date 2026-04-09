---
name: git-hooks-precommit
description: Add a pre-commit workflow using Husky + lint-staged to run linters/formatters on staged files. Use when a user asks for pre-commit hooks, linting before commit, auto-fix on commit, or setting up Husky/lint-staged.
---

# Git Hooks: Pre-commit (Husky + lint-staged)

This skill installs and configures a **pre-commit** hook that runs formatters/linters on **staged files** (fast, consistent, CI-friendly).

## Goals

- Run formatting + lint fixes **before every commit**
- Only touch **staged** files (via `lint-staged`)
- Keep the setup **tool-agnostic** (works for Vue/React/Node repos)
- Avoid fragile checks that break commits (typecheck is optional)

## Inputs to decide (ask/derive)

- **Package manager**: Yarn / npm / pnpm
- **Linters present**: ESLint? Prettier?
- **File types**: `.js/.ts/.vue/.json/.md/.css` etc.
- **Policy**: block commit on failures (default: **yes**)

## Step 1 — Install dev dependencies

Choose one:

### Yarn

```bash
yarn add -D husky lint-staged
```

### npm

```bash
npm i -D husky lint-staged
```

### pnpm

```bash
pnpm add -D husky lint-staged
```

## Step 2 — Add/merge scripts in `package.json`

Add these without overwriting existing scripts:

```json
{
  "scripts": {
    "prepare": "husky",
    "lint:staged": "lint-staged"
  }
}
```

## Step 3 — Create a lint-staged config

Prefer a JS config file at repo root: `.lintstagedrc.js`

Use safe defaults:

```js
module.exports = {
  '*.{js,jsx,ts,tsx,vue}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,html,css,scss,yml,yaml}': ['prettier --write'],
};
```

Notes:

- Keep it **fast** and **deterministic**
- Avoid calling typecheck here by default (can be slow/flaky)

## Step 4 — Initialize Husky and create the hook

Initialize:

```bash
npx husky init
```

That creates `.husky/` and a default hook. Replace `.husky/pre-commit` with:

```sh
#!/usr/bin/env sh
echo "Running pre-commit..."
npx lint-staged
```

## Step 5 — Ensure generated / local-only files are ignored

Add common entries if needed:

- `node_modules/`
- `dist/`
- `.yarn/install-state.gz` (Yarn 2+/4)

## Step 6 — Verify

1. Change a file that matches lint-staged patterns
2. Stage it: `git add <file>`
3. Commit: `git commit -m "test"`
4. Confirm the hook runs and auto-fixes get re-staged

## Customization (best practices)

- **Monorepos**: run `lint-staged` at workspace root; keep globs tight
- **ESLint**: use `eslint --cache` in CI, but not in hooks (cache may be stale)
- **Typecheck**: add an opt-in hook:
  - `pre-push`: `tsc -p tsconfig.json --noEmit` (or `vue-tsc`)
  - or a separate script `yarn typecheck`
- **Block vs warn**: pre-commit should usually **block** on errors; keep formatting auto-fixable

## Done checklist

- ✅ `husky` + `lint-staged` installed
- ✅ `prepare` script added
- ✅ `.lintstagedrc.js` created
- ✅ `.husky/pre-commit` runs `npx lint-staged`
- ✅ Commit runs cleanly on a test change
