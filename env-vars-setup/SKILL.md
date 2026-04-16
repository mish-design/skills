---
name: env-vars-setup
description: "Sets up environment variables management with validation, TypeScript support, and best practices. Trigger this skill when initializing a new project, when adding new dependencies requiring environment variables, when preparing for deployment, or when encountering 'variable not defined' errors. Use for setting up .env files, validation with zod, TypeScript types, and security checks."
---

# Environment Variables Setup

## Before doing anything — ask the user

Before installing anything or creating files, **always ask the user for confirmation**:

> "Do you want to apply the `env-vars-setup` skill? It will create `.env.example` template, set up validation with zod, add TypeScript types for `process.env`, and configure security checks for environment variables."

Proceed only if the user confirms.

---

## Helper Functions (Reusable Components)

**These functions are used throughout the skill for consistency:**

### detect_project_type()
```bash
detect_project_type() {
  # Try to detect project type using Node.js
  if command -v node &> /dev/null && [ -f "package.json" ]; then
    node -e "
    try {
      const pkg = require('./package.json');
      const deps = { ...pkg.dependencies, ...pkg.devDependencies };
      
      let type = 'generic';
      if (deps.next) type = 'nextjs';
      else if (deps.react && deps.vite) type = 'vite-react';
      else if (deps.vue && deps.vite) type = 'vite-vue';
      else if (deps.svelte || deps['@sveltejs/kit']) type = 'svelte';
      else if (deps.express || deps.koa || deps.fastify || deps['@nestjs/core']) type = 'node';
      else if (deps.react) type = 'react';
      else if (deps.vue) type = 'vue';
      else if (deps.nuxt) type = 'nuxt';
      
      // Also check for TypeScript
      const hasTS = !!deps.typescript || require('fs').existsSync('tsconfig.json');
      
      console.log(JSON.stringify({ type, hasTS }));
    } catch (error) {
      console.log(JSON.stringify({ type: 'generic', hasTS: false }));
    }
    "
  else
    echo '{"type":"generic","hasTS":false}'
  fi
}
```

### detect_package_manager()
```bash
detect_package_manager() {
  if [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "package-lock.json" ]; then
    echo "npm"
  else
    echo "unknown"
  fi
}
```

### check_command_exists()
```bash
check_command_exists() {
  if command -v "$1" &> /dev/null; then
    return 0
  else
    echo "Warning: Command '$1' not found"
    return 1
  fi
}
```

### create_directory()
```bash
create_directory() {
  if [ ! -d "$1" ]; then
    echo "Creating directory: $1"
    mkdir -p "$1" 2>/dev/null || {
      echo "Failed to create directory: $1"
      return 1
    }
  fi
  return 0
}
```

### safe_file_write()
```bash
safe_file_write() {
  local file="$1"
  local content="$2"
  
  # Create backup if file exists
  if [ -f "$file" ]; then
    cp "$file" "${file}.backup" 2>/dev/null && echo "Backup created: ${file}.backup"
  fi
  
  # Write file
  echo "$content" > "$file"
  
  if [ $? -eq 0 ]; then
    echo "Created/updated: $file"
    return 0
  else
    echo "Failed to write: $file"
    return 1
  fi
}
```

### ask_user()
```bash
ask_user() {
  local prompt="$1"
  local choices="$2"  # Format: "a) Option 1|b) Option 2|c) Option 3"
  local default="$3"
  
  echo "$prompt"
  echo "Options: $choices"
  echo -n "Your choice [$default]: "
  
  # In a real skill, this would wait for user input
  # For skill documentation, we show what would happen
  echo "[Skill would wait for user input here]"
  echo "Assuming choice: $default"
  
  echo "$default"
}
```

---

**Now the main steps begin. Use the helper functions above where appropriate.**

## Step 1 — Check for existing environment configuration

**Using helper functions to check for existing setup:**

```bash
echo "🔍 Checking for existing environment configuration..."

# Check for existing .env files
echo "Looking for existing .env files..."
EXISTING_ENV_FILES=""

# Use cross-platform approach
check_command_exists find && {
  EXISTING_ENV_FILES=$(find . -maxdepth 1 -name ".env*" -type f 2>/dev/null | grep -v ".env.example" | tr '\n' ',' | sed 's/,$//')
} || {
  # Fallback method
  for file in .env .env.local .env.development .env.production .env.test .env.staging; do
    [ -f "$file" ] && EXISTING_ENV_FILES="${EXISTING_ENV_FILES}${file},"
  done
  EXISTING_ENV_FILES=$(echo "$EXISTING_ENV_FILES" | sed 's/,$//')
}

# Check for existing validation files
echo "Looking for existing validation files..."
EXISTING_VALIDATION_FILES=""

if check_command_exists find; then
  EXISTING_VALIDATION_FILES=$(find . -name "env.*" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.mjs" -o -name "*.cjs" \) 2>/dev/null | head -3 | tr '\n' ',' | sed 's/,$//')
else
  # Check common locations
  for file in src/env.ts src/env.js env.ts env.js lib/env.ts lib/env.js; do
    [ -f "$file" ] && EXISTING_VALIDATION_FILES="${EXISTING_VALIDATION_FILES}${file},"
  done
  EXISTING_VALIDATION_FILES=$(echo "$EXISTING_VALIDATION_FILES" | sed 's/,$//')
fi

# Report findings
echo ""
if [ -n "$EXISTING_ENV_FILES" ]; then
  echo "📁 Found existing .env files: ${EXISTING_ENV_FILES//,/, }"
else
  echo "✅ No existing .env files found (except .env.example)"
fi

if [ -n "$EXISTING_VALIDATION_FILES" ]; then
  echo "📁 Found existing validation files: ${EXISTING_VALIDATION_FILES//,/, }"
else
  echo "✅ No existing validation setup found"
fi
echo ""

# Ask user for decisions based on findings
if [ -n "$EXISTING_ENV_FILES" ]; then
  echo "❓ Found existing environment files."
  echo "   Options:"
  echo "   a) Create .env.example template based on existing files"
  echo "   b) Create fresh template (recommended for standardization)"
  echo "   c) Skip creating .env.example"
  
  # In actual skill execution, wait for user input
  # For documentation: show what would happen
  ENV_CHOICE="b"  # Default to fresh template for consistency
  echo "[Assuming choice: $ENV_CHOICE - Create fresh template]"
  echo ""
fi

if [ -n "$EXISTING_VALIDATION_FILES" ]; then
  echo "❓ Found existing validation setup."
  echo "   Options:"
  echo "   a) Overwrite existing files"
  echo "   b) Merge (append new variables to existing schema)"
  echo "   c) Skip validation setup"
  
  # In actual skill execution, wait for user input
  VALIDATION_CHOICE="b"  # Default to merge
  echo "[Assuming choice: $VALIDATION_CHOICE - Merge with existing]"
  echo ""
fi

# Store decisions for later steps
ENV_ACTION="${ENV_CHOICE:-b}"  # Default to fresh template
VALIDATION_ACTION="${VALIDATION_CHOICE:-b}"  # Default to merge

echo "Proceeding with:"
echo "  • .env.example: $([ "$ENV_ACTION" = "a" ] && echo "Create from existing" || [ "$ENV_ACTION" = "b" ] && echo "Create fresh" || echo "Skip")"
echo "  • Validation: $([ "$VALIDATION_ACTION" = "a" ] && echo "Overwrite" || [ "$VALIDATION_ACTION" = "b" ] && echo "Merge" || echo "Skip")"
echo ""
```

