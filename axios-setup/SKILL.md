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
// Adapt based on answer to question 1
type TokenStorage = {
  get(): string | null;
  set(token: string): void;
  remove(): void;
};

// localStorage
const tokenStorage: TokenStorage = {
  get: () => localStorage.getItem('ACCESS_TOKEN_KEY'),
  set: (token) => localStorage.setItem('ACCESS_TOKEN_KEY', token),
  remove: () => localStorage.removeItem('ACCESS_TOKEN_KEY'),
};

// Cookies
const tokenStorage: TokenStorage = {
  get: () => getCookie('ACCESS_TOKEN_KEY'),
  set: (token) => setCookie('ACCESS_TOKEN_KEY', token),
  remove: () => deleteCookie('ACCESS_TOKEN_KEY'),
};

// Memory
let memoryToken: string | null = null;
const tokenStorage: TokenStorage = {
  get: () => memoryToken,
  set: (token) => { memoryToken = token; },
  remove: () => { memoryToken = null; },
};
```

### Refresh Flow

```typescript
// Strategy 2: HttpOnly cookie — no JS refresh needed
// Just attach token if present, let server handle 401

// Strategy 3: Refresh endpoint
async function refreshToken(): Promise<string | null> {
  try {
    const { data } = await axios.post<{ accessToken: string }>(REFRESH_ENDPOINT);
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

### Request Interceptor (attach token)

```typescript
api.interceptors.request.use(async (config) => {
  const token = tokenStorage.get();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

### Response Interceptor (refresh + error handling)

```typescript
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean };

    // Strategy 3: Handle 401 + refresh
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      const newToken = await refreshToken();
      if (newToken && originalRequest.headers) {
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        return api(originalRequest);
      }
    }

    // Centralized error handling
    handleError(error);

    return Promise.reject(error);
  }
);
```

### Error Handler (adapt based on question 4)

```typescript
function handleError(error: AxiosError): void {
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

  // Option 2: send to error tracking
  if (errorTracking) {
    errorTracking.captureException(error);
  }
}
```

### Typed API Methods

```typescript
// Generic helpers for all requests
async function get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
  const { data } = await api.get<T>(url, config);
  return data;
}

async function post<T, D = unknown>(url: string, payload?: D, config?: AxiosRequestConfig): Promise<T> {
  const { data } = await api.post<T>(url, payload, config);
  return data;
}

async function put<T, D = unknown>(url: string, payload?: D, config?: AxiosRequestConfig): Promise<T> {
  const { data } = await api.put<T>(url, payload, config);
  return data;
}

async function del<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
  const { data } = await api.delete<T>(url, config);
  return data;
}

// Example typed endpoint:
// GET /users → User[]
// POST /users → User (created)
interface User {
  id: string;
  name: string;
  email: string;
}

const users = await get<User[]>('/users');
const newUser = await post<User, Omit<User, 'id'>>('/users', { name: 'John', email: 'john@example.com' });
```

### Retry Logic

```typescript
import axiosRetry from 'axios-retry';

axiosRetry(api, {
  retries: RETRY_COUNT,
  retryDelay: (retryCount) => Math.pow(2, retryCount) * 1000, // exponential backoff
  retryCondition: (error) => {
    return (
      error.code === 'ECONNRESET' ||
      error.code === 'ETIMEDOUT' ||
      error.response?.status === 429 ||
      (error.response?.status ?? 0) >= 500
    );
  },
});
```

## Dependencies

Based on the survey, tell the user to install:

```bash
npm i axios
npm i -D axios-retry @types/axios  # or use built-in types
```

Or if using Sentry:

```bash
npm i @sentry/browser
```

## Done Checklist

- `src/utils/api.ts` (or chosen path) exists with typed methods
- All interceptors configured for the chosen storage/refresh strategy
- Errors are handled centrally
- Retry works for network errors and 5xx/429
- User knows which dependencies to install
