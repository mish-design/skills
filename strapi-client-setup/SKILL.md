---
name: strapi-client-setup
description: Set up a typed Strapi API client with proper population, media handling, and version-specific response types. Use when a user asks to connect to Strapi, set up Strapi API layer, configure Strapi client, or handle Strapi media/populate.
---

# Strapi Client Setup

Creates a typed Strapi API client for Next.js/React/etc. projects.

## Survey

Ask these questions before generating:

### 1. Strapi Version

```
? Strapi version:
  1) v5 (current, recommended)
  2) v4 (widely used)
  3) v3 (legacy)
```

### 2. Package Manager

```
? Package manager:
  1) npm
  2) yarn
  3) pnpm
```

### 3. HTTP Client

```
? Use existing axios client (from axios-setup)?
  1) Yes, extend my existing axios instance
  2) No, create a separate fetch wrapper
```

### 4. Strapi Host

```
? Strapi backend URL:
  (e.g., http://localhost:1337 or https://api.example.com)
```

### 5. Generate TypeScript Types

```
? Generate TypeScript types for content models?
  1) No, only generic types (StrapiResponse<T>, StrapiMedia)
  2) Yes, fetch schema from Strapi API automatically
  3) Yes, but I'll specify manually:
     (e.g., articles, categories, pages, authors)
```

## Version Differences

### Response Format

**v3:**
```typescript
// Response structure
{ data: T | T[], status: number }
// Single item
{ data: Article, status: 200 }
// Collection
{ data: Article[], status: 200 }
```

**v4/v5:**
```typescript
// Response structure
{ data: T | T[], meta: { pagination?: {...} } }
// Single item
{ data: Article, meta: {} }
// Collection  
{ data: Article[], meta: { pagination: { page, pageSize, pageCount, total } } }
```

### URL Format

**v3:** `/api/article/1`
**v4/v5:** `/api/articles/1` (pluralized collection name)

### Populate Syntax

**v3:**
```
?_populate=*
?_populate=author,cover
```

**v4/v5:**
```
?populate=*
?populate[author]=*
?populate[author][fields]=*&populate[cover][fields]=url,alternativeText
```

## Generated Files

### 1. `lib/strapi/types.ts` (or `src/lib/strapi/types.ts`)

```typescript
// Universal types for all Strapi versions
export interface StrapiMedia {
  id: number;
  url: string;
  alternativeText?: string;
  caption?: string;
  width?: number;
  height?: number;
  formats?: {
    thumbnail?: StrapiMediaFormat;
    small?: StrapiMediaFormat;
    medium?: StrapiMediaFormat;
    large?: StrapiMediaFormat;
    xlarge?: StrapiMediaFormat;
  };
}

export interface StrapiMediaFormat {
  url: string;
  width: number;
  height: number;
}

// v4/v5 response wrapper
export interface StrapiResponse<T> {
  data: T;
  meta: {
    pagination?: {
      page: number;
      pageSize: number;
      pageCount: number;
      total: number;
    };
  };
}

// v3 response wrapper
export interface StrapiResponseV3<T> {
  data: T;
  status: number;
}

// Error response
export interface StrapiError {
  data: null;
  error: {
    status: number;
    name: string;
    message: string;
    details?: unknown;
  };
}

// Populate parameter types
export type PopulateParam = 
  | '*'
  | string[]
  | Record<string, string | string[] | Record<string, unknown>>;
```

### 2. `lib/strapi/api.ts`

```typescript
// Adapt based on survey answers:
// - version: v3 | v4 | v5
// - useExistingAxios: boolean
// - baseURL: string

import { axiosInstance } from './axios'; // if using existing axios
// OR
import { strapiFetch } from './fetch'; // if using fetch wrapper

// Generic fetch function that handles version differences
async function strapiGet<T>(
  endpoint: string,
  options?: {
    params?: Record<string, unknown>;
    populate?: PopulateParam;
    version?: 3 | 4 | 5;
  }
): Promise<T> {
  // Build URL with proper format
  // Handle populate syntax per version
  // Return typed data
}
```

### 3. `lib/strapi/helpers.ts`

