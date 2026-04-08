import Fastify from 'fastify';
import cors from '@fastify/cors';
import { config } from './lib/config';
import { logger } from './lib/logger';
import { initDatabase, shutdownDatabase } from './db/client';
import { authRoutes } from './auth/challenge';
import { pairRoutes } from './routes/pair';
import { initSocketHub, shutdownHub } from './socket/hub';
import { initApns, shutdownApns } from './apns/sender';

async function main(): Promise<void> {
  logger.info({ env: config.NODE_ENV, port: config.PORT }, 'Starting Sentinel Server');

  // ==================== Database ====================
  await initDatabase();

  // ==================== Fastify ====================
  const app = Fastify({ logger: false });

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
