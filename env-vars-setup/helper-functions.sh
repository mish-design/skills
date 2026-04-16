#!/bin/bash
# Environment Variables Setup - Helper Functions
# This file contains reusable functions for the env-vars-setup skill

# Cross-platform command check
command_exists() {
  # Check if command exists (cross-platform)
  if command -v "$1" > /dev/null 2>&1; then
    return 0
  elif type "$1" > /dev/null 2>&1; then
    return 0
  elif where "$1" > /dev/null 2>&1; then # Windows
    return 0
  else
    return 1
  fi
}

# Detect project type and TypeScript usage with better error handling
detect_project_type() {
  # Try to detect project type using Node.js
  if command_exists node && [ -f "package.json" ]; then
    node -e "
    try {
      const fs = require('fs');
      const path = require('path');
      
      // Safely read package.json
      const pkgPath = path.join(process.cwd(), 'package.json');
      const pkgContent = fs.readFileSync(pkgPath, 'utf8');
      const pkg = JSON.parse(pkgContent);
      
      const deps = { ...pkg.dependencies, ...pkg.devDependencies };
      
      // Simple framework detection with fallbacks
      let type = 'generic';
      
      // Prioritize detection to avoid false positives
      if (deps.next || deps['next-auth']) {
        type = 'nextjs';
      } else if (deps.vite && deps.react) {
        type = 'vite-react';
      } else if (deps.vite && deps.vue) {
        type = 'vite-vue';
      } else if (deps['@sveltejs/kit'] || deps.svelte) {
        type = 'svelte';
      } else if (deps.express || deps.koa || deps.fastify || deps['@nestjs/core']) {
        type = 'node';
      } else if (deps.react || deps['react-dom']) {
        type = 'react';
      } else if (deps.vue || deps['vue-router']) {
        type = 'vue';
      } else if (deps.nuxt || deps['@nuxtjs/modules']) {
        type = 'nuxt';
      }
      
      // Check for TypeScript with multiple methods
      const hasTS = !!deps.typescript || 
                   fs.existsSync(path.join(process.cwd(), 'tsconfig.json')) ||
                   fs.existsSync(path.join(process.cwd(), 'tsconfig.ts')) ||
                   (pkg.scripts && pkg.scripts.build && pkg.scripts.build.includes('tsc'));
      
      console.log(JSON.stringify({ type, hasTS, success: true }));
    } catch (error) {
      // Graceful fallback
      console.log(JSON.stringify({ 
        type: 'generic', 
        hasTS: false, 
        success: false,
        error: error.message 
      }));
    }
    "
  else
    # Fallback without Node.js
    echo '{"type":"generic","hasTS":false,"success":false}'
  fi
}

# Detect package manager from lock files with cross-platform support
detect_package_manager() {
  # Check for lock files (cross-platform)
  if [ -f "yarn.lock" ] || [ -f ".yarn.lock" ]; then
    echo "yarn"
    return 0
  elif [ -f "pnpm-lock.yaml" ] || [ -f ".pnpm-lock.yaml" ]; then
    echo "pnpm"
    return 0
  elif [ -f "package-lock.json" ] || [ -f ".package-lock.json" ]; then
    echo "npm"
    return 0
  else
    # Check package.json for hints
    if [ -f "package.json" ]; then
      if grep -q '"workspaces"' package.json; then
        echo "yarn"  # Workspaces often used with yarn
      elif grep -q '"pnpm"' package.json; then
        echo "pnpm"
      fi
    fi
    
    echo "unknown"
    return 1
  fi
}

# Check if a command exists
check_command_exists() {
  if command -v "$1" &> /dev/null; then
    return 0
  else
    echo "Warning: Command '$1' not found"
    return 1
  fi
}

# Create directory if it doesn't exist
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

# Safely write file with backup and error handling
safe_file_write() {
  local file="$1"
  local content="$2"
  
  # Create backup if file exists
  if [ -f "$file" ]; then
    if cp "$file" "${file}.backup" 2>/dev/null; then
      echo "Backup created: ${file}.backup"
    else
      echo "Warning: Could not create backup for ${file}"
    fi
  fi
  
  # Write file with error handling
  if echo "$content" > "$file"; then
    echo "✅ Created/updated: $file"
    return 0
  else
    echo "❌ Failed to write: $file"
    
    # Try alternative method
    if command_exists cat; then
      cat > "$file" << EOF
$content
EOF
      if [ $? -eq 0 ]; then
        echo "✅ Created using alternative method: $file"
        return 0
      fi
    fi
    
    return 1
  fi
}

# Safe directory creation with error handling
safe_create_directory() {
  local dir="$1"
  
  if [ ! -d "$dir" ]; then
    echo "Creating directory: $dir"
    
    # Try multiple methods
    if mkdir -p "$dir" 2>/dev/null; then
      echo "✅ Directory created: $dir"
      return 0
    elif command_exists mkdir; then
      mkdir "$dir" 2>/dev/null && echo "✅ Directory created: $dir" && return 0
    fi
    
    echo "❌ Failed to create directory: $dir"
    return 1
  else
    echo "✅ Directory already exists: $dir"
    return 0
  fi
}

