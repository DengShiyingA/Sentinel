import Fastify from 'fastify';
import cors from '@fastify/cors';
import { readFileSync } from 'fs';
import { config } from './lib/config';
import { logger } from './lib/logger';
import { initDatabase, shutdownDatabase, cleanExpiredApprovals, expireStalePendingRequests } from './db/client';
import { authRoutes } from './auth/challenge';
import { pairRoutes } from './routes/pair';
import { initSocketHub, shutdownHub } from './socket/hub';
import { initApns, shutdownApns } from './apns/sender';

async function main(): Promise<void> {
  logger.info({ env: config.NODE_ENV, port: config.PORT }, 'Starting Sentinel Server');

  // ==================== Database ====================
  await initDatabase();

  // ==================== Fastify (with optional TLS) ====================
  const hasTls = config.TLS_CERT_PATH && config.TLS_KEY_PATH;
  const app = Fastify({
    logger: false,
    ...(hasTls
      ? {
          https: {
            cert: readFileSync(config.TLS_CERT_PATH!),
            key: readFileSync(config.TLS_KEY_PATH!),
          },
        }
      : {}),
  });

  if (hasTls) {
    logger.info('TLS enabled — server will use HTTPS/WSS');
  } else {
    logger.warn('TLS not configured — server running in plain HTTP/WS (not recommended for production)');
  }

  app.addContentTypeParser('application/json', { parseAs: 'string', bodyLimit: 512 * 1024 }, (req, body, done) => {
    try { done(null, JSON.parse(body as string)); } catch (err) { done(err as Error); }
  });
  await app.register(cors, { origin: true, credentials: true });

  // ==================== Routes ====================
  await app.register(authRoutes);
  await app.register(pairRoutes);

  // ==================== Socket.IO ====================
  initSocketHub(app);

  // ==================== APNs (optional) ====================
  initApns();

  // ==================== Start ====================
  await app.listen({ port: config.PORT, host: config.HOST });

  logger.info(`Sentinel Server listening on ${config.HOST}:${config.PORT}`);

  // Periodic cleanup: expire stale requests and remove old resolved ones
  setInterval(async () => {
    try {
      const expired = await expireStalePendingRequests(config.APPROVAL_TIMEOUT_S);
      const cleaned = await cleanExpiredApprovals();
      if (expired > 0 || cleaned > 0) {
        logger.info({ expired, cleaned }, 'Cleanup: expired pending requests and removed old approvals');
      }
    } catch (err) {
      logger.error({ err }, 'Cleanup job failed');
    }
  }, 60_000); // every minute

  // ==================== Graceful Shutdown ====================
  const shutdown = async (signal: string) => {
    logger.info({ signal }, 'Shutting down...');

    shutdownHub();
    shutdownApns();
    await app.close();
    await shutdownDatabase();

    logger.info('Shutdown complete');
    process.exit(0);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  logger.fatal({ err }, 'Fatal: server failed to start');
  process.exit(1);
});
