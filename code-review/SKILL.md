---
name: code-review
description: Conduct a thorough, structured code review using a professional checklist covering correctness, security, performance, maintainability, type safety, tests, and architecture. Use when a user asks to review code, conduct a review, check quality, or evaluate changes. Triggered by phrases like "проведи ревью", "посмотри код", "оцени качество", "review this", "check this code".
---

# Code Review

Structured, multi-phase code review following professional checklist methodology.

## Review Phases

```
PREPARE → ANALYZE → REPORT
```

## Phase 1: Prepare

### Scope detection

Ask the user what to review:

- specific files (provide paths)
- a git diff / PR URL
- recent commits on current branch

If no scope given, review **uncommitted or recently changed** files:

```bash
git diff --name-only HEAD~5..HEAD
git status --short
```

### Context gathering

1. Find related specs / tickets / requirements (ask user)
2. Check `SPEC.md` in project root
3. Check recent commits to understand intent:

```bash
git log --oneline -10
```

4. Read changed files — all of them before forming opinions

### Severity levels

| Level | Meaning | Action |
|-------|---------|--------|
| **Critical** | Security vulnerability, data loss risk, crash | Must fix before merge |
| **Major** | Functional bug, memory leak, N+1, blocking performance | Address or track in follow-up |
| **Minor** | Code smell, avoidable complexity, fragile pattern | Consider fixing |
| **Nit** | Style preference, naming, formatting | Optional, low priority |

## Phase 2: Analyze

Check each changed file across **7 dimensions**. Mark findings with severity.

### D1 — Correctness

- Logic bugs, off-by-one errors
- Missing null/undefined checks
- Incorrect loop bounds or array access
- Race conditions, async/await mistakes
- Swallowed exceptions (`catch {}` with no handling)
- Mutable global state or shared state without synchronization

**Red flags:**

```javascript
// catching without re-throwing or logging
catch (e) {}

// shared mutable state across requests
let cache = {};

// incorrect array usage — shift() removes from start, pop() from end
arr.pop()
arr.includes
```

### D2 — Security

- User input without sanitization/validation
- SQL / command injection possibilities
- Hardcoded secrets, API keys, tokens
- Missing authorization checks
- Insecure direct object reference
- CORS misconfiguration
- XXS in rendered user content
- Overly permissive file system access

**Red flags:**

```javascript
// user input into shell/eval
eval(userInput)
exec(userInput)
query(`SELECT * FROM users WHERE id = ${id}`)

// hardcoded secret
const API_KEY = "sk-...";

// missing auth check
async function getUserData(req, res) {
  return db.users.findOne({ id: req.params.id }); // no auth check
}
```

### D3 — Performance

- N+1 queries (looping DB calls)
- Large data loaded into memory without pagination
- Unnecessary re-renders in UI frameworks
- Expensive computation in render path
- Missing indexes for frequent queries
- Memory leaks (closures, event listeners, globals)
- Blocking the main thread (synchronous heavy ops)

**Red flags:**

```javascript
// N+1
for (const user of users) {
  const posts = await db.posts.findMany({ userId: user.id });
}

// expensive in render
items.map(item => expensiveTransform(item));

// missing pagination
const allUsers = await db.users.findMany(); // unbounded
```

### D4 — Maintainability

- Functions longer than 40 lines
- Deep nesting (>3 levels)
- Poor naming (single letters, misleading names)
- Missing JSDoc on public APIs
- Magic numbers / hardcoded constants
- Duplicated code blocks
- Overly clever one-liners hard to read
- Missing error messages

**Red flags:**

```javascript
// magic numbers
if (x > 86400000) { ... } // what is this?

// deep nesting
if (a) {
  if (b) {
    if (c) {
      doSomething();
    }
  }
}

// misleading name
let d = getData(); // "d" tells nothing
```

### D5 — Type Safety (TypeScript / PropTypes)

- `any` types without justification
- Missing type definitions for interfaces
- Unsafe casts (`as unknown as X`)
- Missing nullability handling
- Type guards not used where needed
- Functions without return types

**Red flags:**

```typescript
// any without reason
function parse(input: any): any { ... }

// unsafe cast
const val = data as unknown as string;

// missing return type on public function
export function processData(data) { ... }
```

### D6 — Tests

- No tests for critical paths
- Tests with no assertions (`it('...', () => {})`)
- Mocking implementation instead of behavior
- Happy path only (no error/edge cases)
- Test names not describing behavior
- Shared mutable state between tests
- No cleanup after side effects

**Red flags:**

```javascript
// no assertions
it('submits form', () => {
  handleSubmit();
});

// implementation mocking instead of behavior
vi.mock('./api', () => ({
  fetchUser: vi.fn().mockResolvedValue({ id: 1 }), // tested implementation
}));

// no teardown
afterEach(() => {
  // forgot cleanup
});
```

### D7 — Architecture & Patterns

- Tight coupling (file A knows internal details of file B)
- Violation of DRY (repeated business logic)
- Business logic in UI components
- Side effects buried in pure-looking functions
- Missing separation: routing / business logic / data access
- Config that should be env vars but is hardcoded
- Inconsistent error handling patterns

**Red flags:**

```javascript
// business logic in component
function UserCard({ user }) {
  const discount = user.isPremium && user.joinDate > Date.now() - 90
    ? 0.2 : 0.1; // business rule in JSX
}

// inconsistent patterns
try { doThing(); } catch {}
axios.get('/api').catch(e => {}) // different error handling style
```

## Phase 3: Report

Structure output as:

```markdown
## 🔴 Critical (must fix)

...

## 🟠 Major

...

## 🟡 Minor

...

## 💡 Nitpicks

...

## ✅ What's good

...
```

### Reporting rules

1. **Lead with critical** — don't bury security issues at the bottom
2. **Be specific** — file:line, exact code snippet, exact problem
3. **Suggest, don't just describe** — "consider..." or "try..."
4. **Acknowledge context** — "this is fine IF...", "may be intentional because..."
5. **Distinguish taste from requirement** — nitpicks are optional
6. **Balance criticism with credit** — point out what's actually good

### Anti-patterns to avoid in feedback

- Vague: "this could be better" → specific: "this loop makes 50 DB calls, consider a JOIN"
- Personal: "you should..." → neutral: "consider...", "this pattern tends to..."
- Absolute: "never do X" → contextual: "in this case X caused..., prefer Y"
- Overwhelming: list all 40 issues at once → prioritize top 5-7, summarize the rest

### When to request clarification

Instead of guessing, ask the user:

- "Is there a reason for the 500ms setTimeout on line 42? Seems like a potential race condition."
- "Should this data come from an API call or is client-side computation intentional here?"

## Done checklist

- [ ] All changed files read and analyzed
- [ ] Each dimension checked (D1-D7)
- [ ] Issues grouped by severity
- [ ] Top issues have specific fix suggestions
- [ ] Positive observations included
- [ ] Feedback is specific (file:line, not just "the code")
- [ ] Context-dependent judgments noted ("may be intentional because...")
