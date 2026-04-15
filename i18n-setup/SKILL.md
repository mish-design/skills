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
  - `svelte`, `@sveltejs/*` → **Svelte** (optional support)
- Check for existing `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` to determine package manager

If unclear, ask:

```
? Framework:
  1) React/Next.js
  2) Vue/Nuxt
  3) Svelte/SvelteKit

? Package manager:
  1) npm
  2) yarn  
  3) pnpm
```

## Step 2 — Install Dependencies

### React/Next.js

```bash
# npm
npm i i18next react-i18next i18next-browser-languagedetector

# optional: backend for loading translations
npm i i18next-http-backend

# optional: SSR support (Next.js)
npm i next-i18next

# types
npm i -D @types/i18next
```

### Vue 2/3

```bash
# Vue 2
npm i vue-i18n@8

# Vue 3
npm i vue-i18n@9

# Composition API helpers (optional)
npm i @vueuse/core
```

## Step 3 — Create Translation Structure

```
locales/
├── en/
│   ├── common.json
│   ├── auth.json
│   ├── dashboard.json
│   └── errors.json
├── ru/
│   ├── common.json
│   └── ...
├── es/
│   └── ...
└── index.ts          # exports all translations
```

Example `locales/en/common.json`:

```json
{
  "welcome": "Welcome",
  "login": {
    "title": "Sign in",
    "button": "Log in",
    "forgot_password": "Forgot your password?"
  },
  "errors": {
    "required": "This field is required",
    "email": "Please enter a valid email"
  }
}
```

## Step 4 — Generate TypeScript Types (React)

Create `locales/index.ts`:

```typescript
// Auto-generated type definitions
// Re-export this file to have type-safe translations

import enCommon from './en/common.json';
import ruCommon from './ru/common.json';
// ... import all namespaces

export type Locale = 'en' | 'ru' | 'es';
export type Namespace = 'common' | 'auth' | 'dashboard' | 'errors';

// Generate type-safe translation keys
export type TranslationKeys = {
  common: typeof enCommon;
  auth: any; // Replace with actual imports
  dashboard: any;
  errors: any;
};

export type AllTranslationKeys = {
  [K in keyof TranslationKeys]: keyof TranslationKeys[K];
};
```

Create `src/types/i18n.d.ts`:

```typescript
// Augment i18next types
import 'i18next';
import { TranslationKeys } from '../../locales';

declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: 'common';
    resources: TranslationKeys;
  }
}
```

## Step 5 — Initialize i18n

### React: `src/i18n/config.ts`

```typescript
import i18next from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import Backend from 'i18next-http-backend'; // optional

i18next
  .use(initReactI18next)
  .use(LanguageDetector)
  .use(Backend) // optional: load translations via HTTP
  .init({
    fallbackLng: 'en',
    defaultNS: 'common',
    ns: ['common', 'auth', 'dashboard', 'errors'],
    supportedLngs: ['en', 'ru', 'es'],
    
    // Debug in development
    debug: process.env.NODE_ENV === 'development',
    
    // Load strategy
    load: 'languageOnly', // en-US → en
    
    // Cache
    cache: {
      enabled: true,
      prefix: 'i18n_',
      expirationTime: 7 * 24 * 60 * 60 * 1000, // 1 week
    },
    
    // Interpolation
    interpolation: {
      escapeValue: false, // React already escapes
    },
    
    // Backend options (if using backend)
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

### Next.js (App Router)

```typescript
// app/[lang]/layout.tsx
import { i18nRouter } from 'next-i18next-router';

export default function RootLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { lang: string };
}) {
  return (
    <html lang={params.lang}>
      <body>
        {children}
      </body>
    </html>
  );
}

// next.config.js
const { i18n } = require('./next-i18next.config');

module.exports = {
  i18n,
};
```

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

  const changeLanguage = (lng: string) => {
    i18n.changeLanguage(lng);
    localStorage.setItem('preferred-language', lng);
  };

  return (
    <div className="language-switcher">
      {LANGUAGES.map((lang) => (
        <button
          key={lang.code}
          onClick={() => changeLanguage(lang.code)}
          className={i18n.language === lang.code ? 'active' : ''}
        >
          <span>{lang.flag}</span> {lang.name}
        </button>
      ))}
    </div>
  );
}
```

### Type-safe Hook (React)

```typescript
// hooks/useTypedTranslation.ts
import { useTranslation } from 'react-i18next';
import { AllTranslationKeys } from '../locales';

export function useTypedTranslation() {
  const { t, i18n, ready } = useTranslation();

  const typedT = (key: AllTranslationKeys, options?: any) => {
    return t(key as string, options);
  };

  return {
    t: typedT,
    i18n,
    ready,
  };
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
import { useTypedTranslation } from '../hooks/useTypedTranslation';

function LoginForm() {
  const { t } = useTypedTranslation();

  return (
    <form>
      <h1>{t('auth.login.title')}</h1>
      <input placeholder={t('auth.login.email_placeholder')} />
      <button>{t('auth.login.button')}</button>
      <a href="/forgot">{t('auth.login.forgot_password')}</a>
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

Add these scripts to `package.json`:

```json
{
  "scripts": {
    "i18n:extract": "i18next-parser -c i18next-parser.config.js",
    "i18n:sync": "npm run i18n:extract && git add locales/",
    "i18n:compile": "tsc --noEmit src/types/i18n.d.ts"
  }
}
```

### i18next-parser.config.js (optional)

```javascript
module.exports = {
  locales: ['en', 'ru', 'es'],
  output: 'locales/$LOCALE/$NAMESPACE.json',
  input: ['src/**/*.{ts,tsx,vue}'],
  keySeparator: '.',
  namespaceSeparator: ':',
  defaultValue: (locale, namespace, key) => key,
  sort: true,
};
```

## Done Checklist

- ✅ Dependencies installed (i18next, react-i18next/vue-i18n)
- ✅ `locales/` structure created with JSON files
- ✅ i18n configuration file created (TypeScript types included)
- ✅ Framework integration (Next.js/Vue main file)
- ✅ Language switcher component
- ✅ Type-safe translation hooks
- ✅ Package.json scripts for extraction/compilation
- ✅ Translation keys are type-safe in components