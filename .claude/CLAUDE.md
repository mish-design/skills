## Pull Requests

1. Create a detailed message of what changed. Focus on the high level description of the problem it tries to solve, and how it is solved. Don't go into the specifics of the code unless it adds clarity.
2. NEVER ever mention a co-authored-by or similar aspects. In particular, never mention the tool used to create the commit message or PR.

## Breaking Changes

When making breaking changes, document them in docs/migration.md. Include:

1. What changed
2. Why it changed
3. How to migrate existing code

Search for related sections in the migration guide and group related changes together rather than adding new standalone sections.

---
paths:
- "src/app/api/**/*.ts"
---

# API Development Rules

- All API endpoints must include input validation
- Use the standard error response format
- Include OpenAPI documentation comments