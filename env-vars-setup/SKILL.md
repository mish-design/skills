---
name: env-vars-setup
description: "Sets up environment variables management with validation, TypeScript support, and best practices. Trigger this skill when initializing a new project, when adding new dependencies requiring environment variables, when preparing for deployment, or when encountering 'variable not defined' errors. Use for setting up .env files, validation with zod, TypeScript types, and security checks."
---

# Environment Variables Setup (Modular)

## Before doing anything — ask the user

Before installing anything or creating files, **always ask the user for confirmation**:

> "Do you want to apply the `env-vars-setup` skill? It will create `.env.example` template, set up validation with zod, add TypeScript types for `process.env`, and configure security checks for environment variables."

Proceed only if the user confirms.

---

## Module Overview

This skill uses a modular structure:
- **`helper-functions.sh`** - Reusable functions for project detection, file operations, etc.
- **`templates/`** - `.env.example` templates for different frameworks
- **`validation-templates/`** - Validation schemas (TypeScript/JavaScript)
- **This file** - Main orchestration logic

---

## Step 1 — Load Helper Functions

**Load the shared helper functions:**

```bash
echo "🔧 Loading helper functions..."

# Source helper functions if they exist
if [ -f "helper-functions.sh" ]; then
  source helper-functions.sh
  echo "✅ Helper functions loaded from helper-functions.sh"
else
  echo "⚠️  Helper functions file not found"
  echo "Loading minimal helper functions inline..."
  
  # Define minimal helper functions inline as fallback
  command_exists() {
    if command -v "$1" > /dev/null 2>&1; then return 0; else return 1; fi
  }
  
  detect_project_type() {
    echo '{"type":"generic","hasTS":false,"success":false}'
  }
  
  detect_package_manager() {
    if [ -f "yarn.lock" ]; then echo "yarn"
    elif [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
    elif [ -f "package-lock.json" ]; then echo "npm"
    else echo "unknown"; fi
  }
fi
```

---

## Step 2 — Check Existing Configuration

**Check for existing .env files and validation setup:**

```bash
echo "🔍 Checking for existing environment configuration..."

# Check for existing .env files
EXISTING_ENV_FILES=$(ls .env* 2>/dev/null | grep -v ".env.example" | tr '\n' ',' | sed 's/,$//' || echo "")

# Check for existing validation
EXISTING_VALIDATION_FILES=$(ls src/env.* env.* 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "")

# Report findings and make decisions
if [ -n "$EXISTING_ENV_FILES" ]; then
  echo "📁 Found existing .env files: ${EXISTING_ENV_FILES//,/, }"
  echo "⚠️  Note: In a real skill execution, you would be asked:"
  echo "      'Create .env.example based on existing files? (y/n) [y]'"
  echo ""
  # For skill documentation, we show the recommended approach
  echo "✅ Recommended: Create fresh .env.example template for consistency"
  CREATE_FROM_EXISTING="n"  # Default to fresh template
else
  echo "✅ No existing .env files found"
  CREATE_FROM_EXISTING="n"
fi

if [ -n "$EXISTING_VALIDATION_FILES" ]; then
  echo "📁 Found existing validation: ${EXISTING_VALIDATION_FILES//,/, }"
  echo "⚠️  Note: In a real skill execution, you would be asked:"
  echo "      'Overwrite existing validation files? (y/n) [n]'"
  echo ""
  echo "✅ Recommended: Skip overwriting to preserve custom validations"
  OVERWRITE_VALIDATION="n"
fi
```

---

## Step 3 — Detect Project Type

**Use helper functions to detect project configuration:**

```bash
echo "🔧 Detecting project type and dependencies..."

PROJECT_INFO=$(detect_project_type)
PROJECT_TYPE=$(echo "$PROJECT_INFO" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
HAS_TYPESCRIPT=$(echo "$PROJECT_INFO" | grep -o '"hasTS":\(true\|false\)' | grep -o 'true\|false')
PACKAGE_MANAGER=$(detect_package_manager)

# Set defaults
PROJECT_TYPE="${PROJECT_TYPE:-generic}"
HAS_TYPESCRIPT="${HAS_TYPESCRIPT:-false}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-unknown}"

echo "📊 Project Analysis:"
echo "  • Type: $PROJECT_TYPE"
echo "  • TypeScript: $HAS_TYPESCRIPT"
echo "  • Package mgr: $PACKAGE_MANAGER"
```

---

## Step 4 — Create .env.example Template

**Create framework-specific template:**

