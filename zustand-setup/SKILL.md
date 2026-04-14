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
<pkg-manager> add -D @types/node  # if using TypeScript
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
<pkg-manager> add -D @types/node

# Optional middleware
<pkg-manager> add zustand/middleware
```

**Generated files:**

**1. `lib/store/middleware.ts`:**
```typescript
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'
import { immer } from 'zustand/middleware/immer'

// Combine middleware based on survey
export function createStore<T>(
  storeName: string,
  initialState: T,
  actions: (set: any, get: any) => any
) {
  let store = create(actions)
  
  if (survey.includes('immer')) {
    store = create(immer(actions))
  }
  
  if (survey.includes('persist')) {
    store = create(
      persist(actions, {
        name: storeName,
        storage: localStorage, // or sessionStorage
      })
    )
  }
  
  if (survey.includes('devtools')) {
    store = create(devtools(actions, { name: storeName }))
  }
  
  return store
}
```

**2. `lib/store/store.ts`:**
```typescript
import { createStore } from './middleware'

interface AppState {
  user: { name: string; email: string } | null
  theme: 'light' | 'dark'
  sidebarOpen: boolean
  setUser: (user: AppState['user']) => void
  toggleTheme: () => void
  toggleSidebar: () => void
}

export const useAppStore = createStore<AppState>(
  'app-store',
  {
    user: null,
    theme: 'light',
    sidebarOpen: false,
  },
  (set, get) => ({
    setUser: (user) => set({ user }),
    toggleTheme: () => set((state) => ({ 
      theme: state.theme === 'light' ? 'dark' : 'light' 
    })),
    toggleSidebar: () => set((state) => ({ 
      sidebarOpen: !state.sidebarOpen 
    })),
  })
)
```

### Level 3: Advanced (Next.js/SSR Setup)

**Goal:** SSR-compatible store with hydration.

**Dependencies:**
```bash
<pkg-manager> add zustand
<pkg-manager> add zustand/middleware
<pkg-manager> add -D @types/node
```

**Generated files:**

**1. `lib/store/hydration.ts`:**
```typescript
'use client'

import { useEffect, useState } from 'react'

/**
 * Hook to prevent hydration mismatch in Next.js
 */
export function useHydration(store: any, callback?: () => void) {
  const [hydrated, setHydrated] = useState(false)

  useEffect(() => {
    const unsub = store.persist?.onFinishHydration(() => {
      setHydrated(true)
      callback?.()
    })

    setHydrated(true)
    return () => {
      unsub?.()
    }
  }, [store, callback])

  return hydrated
}
```

**2. `lib/store/ssr-store.ts`:**
```typescript
import { create } from 'zustand'
import { persist, devtools } from 'zustand/middleware'
import { createJSONStorage } from 'zustand/middleware'

// SSR-safe store creation
export function createSSRStore<T>(
  name: string,
  initialState: T,
  actions: (set: any, get: any) => any
) {
  // Check if we're in browser
  const isClient = typeof window !== 'undefined'
  
  return create<T>()(
    devtools(
      persist(
        actions,
        {
          name,
          storage: createJSONStorage(() => 
            isClient ? localStorage : {
              getItem: () => null,
              setItem: () => {},
              removeItem: () => {},
            }
          ),
          skipHydration: !isClient,
        }
      ),
      { name }
    )
  )
}
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
```typescript
'use client'

import { useAppStore } from '@/lib/store/store'
import { useHydration } from '@/lib/store/hydration'

function ThemeToggle() {
  const { theme, toggleTheme } = useAppStore()
  const hydrated = useHydration(useAppStore)
  
  if (!hydrated) return <div>Loading...</div>
  
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
```typescript
// Create slices separately
const createAuthSlice = (set, get) => ({
  user: null,
  login: (user) => set({ user }),
  logout: () => set({ user: null }),
})

const createUiSlice = (set, get) => ({
  theme: 'light',
  toggleTheme: () => set((state) => ({ 
    theme: state.theme === 'light' ? 'dark' : 'light' 
  })),
})

// Combine slices
export const useStore = create((...a) => ({
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