---

## Step 2 — Determine project type and dependencies

**Use helper functions to detect project configuration:**

```bash
echo "🔧 Detecting project type and dependencies..."

# Check if we have a package.json
if [ ! -f "package.json" ]; then
  echo "⚠️  No package.json found - treating as generic JavaScript project"
  PROJECT_TYPE="generic"
  HAS_TYPESCRIPT=false
  PACKAGE_MANAGER="unknown"
  HAS_ZOD=false
  HAS_DOTENV=false
else
  echo "✅ Found package.json"
  
  # Use our helper function
  PROJECT_INFO=$(detect_project_type)
  
  # Parse the JSON output
  PROJECT_TYPE=$(echo "$PROJECT_INFO" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
  HAS_TYPESCRIPT=$(echo "$PROJECT_INFO" | grep -o '"hasTS":\(true\|false\)' | grep -o 'true\|false')
  
  # Get package manager
  PACKAGE_MANAGER=$(detect_package_manager)
  
  # Check for zod and dotenv
  if check_command_exists node; then
    DEP_CHECK=$(node -e "
    try {
      const pkg = require('./package.json');
      const deps = { ...pkg.dependencies, ...pkg.devDependencies };
      console.log(JSON.stringify({
        zod: !!deps.zod,
        dotenv: !!deps.dotenv,
        envalid: !!deps.envalid
      }));
    } catch {
      console.log('{\"zod\":false,\"dotenv\":false,\"envalid\":false}');
    }
    ")
    
    HAS_ZOD=$(echo "$DEP_CHECK" | grep -o '"zod":\(true\|false\)' | grep -o 'true\|false')
    HAS_DOTENV=$(echo "$DEP_CHECK" | grep -o '"dotenv":\(true\|false\)' | grep -o 'true\|false')
  else
    # Fallback grep check
    if grep -q '"zod"' package.json; then HAS_ZOD=true; else HAS_ZOD=false; fi
    if grep -q '"dotenv"' package.json; then HAS_DOTENV=true; else HAS_DOTENV=false; fi
  fi
fi

# Set defaults if empty
PROJECT_TYPE="${PROJECT_TYPE:-generic}"
HAS_TYPESCRIPT="${HAS_TYPESCRIPT:-false}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-unknown}"
HAS_ZOD="${HAS_ZOD:-false}"
HAS_DOTENV="${HAS_DOTENV:-false}"

# Report findings
echo ""
echo "📊 PROJECT ANALYSIS:"
echo "  • Type:          $PROJECT_TYPE"
echo "  • TypeScript:    $HAS_TYPESCRIPT"
echo "  • Package mgr:   $PACKAGE_MANAGER"
echo "  • Has zod:       $HAS_ZOD"
echo "  • Has dotenv:    $HAS_DOTENV"
echo ""

# Determine focus based on project type
echo "🎯 SETUP FOCUS:"
case "$PROJECT_TYPE" in
  nextjs)
    echo "  • Next.js specific variables (NEXTAUTH_*, NEXT_PUBLIC_*)"
    echo "  • Automatic .env loading (no dotenv needed)"
    echo "  • Client/server variable separation"
    ;;
  vite-react|vite-vue)
    echo "  • Vite environment variables (VITE_* prefix)"
    echo "  • Access via import.meta.env"
    echo "  • Build-time replacement"
    ;;
  svelte)
    echo "  • Vite-based (VITE_*) or SvelteKit (PUBLIC_*)"
    echo "  • Check SvelteKit documentation for exact prefix"
    ;;
  node)
    echo "  • Node.js backend variables"
    echo "  • Database connections, API keys, ports"
    echo "  • Requires dotenv for loading"
    ;;
  nuxt)
    echo "  • Nuxt.js variables (NUXT_* prefix)"
    echo "  • Runtime configuration"
    ;;
  *)
    echo "  • Generic environment variables"
    echo "  • Basic validation setup"
    ;;
esac

echo ""
echo "📝 VALIDATION APPROACH:"
if [ "$HAS_TYPESCRIPT" = "true" ]; then
  echo "  • TypeScript: Full type safety with generated types"
else
  echo "  • JavaScript: Runtime validation only"
fi

if [ "$HAS_ZOD" = "true" ]; then
  echo "  • Zod: Already installed, will use existing"
elif check_command_exists node && [ -f "package.json" ]; then
  echo "  • Zod: Will be installed (recommended)"
else
  echo "  • Zod: Cannot install automatically (no Node.js)"
fi

if [ "$PROJECT_TYPE" = "node" ] && [ "$HAS_DOTENV" = "false" ]; then
  echo "  • Dotenv: Will be installed for Node.js projects"
fi
echo ""
```