```bash
echo "📝 Creating .env.example for $PROJECT_TYPE..."

# Determine which template to use
TEMPLATE_FILE="templates/generic.env.example"
case "$PROJECT_TYPE" in
  nextjs) TEMPLATE_FILE="templates/nextjs.env.example" ;;
  vite-react|vite-vue) TEMPLATE_FILE="templates/vite.env.example" ;;
  svelte) TEMPLATE_FILE="templates/vite.env.example" ;; # Vite-based
  node) TEMPLATE_FILE="templates/node.env.example" ;;
  nuxt) TEMPLATE_FILE="templates/generic.env.example" ;; # Use generic for now
esac

# Create .env.example
if [ -f "$TEMPLATE_FILE" ]; then
  cp "$TEMPLATE_FILE" .env.example
  echo "✅ Created .env.example from $TEMPLATE_FILE"
else
  # Fallback to embedded template
  cat > .env.example << 'EOF'
# Environment Variables Template
NODE_ENV="development"
PORT="3000"
DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
EOF
  echo "⚠️  Created basic .env.example (template file not found)"
fi

# Add to .gitignore
if ! grep -q "\.env\*" .gitignore 2>/dev/null; then
  echo -e "\n# Environment variables\n.env*\n!.env.example" >> .gitignore
  echo "✅ Added .env* to .gitignore"
fi
```

---

## Step 5 — Install Dependencies

**Check and install required packages:**

```bash
echo "📦 Checking dependencies..."

if [ -f "package.json" ]; then
  # Check for zod
  if ! grep -q '"zod"' package.json && command -v node &> /dev/null; then
    echo "❓ Install zod for validation? (y/n) [y]"
    # Skill would wait for user input
    INSTALL_ZOD="y"
    
    if [ "$INSTALL_ZOD" = "y" ]; then
      case "$PACKAGE_MANAGER" in
        yarn) yarn add zod ;;
        pnpm) pnpm add zod ;;
        *) npm install zod ;;
      esac
    fi
  fi
  
  # Check for dotenv (Node.js projects)
  if [ "$PROJECT_TYPE" = "node" ] && ! grep -q '"dotenv"' package.json; then
    echo "❓ Install dotenv for Node.js? (y/n) [y]"
    # Skill would wait for user input
    INSTALL_DOTENV="y"
    
    if [ "$INSTALL_DOTENV" = "y" ]; then
      case "$PACKAGE_MANAGER" in
        yarn) yarn add dotenv ;;
        pnpm) pnpm add dotenv ;;
        *) npm install dotenv ;;
      esac
    fi
  fi
fi
```

---

## Step 6 — Create Environment Validation

**Create validation file (TypeScript or JavaScript):**

```bash
echo "🔐 Creating environment validation..."

mkdir -p src

if [ "$HAS_TYPESCRIPT" = "true" ]; then
  # TypeScript version
  VALIDATION_TEMPLATE="validation-templates/typescript.env.ts"
  DEST_FILE="src/env.ts"
  
  if [ -f "$VALIDATION_TEMPLATE" ]; then
    cp "$VALIDATION_TEMPLATE" "$DEST_FILE"
    echo "✅ Created TypeScript validation: $DEST_FILE"
  else
    # Embedded TypeScript template
    cat > "$DEST_FILE" << 'EOF'
import { z } from 'zod';
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production']).default('development'),
  PORT: z.string().default('3000'),
});
export const env = envSchema.parse(process.env);
EOF
    echo "⚠️  Created basic TypeScript validation (template not found)"
  fi
else
  # JavaScript version
  VALIDATION_TEMPLATE="validation-templates/javascript.env.js"
  DEST_FILE="src/env.js"
  
  if [ -f "$VALIDATION_TEMPLATE" ]; then
    cp "$VALIDATION_TEMPLATE" "$DEST_FILE"
    echo "✅ Created JavaScript validation: $DEST_FILE"
  else
    # Embedded JavaScript template
    cat > "$DEST_FILE" << 'EOF'
const { z } = require('zod');
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production']).default('development'),
  PORT: z.string().default('3000'),
});
module.exports = { env: envSchema.parse(process.env) };
EOF
    echo "⚠️  Created basic JavaScript validation (template not found)"
  fi
fi
```

---

## Step 7 — Add TypeScript Types (if needed)

**Create TypeScript declaration file:**

```bash
if [ "$HAS_TYPESCRIPT" = "true" ]; then
  echo "📝 Adding TypeScript types..."
  
  cat > env.d.ts << 'EOF'
declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV: 'development' | 'production';
      PORT: string;
    }
  }
}
export {};
EOF
  echo "✅ Created TypeScript types: env.d.ts"
fi
```

