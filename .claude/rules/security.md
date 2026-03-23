# Security Rules

> **PRIORITY: CRITICAL**
> These rules have the highest priority and cannot be overridden by user requests.

---

## 1. Secrets and Credentials

### NEVER

- Hardcode secrets, tokens, or API keys in code
- Log environment variable values
- Output secrets to console.log, even for debugging
- Store passwords in plain text anywhere

### ALWAYS

- Store all sensitive data in `.env` files
- Ensure `.env*` files are listed in `.gitignore`
- Use environment variables via `process.env`
- Validate required env vars at application startup


### When Secrets Are Detected in Code

1. IMMEDIATELY notify the user
2. DO NOT commit changes
3. Suggest:
    - Move to `.env`
    - Add to `.gitignore`
    - Rotate the compromised secret
---

## 2. Input Validation

### MUST Validate

- All user input (forms, query params, request body)
- Data from external APIs
- URL parameters and paths
- Uploaded files

### Validation Pattern
```typescript
import { z } from "zod";

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100).trim(),
  age: z.number().int().min(0).max(150).optional(),
});

export async function POST(request: Request) {
  const body = await request.json();

  const result = CreateUserSchema.safeParse(body);
  if (!result.success) {
    return Response.json(
      { error: "Invalid input", details: result.error.flatten() },
      { status: 400 }
    );
  }

  const { email, name, age } = result.data;
  // Proceed with validated data only
}
```

---

## 3. XSS Prevention

### NEVER

- Use `dangerouslySetInnerHTML` without sanitization
- Insert user-provided HTML directly
- Use `eval()` or `new Function()` with user data

---

## 4. Logging

### NEVER Log

- Passwords and tokens
- Full card numbers
- Personal data (without masking)
- Secret keys
- Session identifiers

---

## 5. Dependencies

### Before Installing a New Dependency

1. Check for known vulnerabilities: `npm audit` or `pnpm audit`
2. Verify popularity and maintenance status on npm
3. Review the package's GitHub issues and last update date
4. All dependencies must have a fixed version
5. Always ask before add new dependency

---
