---
name: git-hooks-prepush-ai-review
description: Add a pre-push AI review hook that sends diffs/context to an OpenAI-compatible LLM endpoint and writes a Markdown report (AI_REVIEW.md). Use when a user asks for AI code review before push, automated review reports, or LLM-based quality gates.
---

# Git Hooks: Pre-push AI Review (LLM + OpenAI-compatible API)

This skill adds a **pre-push** hook that generates a structured review report (`AI_REVIEW.md`) using a **real LLM**, based on:

- Unified diff of changed source files
- Project rules (optional, e.g. `.cursorrules`)
- Current versions of changed files (bounded by limits)

The hook is designed to be:

- **Non-blocking by default** (push continues even if AI fails)
- **Safe** (basic secret redaction + size limits)
- **Portable** (works with any OpenAI-compatible API endpoint)

## Security model (important)

This setup may send code diffs to a remote LLM endpoint. To reduce risk:

- Redact common secret patterns before sending
- Avoid including `.env*` files
- Limit request size (files/diff chars)
- Keep `AI_REVIEW.md` out of git

## Step 1 — Check for linters and run them first

Before running AI review, check if the project has linters installed:

1. Check `package.json` for lint-related scripts: `lint`, `lint:fix`, `eslint`, `prettier`
2. If linters exist, run them on changed files **before** sending to AI (this reduces noise in the diff and improves review quality)
3. If no linters found, inform the user that linting is not set up and suggest running the **pre-commit** skill first to install Husky + lint-staged

## Step 2 — Add an AI review script

Create `scripts/ai-review.js` (Node 18+ recommended). The script should:

- Detect a base ref:
  - upstream `@{u}` if available
  - else try `origin/dev`, `origin/main`, `origin/master`, etc.
- Collect changed files under `src/` with extensions `.vue/.js/.ts`
- Build unified diff limited by size
- Redact secrets
- Call OpenAI-compatible `POST /chat/completions`
- Write `AI_REVIEW.md`
- Exit with code `0` even on failures (non-blocking)

## Step 3 — Add package.json script

Merge into `package.json`:

```json
{
  "scripts": {
    "ai-review": "node scripts/ai-review.js"
  }
}
```

## Step 4 — Add `.env.example` for configuration

Add a tracked `.env.example` such as:

```dotenv
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
OPENAI_BASE_URL=https://api.openai.com/v1

AI_REVIEW_MAX_FILES=12
AI_REVIEW_MAX_FILE_CHARS=40000
AI_REVIEW_MAX_DIFF_CHARS=120000
```

Recommend users copy it to `.env.local` (ignored by git).

## Step 5 — Ignore the report file

Add to `.gitignore`:

```gitignore
AI_REVIEW.md
```

## Step 6 — Add Husky pre-push hook

Ensure Husky is installed and initialized (see pre-commit skill).

Create/replace `.husky/pre-push`:

```sh
#!/usr/bin/env sh
echo "Running AI review before push..."
yarn ai-review || true
echo "AI review done (push not blocked)."
```

Optionally print the top of the report:

```sh
test -f AI_REVIEW.md && head -n 25 AI_REVIEW.md || true
```

## Step 7 — Verify

1. Make a small change in `src/`
2. Commit it
3. Set env vars (prefer `.env.local`)
4. Run `git push`
5. Confirm `AI_REVIEW.md` was generated

## Best practices / customization

- **Blocking mode (optional)**:
  - Parse the report and `exit 1` if it contains a "critical issues" marker
  - Only enable after team buy-in (to avoid frustration)
- **Faster reviews**:
  - Reduce `AI_REVIEW_MAX_*` limits
  - Only include `.vue` and key `.js` files
- **Safer reviews**:
  - Expand redaction patterns (org-specific tokens)
  - Add an allowlist of directories (e.g. only `src/components/`)
- **Provider-agnostic**:
  - Support `OPENAI_BASE_URL` so it works with OpenAI, Azure OpenAI, or other compatible gateways

## Done checklist

- ✅ `scripts/ai-review.js` exists and runs locally
- ✅ `.env.example` exists, `.env.local` used for real secrets
- ✅ `AI_REVIEW.md` is ignored by git
- ✅ `.husky/pre-push` runs `yarn ai-review`
- ✅ Push generates a report and does not block on AI failure
