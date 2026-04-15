---
name: i18n-setup
description: Set up i18n for React (react-i18next) or Vue (vue-i18n) with typed translations, lazy loading, SSR support, and language detection. Use when a user asks for internationalization, add translations, set up i18n, or configure multi-language support.
---

# i18n Setup

Creates a fully typed i18n setup for React/Vue projects.

## Step 1 — Detect Framework and Package Manager

First, check the project:

- Look for `package.json` dependencies to determine framework:
  - `react`, `next` → **React** 
  - `vue`, `@vue/*` → **Vue**
- Check for existing `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` to determine package manager

If unclear, ask:

```
? Framework:
  1) React/Next.js
  2) Vue/Nuxt

? Package manager:
  1) npm
  2) yarn  
  3) pnpm
```

## Step 2 — Install Dependencies

> **Note**: Use the package manager detected/selected in Step 1.
> - `npm` → `npm i` / `npm i -D`
> - `yarn` → `yarn add` / `yarn add -D`
> - `pnpm` → `pnpm add` / `pnpm add -D`

Below examples use `{PM}` as placeholder — replace with your package manager.

### React/Next.js

```bash
# Core i18next libraries
{PM} i i18next react-i18next i18next-browser-languagedetector i18next-http-backend

# Optional: SSR support for Next.js (Pages Router only)
{PM} i next-i18next

# Dev dependencies for type generation and key extraction
{PM} i -D @types/i18next i18next-parser i18next-resources-to-ts
```

### Vue 2/3

```bash
# Vue 2
{PM} i vue-i18n@8

# Vue 3
{PM} i vue-i18n@9

# Composition API helpers (optional)
{PM} i @vueuse/core
```

## Step 3 — Create Translation Structure

```
public/locales/
├── en/
│   ├── common.json
│   └── auth.json
├── ru/
│   ├── common.json
│   └── auth.json
└── es/
    ├── common.json
    └── auth.json
```

Example `public/locales/en/common.json`:

```json
{
  "welcome": "Welcome",
  "errors": {
    "required": "This field is required",
    "email": "Please enter a valid email"
  }
}
```

Example `public/locales/en/auth.json`:

```json
{
  "login": {
    "title": "Sign in",
    "button": "Log in",
    "email_placeholder": "Enter your email",
    "forgot_password": "Forgot your password?"
  }
}
```

## Step 4 — Generate TypeScript Types (React)

Instead of manually maintaining types, you can either generate `.d.ts` files from JSON, or import JSON directly.

**Option A: Generate types from JSON (no tsconfig changes)**

Add to `package.json` scripts:

```json
{
  "scripts": {
    "i18n:types": "i18next-resources-to-ts --input 'public/locales/**/*.json' --output 'src/types/i18n.d.ts'"
  }
}
```

Then create a small `src/types/i18next.d.ts` that references the generated declarations (exact module names depend on your generator output).

**Option B: Direct JSON import (requires tsconfig)**

If your `tsconfig.json` has `"resolveJsonModule": true` and `"esModuleInterop": true`:

```typescript
// src/i18n/types.ts
import 'i18next';
import en_common from '../../public/locales/en/common.json';
import en_auth from '../../public/locales/en/auth.json';

declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: 'common';
    resources: {
      common: typeof en_common;
      auth: typeof en_auth;
    };
  }
}
```

The generator approach is convenient for large projects; direct JSON import is simplest if your tsconfig allows it.

## Step 5 — Initialize i18n

### React: `src/i18n/config.ts`

```typescript
import i18next from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import Backend from 'i18next-http-backend';

i18next
  .use(initReactI18next)
  .use(LanguageDetector)
  .use(Backend)
  .init({
    fallbackLng: 'en',
    debug: process.env.NODE_ENV === 'development',
    defaultNS: 'common',
    ns: ['common', 'auth'],
    supportedLngs: ['en', 'ru', 'es'],
    interpolation: {
      escapeValue: false, // React already escapes
    },
    backend: {
      loadPath: '/locales/{{lng}}/{{ns}}.json',
    },
  });

export default i18next;
```

### Vue: `src/plugins/i18n.ts`

```typescript
import { createI18n } from 'vue-i18n';
import en from '../locales/en/common.json';
import ru from '../locales/ru/common.json';

export const i18n = createI18n({
  legacy: false, // Composition API
  locale: 'en',
  fallbackLocale: 'en',
  messages: {
    en,
    ru,
  },
  // Vue 3 options
  globalInjection: true,
  allowComposition: true,
});
```

## Step 6 — Integration with Framework

### Next.js App Router

For App Router, use `i18next` with a provider pattern:

**1. Create `src/i18n/provider.tsx`:**

```typescript
'use client';

import { I18nextProvider } from 'react-i18next';
import i18n from './config';

export function I18nProvider({ children, lng }: { children: React.ReactNode; lng: string }) {
  return (
    <I18nextProvider i18n={i18n}>
      {children}
    </I18nextProvider>
  );
}
```

