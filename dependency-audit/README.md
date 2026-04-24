# Dependency Audit

## Что делает

Аудит зависимостей в три слоя:

- **Security** — `npm audit` для уязвимостей
- **Outdated** — `ncu` для устаревших пакетов
- **Unused** — `depcheck` для неиспользуемых зависимостей

## Как работает

Скилл запускает любую комбинацию проверок:

1. `npm audit` — known vulnerabilities
2. `ncu` — какие пакеты устарели и как обновить
3. `depcheck` — какие пакеты не используются в коде

## Как вызвать

Скилл загружается, когда вы просите:

- "аудит зависимостей"
- "проверь уязвимости"
- "найди устаревшие пакеты"
- "почисти неиспользуемые зависимости"
- "check for vulnerabilities"

## Три слоя аудита

| Слой | Инструмент | Что проверяет |
|------|-----------|----------------|
| Security | `npm audit` | Known vulnerabilities (CVE) |
| Outdated | `ncu` | Major/minor/patch обновления |
| Unused | `depcheck` | Неиспользуемый код |

## Ключевые команды

```bash
npm audit --audit-level=high  # fails build on high/critical
ncu -u                       # обновить package.json
npm uninstall <package>     # удалить неиспользуемый пакет
```

## Что стыкуется

- `github-actions-setup` — добавляет Security Audit workflow в CI
- `sentry-setup` — уязвимости могут привести к errors в Sentry