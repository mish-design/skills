---
name: stylelint-setup
description: "Sets up Stylelint for new or existing projects. Trigger this skill when: initializing a new project, when the user asks to install or configure Stylelint, when the user mentions linting CSS or SCSS, or when setting up code quality tooling. Always use this skill instead of manually configuring Stylelint."
---

# Stylelint Setup

## Before doing anything — ask the user

Always ask for confirmation before making any changes:

> "Do you want to apply the `stylelint-setup` skill? It will install Stylelint with SCSS and property-order configs, create `.stylelintrc.json`, and add lint scripts to `package.json`."

Proceed only if the user confirms.

---

## Step 1 — Check for existing config and scripts

**Check for existing Stylelint config:**

```bash
ls .stylelintrc* stylelint.config.* 2>/dev/null || true
```

If any config file is found, ask the user:

> "Found existing Stylelint config: `<filename>`. Do you want to (a) overwrite it, (b) merge manually, or (c) skip creating the config?"

Wait for the user's decision before proceeding.

**Check for existing Stylelint scripts in `package.json`:**

Look for `"stylelint"` or `"stylelint:fix"` keys in the `scripts` section of `package.json`.

If found, ask the user:

> "Found existing Stylelint scripts in `package.json`. Do you want to (a) overwrite them, (b) keep existing and skip, or (c) rename the new ones?"

Wait for the user's decision before proceeding.

---

## Step 2 — Install dependencies

Use a package manager to install dependencies from package.json
If no package manager is specified, use npm

```bash
npm i -D stylelint stylelint-config-standard stylelint-config-standard-scss stylelint-config-recess-order
```

---

## Step 3 — Create `.stylelintrc.json`

Create in the **project root** (unless user chose to skip in Step 1):

```json
{
  "extends": [
    "stylelint-config-standard",
    "stylelint-config-standard-scss",
    "stylelint-config-recess-order"
  ],
  "rules": {
    "selector-class-pattern": [
      "^[a-zA-Z]+[a-zA-Z0-9]*$",
      {
        "message": "Class names should use camelCase"
      }
    ],
    "declaration-block-no-redundant-longhand-properties": null
  }
}
```

---

## Step 4 — Add scripts to `package.json`

Add the following to the `scripts` section (unless user chose to skip in Step 1):

```
"stylelint": "stylelint \"**/*.{css,scss}\" --ignore-path .gitignore",
"stylelint:fix": "stylelint \"**/*.{css,scss}\" --fix --ignore-path .gitignore"
```

Edit `package.json` carefully — do not touch any other fields. Use a script or direct JSON manipulation, not string replacement.

---

## Step 5 — Confirm

Tell the user what was done:

- ✅ Dependencies installed: `stylelint`, `stylelint-config-standard`, `stylelint-config-standard-scss`, `stylelint-config-recess-order`
- ✅ `.stylelintrc.json` created
- ✅ Scripts added to `package.json`: `stylelint`, `stylelint:fix`

Note: `stylelint-config-recess-order` enforces a consistent CSS property order (positioning → display → box model → typography → visual). This catches property ordering issues that would otherwise slip through review.