# Safe package.json update with validation
safe_update_package_json() {
  if [ ! -f "package.json" ]; then
    echo "❌ package.json not found"
    return 1
  fi
  
  if ! command_exists node; then
    echo "⚠️  Node.js not available - cannot safely update package.json"
    return 1
  fi
  
  # Use Node.js for safe JSON manipulation
  node -e "
  const fs = require('fs');
  const path = require('path');
  
  try {
    const pkgPath = path.join(process.cwd(), 'package.json');
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    
    // Add scripts if they don't exist
    if (!pkg.scripts) pkg.scripts = {};
    
    const scriptsToAdd = {
      'env:validate': 'node -e \"try { require(\\'./src/env\\'); console.log(\\'✅ Validated\\') } catch(e) { console.log(\\'❌ Validation failed: ' + e.message + '\\') }\"',
      'env:init': 'cp .env.example .env.local 2>/dev/null || echo \\'Create .env.local manually\\'',
      'env:check': 'node -e \"const fs = require(\\'fs\\'); if (!fs.existsSync(\\'.env.local\\')) { console.log(\\'❌ .env.local missing\\'); process.exit(1) } else { console.log(\\'✅ .env.local exists\\') }\"'
    };
    
    // Only add if not already present
    Object.keys(scriptsToAdd).forEach(key => {
      if (!pkg.scripts[key]) {
        pkg.scripts[key] = scriptsToAdd[key];
      }
    });
    
    // Write back with validation
    const newContent = JSON.stringify(pkg, null, 2);
    fs.writeFileSync(pkgPath, newContent);
    
    console.log('✅ Updated package.json safely');
    return true;
  } catch (error) {
    console.log('❌ Failed to update package.json:', error.message);
    return false;
  }
  "
}

# Ask user for input (simplified for skill context)
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

# Load environment template based on project type
load_env_template() {
  local project_type="$1"
  local template_dir="$(dirname "$0")/templates"
  
  case "$project_type" in
    nextjs)
      cat "$template_dir/nextjs.env.example"
      ;;
    vite-react|vite-vue)
      cat "$template_dir/vite.env.example"
      ;;
    svelte)
      cat "$template_dir/svelte.env.example"
      ;;
    node)
      cat "$template_dir/node.env.example"
      ;;
    nuxt)
      cat "$template_dir/nuxt.env.example"
      ;;
    *)
      cat "$template_dir/generic.env.example"
      ;;
  esac
}

# Load validation template based on project type and TypeScript
load_validation_template() {
  local project_type="$1"
  local has_typescript="$2"
  local template_dir="$(dirname "$0")/validation-templates"
  
  if [ "$has_typescript" = "true" ]; then
    cat "$template_dir/typescript.env.ts"
  else
    cat "$template_dir/javascript.env.js"
  fi
}

# Get package.json scripts
get_package_scripts() {
  local project_type="$1"
  local has_typescript="$2"
  local validation_file="$([ "$has_typescript" = "true" ] && echo "src/env.ts" || echo "src/env.js")"
  
  cat << EOF
{
  "env:validate": "node -e \\\"try { require('./$validation_file'); console.log('✅ Environment variables validated'); } catch(e) { console.log('❌ Validation failed:', e.message); }\\\"",
  "env:check": "node -e \\\"const fs = require('fs'); const path = require('path'); const envLocal = path.join(__dirname, '.env.local'); const envExample = path.join(__dirname, '.env.example'); if (!fs.existsSync(envLocal)) { console.log('❌ .env.local not found'); console.log('📝 Run: cp .env.example .env.local'); process.exit(1); } else if (!fs.existsSync(envExample)) { console.log('⚠️  .env.example not found'); } else { console.log('✅ Environment files check passed'); }\\\"",
  "env:init": "node -e \\\"const fs = require('fs'); const path = require('path'); const example = path.join(__dirname, '.env.example'); const local = path.join(__dirname, '.env.local'); if (!fs.existsSync(example)) { console.error('❌ .env.example missing'); process.exit(1); } if (fs.existsSync(local)) { console.log('✅ .env.local already exists'); } else { fs.copyFileSync(example, local); console.log('✅ Created .env.local from template'); }\\\"",
  "env:list": "node -e \\\"try { const { envSchema } = require('./$validation_file'); console.log('📋 Environment variables in schema:'); Object.keys(envSchema.shape).forEach(key => { const desc = envSchema.shape[key].isOptional ? '(optional)' : '(required)'; console.log('  - ' + key + ' ' + desc); }); } catch(e) { console.log('⚠️  No schema found or error:', e.message); }\\\""
}
EOF
}

# Safe dependency installation with validation
safe_install_dependency() {
  local dependency="$1"
  local package_manager="$2"
  
  echo "Installing $dependency..."
  
  case "$package_manager" in
    yarn)
      if command_exists yarn; then
        yarn add "$dependency" --silent
        return $?
      fi
      ;;
    pnpm)
      if command_exists pnpm; then
        pnpm add "$dependency" --silent
        return $?
      fi
      ;;
    npm)
      if command_exists npm; then
        npm install "$dependency" --silent
        return $?
      fi
      ;;
    *)
      echo "⚠️  Unknown package manager: $package_manager"
      return 1
      ;;
  esac
  
  echo "❌ Could not install $dependency (package manager not found)"
  return 1
}