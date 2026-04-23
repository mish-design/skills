---
name: playwright-setup
description: Set up Playwright for end-to-end testing with MSW API mocking, Page Object Model, and CI integration. Use when a user asks to add E2E tests, set up Playwright, create browser tests, or automate UI testing. Stacks with testing-setup and msw-setup.
---

# Playwright Setup

Playwright enables reliable browser testing. This skill focuses on the patterns that make E2E tests maintainable: Page Object Model, API mocking, and proper selectors.

## Before you start

Ask the user:

```
? Test directory path [e2e]
? Base URL for tests [http://localhost:3000]
? Use MSW for API mocking? (if msw-setup exists) [yes]
```

## Step 1 — Install

```bash
<pkg-manager> add -D @playwright/test
```

Install browsers:

```bash
<pkg-manager> playwright install chromium
```

Or install all browsers:

```bash
<pkg-manager> playwright install
```

## Step 2 — Configure

Create `playwright.config.ts`:

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,

  baseURL: process.env.BASE_URL || 'http://localhost:3000',

  reporter: process.env.CI ? [['github'], ['html']] : [['html', { open: 'never' }]],

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  webServer: process.env.CI
    ? undefined
    : {
        command: 'npm run dev',
        url: 'http://localhost:3000',
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
      },
})
```

Key options explained:

| Option | Purpose |
|--------|---------|
| `forbidOnly` | Ensures no `test.only` slips into CI |
| `retries` | Retry flaky tests (higher in CI) |
| `workers` | Parallel tests (lower in CI to avoid conflicts) |
| `webServer` | Start dev server before tests |
| `trace` | Debug info on failure |
| `screenshot` | Visual evidence of failures |

## Step 3 — MSW integration (if msw-setup exists)

For E2E tests, use `msw/node` directly (not the Storybook addon). Install:

```bash
<pkg-manager> add -D msw
```

Create a test server that persists across tests:

```typescript
// e2e/msw/server.ts
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'

export const server = setupServer(
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'Alice', email: 'alice@example.com' },
      { id: 2, name: 'Bob', email: 'bob@example.com' },
    ])
  }),

  http.post('/api/auth/login', async ({ request }) => {
    const body = await request.json()
    if (body.email === 'test@example.com') {
      return HttpResponse.json({
        token: 'mock-jwt-token',
        user: { id: 1, name: 'Alice', email: body.email },
      })
    }
    return HttpResponse.json({ error: 'Invalid credentials' }, { status: 401 })
  }),
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

In your test file:

```typescript
import { server } from './msw/server'

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

## Step 4 — Page Object Model

The Page Object Model pattern keeps selectors in one place:

### Create page objects (`e2e/pages/LoginPage.ts`)

```typescript
import { Page, Locator } from '@playwright/test'

export class LoginPage {
  readonly page: Page
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly submitButton: Locator
  readonly errorMessage: Locator

  constructor(page: Page) {
    this.page = page
    this.emailInput = page.getByPlaceholder('Email')
    this.passwordInput = page.getByPlaceholder('Password')
    this.submitButton = page.getByRole('button', { name: 'Sign in' })
    this.errorMessage = page.getByRole('alert')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }

  async goto() {
    await this.page.goto('/login')
  }
}
```

### Use in tests (`e2e/login.spec.ts`)

```typescript
import { test, expect } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'

test.describe('Login', () => {
  test('shows error on invalid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page)
    await loginPage.goto()
    await loginPage.login('wrong@example.com', 'wrongpass')

    await expect(loginPage.errorMessage).toContainText('Invalid credentials')
  })

  test('redirects to dashboard on success', async ({ page }) => {
    const loginPage = new LoginPage(page)
    await loginPage.goto()
    await loginPage.login('test@example.com', 'password123')

    await expect(page).toHaveURL('/dashboard')
    await expect(page.getByRole('heading', { name: 'Welcome' })).toBeVisible()
  })
})
```

## Step 5 — Selectors (best practices)

Prefer these in order:

```typescript
// 1. Accessible — best for tests
page.getByRole('button', { name: 'Submit' })
page.getByLabel('Email address')
page.getByPlaceholder('Search')