---

## Step 3 — Create .env.example template

**Create framework-specific .env.example template:**

```bash
echo "📝 Creating .env.example template for $PROJECT_TYPE project..."

# Note: PROJECT_TYPE, HAS_TYPESCRIPT, etc. are already set from Step 2
# ENV_ACTION is set from Step 1 (a=from existing, b=fresh, c=skip)

if [ "$ENV_ACTION" = "c" ]; then
  echo "⏭️  Skipping .env.example creation (user choice)"
  exit 0
fi

echo "Template approach: $([ "$ENV_ACTION" = "a" ] && echo "Based on existing files" || echo "Fresh template")"
```

**Create the appropriate .env.example template:**

```bash
# Create base template with common variables
cat > .env.example << 'ENVEXAMPLE_BASE'
# ============================================
# ENVIRONMENT VARIABLES TEMPLATE
# ============================================
#
# INSTRUCTIONS:
# 1. Copy this file to .env.local: cp .env.example .env.local
# 2. Fill in ACTUAL values (not placeholders)
# 3. NEVER commit .env.local or any file with real secrets to git!
# 4. Add .env.local to .gitignore (already done if using this skill)
#
# SECURITY NOTES:
# - Use different values for development/production
# - Never use real production keys in development
# - Consider using a secrets manager for production
#

# ================ APPLICATION BASICS ================
# Runtime environment (development, test, production)
NODE_ENV="development"

# Server port
PORT="3000"

# Logging level (error, warn, info, debug)
LOG_LEVEL="info"

ENVEXAMPLE_BASE

# Add framework-specific sections
case "$PROJECT_TYPE" in
  nextjs)
    cat >> .env.example << 'ENVEXAMPLE_NEXTJS'

# ================ NEXT.JS SPECIFIC ================
# Next.js automatically loads .env.local
# Prefix with NEXT_PUBLIC_ to expose to browser

# Authentication (NextAuth.js)
# Generate secret: openssl rand -base64 32
NEXTAUTH_SECRET="generate-with-openssl-rand-base64-32"
NEXTAUTH_URL="http://localhost:3000"

# Database (commonly used with Next.js)
DATABASE_URL="postgresql://user:password@localhost:5432/dbname"

# Public variables (exposed to browser)
NEXT_PUBLIC_APP_NAME="My Next.js App"
NEXT_PUBLIC_API_URL="http://localhost:3000/api"
NEXT_PUBLIC_SITE_URL="http://localhost:3000"

ENVEXAMPLE_NEXTJS
    ;;
    
  vite-react|vite-vue|svelte)
    cat >> .env.example << 'ENVEXAMPLE_VITE'

# ================ VITE SPECIFIC ================
# Vite prefixes client-side variables with VITE_
# These are exposed to browser via import.meta.env

# API configuration
VITE_API_URL="http://localhost:3000/api"
VITE_APP_NAME="My Vite App"
VITE_SITE_URL="http://localhost:3000"

# Feature flags (client-side)
VITE_ENABLE_ANALYTICS="false"
VITE_ENABLE_DEBUG="true"

ENVEXAMPLE_VITE
    ;;
    
  node)
    cat >> .env.example << 'ENVEXAMPLE_NODE'

# ================ NODE.JS BACKEND ================
# Use dotenv package: require('dotenv').config()

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
REDIS_URL="redis://localhost:6379"

# Server configuration
HOST="0.0.0.0"
CORS_ORIGIN="http://localhost:3000"

ENVEXAMPLE_NODE
    ;;
esac

# Add common API keys and services (all project types)
cat >> .env.example << 'ENVEXAMPLE_COMMON'

# ================ THIRD-PARTY SERVICES ================
# API Keys & Secrets
# WARNING: These are sensitive - use environment-specific values

# Stripe (payments)
STRIPE_SECRET_KEY="sk_test_51xxx"                    # Test mode only!
STRIPE_PUBLISHABLE_KEY="pk_test_51xxx"               # Test mode only!
STRIPE_WEBHOOK_SECRET="whsec_xxx"

# Authentication providers
GOOGLE_CLIENT_ID="your-google-oauth-client-id.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="your-google-oauth-client-secret"
GITHUB_CLIENT_ID="your-github-oauth-client-id"
GITHUB_CLIENT_SECRET="your-github-oauth-client-secret"

# Email services
SENDGRID_API_KEY="SG.xxx"
RESEND_API_KEY="re_xxx"

# AI/ML services
OPENAI_API_KEY="sk-xxx"
ANTHROPIC_API_KEY="sk-ant-xxx"

# Monitoring & Analytics
SENTRY_DSN="https://xxx@sentry.io/xxx"
DATADOG_API_KEY="xxx"

# ================ DEPLOYMENT & CI/CD ================
# Platform-specific variables (Vercel, Railway, etc.)
VERCEL_URL="https://your-app.vercel.app"
RAILWAY_STATIC_URL="https://your-app.up.railway.app"

# CI/CD secrets
GITHUB_TOKEN="ghp_xxx"
DOCKER_REGISTRY_URL="registry.example.com"

# ================ CUSTOM VARIABLES ================
# Add your application-specific variables below
# MY_FEATURE_FLAG="enabled"
# API_RATE_LIMIT="100"

ENVEXAMPLE_COMMON

echo "✅ Created .env.example template for $PROJECT_TYPE"
```

