---
name: env-vars-setup
description: "Sets up environment variables management with validation, TypeScript support, and best practices. Trigger this skill when initializing a new project, when adding new dependencies requiring environment variables, when preparing for deployment, or when encountering 'variable not defined' errors."
---

# Environment Variables Setup

## Before doing anything — ask the user

Before installing anything or creating files, **always ask the user for confirmation**:

> "Do you want to apply the `env-vars-setup` skill? It will create `.env.example` template, set up validation with zod, add TypeScript types for `process.env`, and configure security checks for environment variables."

Proceed only if the user confirms.

---

## Step 1 — Check Existing Configuration

**Check for existing .env files:**

```bash
echo "🔍 Checking for existing environment files..."
EXISTING_FILES=$(ls .env* 2>/dev/null | grep -v ".env.example" || echo "")
if [ -n "$EXISTING_FILES" ]; then
  echo "📁 Found: $EXISTING_FILES"
fi
```

---

## Step 2 — Detect Project Type

**Basic project detection:**

```bash
echo "🔧 Detecting project type..."

PROJECT_TYPE="generic"
HAS_TYPESCRIPT=false

if [ -f "package.json" ]; then
  # Simple framework detection
  if grep -q '"next"' package.json; then PROJECT_TYPE="nextjs"
  elif grep -q '"react"' package.json && grep -q '"vite"' package.json; then PROJECT_TYPE="vite-react"
  elif grep -q '"express"' package.json || grep -q '"koa"' package.json; then PROJECT_TYPE="node"
  fi
  
  # TypeScript detection
  if [ -f "tsconfig.json" ] || grep -q '"typescript"' package.json; then HAS_TYPESCRIPT=true; fi
fi

echo "📊 Project: $PROJECT_TYPE, TypeScript: $HAS_TYPESCRIPT"
```

---

## Step 3 — Create .env.example

**Create basic template:**

```bash
echo "📝 Creating .env.example..."

cat > .env.example << 'EOF'
# Environment Variables Template
# Copy to .env.local and fill actual values
# NEVER commit .env.local to git!

# Basics
NODE_ENV="development"
PORT="3000"
LOG_LEVEL="info"

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/dbname"

# API Keys (development only!)
STRIPE_SECRET_KEY="sk_test_51xxx"
OPENAI_API_KEY="sk-xxx"

# Frontend (Next.js)
NEXT_PUBLIC_APP_NAME="My App"
NEXT_PUBLIC_API_URL="http://localhost:3000/api"

# Add your variables below
EOF

echo "✅ Created .env.example"
```

---

## Step 4 — Install Dependencies

**Install zod for validation:**

```bash
if [ -f "package.json" ] && ! grep -q '"zod"' package.json; then
  echo "📦 Installing zod..."
  
  if [ -f "yarn.lock" ]; then
    yarn add zod --silent
  elif [ -f "pnpm-lock.yaml" ]; then
    pnpm add zod --silent
  else
    npm install zod --silent
  fi
fi
```

---

## Step 5 — Create Validation

**Create validation file:**

```bash
mkdir -p src

if [ "$HAS_TYPESCRIPT" = "true" ]; then
  # TypeScript version
  cat > src/env.ts << 'EOF'
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production']).default('development'),
  PORT: z.string().default('3000'),
  DATABASE_URL: z.string().url(),
  NEXT_PUBLIC_APP_NAME: z.string().default('My App'),
});

const env = envSchema.parse(process.env);
export { env };
EOF
  echo "✅ Created TypeScript validation"
else
  # JavaScript version
  cat > src/env.js << 'EOF'
const { z } = require('zod');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production']).default('development'),
  PORT: z.string().default('3000'),
  DATABASE_URL: z.string().url(),
  NEXT_PUBLIC_APP_NAME: z.string().default('My App'),
});

module.exports = { env: envSchema.parse(process.env) };
EOF
  echo "✅ Created JavaScript validation"
fi
```

---

## Step 6 — TypeScript Types

**Add types if TypeScript project:**

```bash
if [ "$HAS_TYPESCRIPT" = "true" ]; then
  cat > env.d.ts << 'EOF'
declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV: 'development' | 'production';
      PORT: string;
      DATABASE_URL: string;
      NEXT_PUBLIC_APP_NAME: string;
    }
  }
}
export {};
EOF
  echo "✅ Added TypeScript types"
fi
```

---

## Step 7 — Update package.json

**Add useful scripts:**

```bash
if [ -f "package.json" ]; then
  echo "📜 Adding scripts..."
  
  node -e "
  const fs = require('fs');
  try {
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    if (!pkg.scripts) pkg.scripts = {};
    
    pkg.scripts['env:validate'] = 'node -e \"try { require(\\'./src/env\\'); console.log(\\'✅ Validated\\') } catch(e) { console.log(\\'❌ Failed\\') }\"';
    pkg.scripts['env:init'] = 'cp .env.example .env.local';
    
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    console.log('✅ Added scripts');
  } catch (e) {
    console.log('⚠️  Could not update package.json');
  }
  "
fi
```

---

## Step 8 — Final Instructions

**Provide user guidance:**

```bash
echo "✅ Setup complete!"
echo ""
echo "📋 WHAT WAS CREATED:"
echo "  • .env.example        - Template (safe to commit)"
echo "  • src/env.*           - Validation file"
if [ "$HAS_TYPESCRIPT" = "true" ]; then echo "  • env.d.ts            - TypeScript types"; fi
echo "  • package.json       - Added environment scripts"
echo ""
echo "🚀 NEXT STEPS:"
echo "  1. cp .env.example .env.local"
echo "  2. Edit .env.local with actual values"
echo "  3. NEVER commit .env.local to git!"
echo "  4. npm run env:validate (to test)"
echo ""
echo "🔧 AVAILABLE COMMANDS:"
echo "  npm run env:validate - Validate variables"
echo "  npm run env:init     - Create .env.local"
echo ""
echo "⚠️  SECURITY: Use different values for development/production!"
```

---

## Special Cases

### Next.js
- Automatically loads `.env.local`
- Use `NEXT_PUBLIC_` prefix for browser variables

### Vite/React/Vue
- Use `VITE_` prefix for browser variables
- Access via `import.meta.env.VITE_*`

### Node.js
- Install `dotenv` package
- Load: `require('dotenv').config()`

---

## Testing

**Test validation:**

```bash
node -e "try { require('./src/env'); console.log('✅ Works') } catch(e) { console.log('⚠️  Expected (no .env.local)') }"
```

---

## Common Issues & Solutions

1. **Variable not defined** → Restart dev server
2. **TypeScript errors** → Check `env.d.ts` inclusion
3. **Validation fails** → Check variable names match schema

---

## Best Practices

1. **Use `.env.example` as documentation**
2. **Validate early** - fail fast on missing variables
3. **Type safety** - TypeScript prevents typos
4. **Security** - Never commit secrets
5. **Environment-specific** - Different values per environment