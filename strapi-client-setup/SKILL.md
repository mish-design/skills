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
  if (fields === '*') return 'populate=*';
  
  if (Array.isArray(fields)) {
    return `populate=${fields.join(',')}`;
  }
  
  if (typeof fields === 'object') {
    return Object.entries(fields)
      .map(([key, value]) => {
        if (value === '*') return `populate[${key}]=*`;
        if (Array.isArray(value)) return `populate[${key}]=${value.join(',')}`;
        if (typeof value === 'object') {
          return Object.entries(value)
            .map(([k, v]) => `populate[${key}][${k}]=${v}`)
            .join('&');
        }
        return `populate[${key}]=${value}`;
      })
      .join('&');
  }
  
  return '';
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
function filters(obj: Record<string, unknown>, prefix = 'filters'): string {
  return Object.entries(obj)
    .map(([key, value]) => {
      if (value === null || value === undefined) return '';
      
      if (typeof value === 'object') {
        const [operator, operand] = Object.entries(value)[0] as [string, unknown];
        return `${prefix}[${key}][${operator}]=${operand}`;
      }
      
      return `${prefix}[${key}][$eq]=${value}`;
    })
    .filter(Boolean)
    .join('&');
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
  const dirs = Array.isArray(direction) ? direction : 
    (direction ? [direction] : ['asc']);
  
  const fields = Array.isArray(field) ? field : [field];
  
  return fields
    .map((f, i) => `${f}:${dirs[i] || dirs[0]}`)
    .join('&sort=');
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

async function fetchContentTypes() {
  try {
    const response = await fetch(`${STRAPI_URL}/api/content-types?populate=*`);
    
    if (!response.ok) {
      console.error(`Failed to fetch content types: ${response.status}`);
      return null;
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error fetching Strapi content types:', error);
    return null;
  }
}

function generateTypeFromSchema(schema: any): string {
  // Generate TypeScript interface from Strapi schema
  // This is simplified - expand based on actual Strapi response
  const lines = [`export interface ${schema.uid} {`];
  
  for (const [fieldName, fieldConfig] of Object.entries(schema.attributes)) {
    const field = fieldConfig as any;
    let type = 'unknown';
    
    if (field.type === 'string') type = 'string';
    else if (field.type === 'integer' || field.type === 'biginteger' || field.type === 'decimal') type = 'number';
    else if (field.type === 'boolean') type = 'boolean';
    else if (field.type === 'date' || field.type === 'datetime' || field.type === 'time') type = 'string';
    else if (field.type === 'media') type = 'StrapiMedia | null';
    else if (field.type === 'relation') {
      const related = field.relation?.split('.')?.[1] || 'unknown';
      type = `StrapiResponse<${related}> | null`;
    }
    else if (field.type === 'component') type = 'any';
    else if (field.type === 'dynamiczone') type = 'any[]';
    else if (field.type === 'json') type = 'Record<string, unknown>';
    
    const optional = field.required === false ? '?' : '';
    lines.push(`  ${fieldName}${optional}: ${type};`);
  }
  
  lines.push(`}`);
  return lines.join('\n');
}

async function main() {
  console.log('📡 Fetching Strapi content types...');
  const data = await fetchContentTypes();
  
  if (!data) {
    console.log('❌ Could not fetch content types. Using generic types only.');
    return;
  }
  
  const types: string[] = [];
  types.push('// Auto-generated from Strapi API');
  types.push('// Run with: npm run strapi:types');
  types.push('');
  
  // Generate types for each content type
  for (const contentType of data.data) {
    const interfaceCode = generateTypeFromSchema(contentType);
    types.push(interfaceCode);
    types.push('');
  }
  
  const outputPath = path.join(process.cwd(), 'lib', 'strapi', 'generated-types.ts');
  fs.writeFileSync(outputPath, types.join('\n'), 'utf8');
  
  console.log(`✅ Generated types in ${outputPath}`);
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

### Get articles with author and cover

```typescript
// v4/v5
const { data: articles } = await strapiGet<Article[]>(
  '/articles',
  {
    params: {
      'populate[author]': '*',
      'populate[cover]': '*',
      'pagination[page]': 1,
      'pagination[pageSize]': 10,
      'sort': 'createdAt:desc',
    }
  }
);

// v3
const { data: articles } = await strapiGetV3<Article[]>(
  '/articles',
  {
    params: {
      _populate: 'author,cover',
      _limit: 10,
      _sort: 'createdAt:desc',
    }
  }
);
```

### Display image

```typescript
// In component
const imageUrl = getBestImage(article.cover, 'medium');
// or for specific format
const thumbnailUrl = getImageUrl(article.cover?.formats?.thumbnail);
```

## Done Checklist

- `lib/strapi/types.ts` — StrapiResponse, StrapiMedia types
- `lib/strapi/api.ts` — typed API client (axios or fetch)
- `lib/strapi/helpers.ts` — populate, pagination, filters, getImageUrl
- `.env.local` has `NEXT_PUBLIC_STRAPI_URL` (for Next.js)
- Optional: `lib/strapi/generate-types.ts` — script for auto-generating types