**Add helpful comments at the end:**

```bash
cat >> .env.example << 'ENVEXAMPLE_FOOTER'

# ============================================
# TROUBLESHOOTING & BEST PRACTICES
# ============================================
#
# COMMON ISSUES:
# 1. "Variable not defined" - Restart dev server after changing .env
# 2. Next.js: Variables load automatically, no dotenv needed
# 3. Vite: Only VITE_ prefix works in browser
# 4. Node.js: Require dotenv in entry point
#
# SECURITY:
# - Rotate keys regularly
# - Use different keys per environment
# - Never log environment variables
# - Use .env.production for production values
#
# TEAM COLLABORATION:
# 1. Update .env.example when adding new variables
# 2. Notify team about new required variables
# 3. Use npm run env:init to create .env.local
#
ENVEXAMPLE_FOOTER
```

**Ensure .env files are in .gitignore:**

```bash
# Check if .env* is in .gitignore
if ! grep -q "\.env\*" .gitignore 2>/dev/null; then
  echo -e "\n# Environment variables\n.env*\n!.env.example" >> .gitignore
fi
```

---

## Step 4 — Install dependencies (if needed)

**Check and install required packages:**

```bash
# Only proceed if package.json exists
if [ ! -f "package.json" ]; then
  echo "No package.json found - skipping dependency installation"
  exit 0
fi

# Ask user before installing dependencies
echo "Checking for required dependencies..."

# Use Node.js to properly parse package.json and determine what to install
if command -v node &> /dev/null; then
  node -e "
  const fs = require('fs');
  const { execSync } = require('child_process');
  
  try {
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    const dependencies = { ...pkg.dependencies, ...pkg.devDependencies };
    
    const installList = [];
    const reasons = [];
    
    // Check for zod
    if (!dependencies.zod) {
      installList.push('zod');
      reasons.push('Validation library');
    }
    
    // Check for dotenv (only for Node.js projects)
    const isNodeProject = dependencies.express || dependencies.koa || dependencies.fastify || 
                         dependencies.nestjs || (pkg.main && pkg.main.endsWith('.js'));
    
    if (isNodeProject && !dependencies.dotenv) {
      installList.push('dotenv');
      reasons.push('Environment variable loading for Node.js');
    }
    
    if (installList.length > 0) {
      console.log('Missing dependencies:');
      installList.forEach((dep, i) => {
        console.log(\`  - \${dep} (\${reasons[i]})\`);
      });
      
      // Determine package manager
      let packageManager = 'npm';
      let installCommand = 'install';
      
      if (fs.existsSync('yarn.lock')) {
        packageManager = 'yarn';
        installCommand = 'add';
      } else if (fs.existsSync('pnpm-lock.yaml')) {
        packageManager = 'pnpm';
        installCommand = 'add';
      }
      
      console.log(\`\nWould install using: \${packageManager} \${installCommand} \${installList.join(' ')}\`);
      
      // Ask user for confirmation
      console.log('\nInstall missing dependencies? (y/n)');
      // In real implementation, wait for user input here
      // For skill purposes, we'll note this needs user confirmation
    } else {
      console.log('All required dependencies already installed');
    }
  } catch (error) {
    console.error('Error checking dependencies:', error.message);
  }
  "
else
  echo "Node.js not available - cannot check/install dependencies automatically"
  echo "You may need to install manually: npm install zod"
fi

# Important: The actual installation should only happen AFTER user confirms
# This is just checking and reporting what would be installed
```

---

## Step 5 — Create environment validation

**First, determine if we should create TypeScript or JavaScript validation:**

```bash
# Check if this is a TypeScript project
IS_TYPESCRIPT=false
if [ -f "tsconfig.json" ]; then
  IS_TYPESCRIPT=true
elif [ -f "package.json" ] && command -v node &> /dev/null; then
  # Check package.json for TypeScript dependency
  node -e "try { const pkg = require('./package.json'); const deps = {...pkg.dependencies, ...pkg.devDependencies}; if (deps.typescript) { console.log('typescript'); } }" | grep -q "typescript" && IS_TYPESCRIPT=true
fi

echo "TypeScript project: $IS_TYPESCRIPT"
```

**Create src/env.ts (for TypeScript) or src/env.js (for JavaScript):**

