import apn from '@parse/node-apn';
import { config } from '../lib/config';
import { logger } from '../lib/logger';

let provider: apn.Provider | null = null;

/**
 * 初始化 APNs — 如果缺少配置则跳过（可选功能）
 */
export function initApns(): void {
  if (!config.APNS_KEY_ID || !config.APNS_TEAM_ID || !config.APNS_KEY_PATH) {
    logger.warn('APNs not configured — push notifications disabled');
    return;
  }

  try {
    provider = new apn.Provider({
      token: {
        key: config.APNS_KEY_PATH,
        keyId: config.APNS_KEY_ID,
        teamId: config.APNS_TEAM_ID,
      },
      production: config.APNS_PRODUCTION,
    });
    logger.info('APNs provider initialized');
  } catch (err) {
    logger.error({ err }, 'Failed to init APNs');
  }
}

export function shutdownApns(): void {
  provider?.shutdown();
  provider = null;
}

interface PushPayload {
  requestId: string;
  riskLevel: string;
  toolName: string;
}

/**
 * 推送"有新审批请求"通知
 * 隐私：payload 仅含风险等级，不含文件路径
 */
export async function sendApprovalPush(
  apnsToken: string,
  payload: PushPayload,
): Promise<boolean> {
  if (!provider) return false;

  const note = new apn.Notification();
  note.topic = config.APNS_TOPIC;
  note.expiry = Math.floor(Date.now() / 1000) + config.APPROVAL_TIMEOUT_S;
  note.sound = 'default';
  note.category = 'APPROVAL_ACTIONS';

  const emoji = payload.riskLevel === 'high' ? '🔴' : payload.riskLevel === 'medium' ? '🟡' : '🟢';
  note.alert = {
    title: `${emoji} Sentinel`,
    body: `Tool: ${payload.toolName}`,
  };
  note.payload = { requestId: payload.requestId, riskLevel: payload.riskLevel };

  try {
    const result = await provider.send(note, apnsToken);
    if (result.failed.length > 0) {
      logger.error({ failed: result.failed }, 'APNs push failed');
      return false;
    }
    logger.info({ requestId: payload.requestId }, 'APNs push sent');
    return true;
  } catch (err) {
    logger.error({ err }, 'APNs send error');
    return false;
  }
}
