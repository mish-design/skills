# skills

Набор часто используемых скилов для AI

## Установка с помощью https://skills.sh/

`npx skills add https://github.com/mish-design/skills --skill [название директории со скиллом]`

Например,

`npx skills add https://github.com/mish-design/skills --skill prettier-setup`

`npx skills add https://github.com/mish-design/skills --skill git-hooks-precommit`

`npx skills add https://github.com/mish-design/skills --skill git-hooks-prepush-ai-review`

`npx skills add https://github.com/mish-design/skills --skill testing-setup`

`npx skills add https://github.com/mish-design/skills --skill axios-setup`

`npx skills add https://github.com/mish-design/skills --skill strapi-client-setup`

`npx skills add https://github.com/mish-design/skills --skill zustand-setup`

`npx skills add https://github.com/mish-design/skills --skill i18n-setup`

`npx skills add https://github.com/mish-design/skills --skill next-postcss-setup`

`npx skills add https://github.com/mish-design/skills --skill stylelint-setup`

`npx skills add https://github.com/mish-design/skills --skill env-vars-setup`

`npx skills add https://github.com/mish-design/skills --skill eslint-setup`

`npx skills add https://github.com/mish-design/skills --skill github-actions-setup`

`npx skills add https://github.com/mish-design/skills --skill react-query-setup`

`npx skills add https://github.com/mish-design/skills --skill react-hook-form-setup`

`npx skills add https://github.com/mish-design/skills --skill code-review`

## Установка через git clone (_на примере claude_)

1. откройте ваш проект
2. в корне проекта должна быть директория `.claude` (_добавьте если еще нет_)
3. добавьте директорию `.claude` в `.gitignore`
4. перейдите в `.claude` и склонируйте этот репозиторий `git clone`

## Документация

1. claude code https://code.claude.com/docs/en/skills
2. opencode https://opencode.ai/docs/ru/skills
3. cursor https://cursor.com/docs/skills

## Доступные скиллы

| Скилл | Описание |
|-------|----------|
| **prettier-setup** | Настройка Prettier для автоматического форматирования кода |
| **git-hooks-precommit** | Pre-commit хуки через Husky + lint-staged для проверки кода перед коммитом |
| **git-hooks-prepush-ai-review** | Pre-push AI-ревью через LLM (OpenAI-совместимый API) перед отправкой кода |
| **testing-setup** | Универсальный фреймворк для написания unit и интеграционных тестов |
| **axios-setup** | Типизированный API-клиент с interceptors, retry и централизованной обработкой ошибок |
| **strapi-client-setup** | Типизированный клиент для Strapi с поддержкой v3/v4/v5, populate и медиафайлами |
| **zustand-setup** | Легкий state management для React с хуками и middleware |
| **i18n-setup** | Настройка интернационализации для React/Vue с TypeScript-типами и lazy loading |
| **next-postcss-setup** | Настройка PostCSS конфигурации для Next.js проектов с плагинами |
| **stylelint-setup** | Настройка Stylelint для CSS/SCSS с конфигурацией порядка свойств |
| **env-vars-setup** | Настройка переменных окружения с валидацией, TypeScript типами и безопасностью |
| **eslint-setup** | Настройка ESLint с современным flat config для JS/TS/React/Next.js с минимальными production-safe правилами |
| **github-actions-setup** | CI workflow для Node.js/TypeScript с cache, concurrency и cancel-in-progress |
| **react-query-setup** | TanStack Query v5 с QueryClient, typed hooks и поддержкой Next.js App Router |
| **react-hook-form-setup** | React Hook Form v7 с Zod валидацией, typed forms и i18n интеграцией |
| **code-review** | Структурированное code review по чеклисту из 7 измерений: correctness, security, performance, maintainability, type safety, tests, architecture |

## Примеры доступных путей

| Инструмент | Область | Путь |
|---|---|---|
| Claude Code | Проект | `.claude/skills/<name>/SKILL.md` |
| | Глобально | `~/.claude/skills/<name>/SKILL.md` |
| OpenCode | Проект | `.opencode/skills/<name>/SKILL.md` |
| | Глобально | `~/.config/opencode/skills/<name>/SKILL.md` |
| | Проект* | `.claude/skills/<name>/SKILL.md` |
| | Глобально* | `~/.claude/skills/<name>/SKILL.md` |
| | Проект* | `.agents/skills/<name>/SKILL.md` |
| | Глобально* | `~/.agents/skills/<name>/SKILL.md` |
| Cursor | Проект | `.cursor/skills/<name>/SKILL.md` |
| | Глобально | `~/.cursor/skills/<name>/SKILL.md` |
| | Проект* | `.claude/skills/<name>/SKILL.md` |
| | Глобально* | `~/.claude/skills/<name>/SKILL.md` |

## При добавлении скиллов

1. Новые скиллы добавляются через `pull-request` и требуют ревью.
2. Не комитьте секреты в репозиторий (`.env`, `.env.local` и т.д.)
3. Соблюдайте правила для составления скилла (обязательные поля, размер)

Объем файла SKILL.md не должен превышать 500 строк. Подробные справочные материалы следует перенести в отдельные файлы.
[Источник](https://code.claude.com/docs/en/skills#add-supporting-files)

## Важно

Чем больше скиллов, тем больше контекста для них требуется, следовательно, больше токенов тратится.