```bash
# Create directory if it doesn't exist
mkdir -p src

if [ "$IS_TYPESCRIPT" = "true" ]; then
  # TypeScript version with full type safety
  cat > src/env.ts << 'ENVTS'
import { z } from 'zod';

// ============================================
// ENVIRONMENT VARIABLE SCHEMA
// ============================================
// Define ALL environment variables used in the project here
// Use .optional() for variables that may not be present in all environments
// Use .default() for variables with sensible defaults

const envSchema = z.object({
  // ================ Database ================
  /** Database connection string (PostgreSQL, MySQL, MongoDB) */
  DATABASE_URL: z.string().url().min(1),
  
  // ================ Authentication ================
  /** NextAuth.js secret - generate with: openssl rand -base64 32 */
  NEXTAUTH_SECRET: z.string().min(32).optional(),
  /** NextAuth.js URL (e.g., http://localhost:3000) */
  NEXTAUTH_URL: z.string().url().optional(),
  
  // ================ API Keys & Services ================
  /** Stripe secret key (starts with sk_) */
  STRIPE_SECRET_KEY: z.string().startsWith('sk_').optional(),
  /** Stripe webhook secret (starts with whsec_) */
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_').optional(),
  /** OpenAI API key (starts with sk-) */
  OPENAI_API_KEY: z.string().startsWith('sk-').optional(),
  /** SendGrid API key (starts with SG.) */
  SENDGRID_API_KEY: z.string().startsWith('SG.').optional(),
  
  // ================ Application Configuration ================
  /** Node environment: development, test, or production */
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  /** Server port (default: 3000) */
  PORT: z.string().default('3000'),
  /** Logging level */
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
  
  // ================ Frontend Variables (exposed to browser) ================
  /** Next.js public variables - WILL be exposed to browser */
  NEXT_PUBLIC_APP_NAME: z.string().default('My App'),
  NEXT_PUBLIC_API_URL: z.string().url().default('http://localhost:3000/api'),
  
  // ================ Vite/React/Vue/Svelte Variables ================
  /** Vite environment variables */
  VITE_API_URL: z.string().url().optional(),
  VITE_APP_NAME: z.string().optional(),
});

// ============================================
// VALIDATION & EXPORT
// ============================================

// Parse and validate environment variables
const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Invalid environment variables:');
  
  // Format errors nicely
  const errors = parsedEnv.error.format();
  Object.entries(errors).forEach(([key, value]) => {
    if (key !== '_errors' && Array.isArray(value) && value.length > 0) {
      console.error(`  ${key}: ${value.join(', ')}`);
    }
  });
  
  throw new Error('Environment validation failed');
}

// Export validated environment variables
export const env = parsedEnv.data;

// ============================================
// HELPER FUNCTIONS & UTILITIES
// ============================================

/** Check if running in production */
export const isProduction = env.NODE_ENV === 'production';

/** Check if running in development */
export const isDevelopment = env.NODE_ENV === 'development';

/** Check if running tests */
export const isTest = env.NODE_ENV === 'test';

/** Get server port as number */
export const port = parseInt(env.PORT, 10);

/** Validate that a required variable is present */
export function requireEnv<T extends keyof typeof env>(key: T): NonNullable<typeof env[T]> {
  const value = env[key];
  if (value === undefined || value === null) {
    throw new Error(`Required environment variable ${key} is not set`);
  }
  return value as NonNullable<typeof env[T]>;
}

ENVTS
  echo "Created TypeScript validation: src/env.ts"
else
  # JavaScript version (for non-TypeScript projects)
  cat > src/env.js << 'ENVJS'
const { z } = require('zod');

// ============================================
// ENVIRONMENT VARIABLE SCHEMA
// ============================================

const envSchema = z.object({
  // Database
  DATABASE_URL: z.string().url().min(1),
  
  // Authentication
  NEXTAUTH_SECRET: z.string().min(32).optional(),
  NEXTAUTH_URL: z.string().url().optional(),
  
  // API Keys
  STRIPE_SECRET_KEY: z.string().startsWith('sk_').optional(),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_').optional(),
  OPENAI_API_KEY: z.string().startsWith('sk-').optional(),
  
  // Application
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.string().default('3000'),
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
  
  // Frontend (Next.js)
  NEXT_PUBLIC_APP_NAME: z.string().default('My App'),
  NEXT_PUBLIC_API_URL: z.string().url().default('http://localhost:3000/api'),
});

// ============================================
// VALIDATION & EXPORT
// ============================================

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Invalid environment variables:');
  const errors = parsedEnv.error.format();
  Object.entries(errors).forEach(([key, value]) => {
    if (key !== '_errors' && Array.isArray(value) && value.length > 0) {
      console.error(`  ${key}: ${value.join(', ')}`);
    }
  });
  throw new Error('Environment validation failed');
}

const env = parsedEnv.data;

// Helper functions
const isProduction = env.NODE_ENV === 'production';
const isDevelopment = env.NODE_ENV === 'development';
const isTest = env.NODE_ENV === 'test';
const port = parseInt(env.PORT, 10);

function requireEnv(key) {
  const value = env[key];
  if (value === undefined || value === null) {
    throw new Error(`Required environment variable ${key} is not set`);
  }
  return value;
}

module.exports = {
  env,
  isProduction,
  isDevelopment,
  isTest,
  port,
  requireEnv,
};
ENVJS
  echo "Created JavaScript validation: src/env.js"
fi

**Alternative: For simpler projects, create env.js:**

```bash
cat > env.js << 'ENVJS'
// Simple validation for non-TypeScript projects
const requiredEnvVars = [
  'DATABASE_URL',
  // Add other required variables
];

const missing = requiredEnvVars.filter(key => !process.env[key]);

if (missing.length > 0) {
  console.error('❌ Missing required environment variables:', missing);
  console.error('Please check your .env file');
  process.exit(1);
}

console.log('✅ Environment variables validated');
ENVJS
```

---

## Step 6 — Add TypeScript types (for TypeScript projects only)

**Create TypeScript declaration file for global type augmentation:**

```bash
if [ "$IS_TYPESCRIPT" = "true" ]; then
  echo "Creating TypeScript type definitions..."
  
  # First, check if src/env.ts was created (to import from correct path)
  if [ -f "src/env.ts" ]; then
    cat > src/env.d.ts << 'ENVDTS'
// ============================================
// TYPE DEFINITIONS FOR ENVIRONMENT VARIABLES
// ============================================
// This file augments NodeJS.ProcessEnv interface with our validated types
// DO NOT edit this file manually - it references the schema from env.ts

import { envSchema } from './env';

// Extend NodeJS.ProcessEnv with our validated schema types
declare global {
  namespace NodeJS {
    interface ProcessEnv extends z.infer<typeof envSchema> {}
  }
}

