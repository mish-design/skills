# skills

Набор часто используемых правил и скилов для AI

Подходит для `claude code`, `cursor`, `opencode` т.к. они имеют общий пусть до скиллов
`.claude/skills/<name>/SKILL.md` и их структуру

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


## Как установить (_на примере claude_)

1. откройте ваш проект 
2. в корне проекта должна быть директория `.claude` (_добавьте если еще нет_)
3. добавьте директорию `.claude` в `.gitignore` 
4. перейдите в `.claude` и склонируйте этот репозиторий `git clone`

## Важно

Чем больше скиллов, тем больше контекста для них требуется, следовательно, больше токенов тратится.
Неиспользуемые скиллы можно отключать

> TODO: Добавить информацию о том как отключать скиллы 
