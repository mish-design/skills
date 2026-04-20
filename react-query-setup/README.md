# Настройка TanStack Query

## Что делает

Настраивает TanStack Query v5 для React/Next.js с QueryClient, devtools и typed hooks.

## Как работает

- Определяет React или Next.js App Router
- Создаёт QueryClient с production-дефолтами
- Настраивает Provider для App Router
- Показывает typed hooks паттерн

## Как вызвать

Скилл загружается при запросах:

- "настрой react query"
- "добавь tanstack query"
- "настрой data fetching"
- "добавь кэширование"

## Что поддерживает

| Стек | Поддержка |
|---|---|
| React | Да |
| Next.js App Router | Да |
| TypeScript | Да |
| Devtools | Да (опционально) |

## Принципы

- TanStack Query v5 (gcTime вместо cacheTime)
- Sensible defaults: staleTime 1min, gcTime 5min, retry 1
- App Router ready с 'use client' и useState