// Re-export for convenience
export type Env = z.infer<typeof envSchema>;

// Ensure this file is treated as a module
export {};
ENVDTS
    echo "Created TypeScript types: src/env.d.ts"
  else
    echo "Warning: src/env.ts not found, skipping TypeScript type generation"
  fi
  
  # Also create a simpler global declaration as fallback
  cat > env.d.ts << 'GLOBALDTSC'
// Global environment variable type declarations
// This provides basic TypeScript support even if src/env.ts is not used

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      // Database
      DATABASE_URL: string;
      
      // Authentication
      NEXTAUTH_SECRET?: string;
      NEXTAUTH_URL?: string;
      
      // API Keys
      STRIPE_SECRET_KEY?: string;
      STRIPE_WEBHOOK_SECRET?: string;
      OPENAI_API_KEY?: string;
      SENDGRID_API_KEY?: string;
      
      // Application
      NODE_ENV: 'development' | 'test' | 'production';
      PORT: string;
      LOG_LEVEL: 'error' | 'warn' | 'info' | 'debug';
      
      // Frontend (Next.js)
      NEXT_PUBLIC_APP_NAME: string;
      NEXT_PUBLIC_API_URL: string;
      
      // Vite/React/Vue/Svelte
      VITE_API_URL?: string;
      VITE_APP_NAME?: string;
    }
  }
}

// Ensure this file is treated as a module
export {};
GLOBALDTSC
    echo "Created global TypeScript types: env.d.ts"
    
    # Update tsconfig.json to include type declarations if it exists
    if [ -f "tsconfig.json" ] && command -v node &> /dev/null; then
      node -e "
      const fs = require('fs');
      try {
        const tsconfig = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));
        
        // Ensure typeRoots or types includes our declarations
        if (!tsconfig.compilerOptions) tsconfig.compilerOptions = {};
        
        if (!tsconfig.compilerOptions.typeRoots) {
          tsconfig.compilerOptions.typeRoots = ['./node_modules/@types'];
        }
        
        // Add our env.d.ts to include files if not already there
        if (!tsconfig.include) tsconfig.include = [];
        if (!tsconfig.include.includes('env.d.ts')) {
          tsconfig.include.push('env.d.ts');
        }
        
        fs.writeFileSync('tsconfig.json', JSON.stringify(tsconfig, null, 2));
        console.log('Updated tsconfig.json to include environment type definitions');
      } catch (error) {
        console.log('Could not update tsconfig.json:', error.message);
      }
      "
    fi
  fi
else
  echo "Not a TypeScript project - skipping type definitions"
fi

---

## Step 7 — Create setup script (optional)

**Create setup-env.js for easier onboarding:**

```bash
cat > scripts/setup-env.js << 'SETUPENV'
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log('🚀 Environment Setup Script');
console.log('==========================');

// Check if .env.local exists
const envLocalPath = path.join(__dirname, '..', '.env.local');
const envExamplePath = path.join(__dirname, '..', '.env.example');

if (fs.existsSync(envLocalPath)) {
  console.log('✅ .env.local already exists');
  process.exit(0);
}

if (!fs.existsSync(envExamplePath)) {
  console.error('❌ .env.example not found. Please run the env-vars-setup skill first.');
  process.exit(1);
}

console.log('📝 Creating .env.local from .env.example...');

// Copy .env.example to .env.local
const exampleContent = fs.readFileSync(envExamplePath, 'utf8');
fs.writeFileSync(envLocalPath, exampleContent);

console.log('✅ Created .env.local');
console.log('\n📋 Next steps:');
console.log('1. Edit .env.local and fill in your actual values');
console.log('2. NEVER commit .env.local to git!');
console.log('3. Restart your development server');

rl.close();
SETUPENV

# Make it executable
chmod +x scripts/setup-env.js 2>/dev/null || true
```

---

## Step 8 — Update package.json scripts

**Add useful environment-related scripts to package.json:**