// 2. Test IDs — explicit, stable
page.getByTestId('submit-button')

// 3. Text content
page.getByText('Sign in')
page.getByText(/welcome, \w+/)

// 4. CSS — last resort
page.locator('.btn-primary')
```

Avoid `nth()` and fragile CSS selectors. If you must use nth:

```typescript
// Better: be specific first, then nth
page.getByRole('listitem').nth(0)

// Bad: fragile
page.locator('div > span:nth-child(2)')
```

## Step 6 — Common test patterns

### Loading state

```typescript
test('shows loading while fetching data', async ({ page }) => {
  await page.goto('/users')

  const loader = page.getByRole('progressbar')
  await expect(loader).toBeVisible()

  await expect(page.getByRole('list')).toBeVisible()
  await expect(loader).not.toBeVisible()
})
```

### Empty state

```typescript
test('shows empty message', async ({ page }) => {
  await page.goto('/users')

  await expect(page.getByText('No users found')).toBeVisible()
  await expect(page.getByRole('button', { name: 'Add user' })).toBeDisabled()
})
```

### Form validation

```typescript
test('shows validation errors', async ({ page }) => {
  await page.goto('/register')

  await page.getByRole('button', { name: 'Create account' }).click()

  await expect(page.getByText('Email is required')).toBeVisible()
  await expect(page.getByText('Password must be at least 8 characters')).toBeVisible()
})
```

### Navigation

```typescript
test('persists filter after navigation', async ({ page }) => {
  await page.goto('/products')
  await page.getByLabel('Category').selectOption('Electronics')
  await expect(page.getByTestId('product-card')).toHaveCount(5)

  await page.getByRole('link', { name: 'About' }).click()
  await page.goBack()

  await expect(page.getByLabel('Category')).toHaveValue('Electronics')
})
```

### File download

```typescript
import { test } from '@playwright/test'
import { promises as fs } from 'fs'

test('exports user data', async ({ page }) => {
  const [download] = await Promise.all([
    page.waitForEvent('download'),
    page.getByRole('button', { name: 'Export CSV' }).click(),
  ])

  const path = await download.path()
  expect(path).not.toBeNull()

  const content = await fs.readFile(path!, 'utf-8')

  expect(content).toContain('name,email')
  expect(content).toContain('Alice,alice@example.com')
})
```

## Step 7 — Add scripts

In `package.json`:

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:headed": "playwright test --headed",
    "test:e2e:debug": "playwright test --debug"
  }
}
```

## Step 8 — Add to CI

If `github-actions-setup` exists, add a workflow file:

```yaml
# .github/workflows/e2e.yml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps chromium

      - name: Start dev server
        run: npm run dev &
        background: true

      - name: Wait for server
        run: npx wait-on http://localhost:3000 --timeout 60000

      - name: Run E2E tests
        run: npm run test:e2e
        env:
          BASE_URL: ${{ secrets.BASE_URL || 'http://localhost:3000' }}
```

Note: `BASE_URL` in GitHub Actions secrets is optional — defaults to localhost.

## Step 9 — Debugging tips

```bash
# Open Playwright UI for interactive debugging
npm run test:e2e:ui

# Run single test with headed browser
npx playwright test tests/login.spec.ts --headed

# Debug with Playwright Inspector
npx playwright test tests/login.spec.ts --debug

# Generate test scaffold
npx playwright test --generate
```

View trace after failure:

```bash
npx playwright show-trace trace.zip
```

## Done checklist

- `@playwright/test` installed, browsers downloaded
- `playwright.config.ts` created with proper defaults
- Page Object Model pattern shown
- MSW integration set up (if msw-setup exists)
- Common patterns: loading, empty, validation, navigation
- `test:e2e` and related scripts added
- E2E workflow added to CI (if github-actions-setup exists)
- First test passing