```typescript
/**
 * Convert populate fields to Strapi query string
 * 
 * Usage:
 * populate('*')                           → 'populate=*'
 * populate(['author', 'cover'])           → 'populate=author,cover'
 * populate({ author: '*', cover: 'url' }) → 'populate[author]=*&populate[cover]=url'
 */
function populate(fields: PopulateParam): string {
  if (!fields) return '';

  function buildQuery(obj: any, prefix = '') {
    const queryParts: string[] = [];

    if (typeof obj === 'string') {
      queryParts.push(`${prefix}=${obj}`);
    } else if (Array.isArray(obj)) {
      queryParts.push(`${prefix}=${obj.join(',')}`);
    } else if (typeof obj === 'object') {
      for (const key in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
          const newPrefix = prefix ? `${prefix}[${key}]` : key;
          queryParts.push(...buildQuery(obj[key], newPrefix));
        }
      }
    }
    return queryParts;
  }

  return buildQuery(fields, 'populate').join('&');
}

/**
 * Build pagination query
 * 
 * Usage:
 * pagination({ page: 1, pageSize: 10 })  → 'pagination[page]=1&pagination[pageSize]=10'
 */
function pagination(options: { page?: number; pageSize?: number; start?: number; limit?: number }): string {
  const parts: string[] = [];
  
  if ('page' in options && 'pageSize' in options) {
    parts.push(`pagination[page]=${options.page}`);
    parts.push(`pagination[pageSize]=${options.pageSize}`);
  }
  
  if ('start' in options) {
    parts.push(`pagination[start]=${options.start}`);
  }
  
  if ('limit' in options) {
    parts.push(`pagination[limit]=${options.limit}`);
  }
  
  return parts.join('&');
}

/**
 * Build filters query
 * 
 * Usage:
 * filters({ category: 'news' })
 *   → 'filters[category][$eq]=news'
 * 
 * filters({ author: { id: 1 } })
 *   → 'filters[author][id][$eq]=1'
 * 
 * filters({ price: { $gte: 100 } })
 *   → 'filters[price][$gte]=100'
 */
function filters(filtersObj: Record<string, any>): string {
  const parts: string[] = [];

  function stringify(obj: Record<string, any>, prefix = 'filters') {
    for (const key in obj) {
      if (!Object.prototype.hasOwnProperty.call(obj, key)) continue;

      const value = obj[key];
      const newPrefix = `${prefix}[${key}]`;
      
      if (value === null) {
        parts.push(`${newPrefix}[$null]=true`);
        continue;
      }

      if (typeof value === 'object' && !Array.isArray(value)) {
        const isOperatorGroup = Object.keys(value).every(k => k.startsWith('$'));
        if (isOperatorGroup) {
          for(const op in value) {
            parts.push(`${newPrefix}[${op}]=${encodeURIComponent(value[op])}`);
          }
        } else {
          stringify(value, newPrefix);
        }
      } else {
        parts.push(`${newPrefix}[$eq]=${encodeURIComponent(value)}`);
      }
    }
  }

  stringify(filtersObj);
  return parts.join('&');
}

/**
 * Build sort query
 * 
 * Usage:
 * sort('createdAt', 'desc')      → 'sort=createdAt:desc'
 * sort(['publishedAt', 'title'], ['desc', 'asc'])
 *   → 'sort=publishedAt:desc&sort=title:asc'
 */
function sort(
  field: string | string[],
  direction?: 'asc' | 'desc' | ('asc' | 'desc')[]
): string {
  const dirs = Array.isArray(direction) ? direction : (direction ? [direction] : ['asc']);
  const fields = Array.isArray(field) ? field : [field];

  return fields
    .map((f, i) => `sort=${f}:${dirs[i] || 'asc'}`)
    .join('&');
}

/**
 * Get full image URL with Strapi base URL
 * 
 * Usage:
 * getImageUrl(mediaItem)                    → 'http://localhost:1337/uploads/image.jpg'
 * getImageUrl(mediaItem, 'https://cdn.example.com') → 'https://cdn.example.com/uploads/image.jpg'
 * getImageUrl(mediaItem.formats?.thumbnail) → thumbnail URL
 */
function getImageUrl(
  media: StrapiMedia | StrapiMediaFormat | null | undefined,
  baseUrl?: string
): string {
  if (!media) return '';
  
  const url = 'url' in media ? media.url : media;
  if (!url) return '';
  
  if (url.startsWith('http')) return url;
  
  const base = baseUrl || process.env.NEXT_PUBLIC_STRAPI_URL || 'http://localhost:1337';
  return `${base}${url.startsWith('/') ? '' : '/'}${url}`;
}

/**
 * Get best available image size
 * 
 * Usage:
 * getBestImage(mediaItem, 'large')
 *   → tries large → medium → small → original
 */
function getBestImage(
  media: StrapiMedia,
  preferred: 'thumbnail' | 'small' | 'medium' | 'large' | 'xlarge' = 'medium'
): string {
  const order: Array<keyof StrapiMedia['formats']> = [
    preferred, 'large', 'medium', 'small', 'thumbnail'
  ];
  
  for (const format of order) {
    if (media.formats?.[format]) {
      return getImageUrl(media.formats[format]!);
    }
  }
  
  return getImageUrl(media);
}
```

