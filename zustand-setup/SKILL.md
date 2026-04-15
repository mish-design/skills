---
name: zustand-setup
description: Set up Zustand state management with appropriate middleware (persist, devtools, immer) and TypeScript types. Use when a user asks to add Zustand, set up state management, configure store, or add persist/devtools to Zustand.
---

# Zustand Setup

Configures Zustand store with TypeScript, middleware, and proper patterns for React/Next.js projects.

## Survey

Ask these questions before generating:

### 1. Experience Level

```
? Experience level with Zustand:
  1) Beginner (first time, need simple setup)
  2) Intermediate (used before, want production features)
  3) Advanced (need SSR/hydration for Next.js)
```

### 2. Store Structure

```
? Store structure:
  1) Single store (recommended for small/medium apps)
  2) Multiple slices (by feature: auth, ui, cart, etc.)
```

### 3. Middleware

```
? Middleware to include (multi-select):
  [ ] persist (localStorage/sessionStorage)
  [ ] devtools (Redux DevTools integration)
  [ ] immer (immutable updates)
```

### 4. Package Manager

```
? Package manager:
  1) npm
  2) yarn
  3) pnpm
```

### 5. Persistence Details (if persist selected)

```
? Persistence storage:
  1) localStorage (survives browser restart)
  2) sessionStorage (cleared on tab close)
  3) IndexedDB (large data)

? Storage key [app-store]:
```

## Setup Levels

### Level 1: Beginner (Quick Setup)

**Goal:** Simple store with TypeScript.

**Dependencies:**
```bash
<pkg-manager> add zustand
```

**Generated file (`lib/store/store.ts`):**
```typescript
import { create } from 'zustand'

interface CounterStore {
  count: number
  increment: () => void
  decrement: () => void
  reset: () => void
}

export const useCounterStore = create<CounterStore>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}))
```

### Level 2: Intermediate (Production Setup)

**Goal:** Store with middleware (persist, devtools, immer).

**Dependencies:**
```bash
<pkg-manager> add zustand
# Optional middleware, install if selected
<pkg-manager> add immer
```

**Generated file (`lib/store/store.ts`):**

This setup demonstrates how to correctly compose multiple middlewares. The order is important: `immer` is inside, then `persist`, and `devtools` wraps everything.

```typescript
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'
import { immer } from 'zustand/middleware/immer'
import type { StateCreator } from 'zustand'

// Define your state and actions
interface AppState {
  user: { name: string; email: string } | null
  theme: 'light' | 'dark'
  sidebarOpen: boolean
  setUser: (user: AppState['user']) => void
  toggleTheme: () => void
  toggleSidebar: () => void
}

// The initial state and actions are combined in a single creator function
const createAppState: StateCreator<
  AppState,
  [ ['zustand/devtools', never], ['zustand/persist', unknown], ['zustand/immer', never] ],
  [],
  AppState
> = (set) => ({
  user: null,
  theme: 'light',
  sidebarOpen: false,
  setUser: (user) => set({ user }),
  toggleTheme: () =>
    set((state) => ({ theme: state.theme === 'light' ? 'dark' : 'light' })),
  toggleSidebar: () =>
    set((state) => ({ sidebarOpen: !state.sidebarOpen })),
})

// Create the store, composing the middlewares
export const useAppStore = create<AppState>()(
  devtools(
    persist(
      immer(createAppState),
      {
        name: 'app-store', // Key for localStorage
        // Optional: specify a custom storage provider
        // storage: createJSONStorage(() => sessionStorage),
      }
    ),
    { name: 'AppStore' } // Name for Redux DevTools
  )
)
```

### Level 3: Advanced (Next.js/SSR Setup)

**Goal:** SSR-compatible store that safely handles hydration to prevent client-server mismatches.

**Dependencies:**
```bash
<pkg-manager> add zustand
<pkg-manager> add zustand/middleware # For persist/devtools
<pkg-manager> add immer # If using immer
```

**Generated files:**

