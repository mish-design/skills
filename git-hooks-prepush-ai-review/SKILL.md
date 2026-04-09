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

## Step 2 — Add the AI review script

**IMPORTANT**: Use the exact implementation below. A common bug is that Husky hooks do not automatically load `.env.local`, so the API key ends up undefined and the review silently skips. The script below includes a `loadDotEnvFile` function that fixes this — **do not simplify or rewrite it**.

Create `scripts/ai-review.js` with this exact code:

```javascript
#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const PROJECT_ROOT = process.cwd();
const RULES_FILE = path.join(PROJECT_ROOT, ".cursorrules");
const REPORT_FILE = path.join(PROJECT_ROOT, "AI_REVIEW.md");

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

    if (key && process.env[key] === undefined) {
      process.env[key] = val;
    }
  }
}

// CRITICAL: Husky hooks don't auto-load .env.local — load it ourselves.
loadDotEnvFile(".env.local");
loadDotEnvFile(".env");

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";
const OPENAI_BASE_URL = (
  process.env.OPENAI_BASE_URL || "https://api.openai.com/v1"
).replace(/\/$/, "");

const MAX_FILES = Number(process.env.AI_REVIEW_MAX_FILES || 12);
const MAX_FILE_CHARS = Number(process.env.AI_REVIEW_MAX_FILE_CHARS || 40000);
const MAX_DIFF_CHARS = Number(process.env.AI_REVIEW_MAX_DIFF_CHARS || 120000);

function safeExec(cmd) {
  return execSync(cmd, { encoding: "utf-8" }).trim();
}

function fileExists(absPath) {
  try {
    fs.accessSync(absPath, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

function readTextFile(absPath, maxChars = 60000) {
  const raw = fs.readFileSync(absPath, "utf-8");
  if (raw.length <= maxChars) return raw;
  return raw.slice(0, maxChars) + "\n\n/* … truncated … */\n";
}

function redactSecrets(text) {
  if (!text) return text;
  let t = text;

  t = t.replace(/(Authorization:\s*Bearer\s+)[^\s'"]+/gi, "$1[REDACTED]");
  t = t.replace(/(Authorization:\s*Basic\s+)[^\s'"]+/gi, "$1[REDACTED]");
  t = t.replace(/(Cookie:\s*)[^\n\r]+/gi, "$1[REDACTED]");
  t = t.replace(/(Set-Cookie:\s*)[^\n\r]+/gi, "$1[REDACTED]");

  t = t.replace(
    /(\b(?:OPENAI_API_KEY|API_KEY|TOKEN|ACCESS_TOKEN|REFRESH_TOKEN|SECRET|PASSWORD|PRIVATE_KEY|CLIENT_SECRET|GITHUB_TOKEN)\b\s*=\s*)[^\n\r]+/gi,
    "$1[REDACTED]",
  );
  t = t.replace(
    /(\b(?:openai_api_key|apiKey|token|accessToken|refreshToken|secret|password|privateKey|clientSecret)\b\s*:\s*)['"][^'"]+['"]/gi,
    '$1"[REDACTED]"',
  );

  t = t.replace(
    /-----BEGIN [A-Z ]+-----[\s\S]*?-----END [A-Z ]+-----/g,
    "-----BEGIN [REDACTED]-----\n[REDACTED]\n-----END [REDACTED]-----",
  );

  t = t.replace(/\bsk-[A-Za-z0-9]{20,}\b/g, "sk-[REDACTED]");

  return t;
}

function readProjectRules() {
  if (!fileExists(RULES_FILE)) return "";
  return redactSecrets(readTextFile(RULES_FILE, 80000));
}

function detectBaseRef() {
  try {
    const upstream = safeExec(
      "git rev-parse --abbrev-ref --symbolic-full-name @{u}",
    );
    if (upstream) return upstream;
  } catch {}

  const candidates = [
    "origin/dev",
    "origin/main",
    "origin/master",
    "dev",
    "main",
    "master",
  ];
  for (const ref of candidates) {
    try {
      safeExec(`git rev-parse --verify ${ref}`);
      return ref;
    } catch {}
  }
  return "";
}

function getChangedFiles(baseRef) {
  const out = safeExec(
    `git diff --name-only --diff-filter=ACMRT ${baseRef}...HEAD`,
  );
  if (!out) return [];
  return out
    .split("\n")
    .map((s) => s.trim())
    .filter(Boolean)
    .filter((p) => p.startsWith("src/"))
    .filter((p) => /\.(vue|js|ts)$/.test(p));
}

function getUnifiedDiff(baseRef, files) {
  if (files.length === 0) return "";

  const limitedFiles = files.slice(0, MAX_FILES);
  const fileArgs = limitedFiles.map((f) => `"${f}"`).join(" ");
  let diff = "";
  try {
    diff = execSync(`git diff --unified=6 ${baseRef}...HEAD -- ${fileArgs}`, {
      encoding: "utf-8",
      maxBuffer: 10 * 1024 * 1024,
    });
  } catch (e) {
    diff = (e && e.stdout) || "";
  }

  diff = redactSecrets(diff);

  if (diff.length <= MAX_DIFF_CHARS) return diff;
  return (
    diff.slice(0, MAX_DIFF_CHARS) +
    "\n\n/* … diff truncated (size limit) … */\n"
  );
}

function buildContextPayload(files) {
  const entries = [];
  for (const rel of files.slice(0, MAX_FILES)) {
    const abs = path.join(PROJECT_ROOT, rel);
    if (!fileExists(abs)) continue;
    const content = redactSecrets(readTextFile(abs, MAX_FILE_CHARS));
    entries.push({ path: rel, content });
  }
  return entries;
}

function buildPrompt({ rules, baseRef, files, diff, fileContents }) {
  const filesList = files.map((f) => `- ${f}`).join("\n");
  const contentBlocks = fileContents
    .map(
      (f) =>
        `\n---\nFILE: ${f.path}\n---\n` +
        f.content +
        (f.content.endsWith("\n") ? "" : "\n"),
    )
    .join("");

  return [
    "Ты — опытный senior-разработчик Vue 3/Vuetify/Pinia.",
    "Сделай РЕАЛЬНОЕ AI code review по изменениям в проекте.",
    "",
    "Требования к результату:",
    "- Пиши по-русски.",
    "- Структура отчёта должна быть в Markdown.",
    "- Для каждого файла: перечисли проблемы по категориям:",
    "  1) Баги/потенциальные проблемы (что может сломаться)",
    "  2) Best practices / соответствие Vue 3 и .cursorrules",
    "  3) Улучшения/кодстайл (некритично, но стоит сделать)",
    "- Для каждой проблемы укажи: место (файл + строка/фрагмент), что не так, как исправить.",
    "- Не переписывай код целиком. Только рекомендации.",
    "- Учитывай правила из .cursorrules как source of truth.",
    "",
    `База сравнения: ${baseRef}`,
    "Изменённые файлы:",
    filesList || "(нет)",
    "",
    "=== .cursorrules ===",
    rules || "(нет правил)",
    "",
    "=== unified diff ===",
    diff || "(diff пустой)",
    "",
    "=== текущие версии изменённых файлов (для контекста) ===",
    contentBlocks || "(нет содержимого)",
    "",
    "В конце добавь краткую сводку: сколько критичных проблем, сколько некритичных, и топ-3 рекомендации.",
  ].join("\n");
}

async function callOpenAI({ prompt }) {
  const url = `${OPENAI_BASE_URL}/chat/completions`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      temperature: 0.2,
      messages: [
        {
          role: "system",
          content:
            "Ты делаешь code review. Будь конкретным, практичным и аккуратным. Не выдумывай несуществующие файлы.",
        },
        { role: "user", content: prompt },
      ],
    }),
  });

  if (!res.ok) {
    const txt = await res.text().catch(() => "");
    throw new Error(`OpenAI API error ${res.status}: ${txt || res.statusText}`);
  }

  const data = await res.json();
  const content = data?.choices?.[0]?.message?.content;
  if (!content) throw new Error("Empty model response");
  return content;
}

function wrapReport({ model, baseRef, files, body }) {
  const ts = new Date().toLocaleString("ru-RU");
  return [
    "# AI Review Report",
    "",
    `**Дата:** ${ts}`,
    `**Модель:** ${model}`,
    `**База:** ${baseRef}`,
    `**Файлов:** ${files.length}`,
    "",
    "---",
    "",
    body.trim(),
    "",
  ].join("\n");
}

async function main() {
  console.log("🤖 AI-ревью (LLM) перед push…");

  const baseRef = detectBaseRef();
  if (!baseRef) {
    console.log(
      "⚠️  Не удалось определить base ref для diff. Пропускаю AI-ревью.",
    );
    fs.writeFileSync(
      REPORT_FILE,
      "# AI Review Report\n\nНе удалось определить base ref для diff.\n",
    );
    return;
  }

  const files = getChangedFiles(baseRef);
  if (files.length === 0) {
    console.log("✅ Нет изменённых src/*.vue/js/ts файлов для ревью.");
    fs.writeFileSync(
      REPORT_FILE,
      "# AI Review Report\n\nНет изменённых файлов.\n",
    );
    return;
  }

  if (!OPENAI_API_KEY) {
    console.log(
      "⚠️  OPENAI_API_KEY не задан — пропускаю реальное AI-ревью (push не блокируется).",
    );
    fs.writeFileSync(
      REPORT_FILE,
      [
        "# AI Review Report",
        "",
        "OPENAI_API_KEY не задан, поэтому LLM-ревью не выполнялось.",
        "",
        "Изменённые файлы:",
        ...files.map((f) => `- ${f}`),
        "",
      ].join("\n"),
    );
    return;
  }

  const rules = readProjectRules();
  const diff = getUnifiedDiff(baseRef, files);
  const fileContents = buildContextPayload(files);

  console.log(`📁 Файлы для ревью: ${files.length}`);
  console.log(`🧾 Собираю diff и контекст…`);

  const prompt = buildPrompt({ rules, baseRef, files, diff, fileContents });
  console.log(`📡 Отправляю в модель (${OPENAI_MODEL})…`);

  const reviewBody = await callOpenAI({ prompt });
  const report = wrapReport({
    model: OPENAI_MODEL,
    baseRef,
    files,
    body: reviewBody,
  });
  fs.writeFileSync(REPORT_FILE, report);

  console.log(`✅ Отчёт сохранён: ${REPORT_FILE}`);
}

main().catch((err) => {
  const msg = err && err.message ? err.message : String(err);
  console.error("⚠️  AI-ревью упало:", msg);
  try {
    fs.writeFileSync(
      REPORT_FILE,
      `# AI Review Report\n\nAI-ревью завершилось ошибкой:\n\n\`\`\`\n${msg}\n\`\`\`\n`,
    );
  } catch {}
  process.exit(0);
});
```

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
