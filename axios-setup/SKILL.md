---
name: axios-setup
description: Set up a production-ready Axios wrapper with auth interceptors, retry, typed requests, and centralized error handling. Use when a user asks to configure axios, add API layer, set up auth tokens, or configure API client.
---

# Axios Setup

Creates `utils/api.ts` (or `lib/api.ts`) — a typed, production-ready Axios instance.

## Survey

Ask the user these questions before generating. Default values are in brackets.

### 1. Token Storage

```
? Where to store the access token?
  1) localStorage (most common)
  2) Cookies
  3) Memory only (session-only, React state)
  4) Async storage (Vault, Secret Manager)
```

### 2. Refresh Strategy

```
? How to refresh the token when expired?
  1) No refresh (static token, token never expires)
  2) HttpOnly cookie (browser handles automatically, no JS access)
  3) Refresh endpoint (/auth/refresh or similar)
```

### 3. API Configuration

```
? Base API URL:
  (e.g., https://api.example.com/v1 or /api)

? Refresh endpoint URL (if refresh strategy = 3):
  (e.g., /auth/refresh)
```

### 4. Retry Settings

```
? Retry count on failure [3]:
```

### 5. Error Handling

```
? Error handling level:
  1) Console only
  2) Console + error tracking (Sentry/DataDog)
  3) Silent (no logging)
```

### 6. Project Structure

```
? Where to place the API file?
  1) src/utils/api.ts
  2) src/lib/api.ts
  3) src/services/api.ts
  4) lib/api.ts (custom path)
```

## Implementation Patterns

### Token Storage Abstraction

```typescript
// Safe storage wrapper — works in SSR and private modes
const safeStorage = {
  get: (key: string): string | null => {
    try {
      return typeof window !== 'undefined' && window.localStorage
        ? localStorage.getItem(key)
        : null;
    } catch {
      return null;
    }
  },
  set: (key: string, value: string): void => {
    try {
      if (typeof window !== 'undefined' && window.localStorage) {
        localStorage.setItem(key, value);
      }
    } catch {
      // silently ignore — quota exceeded or disabled
    }
  },
  remove: (key: string): void => {
    try {
      if (typeof window !== 'undefined' && window.localStorage) {
        localStorage.removeItem(key);
      }
    } catch {
      // silently ignore
    }
  },
};

// Use storage variants:
const tokenStorage = {
  // localStorage
  get: () => safeStorage.get('ACCESS_TOKEN_KEY'),
  set: (t: string) => safeStorage.set('ACCESS_TOKEN_KEY', t),
  remove: () => safeStorage.remove('ACCESS_TOKEN_KEY'),
};
```

### Refresh Flow with Queue (prevents race conditions)

```typescript
interface RefreshResponse {
  accessToken: string;
  [key: string]: unknown;  // allows extra fields
}

type PendingRequest = { resolve: (token: string) => void; reject: () => void };

let isRefreshing = false;
let pendingRequests: PendingRequest[] = [];

function processQueue(error: Error | null, token: string | null) {
  pendingRequests.forEach((req) => (error ? req.reject() : req.resolve(token!)));
  pendingRequests = [];
}

async function refreshToken(): Promise<string | null> {
  try {
    const { data } = await axios.post<RefreshResponse>(REFRESH_ENDPOINT);
    tokenStorage.set(data.accessToken);
    return data.accessToken;
  } catch {
    tokenStorage.remove();
    return null;
  }
}
```

### Core Axios Instance

```typescript
import axios, { AxiosInstance, AxiosRequestConfig, AxiosError } from 'axios';

const api: AxiosInstance = axios.create({
  baseURL: BASE_URL,
  timeout: 30_000,
  headers: { 'Content-Type': 'application/json' },
});
```

### Request Interceptor

```typescript
api.interceptors.request.use(async (config) => {
  // Skip auth header for public routes
  if (config.headers['X-Skip-Auth']) {
    delete config.headers['X-Skip-Auth'];
    return config;
  }

  const token = tokenStorage.get();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

### Response Interceptor (race-safe refresh + error handling)

```typescript
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean };

    // Strategy 3: Handle 401 with refresh
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      // If already refreshing — queue this request
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          pendingRequests.push({
            resolve: (token: string) => {
              originalRequest.headers!.Authorization = `Bearer ${token}`;
              resolve(api(originalRequest));
            },
            reject,
          });
        });
      }

      isRefreshing = true;
      const newToken = await refreshToken();
      isRefreshing = false;

      if (newToken && newToken !== 'null') {
        processQueue(null, newToken);
        originalRequest.headers!.Authorization = `Bearer ${newToken}`;
        return api(originalRequest);
      }

      // Refresh failed — reject all queued requests
      processQueue(new Error('Refresh failed'), null);
    }

    // Centralized error handling
    handleError(error);

    return Promise.reject(error);
  }
);
```

### Retry Logic (excluded from refresh endpoint)

```typescript
import axiosRetry from 'axios-retry';

axiosRetry(api, {
  retries: RETRY_COUNT,
  retryDelay: (count) => count * 1000,
  retryCondition: (error) => {
    // Never retry the refresh endpoint
    const url = error.config?.url || '';
    if (url.includes(REFRESH_ENDPOINT)) return false;

    return (
      error.code === 'ECONNRESET' ||
      error.code === 'ETIMEDOUT' ||
      error.response?.status === 429 ||
      (error.response?.status ?? 0) >= 500
    );
  },
});
```

### Error Handler

```typescript
function handleError(error: AxiosError): void {
  // Skip if request was already retried and failed
  if (error.code === 'ECONNABORTED') return;

  switch (error.response?.status) {
    case 401:
      tokenStorage.remove();
      redirectToLogin();
      break;
    case 403:
      redirectToForbidden();
      break;
    case 429:
      showToast('Too many requests. Please wait.');
      break;
    case 500:
    case 502:
    case 503:
      showToast('Server error. Please try again later.');
      break;
  }

  if (errorTracking) {
    errorTracking.captureException(error);
  }
}
```

### Typed API Methods

```typescript
async function get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
  const { data } = await api.get<T>(url, config);
  return data;
}

async function post<T, D = unknown>(
  url: string,
  payload?: D,
  config?: AxiosRequestConfig
): Promise<T> {
  const { data } = await api.post<T>(url, payload, config);
  return data;
}

async function put<T, D = unknown>(
  url: string,
  payload?: D,
  config?: AxiosRequestConfig
): Promise<T> {
  const { data } = await api.put<T>(url, payload, config);
  return data;
}

async function del<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
  const { data } = await api.delete<T>(url, config);
  return data;
}
```

## Dependencies

```bash
npm i axios
npm i -D axios-retry
```

With Sentry:
```bash
npm i @sentry/browser
```

Note: `@types/axios` is not needed (Axios ships its own types).

## Done Checklist

- File created at chosen path with typed methods
- Token storage with SSR-safe wrapper
- Refresh with race-condition protection (queue + flag)
- Retry excludes refresh endpoint
- Centralized error handling
- All dependencies listed
