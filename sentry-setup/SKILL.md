---
name: sentry-setup
description: Set up Sentry v8 for JavaScript/TypeScript/React error tracking and performance monitoring. Use when a user asks to add Sentry, set up error tracking, configure monitoring, or integrate Sentry with an existing project. Stacks with axios-setup for centralized error handling.
---

# Sentry Setup

Sentry v8 provides error tracking, performance monitoring, and session replay. This skill focuses on error tracking + browser tracing, which covers 90% of use cases.

## Architecture

```
App → Sentry SDK (browser/node) → Sentry servers → Dashboard
                  ↑
            Source maps (uploaded in CI)
```

## Before you start

Ask the user:

```
? Sentry DSN URL (from project settings):
   (e.g., https://1234567890abcdef@o123456.ingest.sentry.io/1234567)

? Which platform?
   1) React/Vue (browser)
   2) Node.js (backend)
   3) Both

? Enable performance monitoring? [yes]
? Enable session replay? [no] — can be heavy
```

## Step 1 — Install

### Browser (React/Vue)

```bash
<pkg-manager> add @sentry/react
```

For Next.js:

```bash
<pkg-manager> add @sentry/next
```

### Node.js

```bash
<pkg-manager> add @sentry/node
```

## Step 2 — Browser initialization

Create `src/sentry.ts` (or `src/lib/sentry.ts`):

```typescript
import * as Sentry from '@sentry/react'

Sentry.init({
  dsn: process.env.REACT_APP_SENTRY_DSN,

  tracesSampleRate: 0.1,  // 10% of transactions — adjust for prod

  // Enable in development only if you want to see issues there
  environment: process.env.NODE_ENV,

  // Normalize paths in stack traces
  normalizeDepth: 5,

  // Ignore common noise (browser extensions, 3rd party scripts)
  ignoreErrors: [
    'ResizeObserver loop',
    'Non-Error promise rejection captured',
  ],

  // Include source maps for readable stack traces
  // (requires Vite/Webpack plugin - see Step 4)
})
```

### For React apps — add Error Boundary

```typescript
import { createRoot } from 'react-dom/client'
import { ErrorBoundary } from '@sentry/react'

function fallbackUI() {
  return (
    <div style={{ padding: '2rem', textAlign: 'center' }}>
      <h2>Something went wrong</h2>
      <p>Our team has been notified. Please try again later.</p>
      <button onClick={() => window.location.reload()}>Reload page</button>
    </div>
  )
}

const container = document.getElementById('root')!
const root = createRoot(container)

root.render(
  <ErrorBoundary
    fallback={fallbackUI}
    showDialog  // allows users to submit error reports manually
  >
    <App />
  </ErrorBoundary>
)
```

### For Next.js — use built-in wrapper

```typescript
// src/app/layout.tsx or pages/_app.tsx
import * as Sentry from '@sentry/next'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
})

export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />
}
```

## Step 3 — Node.js initialization

Create `src/sentry-server.ts`:

```typescript
import * as Sentry from '@sentry/node'

Sentry.init({
  dsn: process.env.SENTRY_DSN,

  tracesSampleRate: 0.1,

  // Include stack traces for unhandled errors
  stackTraceLimit: 50,

  // Disable default instrumentation (set to true only if you use custom tracing)
  autoInstrumentRemix: false,
})
```

In your Express/Fastify entry:

```typescript
import * as Sentry from '@sentry/node'

// Import first, before any other imports
Sentry.init({ dsn: process.env.SENTRY_DSN })

// Add request handler for tracing
app.use(Sentry.Handlers.requestHandler())
```

## Step 4 — Source maps for readable stack traces

### Vite

```bash
<pkg-manager> add -D @sentry/vite-plugin
```

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import { sentryVitePlugin } from '@sentry/vite-plugin'

export default defineConfig({
  plugins: [
    react(),
    sentryVitePlugin({
      org: 'your-org',
      project: 'your-project',
      authToken: process.env.SENTRY_AUTH_TOKEN,
    }),
  ],
})
```

The plugin uploads source maps automatically during build.

### Webpack

```bash
<pkg-manager> add -D @sentry/webpack-plugin
```

```javascript
// webpack.config.js
const SentryPlugin = require('@sentry/webpack-plugin')

module.exports = {
  plugins: [
    new SentryPlugin({
      org: 'your-org',
      project: 'your-project',
      authToken: process.env.SENTRY_AUTH_TOKEN,
    }),
  ],
}
```

## Step 5 — CI secrets

In GitHub Actions / CI:

```bash
# Add to .env or CI secrets
SENTRY_AUTH_TOKEN=your_auth_token_here
```

Get `SENTRY_AUTH_TOKEN` from: Sentry → Settings → API Keys → Internal Integration.

## Step 6 — Manual error capture (optional)

For explicit error tracking in try/catch:

```typescript
try {
  await riskyOperation()
} catch (error) {
  Sentry.captureException(error, {
    extra: {
      userId: user.id,
      operation: 'payment_processing',
    },
  })
}
```

For messages without stack trace:

```typescript
Sentry.captureMessage('User bypassed payment step', 'warning')
```

## Step 7 — Breadcrumbs for debugging

Add context before errors:

```typescript
Sentry.addBreadcrumb({
  message: 'User submitted payment form',
  category: 'user-action',
  data: { amount: 99.99 },
  level: 'info',
})
```

Common breadcrumb patterns:
- `user-action` — button clicks, form submissions
- `navigation` — route changes
- `api` — API calls (axios interceptor already does this)

## Integration with axios

If `axios-setup` exists, update `handleError` to send to Sentry:

```typescript
import * as Sentry from '@sentry/react'

function handleError(error: AxiosError): void {
  switch (error.response?.status) {
    case 401:
      tokenStorage.remove()
      redirectToLogin()
      break
    case 500:
    case 502:
    case 503:
      showToast('Server error. Please try again.')
      break
  }

  // Add breadcrumb for API errors
  Sentry.addBreadcrumb({
    message: 'API request failed',
    category: 'api',
    data: {
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status,
    },
    level: 'error',
  })

  // Capture the error
  Sentry.captureException(error)
}
```

## Done checklist

- `@sentry/react` (or `@sentry/next` or `@sentry/node`) installed
- `Sentry.init()` called with DSN
- Error boundary added (React apps)
- Source map plugin configured (Vite/Webpack)
- `SENTRY_AUTH_TOKEN` added to CI
- `SENTRY_DSN` / `REACT_APP_SENTRY_DSN` added to env.example
- Manual capture pattern documented
- Breadcrumbs documented
- Integration with axios error handler done (if axios-setup exists)