**2. Wrap root layout:**

```typescript
// app/layout.tsx
import { I18nProvider } from '@/i18n/provider';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <I18nProvider lng="en">{children}</I18nProvider>
      </body>
    </html>
  );
}
```

**3. For dynamic locale**, use middleware or read from cookie/header.

Note: for App Router, `next-i18next` is designed around the Pages Router. Prefer an `i18next` provider approach (as shown above) or consider `next-intl`.

### Next.js (Pages Router) - `next-i18next.config.js`

```javascript
module.exports = {
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'ru', 'es'],
    localeDetection: true,
  },
  localePath: './public/locales', // or './locales'
  reloadOnPrerender: process.env.NODE_ENV === 'development',
  // Optional: custom routes
  pages: {
    '*': ['common'],
    '/': ['dashboard'],
    '/about': ['about'],
  },
};
```

### Vue (main.ts)

```typescript
import { createApp } from 'vue';
import App from './App.vue';
import { i18n } from './plugins/i18n';

const app = createApp(App);
app.use(i18n);
app.mount('#app');
```

## Step 7 — Create Helper Components

### Language Switcher (React)

This component allows users to change the language. The `i18next-browser-languagedetector` will automatically persist the selection.

```typescript
// components/LanguageSwitcher.tsx
import { useTranslation } from 'react-i18next';

const LANGUAGES = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'ru', name: 'Русский', flag: '🇷🇺' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
];

export function LanguageSwitcher() {
  const { i18n } = useTranslation();

  return (
    <div className="language-switcher">
      {LANGUAGES.map((lang) => (
        <button
          key={lang.code}
          onClick={() => i18n.changeLanguage(lang.code)}
          disabled={i18n.language === lang.code}
        >
          <span role="img" aria-label={lang.name}>{lang.flag}</span> {lang.name}
        </button>
      ))}
    </div>
  );
}
```

### Type-safe Hook (React)

With the augmented types, the standard `useTranslation` hook is now fully type-safe. No custom hook is needed.

```typescript
// No custom hook needed!
import { useTranslation } from 'react-i18next';

function MyComponent() {
  const { t } = useTranslation('auth');
  // t is now type-safe and will autocomplete keys from auth.json
  return <p>{t('login.title')}</p>; 
}
```

### Composition API Helper (Vue)

```typescript
// composables/useI18n.ts
import { useI18n } from 'vue-i18n';

export function useTypedI18n() {
  const { t, locale, availableLocales } = useI18n();

  // Add type-safe methods
  const switchLocale = (newLocale: string) => {
    locale.value = newLocale;
    document.documentElement.lang = newLocale;
  };

  return {
    t,
    locale,
    availableLocales,
    switchLocale,
  };
}
```

## Step 8 — Usage Examples

### React Component

```typescript
import { useTranslation } from 'react-i18next';

function LoginForm() {
  const { t } = useTranslation('auth');

  return (
    <form>
      <h1>{t('login.title')}</h1>
      <input placeholder={t('login.email_placeholder')} />
      <button>{t('login.button')}</button>
      <a href="/forgot">{t('login.forgot_password')}</a>
    </form>
  );
}
```

### Vue Component

```vue
<template>
  <form>
    <h1>{{ $t('auth.login.title') }}</h1>
    <input :placeholder="$t('auth.login.email_placeholder')" />
    <button>{{ $t('auth.login.button') }}</button>
    <a href="/forgot">{{ $t('auth.login.forgot_password') }}</a>
  </form>
</template>

<script setup>
import { useTypedI18n } from '../composables/useI18n';

const { t } = useTypedI18n();
</script>
```

## Step 9 — Scripts for Package.json

Add these scripts to `package.json` to help with translation management:

```json
{
  "scripts": {
    "i18n:extract": "i18next-parser -c i18next-parser.config.js",
    "i18n:types": "i18next-resources-to-ts --input 'public/locales/**/*.json' --output 'src/types/i18n.d.ts'"
  }
}
```

- `i18n:extract` - Extracts translation keys from your code into JSON files.
- `i18n:types` - Generates TypeScript types from translation JSON files.

### i18next-parser.config.js

This file configures how `i18next-parser` extracts keys from your code.

```javascript
module.exports = {
  locales: ['en', 'ru', 'es'],
  output: 'public/locales/$LOCALE/$NAMESPACE.json',
  input: ['src/**/*.{ts,tsx,js,jsx}'],
  defaultNamespace: 'common',
  keySeparator: '.',
  namespaceSeparator: ':',
  sort: true,
  createOldCatalogs: false,
  defaultValue: (locale, namespace, key) => key,
};
```

## Done Checklist

- ✅ Dependencies installed (`i18next`, `react-i18next`, etc.)
- ✅ `public/locales/` structure created with JSON files
- ✅ i18n configuration file created and type-safe
- ✅ Framework integration updated (Next.js/Vue)
- ✅ Language switcher component added
- ✅ `package.json` scripts for key extraction and type generation