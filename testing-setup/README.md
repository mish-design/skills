# Настройка тестирования (Vitest/Jest)

## Что делает

Устанавливает и настраивает тестовый фреймворк с покрытием кода, Testing Library и поддержкой UI-фреймворков.

## Как работает

- **Автоопределение** — обнаруживает Next.js, React, Vue, Svelte, Vitest или Jest в проекте
- **UI-фреймворки** — React, Vue, Svelte или чистый JS/TS без UI-библиотеки
- **CSS-модули** — `identity-obj-proxy` для Jest, `next/jest` для Next.js (автоматически)
- **Покрытие кода** — v8 provider с правильной фильтрацией
- **Готовые скрипты** — `test`, `test:watch`, `test:coverage`

## Как вызвать

Скилл загружается автоматически при запросах:

- "настрой тестирование"
- "добавь тесты"
- "установи vitest/jest"
- "настрой testing library"
- "добавь unit-тесты"

## Поддержка фреймворков

### Тест-раннеры

| Фреймворк | Когда использовать |
|-----------|-------------------|
| **Vitest** | Новые проекты, Vite, быстрая разработка (рекомендуется) |
| **Jest** | Legacy-проекты, большое комьюнити, существующая база тестов |

### UI-фреймворки (для обоих раннеров)

| UI-фреймворк | Пакеты Testing Library | Специфика |
|-------------|----------------------|-----------|
| **React** | `@testing-library/react`, `@testing-library/jest-dom` | Стандартная настройка |
| **Vue** | `@testing-library/vue`, `@vitejs/plugin-vue` | `@vue/vue3-jest` для Jest |
| **Svelte** | `@testing-library/svelte`, `@sveltejs/vite-plugin-svelte` | `svelte-jester` для Jest |
| **Без UI** | `@testing-library/dom` | DOM-тесты без фреймворка |

### Интеграции

| Проект | Особенность |
|--------|-------------|
| **Next.js + Jest** | `next/jest` — SWC, CSS, alias автоматически |
| **Next.js + Vitest** | `__NEXT_TEST_MODE: 'true'`, `@vitejs/plugin-react` |
| **CSS/Sass модули** | `identity-obj-proxy` мокирует импорты стилей |
| **TypeScript** | Автоматическая настройка `compilerOptions.types` |
