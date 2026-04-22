# MSW: Mock Service Worker

MSW перехватывает HTTP-запросы на уровне сети и возвращает мок-ответы. Ваш код не знает что работает с моком.

## Зачем нужен

- **Бэк не готов** — фронт может работать и тестироваться без зависимости от бэка
- **Тестирование** — deterministic tests без реального сервера
- **Edge cases** — легко проверить 500, timeout, network failure
- **CI/CD** — тесты не зависят от внешних сервисов

## Быстрый старт

### 1. Установка

```bash
npm i -D msw
```

### 2. Создание первого мока

Создайте `src/mocks/handlers.ts`:

```typescript
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'Alice', email: 'alice@example.com' },
      { id: 2, name: 'Bob', email: 'bob@example.com' },
    ])
  }),
]
```

### 3. Подключение в браузере (dev)

Создайте `src/mocks/browser.ts`:

```typescript
import { setupWorker } from 'msw'
import { handlers } from './handlers'

export const worker = setupWorker(...handlers)
```

В `main.tsx` (точка входа):

```typescript
import { worker } from './mocks/browser'

async function enableMocking() {
  return worker.start({
    onUnhandledRequest: 'bypass',
  })
}

enableMocking()
```

Инициализируйте worker-файлы:

```bash
npx msw init public/ --save
```

### 4. Подключение в тестах

Создайте `src/mocks/server.ts`:

```typescript
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

В `tests/setup.ts`:

```typescript
import { beforeAll, afterEach, afterAll } from 'vitest'
import { server } from '../src/mocks/server'

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

Подключите setup в `vitest.config.ts`:

```typescript
export default defineConfig({
  test: {
    setupFiles: ['./tests/setup.ts'],
  },
})
```

## Структура файлов

```
src/
  mocks/
    handlers.ts      ← HTTP моки (GET, POST, PUT, DELETE...)
    browser.ts       ← worker для браузера
    server.ts        ← server для тестов
```

## Как работают handlers

### Базовый GET

```typescript
http.get('/api/users', () => {
  return HttpResponse.json([{ id: 1, name: 'Alice' }])
})
```

### GET с параметром пути

```typescript
http.get('/api/users/:id', ({ params }) => {
  const { id } = params
  return HttpResponse.json({ id, name: 'User ' + id })
})
```

### POST с телом

```typescript
http.post('/api/users', async ({ request }) => {
  const body = await request.json()
  return HttpResponse.json({ id: 3, ...body }, { status: 201 })
})
```

### DELETE

```typescript
http.delete('/api/users/:id', () => {
  return new HttpResponse(null, { status: 204 })
})
```

### Ошибка (500, 404)

```typescript
http.get('/api/users', () => {
  return HttpResponse.json(
    { error: 'Server error' },
    { status: 500 }
  )
})
```

### Задержка (имитация сети)

```typescript
http.get('/api/users', async () => {
  await new Promise((resolve) => setTimeout(resolve, 1000))
  return HttpResponse.json([{ id: 1, name: 'Alice' }])
})
```

## Переопределение моков в тестах

Главная фича MSW — можно подменить мок для конкретного теста:

```typescript
test('показывает пустое состояние когда нет пользователей', async () => {
  server.use(
    http.get('/api/users', () => HttpResponse.json([]))
  )

  render(<UserList />)
  expect(screen.getByText('No users')).toBeInTheDocument()
})

test('показывает ошибку когда API упал', async () => {
  server.use(
    http.get('/api/users', () =>
      HttpResponse.json({ error: 'Server error' }, { status: 500 })
    )
  )

  render(<UserList />)
  expect(await screen.findByText('Failed to load')).toBeInTheDocument()
})
```

## Типичные сценарии тестирования

### Loading state

```typescript
test('shows spinner while loading', async () => {
  const { getByRole } = render(<UserList />)
  expect(getByRole('progressbar')).toBeInTheDocument()
})
```

### Empty state

```typescript
test('shows empty message when no data', async () => {
  server.use(http.get('/api/users', () => HttpResponse.json([])))
  render(<UserList />)
  expect(screen.getByText('No users found')).toBeInTheDocument()
})
```

### Error state

```typescript
test('shows error message on failure', async () => {
  server.use(
    http.get('/api/users', () =>
      HttpResponse.json({ message: 'Server error' }, { status: 500 })
    )
  )
  render(<UserList />)
  expect(await screen.findByText('Failed to load users')).toBeInTheDocument()
})
```

## Включение/выключение моков

В браузере можно переключать моки:

```typescript
worker.enable()   // включить моки
worker.disable()  // отключить (запросы идут на реальный сервер)
worker.resetHandlers() // сбросить к начальному состоянию
```

## Важные понятия

| Понятие | Что делает |
|---------|------------|
| `http.get/post/delete` | Определяет какой HTTP метод мокать |
| `HttpResponse.json()` | Возвращает JSON ответ |
| `params` | Параметры из URL пути (`/users/:id`) |
| `request.json()` | Получает тело POST/PUT запроса |
| `server.use()` | Переопределяет мок на время одного теста |
| `server.resetHandlers()` | Сбрасывает все переопределения |

## Частые ошибки

### Забыли вернуть ответ

```typescript
// ❌ неправильно — функция ничего не возвращает
http.get('/api/users', () => {
  HttpResponse.json([])
})

// ✅ правильно — return есть
http.get('/api/users', () => {
  return HttpResponse.json([])
})
```

### Забыли async для тела запроса

```typescript
// ❌ неправильно — request.json() асинхронный
http.post('/api/users', ({ request }) => {
  const body = request.json()
  return HttpResponse.json({ id: 1, ...body })
})

// ✅ правильно — await
http.post('/api/users', async ({ request }) => {
  const body = await request.json()
  return HttpResponse.json({ id: 1, ...body })
})
```

### Не сбросили handlers между тестами

Без `afterEach(() => server.resetHandlers())` моки одного теста влияют на другой.

## Что дальше

- Добавьте моки для каждого API домена (users, products, orders)
- Тестируйте не только happy path, но и ошибки
- Комбинируйте с `axios-setup` — axios не знает что работает с моком
- Добавьте задержки для тестирования loading states