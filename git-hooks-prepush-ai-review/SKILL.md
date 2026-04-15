---
name: git-hooks-prepush-ai-review
description: Add a pre-push AI review hook that sends diffs/context to an OpenAI-compatible LLM endpoint and writes a Markdown report (AI_REVIEW.md). Use when a user asks for AI code review before push, automated review reports, or LLM-based quality gates.
---

# Git Hooks: Pre-push AI Review (LLM + OpenAI-compatible API)

## Overview

Adds a **pre-push** hook that generates `AI_REVIEW.md` using a real LLM based on:

- Unified diff of changed source files
- Project rules (`.cursorrules`, optional)
- Current versions of changed files (bounded by limits)

Design principles:

- **Non-blocking** — push continues even if AI fails
- **Safe** — secret redaction + size limits
- **Portable** — any OpenAI-compatible API endpoint

## Step 1 — Check for linters first

Before AI review, check `package.json`:

1. Look for ESLint/Prettier in `devDependencies` or `dependencies`
2. If linters found — run them on changed files (improves AI review quality)
3. If no linters — tell the user to run the **pre-commit** skill first to install them

## Step 2 — Create the AI review script

Create `scripts/ai-review.js` (Node 18+).

### Critical: Load .env.local manually

**This is a known bug**. Husky hooks do NOT auto-load `.env.local`, so `OPENAI_API_KEY` will be undefined and the review silently skips. Fix it with this pattern:

```javascript
function loadDotEnvFile(relPath) {
  const absPath = path.join(PROJECT_ROOT, relPath);
  if (!fileExists(absPath)) return;

  const raw = fs.readFileSync(absPath, "utf-8");
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;

    const eqIdx = trimmed.indexOf("=");
    if (eqIdx === -1) continue;

    const key = trimmed.slice(0, eqIdx).trim();
    let val = trimmed.slice(eqIdx + 1).trim();

    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }

    // Never override real environment variables (CI / shell).
    // This preserves expected precedence: env vars > .env.local > .env
    if (key && process.env[key] === undefined) {
      process.env[key] = val;
    }
  }
}

// CRITICAL: Husky doesn't auto-load .env files
// Load .env first, then .env.local (both only fill missing values)
loadDotEnvFile(".env");
loadDotEnvFile(".env.local");
```

### Script structure

Implement these functions:

| Function | Purpose |
|----------|---------|
| `loadDotEnvFile(relPath)` | Load env files (see above) |
| `redactSecrets(text)` | Remove secrets before sending to LLM |
| `detectBaseRef()` | Find base ref: `@{u}` → `origin/dev` → `origin/main` → `origin/master` |
| `getChangedFiles(baseRef)` | Get `src/*.vue/.js/.ts` files changed since base ref |
| `getUnifiedDiff(baseRef, files)` | Build diff with size limits |
| `buildContextPayload(files)` | Read file contents with truncation |
| `buildPrompt({...})` | Construct prompt for LLM (in Russian, Markdown output) |
| `callOpenAI({prompt})` | POST to OpenAI-compatible `/chat/completions` |
| `wrapReport({...})` | Format final `AI_REVIEW.md` |
| `main()` | Orchestrate the flow |
| `.catch()` | **Always exit(0)** — do not block push on errors |

### Secret redaction patterns

Apply these redactions before sending to LLM:

```javascript
// Headers
t = t.replace(/(Authorization:\s*Bearer\s+)[^\s'"]+/gi, "$1[REDACTED]");

// Key=value in code
t = t.replace(
  /(\b(?:OPENAI_API_KEY|API_KEY|TOKEN|SECRET|PASSWORD)\b\s*=\s*)[^\n\r]+/gi,
  "$1[REDACTED]"
);

// PEM blocks
t = t.replace(
  /-----BEGIN [A-Z ]+-----[\s\S]*?-----END [A-Z ]+-----/g,
  "-----BEGIN [REDACTED]-----\n[REDACTED]\n-----END [REDACTED]-----"
);

// OpenAI keys
t = t.replace(/\bsk-[A-Za-z0-9]{20,}\b/g, "sk-[REDACTED]");
```

### Base ref detection

```javascript
function detectBaseRef() {
  // 1) upstream tracking branch
  try {
    const upstream = execSync(
      "git rev-parse --abbrev-ref --symbolic-full-name @{u}",
      { encoding: "utf-8" }
    ).trim();
    if (upstream) return upstream;
  } catch {}

  // 2) fallback candidates
  for (const ref of ["origin/dev", "origin/main", "origin/master", "dev", "main", "master"]) {
    try {
      execSync(`git rev-parse --verify ${ref}`, { stdio: "pipe" });
      return ref;
    } catch {}
  }
  return "";
}
```

### Size limits (use env vars with defaults)

```javascript
const MAX_FILES = Number(process.env.AI_REVIEW_MAX_FILES || 12);
const MAX_FILE_CHARS = Number(process.env.AI_REVIEW_MAX_FILE_CHARS || 40000);
const MAX_DIFF_CHARS = Number(process.env.AI_REVIEW_MAX_DIFF_CHARS || 120000);
```

## Step 3 — Add package.json script

```json
{
  "scripts": {
    "ai-review": "node scripts/ai-review.js"
  }
}
```

## Step 4 — Add `.env.example`

```dotenv
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
OPENAI_BASE_URL=https://api.openai.com/v1

AI_REVIEW_MAX_FILES=12
AI_REVIEW_MAX_FILE_CHARS=40000
AI_REVIEW_MAX_DIFF_CHARS=120000
```

Users should copy to `.env.local` (gitignored).

## Step 5 — Ignore report file

In `.gitignore`:

```gitignore
AI_REVIEW.md
```

## Step 6 — Add Husky pre-push hook

```sh
#!/usr/bin/env sh
echo "Running AI review before push..."
yarn ai-review || true
echo "AI review done (push not blocked)."
```

## Step 7 — Verify

1. Make a small change in `src/`
2. Commit it
3. Set `OPENAI_API_KEY` in `.env.local`
4. Run `git push`
5. Confirm `AI_REVIEW.md` was generated

## Done checklist

- `scripts/ai-review.js` exists and runs locally
- `.env.example` exists, `.env.local` used for real secrets
- `AI_REVIEW.md` is ignored by git
- `.husky/pre-push` runs `yarn ai-review`
- Push succeeds and does not block on AI failure