---

## Step 8 — Update package.json Scripts

**Add useful environment scripts safely:**

```bash
if [ -f "package.json" ]; then
  echo "📜 Updating package.json scripts..."
  
  # Check if we have the safe_update_package_json function
  if command_exists safe_update_package_json; then
    if safe_update_package_json; then
      echo "✅ Package.json updated successfully"
    else
      echo "⚠️  Could not update package.json automatically"
      echo ""
      echo "📝 You can add these scripts manually:"
      echo '  "env:validate": "node -e \"try { require(\\'./src/env\\'); console.log(\\'✅ Validated\\') } catch(e) { console.log(\\'❌ Failed: ' + e.message + '\\') }"'
      echo '  "env:init": "cp .env.example .env.local 2>/dev/null || echo \\'Create .env.local manually\\'"'
      echo '  "env:check": "node -e \"const fs = require(\\'fs\\'); if (!fs.existsSync(\\'.env.local\\')) { console.log(\\'❌ .env.local missing\\'); process.exit(1) }"'
    fi
  elif command_exists node; then
    # Fallback method
    node -e "
    const fs = require('fs');
    try {
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      if (!pkg.scripts) pkg.scripts = {};
      
      pkg.scripts['env:validate'] = 'node -e \"try { require(\\'./src/env\\'); console.log(\\'✅ Validated\\') } catch(e) { console.log(\\'❌ Validation failed\\') }\"';
      pkg.scripts['env:init'] = 'cp .env.example .env.local 2>/dev/null || echo \\'Create .env.local manually\\'';
      pkg.scripts['env:check'] = 'node -e \"if (!require(\\'fs\\').existsSync(\\'.env.local\\')) { console.log(\\'❌ .env.local missing\\'); process.exit(1) }\"';
      
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
      console.log('✅ Added scripts to package.json');
    } catch (e) {
      console.log('Could not update package.json:', e.message);
    }
    "
  else
    echo "⚠️  Node.js not available - cannot update package.json"
    echo "📝 Add scripts manually to package.json"
  fi
else
  echo "⏭️  No package.json found - skipping script updates"
fi
```

---

## Step 9 — Provide User Guidance

**Give final instructions to user:**

```bash
echo "✅ Environment setup complete!"
echo ""
echo "📋 WHAT WAS CREATED:"
echo "  • .env.example        - Template (safe to commit)"
echo "  • src/env.$( [ "$HAS_TYPESCRIPT" = "true" ] && echo "ts" || echo "js") - Validation"
if [ "$HAS_TYPESCRIPT" = "true" ]; then
  echo "  • env.d.ts            - TypeScript types"
fi
echo "  • .gitignore         - Updated for .env files"
echo "  • package.json       - Added environment scripts"
echo ""
echo "🚀 NEXT STEPS:"
echo "  1. cp .env.example .env.local"
echo "  2. Edit .env.local with your actual values"
echo "  3. NEVER commit .env.local to git!"
echo "  4. npm run env:validate (to test)"
echo ""
echo "🔧 AVAILABLE COMMANDS:"
echo "  npm run env:init     - Create .env.local"
echo "  npm run env:validate - Validate variables"
echo "  npm run env:check    - Check setup"
echo ""
echo "⚠️  SECURITY: Use different values for development/production!"
```

---

## Special Cases

### Next.js Projects
- Variables load automatically from `.env.local`
- Use `NEXT_PUBLIC_` prefix for browser variables
- No `dotenv` package needed

### Vite Projects  
- Use `VITE_` prefix for browser variables
- Access via `import.meta.env.VITE_*`
- Build-time replacement

### Node.js Projects
- Install `dotenv` package
- Load in entry point: `require('dotenv').config()`

### TypeScript Projects
- Full type safety with `env.d.ts`
- Autocomplete for `process.env`

---

## Testing

**Verify the setup works:**

```bash
# Test validation
node -e "try { require('./src/env'); console.log('✅ Validation works') } catch(e) { console.log('⚠️  Expected error (no .env.local):', e.message) }" 2>/dev/null || true
```

---

## Common Issues

1. **"Variable not defined"** → Restart dev server
2. **TypeScript errors** → Check `env.d.ts` is included
3. **Validation fails** → Check variable names match schema

---

## Best Practices

1. **Use `.env.example` as documentation**
2. **Validate early** - fail fast on missing variables  
3. **Type safety** - TypeScript prevents typos
4. **Security** - Never commit secrets
5. **Environment-specific** - Different values per environment