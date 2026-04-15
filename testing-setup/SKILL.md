---
name: testing-setup
description: Set up Vitest/Jest with Testing Library. Trigger on: testing setup, add tests, vitest, jest, testing library, unit tests.
---

# Testing Setup

Install and configure a testing framework with coverage. Detect existing setup or initialize new.

## Steps

### 1. Detect existing setup

Check `package.json` and project structure:

**Next.js detection:**
- `next` in dependencies → use `next/jest` for Jest, or Vitest for custom setup

**Test framework detection:**
- `vitest` in devDependencies → extend existing
- `jest` in devDependencies → extend existing
- Neither found → ask user to choose (Vitest recommended)

**UI framework detection** (check dependencies):
- `react` → React Testing Library
- `vue` → Vue Testing Library
- `svelte` → Svelte Testing Library
- None → `@testing-library/dom` only

### 2. Detect package manager

- `pnpm-lock.yaml` → `pnpm`
- `yarn.lock` → `yarn`
- `bun.lock` → `bun`
- `package-lock.json` → `npm`
- Default → `npm`

### 3. Install dependencies

**For Vitest:**

```
Basic:        vitest @testing-library/dom jsdom @vitest/coverage-v8
React:        + @testing-library/react @testing-library/jest-dom @vitejs/plugin-react
Vue:          + @testing-library/vue @testing-library/jest-dom @vitejs/plugin-vue
Svelte:       + @testing-library/svelte @testing-library/jest-dom @sveltejs/vite-plugin-svelte
```

```bash
<pkg-manager> add --save-dev vitest @testing-library/dom jsdom @vitest/coverage-v8
```

Add framework-specific packages as needed.

**For Jest:**

```
React:   jest @testing-library/react @testing-library/jest-dom jest-environment-jsdom
Vue:     jest @testing-library/vue @testing-library/jest-dom @vue/vue3-jest jest-environment-jsdom
Svelte:  jest @testing-library/svelte @testing-library/jest-dom svelte-jester jest-environment-jsdom
CSS:     identity-obj-proxy    # for CSS module mocking
```

```bash
<pkg-manager> add --save-dev jest jest-environment-jsdom identity-obj-proxy
```

Add Testing Library packages matching detected UI framework. Add `identity-obj-proxy` unless project uses Next.js.

### 4. Create configuration

**Standard Vitest** — `vitest.config.ts`:

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react'; // if React
// import vue from '@vitejs/plugin-vue';   // if Vue
// import { svelte } from '@sveltejs/vite-plugin-svelte'; // if Svelte

export default defineConfig({
  plugins: [react()], // framework plugin
  test: {
    environment: 'jsdom',
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    exclude: ['node_modules', 'dist', '.next'],
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      exclude: [
        'node_modules',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.{ts,js}',
        '**/index.ts',
      ],
    },
  },
});
```

**Next.js + Vitest** — `vitest.config.ts`:

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    env: {
      __NEXT_TEST_MODE: 'true',
    },
  },
});
```

**Standard Jest** — `jest.config.js`:

```javascript
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['./src/test/setup.ts'],
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.config.{ts,js}',
    '!src/test/**/*',
  ],
  testMatch: ['**/src/**/*.{test,spec}.{ts,tsx}'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
  },
};
```

**Next.js + Jest** — `jest.config.js`:

```javascript
const nextJest = require('next/jest');

const createJestConfig = nextJest({ dir: './' });

const customConfig = {
  setupFilesAfterEnv: ['./src/test/setup.ts'],
  testMatch: ['**/src/**/*.{test,spec}.{ts,tsx}'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
};

module.exports = createJestConfig(customConfig);
```

Note: `next/jest` auto-handles CSS, SWC, and environment — no need for `identity-obj-proxy` or `testEnvironment`.

**Jest + Vue** — `jest.config.js`:

```javascript
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['./src/test/setup.ts'],
  moduleFileExtensions: ['js', 'mjs', 'cjs', 'jsx', 'ts', 'tsx', 'json', 'vue'],
  testMatch: ['**/src/**/*.{test,spec}.{ts,tsx,vue}'],
  transform: {
    '^.+\\.vue$': '@vue/vue3-jest',
    '^.+\\.tsx?$': 'ts-jest',
  },
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
  },
};
```

Also create `src/test/setup.ts`:
```typescript
import '@testing-library/jest-dom';
```

**Jest + Svelte** — `jest.config.js`:

```javascript
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['./src/test/setup.ts'],
  testMatch: ['**/src/**/*.{test,spec}.{ts,tsx,svelte}'],
  transform: {
    '^.+\\.svelte$': 'svelte-jester',
    '^.+\\.tsx?$': 'ts-jest',
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'svelte'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
  },
};
```

Also add to `package.json`:
```json
"svelte-jester": { "preprocess": false }
```

### 5. Create setup file

Create `src/test/setup.ts`:

```typescript
import '@testing-library/jest-dom';
```

**tsconfig.json** — merge into existing `compilerOptions.types`:

For Vitest with `globals: true` (add `globals: true` to vitest config first):
```json
{ "compilerOptions": { "types": ["vitest/globals", "@testing-library/jest-dom"] } }
```

For Jest:
```json
{ "compilerOptions": { "types": ["jest", "@testing-library/jest-dom"] } }
```

For Jest + Vue add `"vue3/jest"` to types. For Jest + Svelte add `"svelte"` to types.

Do NOT overwrite — merge into existing array.

### 6. Add scripts to `package.json`

Merge into `"scripts"`:

For Vitest:
```json
"test": "vitest run",
"test:watch": "vitest",
"test:coverage": "vitest run --coverage"
```

For Jest:
```json
"test": "jest",
"test:watch": "jest --watch",
"test:coverage": "jest --coverage"
```

### 7. Create example test

**Globals-enabled** (no imports needed):
```typescript
describe('Example', () => {
  it('should pass', () => {
    expect(1 + 1).toBe(2);
  });
});
```

**React:**
```typescript
import { render, screen } from '@testing-library/react';

describe('Example', () => {
  it('renders text', () => {
    render(<div>Hello Tests</div>);
    expect(screen.getByText('Hello Tests')).toBeInTheDocument();
  });
});
```

### 8. Verify

```bash
<pkg-manager> run test
```

Fix any errors before confirming.

## Done

Confirm to the user:
- Test framework installed and configured for detected UI framework
- CSS imports handled (identity-obj-proxy or next/jest)
- Coverage enabled with proper exclusions
- Scripts added to package.json
- Tests passed on verification
