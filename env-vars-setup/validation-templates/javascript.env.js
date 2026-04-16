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
  envSchema,
  env,
  isProduction,
  isDevelopment,
  isTest,
  port,
  requireEnv,
};