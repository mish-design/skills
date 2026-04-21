# Настройка React Hook Form

## Что делает

Настраивает react-hook-form v7 с валидацией, typed forms и поддержкой i18n.

## Как работает

- Создаёт typed form hook
- Показывает встроенную валидацию и Zod resolver
- Controller для кастомных инпутов
- Интеграция с i18n

## Как вызвать

Скилл загружается при запросах:

- "настрой react-hook-form"
- "добавь форму"
- "настрой валидацию формы"
- "добавь форму с zod"

## Что поддерживает

| Стек | Поддержка |
|---|---|
| React | Да |
| TypeScript | Да (Zod) |
| Zod validation | Да |
| Custom inputs (Controller) | Да |
| i18n | Да (опционально) |

## Принципы

- `mode: 'onBlur'` — валидация при blur, не при каждом вводе
- Zod resolver — рекомендуется для TypeScript проектов
- Типизированные FormData через `z.infer`
- Controller — для компонентов со своим состоянием
