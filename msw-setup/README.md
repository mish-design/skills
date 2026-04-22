# MSW Setup

## Что делает

Настраивает MSW (Mock Service Worker) для прозрачного мока API:

- **Browser dev** — service worker перехватывает запросы, можно работать без бэкенда
- **Unit tests** — `server.use()` подменяет моки на уровне конкретного теста
- **Error states** — легко тестировать 500, timeout, network failure
- **Deterministic tests** — без реального сервера, без flaky тестов

## Как работает

Скилл определяет стек проекта:

- React/Vue/Next → browser mocking (service worker)
- Vitest/Jest → test mocking (server)

Создаёт файлы по паттерну:

```
src/mocks/
  handlers.ts    ← HTTP моки (GET/POST/DELETE/...)
  browser.ts     ← worker для браузера
  server.ts      ← server для тестов
```

Генерирует `public/mockServiceWorker.js` и добавляет `msw:init` в package.json.

## Как вызвать

Скилл загружается, когда вы просите:

- "добавь моки"
- "настрой MSW"
- "мокай API"
- "работай без бэкенда"
- "нужны моки для тестов"
- "mock API"

## Что стыкуется

- `axios-setup` — axios не знает что работает с моком, всё прозрачно
- `testing-setup` — моки в тестах усиливают покрытие error states