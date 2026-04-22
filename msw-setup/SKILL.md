---
name: msw-setup
description: Set up MSW (Mock Service Worker) for API mocking in browser development and unit tests. Use when a user asks to add mocks, mock API, set up MSW, or needs to develop without a backend. Stacks with axios-setup and testing-setup.
---

# MSW Setup

MSW intercepts HTTP requests at the network layer — your code doesn't know the difference between real API and mocks.

## Architecture

```
Browser/Node → Service Worker (MSW) → matches handler → returns mock response
```

Two environments:
- **Browser (dev)** — service worker, live reload, manual toggle
- **Tests** — `server.use()` per-test override, deterministic

## Step 1 — Detect stack

Check `package.json`:

```
React/Vue/Next present → browser mocking relevant
Vitest/Jest present     → test mocking relevant
both                    → set up both
```

## Step 2 — Install

```bash
<pkg-manager> add -D msw
```

For browser mocking also install:

```bash
<pkg-manager> add -D https
```

## Step 3 — Project structure

```
src/
  mocks/
    handlers.ts      ← your API mocks (one file per domain)
    browser.ts       ← browser worker setup
    server.ts        ← test server setup (if testing)
  mocks.ts           ← combined exports
```

## Step 4 — Create handlers

### Basic REST handler

```typescript
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'Alice', email: 'alice@example.com' },
      { id: 2, name: 'Bob', email: 'bob@example.com' },
    ])
  }),

  http.get('/api/users/:id', ({ params }) => {
    const { id } = params
    return HttpResponse.json({ id, name: 'User ' + id })
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json({ id: 3, ...body }, { status: 201 })
  }),

  http.delete('/api/users/:id', () => {
    return new HttpResponse(null, { status: 204 })
  }),
]
```

### Handler with error response

```typescript
http.get('/api/users', () => {
  return HttpResponse.json(
    { error: 'Server error', code: 'INTERNAL_ERROR' },
    { status: 500 }
  )
})

http.get('/api/users', () => {
  return HttpResponse.json(
    { error: 'Not found' },
    { status: 404 }
  )
})
```

### Handler with delay (simulate network latency)

```typescript
http.get('/api/users', async () => {
  await new Promise((resolve) => setTimeout(resolve, 500))
  return HttpResponse.json([{ id: 1, name: 'Alice' }])
})
```

## Step 5 — Browser setup (dev)

### Create worker

```typescript
// src/mocks/browser.ts
import { setupWorker } from 'msw'
import { handlers } from './handlers'

export const worker = setupWorker(...handlers)
```

### Initialize in main entry

```typescript
// src/main.ts (or index.tsx)
import { worker } from './mocks/browser'

async function enableMocking() {
  if (process.env.NODE_ENV === 'development') {
    return worker.start({
      onUnhandledRequest: 'bypass',  // don't warn on unmocked requests
    })
  }
}

enableMocking()
```

### Add startup script to package.json

```json
{
  "scripts": {
    "msw:init": "msw init public/ --save"
  }
}
```

Run `npm run msw:init` — creates `public/mockServiceWorker.js`.

## Step 6 — Test setup

### Create server

```typescript
// src/mocks/server.ts
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

### Configure test setup files

**For Vitest** (`tests/setup.ts`):

```typescript
import { beforeAll, afterEach, afterAll } from 'vitest'
import { server } from '../src/mocks/server'

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

**For Jest** (`tests/setup.ts`):

```typescript
import { beforeAll, afterEach, afterAll } from '@jest/globals'
import { server } from '../src/mocks/server'

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Add setup to config

**Vitest** (`vitest.config.ts`):

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    setupFiles: ['./tests/setup.ts'],
  },
})
```

**Jest** (`jest.config.ts`):

```typescript
export default {
  setupFilesAfterEnv: ['./tests/setup.ts'],
}
```

## Step 7 — Override handlers per test

```typescript
import { server } from '../src/mocks/server'
import { http, HttpResponse } from 'msw'

test('shows empty state when no users', async () => {
  server.use(
    http.get('/api/users', () => HttpResponse.json([]))
  )

  render(<UserList />)
  expect(screen.getByText('No users')).toBeInTheDocument()
})

test('shows error when API fails', async () => {
  server.use(
    http.get('/api/users', () =>
      HttpResponse.json({ error: 'Server error' }, { status: 500 })
    )
  )

  render(<UserList />)
  expect(screen.getByText('Something went wrong')).toBeInTheDocument()
})
```

## Step 8 — Enable/disable mocking

For browser, you can toggle mocking on/off:

```typescript
// Enable (already started by default)
worker.enable()

// Disable (requests go to real server)
worker.disable()

// Reset handlers to initial state
worker.resetHandlers()
```

Or by URL pattern — bypass specific paths:

```typescript
worker.start({
  onUnhandledRequest: 'bypass',
  serviceWorker: {
    url: '/mockServiceWorker.js',
  },
})
```

## Testing scenarios

### Test loading state

```typescript
test('shows spinner while loading', async () => {
  const { getByRole } = render(<UserList />)
  expect(getByRole('progressbar')).toBeInTheDocument()
})
```

### Test empty state

```typescript
test('shows empty message when no data', async () => {
  server.use(http.get('/api/users', () => HttpResponse.json([])))
  render(<UserList />)
  expect(screen.getByText('No users found')).toBeInTheDocument()
})
```

### Test error state

```typescript
test('shows error message on failure', async () => {
  server.use(
    http.get('/api/users', () =>
      HttpResponse.json({ message: 'Server error' }, { status: 500 })
    )
  )
  render(<UserList />)
  expect(await screen.findByText('Failed to load users')).toBeInTheDocument()
})
```

## Done checklist

- `msw` installed as dev dependency
- `handlers.ts` created with REST endpoints
- Browser worker initialized in entry point
- Test server created in `server.ts`
- Test setup file configured (Vitest/Jest)
- Per-test override pattern documented
- `msw:init` script added to package.json
- `public/mockServiceWorker.js` generated and gitignored

## Next steps

- Combine with `axios-setup` — your API calls are mocked transparently
- Add handlers for each API domain (users, products, orders)
- Use `server.use()` to override specific handlers per test
- Test error states (500, timeout, network failure) — not just happy path