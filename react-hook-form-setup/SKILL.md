---
name: react-hook-form-setup
description: Set up react-hook-form v7 with validation and typed forms. Use when asked to add react-hook-form, set up form validation, configure form handling, or add forms to a React project.
---

# React Hook Form Setup

Set up react-hook-form v7 with production-ready patterns.

## Step 1 — Detect project

Check `package.json`:
- `react` present → proceed
- neither → ask before proceeding

Check for existing installation:
- `react-hook-form` in dependencies → extend, do not overwrite

Ask also whether to use Zod for schema validation (recommended for TypeScript projects).

## Step 2 — Install dependencies

**Basic:**
```bash
<pkg-manager> add react-hook-form
```

**With Zod validation (recommended for TypeScript):**
```bash
<pkg-manager> add react-hook-form @hookform/resolvers zod
```

## Step 3 — Create a typed form hook

Create `src/lib/use-form.ts` (or `hooks/use-form.ts`):

### Option A — Built-in validation

```typescript
import { useForm } from 'react-hook-form';

export type LoginFormData = {
  email: string;
  password: string;
};

export function useLoginForm() {
  return useForm<LoginFormData>({
    mode: 'onBlur',
    defaultValues: {
      email: '',
      password: '',
    },
  });
}
```

### Option B — Zod schema (recommended)

```typescript
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';

export const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

export type LoginFormData = z.infer<typeof loginSchema>;

export function useLoginForm() {
  return useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    mode: 'onBlur',
    defaultValues: {
      email: '',
      password: '',
    },
  });
}
```

## Step 4 — Form component

```typescript
import { useLoginForm, type LoginFormData } from '@/lib/use-form';

export function LoginForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useLoginForm();

  const onSubmit = async (data: LoginFormData) => {
    await fetch('/api/login', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <input {...register('email')} placeholder="Email" />
        {errors.email && <span>{errors.email.message}</span>}
      </div>

      <div>
        <input {...register('password')} type="password" placeholder="Password" />
        {errors.password && <span>{errors.password.message}</span>}
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Log in'}
      </button>
    </form>
  );
}
```

## Step 5 — Controller for custom inputs

For components that manage their own state (e.g., a custom Select), use `Controller`:

```typescript
import { Controller, useForm } from 'react-hook-form';
import { Select } from './Select';

export function CountryForm() {
  const { control, handleSubmit } = useForm<{ country: string }>();

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Controller
        name="country"
        control={control}
        defaultValue=""
        render={({ field, fieldState }) => (
          <Select
            {...field}
            options={['US', 'UA', 'GB']}
            error={fieldState.error?.message}
          />
        )}
      />
      <button>Submit</button>
    </form>
  );
}
```

## Step 6 — i18n integration (optional)

If the project uses i18n-setup, wire error messages through `t`:

```typescript
import { useTranslation } from 'react-i18next';

export function LoginForm() {
  const { t } = useTranslation();
  const { register, handleSubmit, formState: { errors } } = useLoginForm();

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} placeholder={t('auth.email')} />
      {errors.email && <span>{t(errors.email.message!)}</span>}
      {/* ... */}
    </form>
  );
}
```

Note: Zod error messages are plain strings at runtime. To use i18n, either pass `t()` as a resolver factory, or translate errors at render time as shown above.

## Done

- `react-hook-form` installed
- Typed form hook created
- Zod resolver shown (recommended for TypeScript)
- Controller pattern for custom inputs
- i18n integration noted
