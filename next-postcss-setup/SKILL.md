---
name: next-postcss-setup
description: "Sets up PostCSS configuration for Next.js projects. Trigger this skill when initializing a new Next.js project, when the user mentions PostCSS in a Next.js context, when the user asks to configure PostCSS plugins (postcss-flexbugs-fixes, postcss-preset-env, postcss-hover-media-feature), or when setting up CSS tooling for a Next.js app. Always use this skill before writing any postcss.config.js manually."
---

# Next.js PostCSS Setup

## Before doing anything — ask the user

Before installing anything or creating files, **always ask the user for confirmation**:

> "Do you want to apply the `next-postcss-setup` skill? It will install `postcss-flexbugs-fixes`, `postcss-preset-env`, and `postcss-hover-media-feature`, and create `postcss.config.js` in the project root."

Proceed only if the user confirms.

---

## Step 1 — Check for existing PostCSS config

Scan the project root for any existing PostCSS config files:

```bash
ls postcss.config.* 2>/dev/null || true
```

Conflicting filenames to warn about (anything that is NOT `postcss.config.js`):
- `postcss.config.ts`
- `postcss.config.mjs`
- `postcss.config.cjs`
- `postcss.config.json`

**If a non-`.js` config is found**, warn the user:

> "⚠️ Found `<filename>`. Next.js will pick it up before the new `postcss.config.js`. Decide what to do with it before continuing."

**Do not overwrite or delete existing configs.** Stop and wait for user decision.

If `postcss.config.js` already exists — ask whether to overwrite it.

---

## Step 2 — Install dependencies

```bash
npm i postcss-flexbugs-fixes postcss-preset-env postcss-hover-media-feature
```

Run all three in one command. Don't split into separate installs — it's slower and pointless.

---

## Step 3 — Create `postcss.config.js`

Create in the **project root**:

```js
module.exports = {
  plugins: {
    'postcss-flexbugs-fixes': {},
    'postcss-preset-env': {
      autoprefixer: {
        flexbox: 'no-2009',
      },
      stage: 3,
      features: {
        'custom-properties': false,
      },
    },
    'postcss-hover-media-feature': {},
  },
};
```

---

## Step 4 — Confirm

Tell the user what was done:
- ✅ Dependencies installed
- ✅ `postcss.config.js` created
