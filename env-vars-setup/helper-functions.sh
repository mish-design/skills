#!/bin/bash
# Environment Variables Setup - Helper Functions
# This file contains reusable functions for the env-vars-setup skill

# Detect project type and TypeScript usage
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

# Detect package manager from lock files
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

# Safely write file with backup
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
  "env:validate": "node -e \\\"require('./$validation_file'); console.log('✅ Environment variables validated')\\\"",
  "env:check": "node -e \\\"const fs = require('fs'); if (!fs.existsSync('.env.local')) { console.log('❌ .env.local not found'); console.log('Run: cp .env.example .env.local'); process.exit(1); } else { console.log('✅ .env.local exists'); }\\\"",
  "env:init": "cp .env.example .env.local 2>/dev/null || echo 'Create .env.local manually'",
  "env:list": "node -e \\\"try { const schema = require('./$validation_file').envSchema; console.log('📋 Defined variables:'); Object.keys(schema.shape).forEach(k => console.log('  - ' + k)); } catch(e) { console.log('No schema found'); }\\\""
}
EOF
}