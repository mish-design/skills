# Zustand Setup

## Что делает

Настраивает Zustand store с TypeScript и middleware для production-приложений. Поддерживает три уровня сложности:

1. **Beginner** — простой store для новичков
2. **Intermediate** — production-настройка с persist/devtools/immer
3. **Advanced** — SSR-совместимость для Next.js

## Как работает

Скилл задаёт вопросы:

1. **Уровень опыта** — Beginner/Intermediate/Advanced
2. **Структура store** — единый или slices
3. **Middleware** — persist, devtools, immer
4. **Package manager** — npm/yarn/pnpm
5. **Детали persist** — localStorage, sessionStorage, ключ

Затем генерирует:
- `lib/store/store.ts` — основной store
- `lib/store/middleware.ts` — конфигурация middleware
- `lib/store/hydration.ts` — SSR-совместимость для Next.js
- `lib/store/slices/` — slices по фичам (опционально)

## Особенности

| Уровень | Что включает |
|---------|--------------|
| **Beginner** | Базовый store, TypeScript типы |
| **Intermediate** | Persist (localStorage), DevTools, Immer |
| **Advanced** | SSR-гидрация, Next.js совместимость |

## Когда использовать

Этот скилл загружается автоматически, когда вы просите:

- "добавь Zustand"
- "настрой state management"
- "добавь persist в Zustand"
- "zustand с devtools"
- "zustand для Next.js"
- "zustand slices"

## Преимущества

✅ **Адаптивная сложность** — от простого к продвинутому  
✅ **TypeScript готовность** — полная типизация  
✅ **Middleware комбинации** — persist + devtools + immer  
✅ **SSR поддержка** — для Next.js проектов  
✅ **Best practices** — селекторы, shallow сравнение