---
name: eslint-setup
description: Set up ESLint with modern flat config for JavaScript or TypeScript projects, including React or Next.js when detected. Use when the user asks to add ESLint, configure linting, set up code quality, or integrate lint scripts into a project.
---

# ESLint Setup

Set up ESLint using the current flat config format with production-safe defaults.

## Step 1 - Detect project shape

Check `package.json` and project files:

- `typescript` present -> configure TypeScript support
- `react` present -> add React rules
- `next` present -> add Next.js rules
- existing `eslint.config.*` or `.eslintrc*` present -> extend or merge, do not overwrite blindly

If an ESLint config already exists, ask whether to merge or replace it.

## Step 2 - Install dependencies

Choose package manager from lockfile.

### Base

```bash
<pkg-manager> add -D eslint @eslint/js globals
```

### TypeScript

```bash
<pkg-manager> add -D typescript typescript-eslint
```

### React

```bash
<pkg-manager> add -D eslint-plugin-react eslint-plugin-react-hooks
```

### Next.js

```bash
<pkg-manager> add -D @next/eslint-plugin-next
```

### Optional import hygiene

```bash
<pkg-manager> add -D eslint-plugin-unused-imports
```

Use only the packages that match the detected stack.

## Step 3 - Create `eslint.config.mjs`

Create a flat config in project root.

### JavaScript base

```javascript
import js from '@eslint/js';
import globals from 'globals';

export default [
  {
    ignores: [
      'dist/**',
      'build/**',
      '.next/**',
      'coverage/**',
      'node_modules/**',
    ],
  },
  js.configs.recommended,
  {
    files: ['**/*.{js,mjs,cjs}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    rules: {
      'no-console': ['warn', { allow: ['warn', 'error'] }],
    },
  },
];
```

### TypeScript extension

If `typescript` is present, use this instead of the JavaScript-only export:

```javascript
import js from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default [
  {
    ignores: [
      'dist/**',
      'build/**',
      '.next/**',
      'coverage/**',
      'node_modules/**',
    ],
  },
  js.configs.recommended,
  {
    files: ['**/*.{js,jsx,mjs,cjs}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    rules: {
      'no-console': ['warn', { allow: ['warn', 'error'] }],
    },
  },
  ...tseslint.configs.recommended.map((config) => ({
    ...config,
    files: ['**/*.{ts,tsx,mts,cts}'],
  })),
  {
    files: ['**/*.{ts,tsx,mts,cts}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    rules: {
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      '@typescript-eslint/no-unused-vars': [
        'warn',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
    },
  },
];
```

### React extension

If `react` is present, extend the config:

```javascript
import reactPlugin from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';

{
  files: ['**/*.{jsx,tsx}'],
  plugins: {
    react: reactPlugin,
    'react-hooks': reactHooks,
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
  rules: {
    ...reactPlugin.configs.flat.recommended.rules,
    ...reactPlugin.configs.flat['jsx-runtime'].rules,
    ...reactHooks.configs.recommended.rules,
  },
}
```

Add that object as another item in the exported config array.

### Next.js extension

If `next` is present, extend the config:

```javascript
import nextPlugin from '@next/eslint-plugin-next';

{
  files: ['**/*.{js,jsx,ts,tsx}'],
  plugins: {
    '@next/next': nextPlugin,
  },
  rules: {
    ...nextPlugin.configs.recommended.rules,
    ...nextPlugin.configs['core-web-vitals'].rules,
  },
}
```

Add that object as another item in the exported config array.

### Optional unused imports cleanup

If the project wants auto-removal of dead imports:

```javascript
import unusedImports from 'eslint-plugin-unused-imports';

{
  plugins: {
    'unused-imports': unusedImports,
  },
  rules: {
    'unused-imports/no-unused-imports': 'warn',
  },
}
```

Add that object as another item in the exported config array.

Keep the first version minimal. Add stricter rules only when the user asks.

## Step 4 - Add scripts to `package.json`

Merge into `scripts`:

```json
{
  "lint": "eslint .",
  "lint:fix": "eslint . --fix"
}
```

If the repo is large, it is acceptable to use explicit globs instead of `eslint .`.

## Step 5 - Prettier compatibility

If the project already uses Prettier:

- do not add stylistic ESLint rules
- do not use ESLint for formatting
- keep ESLint focused on correctness and code quality

Only install `eslint-config-prettier` if the project already has stylistic ESLint rules that need disabling.

## Step 6 - Existing config migration

If the project already uses `.eslintrc.*`, prefer a minimal migration:

- keep current rules if they are still needed
- move them into `eslint.config.mjs`
- remove duplicated legacy config after migration is verified
- do not keep both config systems active unless the user explicitly asks

## Step 7 - Verify

Run:

```bash
<pkg-manager> run lint
```

Fix config errors before finishing.

## Done checklist

- `eslint.config.mjs` created or merged safely
- correct packages installed for detected stack
- `lint` and `lint:fix` scripts added
- React and Next.js rules added only when relevant
- configuration verified with a lint run
