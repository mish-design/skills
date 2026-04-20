---
name: react-query-setup
description: Set up TanStack Query (React Query) v5 with QueryClient, devtools, and typed hooks. Use when asked to add React Query, set up data fetching, configure TanStack Query, or add caching to a React project.
---

# React Query Setup

Set up TanStack Query v5 with sensible production defaults.

## Step 1 — Detect project

Check `package.json`:
- `react` present → React project, proceed
- `next` present → Next.js App Router setup
- neither → ask before proceeding

Check for existing React Query:
- `@tanstack/react-query` in dependencies → extend existing config, do not overwrite

## Step 2 — Install dependencies

```bash
<pkg-manager> add @tanstack/react-query @tanstack/react-query-devtools
```

## Step 3 — Create QueryClient

Create `src/lib/query-client.ts` (or `lib/query-client.ts` for Next.js):

```typescript
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60,        // 1 minute before refetch
      gcTime: 1000 * 60 * 5,      // 5 minutes cache retention
      retry: 1,
      refetchOnWindowFocus: true,
    },
    mutations: {
      retry: 0,
    },
  },
});
```

Note: `gcTime` replaces the deprecated `cacheTime` in v5.

## Step 4 — Add Provider

**React** — `src/App.tsx` or `src/providers/QueryProvider.tsx`:

```typescript
import { QueryClientProvider } from '@tanstack/react-query';

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
    </QueryClientProvider>
  );
}
```

**Next.js App Router** — `src/app/providers.tsx`:

```typescript
('use client');

import { QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());

  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}
```

Then in `src/app/layout.tsx`:

```typescript
import { Providers } from './providers';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

## Step 5 — Devtools (optional)

Add devtools only in development. In `src/lib/query-client.ts`:

```typescript
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

export const queryClient = new QueryClient({ ... });

// Export for use in components
export { ReactQueryDevtools };
```

Then add `<ReactQueryDevtools initialIsOpen={false} />` inside `QueryClientProvider` in development only.

## Step 6 — Typed hooks

Create `src/lib/hooks.ts` for reusable typed hooks:

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export { useQueryClient };

export function useCustomQuery<T>(
  key: string[],
  fetcher: () => Promise<T>,
  options?: Parameters<typeof useQuery>[0]
) {
  return useQuery({
    queryKey: key,
    queryFn: fetcher,
    ...options,
  });
}

export function useCustomMutation<TData, TVariables>(
  mutationFn: (variables: TVariables) => Promise<TData>,
  queryKeysToInvalidate: string[] = [],
  options?: Parameters<typeof useMutation>[0]
) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn,
    onSuccess: () => {
      queryKeysToInvalidate.forEach((key) => queryClient.invalidateQueries({ queryKey: [key] }));
    },
    ...options,
  });
}
```

## Usage

```typescript
// useQuery
const { data, isLoading, error } = useQuery({
  queryKey: ['users'],
  queryFn: () => api.get<User[]>('/users'),
});

// useMutation
const { mutate, isPending } = useMutation({
  mutationFn: (newUser: CreateUserDto) => api.post<User>('/users', newUser),
  onSuccess: () => {
    // auto-invalidates 'users' query
  },
});
```

## Done

- `@tanstack/react-query` installed
- `QueryClient` created with production defaults
- Provider added to app root
- Devtools installed (optional)
- Typed hooks pattern shown
