---
name: storybook-setup
description: Set up Storybook v7+ with Vite for component-driven development, CSF3 stories, MSW mocking, interaction testing, and decorators for i18n/store providers. Use when a user asks to add Storybook, set up component documentation, or create a design system.
---

# Storybook Setup

Storybook is only useful when stories are interactive, documented, and test edge cases. This skill sets up Storybook properly and establishes useful patterns.

## Before you start

Ask the user:

```
? What framework?
  1) React
  2) Vue
  3) Other

? Use local Storybook docs domain (for development):
   http://localhost:6006
```

## Step 1 — Install

```bash
<pkg-manager> add -D @storybook/<framework>-vite storybook
```

For React:
```bash
<pkg-manager> add -D @storybook/react-vite
```

For Vue:
```bash
<pkg-manager> add -D @storybook/vue3-vite
```

### Core addons

```bash
<pkg-manager> add -D @storybook/addon-essentials
```

`addon-essentials` includes: controls, actions, viewport, backgrounds, toolbars, docs, interactions (step-through testing with Playwright).

### MSW for stories (if API mocking needed)

```bash
<pkg-manager> add -D msw-storybook-addon
```

### Playwright for interaction testing

```bash
<pkg-manager> add -D @storybook/test
```

`@storybook/test` is the modern replacement for `@storybook/testing-react`.

## Step 2 — Configure

### Vite config (`vite.config.ts`)

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    // Storybook needs this
    react(),
  ],
})
```

### Storybook config (`.storybook/main.ts`)

```typescript
import type { StorybookConfig } from '@storybook/react-vite'

const config: StorybookConfig = {
  stories: ['../src/**/*.stories.@(js|ts)'],
  addons: [
    '@storybook/addon-essentials',  // includes controls, actions, viewport, docs, interactions
  ],
  framework: {
    name: '@storybook/react-vite',
    options: {},
  },
  docs: {
    autodocs: 'tag',  // generate docs from JSDoc + argTypes
  },
}

export default config
```

### Preview config (`.storybook/preview.ts`)

```typescript
import type { Preview } from '@storybook/react'

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
    backgrounds: {
      default: 'white',
      values: [
        { name: 'white', value: '#ffffff' },
        { name: 'gray', value: '#f5f5f5' },
        { name: 'dark', value: '#1a1a1a' },
      ],
    },
  },
}

export default preview
```

## Step 3 — MSW for stories (optional but recommended)

If the project uses MSW, set up Storybook-specific worker:

### Initialize MSW in preview (`.storybook/preview.ts`)

```typescript
import { initialize, mswDecorator } from 'msw-storybook-addon'

// Initialize MSW before rendering stories
initialize()

export const decorators = [
  mswDecorator,
]
```

The addon handles service worker injection automatically.

## Step 4 — Create first story

### Basic component story (CSF3)

Create `src/components/Button/Button.stories.ts`:

```typescript
import type { Meta, StoryObj } from '@storybook/react'
import { Button } from './Button'

const meta: Meta<typeof Button> = {
  component: Button,
  tags: ['autodocs'],  // generates docs automatically
}

export default meta
type Story = StoryObj<typeof Button>

export const Primary: Story = {
  args: {
    variant: 'primary',
    label: 'Click me',
  },
}

export const Secondary: Story = {
  args: {
    variant: 'secondary',
    label: 'Cancel',
  },
}

export const Disabled: Story = {
  args: {
    ...Primary.args,
    disabled: true,
  },
}
```

### Story with controls

```typescript
export const WithControls: Story = {
  args: {
    variant: 'primary',
    label: 'Button',
    disabled: false,
    loading: false,
  },
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'ghost'],
    },
  },
}
```

### Story with MSW mock

```typescript
import { http, HttpResponse } from 'msw'

export const WithMockedData: Story = {
  parameters: {
    msw: {
      handlers: [
        http.get('/api/users', () => {
          return HttpResponse.json([
            { id: 1, name: 'Alice' },
            { id: 2, name: 'Bob' },
          ])
        }),
      ],
    },
  },
}
```

### Interaction test

```typescript
import { within, userEvent, expect } from '@storybook/test'

export const Clickable: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)
    await userEvent.click(canvas.getByRole('button'))
    // Assert something happened
  },
}

export const FormSubmission: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)

    await userEvent.type(canvas.getByPlaceholderText('Email'), 'test@example.com')
    await userEvent.click(canvas.getByRole('button', { name: /submit/i }))

    await expect(canvas.getByText('Success!')).toBeInTheDocument()
  },
}
```

## Step 5 — Decorators for providers

If the app uses i18n, store, or theme providers:

### Create decorators file (`src/storybook/decorators.tsx`)

```typescript
import React from 'react'
import { I18nextProvider } from 'react-i18next'
import { Provider } from 'react-redux'
import { configureStore } from '@reduxjs/toolkit'
import i18n from '../i18n'  // your i18n instance

// Example: redux store
const store = configureStore({
  reducer: {
    // your root reducer
  },
})

export const withProviders = (Story: React.ComponentType) => (
  <I18nextProvider i18n={i18n}>
    <Provider store={store}>
      <Story />
    </Provider>
  </I18nextProvider>
)
```

### Add to preview (`.storybook/preview.ts`)

```typescript
import { decorators } from '../src/storybook/decorators'

export const decorators = [
  withProviders,
]
```

## Step 6 — Add scripts

In `package.json`:

```json
{
  "scripts": {
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build",
    "storybook:preview": "storybook preview"
  }
}
```

## Step 7 — Add to .gitignore

```gitignore
storybook-static/
```

## Useful story patterns

### Loading state

```typescript
import { http } from 'msw'

export const Loading: Story = {
  parameters: {
    msw: {
      handlers: [
        http.get('/api/data', () => {
          // Never resolves - component stays in loading state
          return new Promise(() => {})
        }),
      ],
    },
  },
}
```

### Error state

```typescript
import { http, HttpResponse } from 'msw'

export const ErrorState: Story = {
  parameters: {
    msw: {
      handlers: [
        http.get('/api/data', () => {
          return HttpResponse.json(
            { error: 'Server error' },
            { status: 500 }
          )
        }),
      ],
    },
  },
}
```

### Empty state

```typescript
import { http, HttpResponse } from 'msw'

export const EmptyState: Story = {
  parameters: {
    msw: {
      handlers: [
        http.get('/api/items', () => HttpResponse.json([])),
      ],
    },
  },
}
```

### Variants as separate stories

```typescript
export const Primary = { ... }
export const Secondary = { ... }
export const Ghost = { ... }
export const Sizes: Story = {
  render: () => (
    <div style={{ display: 'flex', gap: '1rem' }}>
      <Button size="sm">Small</Button>
      <Button size="md">Medium</Button>
      <Button size="lg">Large</Button>
    </div>
  ),
}
```

## Story organization

```
src/
  components/
    Button/
      Button.tsx
      Button.stories.ts    ← CSF3 story
      Button.test.tsx      ← unit tests
    UserCard/
      UserCard.tsx
      UserCard.stories.ts
```

One story file per component, co-located next to the component.

## Done checklist

- Storybook v7+ with Vite framework installed
- `@storybook/addon-essentials` added
- CSF3 format documented
- MSW integration set up via `msw-storybook-addon` (if project uses MSW)
- Decorators for providers configured (i18n, store)
- Interaction testing pattern shown with `@storybook/test`
- `storybook` and `build-storybook` scripts added
- First component story created
- `storybook-static/` gitignored