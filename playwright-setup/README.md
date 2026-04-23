# Playwright Setup

## Что делает

Настраивает Playwright для E2E тестирования:

- **Page Object Model** — паттерн для поддерживаемых селекторов
- **MSW** — мок API для E2E без реального бэкенда
- **CI интеграция** — GitHub Actions workflow
- **Common patterns** — loading, empty, validation, navigation

## Как работает

Скилл:

1. Устанавливает `@playwright/test`
2. Генерирует `playwright.config.ts` с webServer для dev
3. Настраивает MSW для мока API в E2E
4. Показывает Page Object Model паттерн
5. Добавляет E2E workflow в CI

## Как вызвать

Скилл загружается, когда вы просите:

- "добавь E2E тесты"
- "настрой playwright"
- "создай браузерные тесты"
- "автоматизируй UI тестирование"

## Что стыкуется

- `testing-setup` — юниты + E2E = полная пирамида тестирования
- `msw-setup` — MSW для E2E без зависимости от бэкенда
- `github-actions-setup` — E2E workflow в CI

## Паттерны

| Паттерн | Что тестирует |
|---------|---------------|
| `LoginPage` POM | Селекторы логина в одном месте |
| `getByRole` | Доступные селекторы — приоритет 1 |
| `getByTestId` | Test ID — стабильные, явные |
| `server.use()` | Переопределение мока на один тест |