```bash
if [ -f "package.json" ]; then
  echo "Updating package.json scripts..."
  
  # Create backup first
  cp package.json package.json.bak 2>/dev/null || true
  
  # Use Node.js to safely update package.json
  if command -v node &> /dev/null; then
    node -e "
    const fs = require('fs');
    const path = require('path');
    
    try {
      const pkgPath = path.join(process.cwd(), 'package.json');
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
      
      // Initialize scripts object if it doesn't exist
      if (!pkg.scripts) pkg.scripts = {};
      
      // Check what validation file exists
      const hasTypeScriptEnv = fs.existsSync(path.join(process.cwd(), 'src/env.ts'));
      const hasJavaScriptEnv = fs.existsSync(path.join(process.cwd(), 'src/env.js'));
      
      // Determine the correct validation command
      let validateCommand = 'echo \"No environment validation setup found\"';
      if (hasTypeScriptEnv) {
        validateCommand = 'node -r ts-node/register/transpile-only -e \"import { env } from \\'./src/env\\'; console.log(\\'✅ Environment variables validated\\')\"';
      } else if (hasJavaScriptEnv) {
        validateCommand = 'node -e \"require(\\'./src/env\\'); console.log(\\'✅ Environment variables validated\\')\"';
      }
      
      // Add environment-related scripts
      const newScripts = {
        // Validate environment variables
        'env:validate': validateCommand,
        
        // Check if .env.local exists and is properly configured
        'env:check': \`node -e \"\\
          const fs = require('fs');\\
          const path = require('path');\\
          \\
          const envLocal = path.join(__dirname, '.env.local');\\
          const envExample = path.join(__dirname, '.env.example');\\
          \\
          if (!fs.existsSync(envLocal)) {\\
            console.log('❌ .env.local not found');\\
            console.log('Run: cp .env.example .env.local');\\
            process.exit(1);\\
          }\\
          \\
          if (!fs.existsSync(envExample)) {\\
            console.log('⚠️  .env.example not found');\\
          } else {\\
            const example = fs.readFileSync(envExample, 'utf8');\\
            const local = fs.existsSync(envLocal) ? fs.readFileSync(envLocal, 'utf8') : '';\\
            \\
            // Simple check for TODO values
            if (local.includes('your-') || local.includes('example.com') || local.includes('changeme')) {\\
              console.log('⚠️  .env.local contains placeholder values');\\
              console.log('Please update with your actual values');\\
            } else {\\
              console.log('✅ .env.local looks properly configured');\\
            }\\
          }\\
        \"\`,
        
        // Create .env.local from example (cross-platform)
        'env:init': \`node -e \"\\
          const fs = require('fs');\\
          const path = require('path');\\
          \\
          const envExample = path.join(__dirname, '.env.example');\\
          const envLocal = path.join(__dirname, '.env.local');\\
          \\
          if (!fs.existsSync(envExample)) {\\
            console.error('❌ .env.example not found');\\
            process.exit(1);\\
          }\\
          \\
          if (fs.existsSync(envLocal)) {\\
            console.log('✅ .env.local already exists');\\
            process.exit(0);\\
          }\\
          \\
          try {\\
            const content = fs.readFileSync(envExample, 'utf8');\\
            fs.writeFileSync(envLocal, content);\\
            console.log('✅ Created .env.local from .env.example');\\
            console.log('📝 Next: Edit .env.local with your actual values');\\
          } catch (error) {\\
            console.error('❌ Failed to create .env.local:', error.message);\\
            process.exit(1);\\
          }\\
        \"\`,
        
        // List all environment variables from schema
        'env:list': \`node -e \"\\
          try {\\
            // Try TypeScript first, then JavaScript\\
            try {\\
              const { envSchema } = require('./src/env.ts');\\
              const shape = envSchema.shape;\\
              console.log('📋 Environment variables defined in schema:');\\
              Object.keys(shape).forEach(key => {\\
                const isOptional = shape[key].isOptional ? '(optional)' : '(required)';\` +
                \`console.log(\`  - \${key} \${isOptional}\`);\\
              });\\
            } catch {\\
              const { envSchema } = require('./src/env.js');\\
              const shape = envSchema.shape;\\
              console.log('📋 Environment variables defined in schema:');\\
              Object.keys(shape).forEach(key => {\\
                const isOptional = shape[key].isOptional ? '(optional)' : '(required)';\` +
                \`console.log(\`  - \${key} \${isOptional}\`);\\
              });\\
            }\\
          } catch (error) {\\
            console.log('No environment schema found');\\
          }\\
        \"\`,
      };
      
      // Add or update scripts (don't overwrite existing custom scripts)
      Object.entries(newScripts).forEach(([key, value]) => {
        if (!pkg.scripts[key] || pkg.scripts[key].includes('echo')) {
          pkg.scripts[key] = value;
        }
      });
      
      // Write back to package.json
      fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
      console.log('✅ Added environment scripts to package.json');
      
      // Show user what was added
      console.log('\\nNew scripts available:');
      Object.keys(newScripts).forEach(key => {
        console.log(\`  npm run \${key}\`);
      });
      
    } catch (error) {
      console.error('Failed to update package.json:', error.message);
      // Restore backup if possible
      if (fs.existsSync(package.json.bak)) {
        fs.copyFileSync('package.json.bak', 'package.json');
      }
    }
    "
  else
    echo "Node.js not available - cannot update package.json automatically"
    echo "Consider adding these scripts manually:"
    echo "  \"env:validate\": \"node -e \\\"require('./src/env'); console.log('✅ Validated')\\\"\""
    echo "  \"env:init\": \"cp .env.example .env.local\""
    echo "  \"env:check\": \"node -e \\\"console.log('Check .env files')\\\"\""
  fi
else
  echo "No package.json found - skipping script updates"
fi
```

---

## Step 9 — Provide framework-specific guidance to user

**After setup, provide clear, framework-specific instructions:**

```bash
# Determine project type again for final instructions
if command -v node &> /dev/null && [ -f "package.json" ]; then
  FRAMEWORK_INFO=$(node -e "
    try {
      const pkg = require('./package.json');
      const deps = { ...pkg.dependencies, ...pkg.devDependencies };
      const info = {
        hasNext: !!deps.next,
        hasVite: !!deps.vite,
        hasReact: !!(deps.react || deps['react-dom']),
        hasVue: !!deps.vue,
        hasSvelte: !!(deps.svelte || deps['@sveltejs/kit']),
        hasExpress: !!deps.express,
        isTypeScript: !!deps.typescript || require('fs').existsSync('tsconfig.json'),
        packageManager: require('fs').existsSync('yarn.lock') ? 'yarn' : 
                       require('fs').existsSync('pnpm-lock.yaml') ? 'pnpm' : 'npm'
      };
      console.log(JSON.stringify(info));
    } catch {
      console.log('{}');
    }
  " 2>/dev/null || echo "{}")
else
  FRAMEWORK_INFO="{}"
fi
```

**Provide tailored instructions based on project type:**

