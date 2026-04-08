import { Socket } from 'socket.io';
import { z } from 'zod';
import { createId } from '@paralleldrive/cuid2';
import { findDeviceById, createApproval, resolveApproval, findApprovalById } from '../../db/client';
import { relay } from '../hub';
import { sendApprovalPush } from '../../apns/sender';
import { config } from '../../lib/config';
import { logger } from '../../lib/logger';

const ApprovalRequestSchema = z.object({
  toolName: z.string().min(1),
  toolInput: z.record(z.unknown()),
  riskLevel: z.enum(['low', 'medium', 'high']).default('low'),
});

const DecisionSchema = z.object({
  requestId: z.string().min(1),
  action: z.enum(['allowed', 'blocked']),
});

const timeoutTimers = new Map<string, NodeJS.Timeout>();

function scheduleTimeout(requestId: string, macDeviceId: string): void {
  const timer = setTimeout(async () => {
    timeoutTimers.delete(requestId);
    try {
      const count = await resolveApproval(requestId, 'timeout');
      if (count > 0) {
        relay(macDeviceId, 'decision', { requestId, action: 'timeout' });
        logger.info({ requestId }, 'Approval timed out → auto block');
      }
    } catch (err) {
      logger.error({ err, requestId }, 'Timeout handler error');
    }
  }, config.APPROVAL_TIMEOUT_S * 1000);
  timeoutTimers.set(requestId, timer);
}

function cancelTimeout(requestId: string): void {
  const timer = timeoutTimers.get(requestId);
  if (timer) { clearTimeout(timer); timeoutTimers.delete(requestId); }
}

export function registerApprovalHandlers(socket: Socket): void {
  const deviceId = socket.data.deviceId as string;
  const deviceType = socket.data.type as string;

  socket.on('approval_request', async (data: unknown, ack?: (res: unknown) => void) => {
    if (deviceType !== 'mac') {
      ack?.({ success: false, error: 'Only Mac devices can send approval requests' });
      return;
    }

    const parsed = ApprovalRequestSchema.safeParse(data);
    if (!parsed.success) {
      ack?.({ success: false, error: parsed.error.message });
      return;
    }

    try {
      const macDevice = await findDeviceById(deviceId);
      if (!macDevice?.pairedWithId) {
        ack?.({ success: false, error: 'No paired iOS device' });
        return;
      }

      const iosDeviceId = macDevice.pairedWithId;

      const approval = await createApproval({
        id: createId(),
        macDeviceId: deviceId,
        toolName: parsed.data.toolName,
        toolInput: parsed.data.toolInput,
        riskLevel: parsed.data.riskLevel,
      });

      const relayed = relay(iosDeviceId, 'approval_request', {
        id: approval.id,
        toolName: approval.toolName,
        toolInput: approval.toolInput,
        riskLevel: approval.riskLevel,
        macDeviceId: deviceId,
        timestamp: new Date().toISOString(),
        timeoutAt: new Date(Date.now() + config.APPROVAL_TIMEOUT_S * 1000).toISOString(),
      });

      if (!relayed) {
        const iosDevice = await findDeviceById(iosDeviceId);
        if (iosDevice?.apnsToken) {
          await sendApprovalPush(iosDevice.apnsToken, {
            requestId: approval.id,
            riskLevel: approval.riskLevel,
            toolName: approval.toolName,
          });
        } else {
          logger.warn({ iosDeviceId }, 'iOS offline, no APNs token');
        }
      }

      scheduleTimeout(approval.id, deviceId);

      logger.info({ requestId: approval.id, toolName: approval.toolName }, 'Approval created');
      ack?.({ success: true, requestId: approval.id });
    } catch (err) {
      logger.error({ err }, 'approval_request error');
      ack?.({ success: false, error: 'Internal error' });
    }
  });

  socket.on('decision', async (data: unknown, ack?: (res: unknown) => void) => {
    if (deviceType !== 'ios') {
      ack?.({ success: false, error: 'Only iOS devices can send decisions' });
      return;
    }

    const parsed = DecisionSchema.safeParse(data);
    if (!parsed.success) {
      ack?.({ success: false, error: parsed.error.message });
      return;
    }

    const { requestId, action } = parsed.data;

    try {
      const count = await resolveApproval(requestId, action);
      if (count === 0) {
        ack?.({ success: false, error: 'Request not found or already resolved' });
        return;
      }

      cancelTimeout(requestId);

      const approval = await findApprovalById(requestId);
      if (approval) {
        relay(approval.macDeviceId, 'decision', { requestId, action });
      }

      logger.info({ requestId, action }, 'Decision recorded');
      ack?.({ success: true });
    } catch (err) {
      logger.error({ err, requestId }, 'decision error');
      ack?.({ success: false, error: 'Internal error' });
    }
  });
}
