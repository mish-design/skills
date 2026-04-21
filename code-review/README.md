# Проведение Code Review

## Что делает

Проводит структурированное ревью кода по профессиональному чеклисту из 7 измерений: Correctness, Security, Performance, Maintainability, Type Safety, Tests, Architecture.

## Как работает

1. **Prepare** — определяет scope (какие файлы/коммиты/PR)
2. **Analyze** — проверяет по 7 измерениям, размечает severity
3. **Report** — отчёт с группировкой по Critical / Major / Minor / Nit

## Как вызвать

Скилл загружается, когда вы просите:

- "проведи ревью"
- "посмотри код"
- "оцени качество"
- "review this code"
- "check quality"

## Измерения

| # | Измерение | Что проверяет |
|---|-----------|---------------|
| D1 | Correctness | Логические ошибки, race conditions, исключения |
| D2 | Security | Инъекции, секреты, авторизация |
| D3 | Performance | N+1, утечки памяти, пагинация |
| D4 | Maintainability | Глубина функций, нейминг, дублирование |
| D5 | Type Safety | any, unsafe casts, nullability |
| D6 | Tests | Покрытие, assertions, моки |
| D7 | Architecture |耦合, DRY, разделение ответственности |

## Принципы

- Сначала критическое — не хоронить security в конце
- Будь конкретен: "file:line, exact code snippet"
- Предлагай, а не только описывай
- Спрашивай вместо догадок
- Хвали хорошее, не только критикуй
