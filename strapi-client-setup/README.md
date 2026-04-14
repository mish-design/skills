# Strapi Client Setup

## Что делает

Создаёт типизированный API-клиент для Strapi (v3/v4/v5):

- **TypeScript типы** для Strapi-ответов (StrapiResponse, StrapiMedia)
- **Хелперы** для populate, пагинации, фильтров
- **Утилиты** для работы с медиафайлами (getImageUrl, getBestImage)
- **Поддержка версий** Strapi v3, v4, v5

## Как работает

Скилл задаёт вопросы:

1. Версия Strapi (v3/v4/v5)
2. Пакетный менеджер (npm/yarn/pnpm)
3. Использовать существующий axios или fetch
4. URL Strapi сервера
5. Генерировать TypeScript типы для моделей?

Затем генерирует готовые файлы в `lib/strapi/`:
- `types.ts` — базовые типы (StrapiResponse, StrapiMedia)
- `api.ts` — typed API-клиент с поддержкой версий
- `helpers.ts` — populate, пагинация, фильтры, работа с изображениями
- `generate-types.ts` — скрипт для автоматической генерации типов из Strapi API

## Примеры сгенерированного кода

```typescript
// Получить статьи с автором и обложкой
const { data: articles } = await strapiGet<Article[]>('/articles', {
  params: { 'populate[author]': '*', 'pagination[page]': 1 },
});

// Получить URL изображения
const imageUrl = getBestImage(article.cover, 'medium');
```

## Как вызвать

Этот скилл загружается автоматически, когда вы просите:

- "подключи Strapi"
- "настрой API для Strapi"
- "добавь Strapi клиент"
- "работа с медиафайлами Strapi"
- "populate в Strapi"
