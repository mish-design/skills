# Storybook Setup

## Что делает

Настраивает Storybook v7+ с Vite для component-driven development:

- **CSF3 stories** — современный формат историй
- **Controls** — интерактивные пропсы в UI
- **MSW** — мок API прямо в stories
- **Interaction testing** — пошаговое тестирование взаимодействий
- **Decorators** — обёртки для i18n, store, theme

## Как работает

Скилл:

1. Устанавливает `@storybook/react-vite` + addons
2. Генерирует `.storybook/main.ts` и `preview.ts`
3. Настраивает MSW через `msw-storybook-addon`
4. Создаёт декораторы для провайдеров (i18n, redux)
5. Показывает паттерны для полезных stories

## Как вызвать

Скилл загружается, когда вы просите:

- "настрой storybook"
- "добавь storybook"
- "создай design system"
- "документируй компоненты"
- "set up component documentation"

## Полезные паттерны

| Паттерн | Зачем |
|---------|-------|
| `Primary`, `Secondary`, `Disabled` | Варианты компонента |
| `Loading: Story` | Состояние загрузки |
| `ErrorState: Story` | Состояние ошибки |
| `EmptyState: Story` | Пустое состояние |
| `WithMockedData: Story` | Компонент с моком API |
| `FormSubmission: Story` | Тест взаимодействия (play) |

## Что стыкуется

- `msw-setup` — если MSW уже есть, Storybook подхватит те же handlers
- `i18n-setup` — декоратор для i18n провайдера
- `axios-setup` — Storybook мокает API прозрачно для axios