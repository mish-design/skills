---
name: dependency-audit
description: Audit project dependencies for security vulnerabilities, outdated packages, and unused dependencies. Use when a user asks to audit dependencies, check for vulnerabilities, find outdated packages, or clean up unused dependencies.
---

# Dependency Audit

Three audit layers:

```
Security      → npm audit
Outdated      → ncu (npm-check-updates)
Unused        → depcheck
```

## Before you start

Ask the user:

```
? Run full audit or specific check?
  1) Full audit (all three)
  2) Security only (npm audit)
  3) Outdated only (ncu)
  4) Unused only (depcheck)
```

## Step 1 — Security audit (npm audit)

Run without args to check for vulnerabilities:

```bash
npm audit
```

For a more detailed JSON report:

```bash
npm audit --json > audit-report.json
```

### Severity levels

| Level | Meaning |
|-------|---------|
| `critical` | Direct threat, immediate fix required |
| `high` | Significant risk, fix soon |
| `moderate` | Less severe, timing dependent |
| `low` | Minor issue, low priority |

### Auto-fix low severity:

```bash
npm audit fix
```

### Fix specific vulnerability:

```bash
npm audit fix --force  # use carefully — may break things
```

### Add to CI:

```yaml
# .github/workflows/audit.yml
name: Security Audit

on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      - name: Run npm audit
        run: npm audit --audit-level=high
```

The `--audit-level=high` fails the build if any `high` or `critical` vulnerabilities exist.

## Step 2 — Outdated packages (ncu)

Install ncu globally or as dev dependency:

```bash
npm i -g npm-check-updates
# or
npm i -D npm-check-updates
```

### Check for outdated:

```bash
ncu
```

### Show all outdated (including major):

```bash
ncu --upgrade-all
```

### Interactive upgrade:

```bash
ncu --interactive
```

### Target specific package:

```bash
ncu --upgrade --package package.json
ncu -u react react-dom  # upgrade only react packages
```

### ncu options

| Flag | What it does |
|------|--------------|
| `-u` | Upgrade package.json |
| `--target major` | Include major version changes |
| `--target minor` | Include minor + patch (default) |
| `--target patch` | Only patch updates |
| `--interactive` | Ask before each upgrade |
| `-l 3` | Limit to depth of 3 (show indirect) |

### Check specific package ecosystem:

```bash
ncu --package @types/*  # only @types packages
ncu --reject axios@0.14  # reject specific version
```

### Per-project config (`.ncurc.json`):

```json
{
  "upgrade": true,
  "target": "minor",
  "reject": ["lodash@<4.17.21"],
  "ignore": ["@types/node"]
}
```

With this config, `ncu` alone respects these settings.

### Add to CI:

```bash
ncu --upgrade --package package.json
```

The `--upgrade` flag updates package.json. For dry-run first:

```bash
ncu --dry-run
```

Or use the GitHub Actions:

```yaml
- name: Check outdated dependencies
  run: npx npm-check-updates --upgrade --package package.json
```

`GITHUB_TOKEN` is not needed for public repos. For private, ncu may need it to access GitHub API.

## Step 3 — Unused dependencies (depcheck)

Install:

```bash
npm i -D depcheck
```

### Run:

```bash
depcheck
```

### Common output:

```
Unused devDependencies:
 * typescript (not main)
 * @types/node (not main)
 * ts-node (not main)
```

### With path:

```bash
depcheck ./path/to/project
```

### Special handling for non-standard imports:

```bash
# Ignore specific patterns
depcheck --ignore-types types,optional

# Or ignore specific packages
depcheck --ignore jest,@types/node
```

### Remove unused packages directly:

```bash
npm uninstall @types/jest ts-node rimraf
```

Or remove all unused in one pass:

```bash
npm uninstall $(depcheck --package package.json --dev --prod 2>/dev/null | grep '^Unused' | awk '{print $3}')
```

### Add to cleanup script:

```json
{
  "scripts": {
    "depcheck": "depcheck",
    "clean:unused": "depcheck --remove-empty"
  }
}
```

Note: `--remove-empty` removes unused dependencies from package.json automatically. Use with caution — commit before running.

## Step 4 — Combined workflow

For a complete dependency health check:

```bash
#!/bin/bash
# scripts/dep-audit.sh

echo "=== Security Audit ==="
npm audit --audit-level=high || echo "Audit completed with warnings"

echo "=== Outdated Packages ==="
ncu --json 2>/dev/null || true

echo "=== Unused Dependencies ==="
depcheck || true
```

## Step 5 — Interpret results

### npm audit output

```
found 5 vulnerabilities (2 high, 3 moderate)
  Run npm audit fix to fix 3 of them.
  2 high severity vulnerabilities require manual review.
```

Action: Fix the 2 high manually first. Never ignore `critical`.

### ncu output

```
react       17.0.1  →  18.2.0
axios       0.21.0  →  1.6.0
lodash     4.14.0  →  4.17.21  (security fix)
```

Action: Review major upgrades in PR. Don't blindly upgrade everything.

### depcheck output

```
Unused dependencies:
 * @types/jest
 * ts-node
 * rimraf

Unused devDependencies:
 * @storybook/testing-react
```

Action: Remove with `npm uninstall`. Some may be used by custom scripts or tooling.

## Done checklist

- `npm audit` run and vulnerabilities reviewed
- `ncu` report generated, major upgrades tracked in PR
- `depcheck` run, unused dependencies identified
- Security workflow added to CI (if github-actions-setup exists)
- No critical/high vulnerabilities left unaddressed