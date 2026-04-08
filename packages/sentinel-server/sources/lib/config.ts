import { z } from 'zod';
import 'dotenv/config';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3005),
  HOST: z.string().default('0.0.0.0'),

  // JWT / Auth
  MASTER_SECRET: z.string().min(16, 'MASTER_SECRET must be at least 16 chars'),
  JWT_TTL_DAYS: z.coerce.number().default(30),

  // PGlite data directory
  DATA_DIR: z.string().default('/data/sentinel'),

  // APNs (optional)
  APNS_TEAM_ID: z.string().optional(),
  APNS_KEY_ID: z.string().optional(),
  APNS_KEY_PATH: z.string().optional(),
  APNS_TOPIC: z.string().default('com.sentinel.ios'),
  APNS_PRODUCTION: z.coerce.boolean().default(false),

  // Timeouts
  APPROVAL_TIMEOUT_S: z.coerce.number().default(120),
  PAIR_SECRET_TTL_S: z.coerce.number().default(300), // 5 min
});

export type Config = z.infer<typeof envSchema>;

function loadConfig(): Config {
  const result = envSchema.safeParse(process.env);
  if (!result.success) {
    console.error('❌ Invalid environment variables:');
    for (const [key, errors] of Object.entries(result.error.flatten().fieldErrors)) {
      console.error(`  ${key}: ${errors?.join(', ')}`);
    }
    process.exit(1);
  }
  return result.data;
}

export const config = loadConfig();
