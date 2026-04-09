import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { randomBytes } from 'crypto';
import { findDeviceById, healthCheck, createPairSecret, findPairSecret, cleanExpiredPairSecrets, pairDevicesTransaction } from '../db/client';
import { verifyJwt } from '../auth/challenge';
import { config } from '../lib/config';
import { logger } from '../lib/logger';

// Clean expired secrets periodically
setInterval(() => {
  cleanExpiredPairSecrets().catch((err) => logger.error({ err }, 'Failed to clean expired pair secrets'));
}, 60_000);

// ==================== Zod ====================

const PairLinkSchema = z.object({ token: z.string().min(1) });
const PairConfirmSchema = z.object({
  secret: z.string().min(1),
  token: z.string().min(1),
  apnsToken: z.string().optional(),
});
const PairStatusSchema = z.object({ token: z.string().min(1) });

// ==================== Routes ====================

export async function pairRoutes(app: FastifyInstance): Promise<void> {

  // POST /v1/pair/link — Mac 生成配对深链接
  app.post('/v1/pair/link', async (request, reply) => {
    const parsed = PairLinkSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ success: false, error: { code: 'INVALID_BODY', message: parsed.error.message } });
    }

    const jwt = verifyJwt(parsed.data.token);
    if (!jwt) return reply.status(401).send({ success: false, error: { code: 'AUTH_FAILED', message: 'Invalid token' } });
    if (jwt.type !== 'mac') return reply.status(403).send({ success: false, error: { code: 'FORBIDDEN', message: 'Mac only' } });

    const secretBytes = randomBytes(32);
    const secretBase64Url = secretBytes.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

    await createPairSecret(secretBase64Url, jwt.deviceId, config.PAIR_SECRET_TTL_S);

    logger.info({ macDeviceId: jwt.deviceId }, 'Pair link generated');
    return reply.send({ success: true, data: { link: `sentinel://pair/${secretBase64Url}`, expiresIn: config.PAIR_SECRET_TTL_S } });
  });

  // POST /v1/pair/confirm — iOS 确认配对
  app.post('/v1/pair/confirm', async (request, reply) => {
    const parsed = PairConfirmSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ success: false, error: { code: 'INVALID_BODY', message: parsed.error.message } });
    }

    const { secret, token, apnsToken } = parsed.data;

    const jwt = verifyJwt(token);
    if (!jwt) return reply.status(401).send({ success: false, error: { code: 'AUTH_FAILED', message: 'Invalid token' } });
    if (jwt.type !== 'ios') return reply.status(403).send({ success: false, error: { code: 'FORBIDDEN', message: 'iOS only' } });

    const entry = await findPairSecret(secret);
    if (!entry) return reply.status(404).send({ success: false, error: { code: 'PAIR_EXPIRED', message: 'Pair link expired or invalid' } });

    const macDeviceId = entry.macDeviceId;
    const iosDeviceId = jwt.deviceId;

    try {
      // Atomic: both pairing updates + secret deletion in one transaction
      await pairDevicesTransaction(macDeviceId, iosDeviceId, secret, apnsToken);

      const macDevice = await findDeviceById(macDeviceId);

      logger.info({ macDeviceId, iosDeviceId }, 'Devices paired');
      return reply.send({
        success: true,
        data: { pairedDeviceId: macDeviceId, macPublicKey: macDevice?.publicKey, macName: macDevice?.name },
      });
    } catch (err) {
      logger.error({ err }, 'Pair confirm failed');
      return reply.status(500).send({ success: false, error: { code: 'INTERNAL', message: 'Failed to pair' } });
    }
  });

  // GET /v1/pair/status
  app.get('/v1/pair/status', async (request, reply) => {
    const parsed = PairStatusSchema.safeParse(request.query);
    if (!parsed.success) return reply.status(400).send({ success: false, error: { code: 'INVALID_QUERY', message: 'token required' } });

    const jwt = verifyJwt(parsed.data.token);
    if (!jwt) return reply.status(401).send({ success: false, error: { code: 'AUTH_FAILED', message: 'Invalid token' } });

    const device = await findDeviceById(jwt.deviceId);
    let pairedDevice = null;
    if (device?.pairedWithId) {
      pairedDevice = await findDeviceById(device.pairedWithId);
    }

    return reply.send({
      success: true,
      data: { paired: !!device?.pairedWithId, pairedDevice: pairedDevice ? { id: pairedDevice.id, name: pairedDevice.name, type: pairedDevice.type } : null },
    });
  });

  // GET /health
  app.get('/health', async (_request, reply) => {
    const dbOk = await healthCheck();
    return reply.status(dbOk ? 200 : 503).send({
      success: dbOk,
      data: { status: dbOk ? 'healthy' : 'degraded', version: '1.0.0', uptime: process.uptime(), db: dbOk ? 'ok' : 'error' },
    });
  });
}
