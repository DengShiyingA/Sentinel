import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import nacl from 'tweetnacl';
import { decodeBase64 } from 'tweetnacl-util';
import jwt from 'jsonwebtoken';
import { createId } from '@paralleldrive/cuid2';
import { config } from '../lib/config';
import { logger } from '../lib/logger';
import { findDeviceByPublicKey, upsertDevice } from '../db/client';

const AuthRequestSchema = z.object({
  challenge: z.string().min(1),
  publicKey: z.string().min(1),
  signature: z.string().min(1),
  deviceName: z.string().default('Unknown Device'),
  deviceType: z.enum(['mac', 'ios']).default('mac'),
});

export interface JwtPayload {
  deviceId: string;
  publicKey: string;
  type: string;
}

export async function authRoutes(app: FastifyInstance): Promise<void> {
  app.post('/v1/auth', async (request, reply) => {
    const parsed = AuthRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_BODY', message: parsed.error.message },
      });
    }

    const { challenge, publicKey, signature, deviceName, deviceType } = parsed.data;

    let challengeBytes: Uint8Array;
    let publicKeyBytes: Uint8Array;
    let signatureBytes: Uint8Array;
    try {
      challengeBytes = decodeBase64(challenge);
      publicKeyBytes = decodeBase64(publicKey);
      signatureBytes = decodeBase64(signature);
    } catch {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_BASE64', message: 'Bad base64' },
      });
    }

    // Validate decoded byte lengths (Ed25519: challenge=32, publicKey=32, signature=64)
    if (challengeBytes.length !== 32) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_CHALLENGE', message: `Challenge must be 32 bytes, got ${challengeBytes.length}` },
      });
    }
    if (publicKeyBytes.length !== 32) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_PUBLIC_KEY', message: `Public key must be 32 bytes, got ${publicKeyBytes.length}` },
      });
    }
    if (signatureBytes.length !== 64) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_SIGNATURE', message: `Signature must be 64 bytes, got ${signatureBytes.length}` },
      });
    }

    const valid = nacl.sign.detached.verify(challengeBytes, signatureBytes, publicKeyBytes);
    if (!valid) {
      logger.warn({ publicKey }, 'Auth failed: invalid signature');
      return reply.status(401).send({
        success: false,
        error: { code: 'AUTH_FAILED', message: 'Signature verification failed' },
      });
    }

    let device = await findDeviceByPublicKey(publicKey);
    if (!device) {
      device = await upsertDevice({ id: createId(), publicKey, type: deviceType, name: deviceName });
      logger.info({ deviceId: device.id, type: deviceType }, 'New device created');
    }

    const payload: JwtPayload = { deviceId: device.id, publicKey: device.publicKey, type: device.type };
    const token = jwt.sign(payload, config.MASTER_SECRET, { expiresIn: `${config.JWT_TTL_DAYS}d` });

    logger.info({ deviceId: device.id }, 'Auth successful');
    return reply.send({
      success: true,
      data: { token, deviceId: device.id, expiresIn: config.JWT_TTL_DAYS * 86400 },
    });
  });
}

export function verifyJwt(token: string): JwtPayload | null {
  try {
    return jwt.verify(token, config.MASTER_SECRET) as JwtPayload;
  } catch {
    return null;
  }
}
