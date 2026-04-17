# Настройка ESLint

## Что делает

Настраивает ESLint через современный flat config с безопасными production-дефолтами для JS/TS, React и Next.js.

## Как работает

- определяет TypeScript, React, Next.js
- создаёт `eslint.config.mjs`
- добавляет только нужные зависимости
- не смешивает ESLint и Prettier
- добавляет `lint` и `lint:fix`

## Как вызвать

Скилл загружается, когда вы просите:

- "настрой eslint"
- "добавь линтер"
- "сконфигурируй eslint для typescript"
- "добавь eslint в next/react проект"

## Что поддерживает

| Стек | Поддержка |
|---|---|
| JavaScript | Да |
| TypeScript | Да |
| React | Да |
| Next.js | Да |

## Принципы

- flat config вместо legacy `.eslintrc`
- минимум правил по умолчанию
- без форматирования через ESLint
- безопасное расширение существующей конфигурации