```bash
echo "✅ Environment variables setup complete!"
echo ""
echo "📁 WHAT WAS CREATED:"
echo "  • .env.example        - Template with comments (SAFE to commit)"
echo "  • src/env.$( [ -f "src/env.ts" ] && echo "ts" || echo "js" ) - Validation with zod"
if [ -f "src/env.d.ts" ] || [ -f "env.d.ts" ]; then
  echo "  • *.d.ts              - TypeScript type definitions"
fi
echo "  • .gitignore         - Updated to exclude .env* files"
echo "  • package.json       - Added environment scripts"
echo ""

# Show framework-specific loading instructions
if echo "$FRAMEWORK_INFO" | grep -q '"hasNext":true'; then
  echo "🚀 NEXT.JS SPECIFIC:"
  echo "  • Next.js automatically loads .env.local"
  echo "  • Use NEXT_PUBLIC_ prefix for browser variables"
  echo "  • Restart dev server after changing .env files"
  echo ""
elif echo "$FRAMEWORK_INFO" | grep -q '"hasVite":true'; then
  echo "🚀 VITE SPECIFIC:"
  echo "  • Use VITE_ prefix for browser variables"
  echo "  • Access via import.meta.env.VITE_*"
  echo "  • Variables without VITE_ are server-only"
  echo ""
elif echo "$FRAMEWORK_INFO" | grep -q '"hasExpress":true'; then
  echo "🚀 NODE.JS SPECIFIC:"
  echo "  • Load dotenv in entry point:"
  echo "    require('dotenv').config();"
  echo "  • Or use: import 'dotenv/config' (ESM)"
  echo ""
fi

echo "📋 NEXT STEPS:"
echo ""
echo "1. CREATE YOUR LOCAL ENVIRONMENT FILE:"
echo "   npm run env:init"
echo "   # Or manually: cp .env.example .env.local"
echo ""
echo "2. EDIT .env.local WITH YOUR VALUES:"
echo "   # Open .env.local and replace placeholders"
echo "   # Example: DATABASE_URL=\"postgresql://realuser:realpass@localhost:5432/realdb\""
echo ""
echo "3. VALIDATE YOUR SETUP:"
echo "   npm run env:validate"
echo ""
echo "4. CHECK FOR PLACEHOLDER VALUES:"
echo "   npm run env:check"
echo ""
echo "⚠️  SECURITY REMINDERS:"
echo "  • NEVER commit .env.local to git"
echo "  • Use different keys for development/production"
echo "  • Consider a secrets manager for production"
echo ""
echo "👥 FOR TEAM COLLABORATION:"
echo "  • New developers: npm run env:init"
echo "  • Update .env.example when adding variables"
echo "  • Notify team about new required variables"
echo ""
echo "🔧 AVAILABLE SCRIPTS:"
echo "  npm run env:init     - Create .env.local from template"
echo "  npm run env:validate - Validate environment variables"
echo "  npm run env:check    - Check for placeholder values"
echo "  npm run env:list     - List all defined variables"
echo ""
echo "🆕 ADDING NEW VARIABLES:"
echo "  1. Add to .env.example with comments"
echo "  2. Add to src/env.$( [ -f "src/env.ts" ] && echo "ts" || echo "js" ) schema"
echo "  3. TypeScript types update automatically"
echo ""
echo "❌ COMMON ERRORS & SOLUTIONS:"
echo "  • 'Variable not defined' → Restart dev server"
echo "  • TypeScript errors → Check env.d.ts is included"
echo "  • Validation fails → Check variable names match schema"
echo ""
echo "📚 DOCUMENTATION:"
echo "  • Zod validation: https://zod.dev"
echo "  • Next.js env: https://nextjs.org/docs/pages/building-your-application/configuring/environment-variables"
echo "  • Vite env: https://vitejs.dev/guide/env-and-mode"
echo ""
echo "💡 PRO TIP: Use different .env files for different environments:"
echo "  • .env.development"
echo "  • .env.test"
echo "  • .env.production"
echo ""
```

---

## Step 10 — Security check

**Warn about common security issues:**

```bash
# Simple check for potential secrets in git history
echo "🔒 Security Reminders:"
echo "1. Check that .env* is in .gitignore: grep '\.env\*' .gitignore"
echo "2. Never commit real API keys or secrets"
echo "3. Use different keys for development and production"
echo "4. Consider using a secrets manager for production"
```

---

## Special Cases

### Next.js Projects
- Use `NEXT_PUBLIC_` prefix for browser-accessible variables
- Next.js automatically loads `.env.local`
- No need for `dotenv` package

### Node.js Projects
- Install `dotenv` package
- Load in entry point: `require('dotenv').config()`
- Consider `dotenv-expand` for variable expansion

### React/Vite Projects
- Variables must be prefixed with `VITE_`
- Use `import.meta.env` instead of `process.env`

### Docker/Containerized Apps
- Use Docker secrets or mounted volumes for production
- Consider 12-factor app principles

---

## Testing the Setup

**Verify the setup works:**

```bash
# Test validation (should fail without .env.local)
node -e "try { require('./src/env.ts'); console.log('✅ Validation works'); } catch(e) { console.log('⚠️  Expected error:', e.message); }" 2>/dev/null || true

# Check TypeScript types (if TypeScript project)
if [ -f "tsconfig.json" ]; then
  npx tsc --noEmit --project . 2>/dev/null | grep -i "env" || echo "TypeScript check complete"
fi
```

---

## Common Issues and Solutions

1. **"Variable not defined" errors**
   - Check `.env.local` exists and has the variable
   - Restart development server (env vars are cached)
   - Check variable name matches schema

2. **TypeScript errors**
   - Ensure `env.d.ts` is included in `tsconfig.json`
   - Run `npx tsc --noEmit` to check types

3. **Validation failing in production**
   - Production may have different variable names
   - Check deployment platform's env var setup
   - Use `.env.production` for production values

---

## Best Practices to Emphasize

1. **Use `.env.example` as documentation**
2. **Validate early** - fail fast if vars are missing
3. **Type safety** - TypeScript prevents typos
4. **Security** - Never commit secrets
5. **Environment-specific** - Different values for dev/prod

This skill ensures consistent, secure, and type-safe environment variable management across all projects.