**1. `lib/store/store.ts`:** (No complex SSR-specific store needed, we use a custom hook instead)

The store is defined as in Level 2. The magic happens in the component that uses it.

**2. `hooks/use-hydrated-store.ts`:**

This simple but powerful hook solves SSR hydration issues. It ensures that the client-side state (e.g., from `localStorage`) is only used *after* the initial server render is complete.

```typescript
import { useState, useEffect } from 'react'

const useHydratedStore = <T, F>(
  store: (callback: (state: T) => unknown) => unknown,
  callback: (state: T) => F
) => {
  const result = store(callback) as F;
  const [hydratedResult, setHydratedResult] = useState<F>();

  useEffect(() => {
    setHydratedResult(result);
  }, [result]);

  return hydratedResult;
};

export default useHydratedStore;
```

**3. `lib/store/slices/`** (if multiple slices selected):
```
slices/
├── auth.slice.ts
├── ui.slice.ts
├── cart.slice.ts
└── index.ts  # combine slices
```

## Usage Examples

### Basic Usage
```typescript
import { useCounterStore } from '@/lib/store/store'

function Counter() {
  const { count, increment } = useCounterStore()
  return <button onClick={increment}>Count: {count}</button>
}
```

### With Persist
```typescript
// Theme persists across browser sessions
const { theme, toggleTheme } = useAppStore()
```

### SSR Usage (Next.js)

To use a persisted store in a Next.js component, use the `useHydratedStore` hook to prevent hydration mismatches. It will return `undefined` on the server and the actual state on the client after hydration.

```typescript
'use client'

import { useAppStore } from '@/lib/store/store'
import useHydratedStore from '@/hooks/use-hydrated-store'

function ThemeToggle() {
  const theme = useHydratedStore(useAppStore, (state) => state.theme)
  const { toggleTheme } = useAppStore()
  
  // Render a placeholder or null on the server and during hydration
  if (!theme) {
    return <div style={{width: 80, height: 24}} /> // Or some loading skeleton
  }
  
  return <button onClick={toggleTheme}>Theme: {theme}</button>
}
```

## Best Practices

### 1. **Selectors for Performance**
```typescript
// ❌ Re-renders on any store change
const { user, theme } = useAppStore()

// ✅ Only re-renders when user changes
const user = useAppStore((state) => state.user)
```

### 2. **Shallow Comparison**
```typescript
import { shallow } from 'zustand/shallow'

// Prevents unnecessary re-renders
const { user, theme } = useAppStore(
  (state) => ({ user: state.user, theme: state.theme }),
  shallow
)
```

### 3. **Slice Pattern** (for large stores)

This pattern helps organize a large store into smaller, feature-based slices.

```typescript
import { StateCreator } from 'zustand'

// 1. Define the state and actions for each slice
interface AuthSlice {
  user: { name: string } | null;
  login: (user: { name: string }) => void;
  logout: () => void;
}

interface UiSlice {
  theme: 'light' | 'dark';
  toggleTheme: () => void;
}

// 2. Create the slice creator functions
const createAuthSlice: StateCreator<AuthSlice> = (set) => ({
  user: null,
  login: (user) => set({ user }),
  logout: () => set({ user: null }),
})

const createUiSlice: StateCreator<UiSlice> = (set) => ({
  theme: 'light',
  toggleTheme: () => set((state) => ({ theme: state.theme === 'light' ? 'dark' : 'light' })),
})

// 3. Combine your slices in the main store
// Note: The `&` operator is used to combine slice types
export const useBoundStore = create<AuthSlice & UiSlice>()((...a) => ({
  ...createAuthSlice(...a),
  ...createUiSlice(...a),
}))
```

## Done Checklist

- ✅ `lib/store/store.ts` created with appropriate level
- ✅ Middleware configured (persist/devtools/immer if selected)
- ✅ TypeScript types defined
- ✅ Package manager commands provided
- ✅ SSR support if Next.js selected
- ✅ Usage examples included