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