# Настройка GitHub Actions

## Что делает

Создаёт production-ready CI workflow для Node.js/TypeScript проектов. Автоматически определяет пакетный менеджер, добавляет кэширование и cancel-in-progress.

## Как работает

- Определяет npm/yarn/pnpm по lockfile
- Создаёт `.github/workflows/ci.yml`
- Настраивает concurrency, permissions, cache
- Пропускает doc-only изменения

## Как вызвать

Скилл загружается при запросах:

- "настрой github actions"
- "добавь CI"
- "настрой автоматизацию на пуш"
- "сделай workflow для тестов"

## Что поддерживает

| Стек | Поддержка |
|---|---|
| npm | Да |
| pnpm | Да |
| yarn | Да |
| Next.js / React | Да (через `npm run build --if-present`) |
| ESLint / Prettier | Да (lint step опционально) |

## Принципы

- `$default-branch` вместо hardcoded 'main'
- cancel-in-progress для concurrency
- минимальные permissions
- встроенный cache для зависимостей
