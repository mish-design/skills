# Sentry Setup

## Что делает

Настраивает Sentry v8 для отслеживания ошибок и мониторинга производительности:

- **Error tracking** — ловит необработанные ошибки и exception'ы
- **Performance monitoring** — trace'ы транзакций (APM)
- **Source maps** — читаемые стектрейсы в продакшене
- **Breadcrumbs** — контекст перед ошибкой для быстрой отладки

## Как работает

Скилл:

1. Устанавливает `@sentry/react` (или `@sentry/next` / `@sentry/node`)
2. Инициализирует SDK с DSN из env
3. Добавляет Error Boundary для React
4. Настраивает source map upload в CI (Vite/Webpack плагины)
5. Показывает паттерны для breadcrumbs и manual capture

## Как вызвать

Скилл загружается, когда вы просите:

- "добавь sentry"
- "настрой error tracking"
- "подключи мониторинг ошибок"
- "интегрируй sentry"

## Что стыкуется

- `axios-setup` — Sentry ловит ошибки которые axios отправляет в `handleError`
- `github-actions-setup` — SENTRY_AUTH_TOKEN добавляется в CI secrets

## Ключевые понятия

| Понятие | Что делает |
|---------|------------|
| `Sentry.init()` | Инициализация SDK с DSN |
| `ErrorBoundary` | React-компонент для перехвата ошибок |
| `captureException()` | Отправить exception вручную |
| `captureMessage()` | Отправить message без стектрейса |
| `addBreadcrumb()` | Добавить контекст перед ошибкой |
| `tracesSampleRate` | Процент транзакций для APM (0.1 = 10%) |