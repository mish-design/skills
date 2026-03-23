---
name: prettier-setup
description: Set up Prettier code formatter in a project. Use this skill whenever a user mentions setting up Prettier, code formatting, initializing a new project with formatting tools, or asks to add prettier/pretty-quick to their project. Trigger on phrases like "set up prettier", "add code formatting", "initialize prettier", "configure prettier", or when onboarding a new project.
---

# Prettier Setup

Installs and configures Prettier with `pretty-quick` for a consistent code formatting workflow.

## Steps

### 1. Install dependencies

```bash
npm install --save-dev prettier@3.7.4 pretty-quick@4.2.2
```

### 2. Add scripts to `package.json`

Add the following entries to the `"scripts"` section:

```
"prettier:fix-all": "prettier --write . --ignore-path .prettierignore",
"prettier:fix-changes": "pretty-quick --ignore-path .prettierignore",
```

Use a JSON merge — do NOT overwrite existing scripts.

### 3. Create `.prettierignore` in the project root

```
# Base example — you may need to add more paths depending on your project structure
.next/*
storybook-static/*
node_modules/*
types/Api.ts
```

> ⚠️ This is a minimal starting point. Add any generated files, build artifacts, or third-party code that should not be formatted.

### 4. Create `.prettierrc` in the project root

```json
{
  "bracketSameLine": true,
  "singleQuote": true,
  "jsxSingleQuote": false,
  "printWidth": 90,
  "semi": true,
  "endOfLine": "lf",
  "tabWidth": 2
}
```

## Done

After completing these steps, confirm to the user:
- ✅ `prettier` and `pretty-quick` installed
- ✅ Scripts added to `package.json`
- ✅ `.prettierignore` created (remind them to extend it as needed)
- ✅ `.prettierrc` created
