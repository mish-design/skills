# skills

Набор часто используемых скилов для AI

## Установка с помощью https://skills.sh/

`npx skills add https://github.com/mish-design/skills --skill prettier-setup`

## Установка через git clone (_на примере claude_)

1. откройте ваш проект
2. в корне проекта должна быть директория `.claude` (_добавьте если еще нет_)
3. добавьте директорию `.claude` в `.gitignore`
4. перейдите в `.claude` и склонируйте этот репозиторий `git clone`

## Документация

1. claude code https://code.claude.com/docs/en/skills
2. opencode https://opencode.ai/docs/ru/skills
3. cursor https://cursor.com/docs/skills


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


## Важно

Чем больше скиллов, тем больше контекста для них требуется, следовательно, больше токенов тратится.