### 3. `lib/strapi/generate-types.ts` (optional, if requested)

```typescript
#!/usr/bin/env tsx

import fs from 'fs';
import path from 'path';

const STRAPI_URL = process.env.NEXT_PUBLIC_STRAPI_URL || 'http://localhost:1337';

import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

// --- CONFIGURATION ---
const STRAPI_URL = process.env.NEXT_PUBLIC_STRAPI_URL || 'http://localhost:1337';
const API_TOKEN = process.env.STRAPI_API_TOKEN;
const OUTPUT_DIR = join(process.cwd(), 'src', 'types', 'strapi');

// --- UTILITY FUNCTIONS ---

function toPascalCase(str: string): string {
  return str.replace(/(?:^|[-_])(\w)/g, (_, c) => c.toUpperCase()).replace(/[-_]/g, '');
}

function getInterfaceName(uid: string): string {
  // e.g., api::article.article -> Article
  const parts = uid.split('.');
  const name = parts[parts.length - 1];
  return toPascalCase(name);
}

// --- TYPE GENERATION LOGIC ---

function getTypeForField(field: any): string {
  switch (field.type) {
    case 'string':
    case 'text':
    case 'richtext':
    case 'email':
    case 'uid':
    case 'password':
      return 'string';
    case 'integer':
    case 'biginteger':
    case 'decimal':
    case 'float':
      return 'number';
    case 'boolean':
      return 'boolean';
    case 'date':
    case 'datetime':
    case 'time':
      return 'string'; // Or Date, depending on preference
    case 'json':
      return 'Record<string, unknown>';
    case 'enumeration':
      return field.enum.map((v: string) => `'${v}'`).join(' | ');
    case 'media':
      return `StrapiResponse<StrapiMedia${field.multiple ? '[]' : ''}>`;
    case 'relation':
      const targetInterface = getInterfaceName(field.target);
      return `StrapiResponse<${targetInterface}${field.relation.endsWith('Many') ? '[]' : ''}>`;
    case 'component':
      const componentInterface = getInterfaceName(field.component);
      return `${componentInterface}${field.repeatable ? '[]' : ''}`;
    case 'dynamiczone':
      return `(${field.components.map(getInterfaceName).join(' | ')})[]`;
    default:
      return 'any';
  }
}

async function generateContentTypes(schemas: any[]): Promise<string> {
  let content = '// --- CONTENT TYPES ---\n\n';
  for (const schema of schemas) {
    if (!schema.uid.startsWith('api::')) continue;

    const interfaceName = getInterfaceName(schema.uid);
    content += `export interface ${interfaceName} {\n`;
    content += `  id: number;\n`;
    content += '  attributes: {\n';

    for (const [key, attr] of Object.entries(schema.attributes)) {
      const type = getTypeForField(attr);
      const optional = (attr as any).required ? '' : '?';
      content += `    ${key}${optional}: ${type};\n`;
    }
    
    content += '    createdAt: string;\n';
    content += '    updatedAt: string;\n';
    content += '    publishedAt?: string;\n';
    content += '  };\n}
\n';
  }
  return content;
}

async function generateComponentTypes(schemas: any[]): Promise<string> {
  let content = '// --- COMPONENTS ---\n\n';
  for (const schema of schemas) {
    if (schema.uid.startsWith('api::')) continue;

    const interfaceName = getInterfaceName(schema.uid);
    content += `export interface ${interfaceName} {\n`;
    content += `  id: number;\n`;

    for (const [key, attr] of Object.entries(schema.attributes)) {
      const type = getTypeForField(attr);
      const optional = (attr as any).required ? '' : '?';
      content += `  ${key}${optional}: ${type};\n`;
    }
    content += '}\n\n';
  }
  return content;
}

// --- MAIN EXECUTION ---

async function main() {
  if (!API_TOKEN) {
    console.error('❌ STRAPI_API_TOKEN environment variable is not set.');
    return;
  }

  console.log('📡 Fetching all content types from Strapi...');
  const response = await fetch(`${STRAPI_URL}/api/content-type-builder/content-types`, {
    headers: { Authorization: `Bearer ${API_TOKEN}` }
  });

  if (!response.ok) {
    console.error(`❌ Failed to fetch schemas: ${response.status}`);
    return;
  }

  const { data: schemas } = await response.json();

  if (!existsSync(OUTPUT_DIR)) {
    mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  // Base types
  const baseTypes = `
    // Base Strapi types. Need to be in a separate file to avoid circular dependencies.
    export interface StrapiMedia {}
    export interface StrapiResponse<T> {}
  `;
  writeFileSync(join(OUTPUT_DIR, 'base.ts'), baseTypes, 'utf8');

  // Components
  const componentTypes = await generateComponentTypes(schemas);
  writeFileSync(join(OUTPUT_DIR, 'components.ts'), componentTypes, 'utf8');
  
  // Content Types
  const contentTypes = await generateContentTypes(schemas);
  writeFileSync(join(OUTPUT_DIR, 'content-types.ts'), contentTypes, 'utf8');

  // Index file
  const indexFile = `
    export * from './base';
    export * from './components';
    export * from './content-types';
  `;
  writeFileSync(join(OUTPUT_DIR, 'index.ts'), indexFile, 'utf8');

  console.log(`✅ Types generated successfully in ${OUTPUT_DIR}`);
  console.log('💡 Add to package.json: "strapi:types": "tsx lib/strapi/generate-types.ts"');
}

main().catch(console.error);
```

### 4. `lib/strapi/fetch.ts` (if not using axios)
async function strapiFetch<T>(
  endpoint: string,
  options?: RequestInit & {
    params?: Record<string, unknown>;
  }
): Promise<T> {
  const baseUrl = process.env.NEXT_PUBLIC_STRAPI_URL || 'http://localhost:1337';
  let url = `${baseUrl}/api${endpoint}`;
  
  if (options?.params) {
    const searchParams = new URLSearchParams();
    Object.entries(options.params).forEach(([key, value]) => {
      searchParams.append(key, String(value));
    });
    url += `?${searchParams.toString()}`;
  }
  
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });
  
  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error?.error?.message || `HTTP ${response.status}`);
  }
  
  return response.json();
}
```

## Usage Examples

### Combining helpers to get articles

```typescript
import { strapiGet } from './api';
import { populate, filters, sort, pagination } from './helpers';
import type { Article } from './generated-types'; 

async function getPublishedArticles() {
  const query = [
    populate({ 
      author: { populate: '*' }, 
      cover: 'url' 
    }),
    filters({ 
      publishedAt: { $notNull: true },
      category: { name: 'News' },
    }),
    sort(['publishedAt', 'title'], ['desc', 'asc']),
    pagination({ page: 1, pageSize: 10 })
  ].filter(Boolean).join('&');

  const { data: articles } = await strapiGet<Article[]>(
    `/articles?${query}`
  );

  return articles;
}
```

### Display image

```typescript
import { getBestImage, getImageUrl } from './helpers';
// In component
const imageUrl = getBestImage(article.attributes.cover.data, 'medium');
// or for specific format
const thumbnailUrl = getImageUrl(article.attributes.cover.data.attributes.formats?.thumbnail);
```

## Done Checklist

- `lib/strapi/types.ts` — StrapiResponse, StrapiMedia types
- `lib/strapi/api.ts` — typed API client (axios or fetch)
- `lib/strapi/helpers.ts` — populate, pagination, filters, getImageUrl
- `.env.local` has `NEXT_PUBLIC_STRAPI_URL` (for Next.js)
- Optional: `lib/strapi/generate-types.ts` — script for auto-generating types
