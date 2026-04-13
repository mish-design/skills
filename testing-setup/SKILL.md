---
name: testing-setup
description: Set up a universal testing framework (Vitest/Jest) with Testing Library. Use this skill when user mentions setting up tests, test framework, unit tests, testing library, or asks to add testing to their project. Triggers on phrases like "set up testing", "add tests", "configure vitest", "jest setup", "testing library", or when onboarding a new project.
---

# Testing Setup

Installs and configures a testing framework with coverage support. Automatically detects existing setup or initializes a new one.

## Steps

### 1. Detect or suggest framework

Check `package.json` for existing test dependencies:

- If `vitest` found → extend existing config
- If `jest` found → extend existing config
- If neither found → ask user to choose (Vitest recommended for modern projects)

### 2. Detect package manager

Check which package manager is used in the project:

- If `pnpm-lock.yaml` exists → use `pnpm`
- If `yarn.lock` exists → use `yarn`
- If `bun.lock` exists → use `bun`
- Default → use `npm`

### 3. Install dependencies

**For Vitest (recommended):**

```bash
<pkg-manager> add --save-dev vitest@latest @testing-library/react@latest @testing-library/jest-dom@latest jsdom@latest @vitest/coverage-v8@latest
```

**For Jest:**

```bash
<pkg-manager> add --save-dev jest@latest @testing-library/react@latest @testing-library/jest-dom@latest jest-environment-jsdom@latest
```

Replace `<pkg-manager>` with detected package manager (npm/pnpm/yarn/bun).

### 4. Create configuration

**For Vitest** — create `vitest.config.ts` in project root:

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      exclude: ['node_modules/', 'src/test/'],
    },
  },
});
```

**For Jest** — create `jest.config.js` in project root:

```javascript
export default {
  testEnvironment: 'jest-environment-jsdom',
  setupFilesAfterFramework: ['./src/test/setup.ts'],
  coverageDirectory: 'coverage',
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts'],
  testMatch: ['**/__tests__/**/*.test.{ts,tsx}'],
};
```

### 5. Create setup file

Create `src/test/setup.ts`:

```typescript
import '@testing-library/jest-dom';
```

For **Jest**, also add to `tsconfig.json`:

```json
{
  "types": ["jest", "@testing-library/jest-dom"]
}
```

### 5. Add scripts to `package.json`

Add to `"scripts"` section using JSON merge (do NOT overwrite):

```json
"test": "vitest run",
"test:watch": "vitest",
"test:coverage": "vitest run --coverage"
```

For **Jest** use:

```json
"test": "jest",
"test:watch": "jest --watch",
"test:coverage": "jest --coverage"
```

### 6. Create example test (optional)

Create `src/example.test.ts` to verify setup:

```typescript
import { describe, it, expect } from 'vitest';

describe('Example Test', () => {
  it('should pass', () => {
    expect(true).toBe(true);
  });
});
```

### 7. Run tests to verify

```bash
<pkg-manager> run test
```

## Done

After completing these steps, confirm to the user:
- ✅ Testing framework installed (Vitest/Jest)
- ✅ Testing Library configured
- ✅ Configuration file created (`vitest.config.ts` or `jest.config.js`)
- ✅ Setup file created (`src/test/setup.ts`)
- ✅ Scripts added to `package.json`
- ✅ Run `<pkg-manager> run test` to verify everything works

## Package Manager Detection

```
Project root contains:
├── pnpm-lock.yaml → use pnpm
├── yarn.lock → use yarn
├── bun.lock → use bun
└── package-lock.json or nothing → use npm
```

## Framework Detection Logic

```
package.json scripts.test
├── contains "vitest" → use Vitest
├── contains "jest" → use Jest
└── empty/not found → default to Vitest (recommend)
```
