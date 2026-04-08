import { randomBytes } from 'crypto';
import type { Transport, ApprovalPayload } from './interface';
import { pending } from '../relay/pending';
import { log } from '../lib/logger';

const POLL_INTERVAL = 2000;

/**
 * CloudKit transport — uses CloudKit Web Services REST API.
 *
 * Mac writes ApprovalRequest records, polls for Decision records.
 * iOS writes Decision records via CKDatabase on-device.
 *
 * Env vars: CLOUDKIT_CONTAINER, CLOUDKIT_API_TOKEN, CLOUDKIT_ENVIRONMENT
 */
export class CloudKitTransport implements Transport {
  readonly mode = 'cloudkit' as const;

  private container: string;
  private apiToken: string;
  private environment: string;
  private baseURL: string;
  private pollTimer: NodeJS.Timeout | null = null;
  private decisionCb: ((id: string, action: 'allowed' | 'blocked' | 'timeout') => void) | null = null;
  private knownDecisions = new Set<string>();
  private _connected = false;

  constructor() {
    this.container = process.env.CLOUDKIT_CONTAINER ?? '';
    this.apiToken = process.env.CLOUDKIT_API_TOKEN ?? '';
    this.environment = process.env.CLOUDKIT_ENVIRONMENT ?? 'development';
    this.baseURL = `https://api.apple-cloudkit.com/database/1/${this.container}/${this.environment}/private`;
  }

  get isConnected(): boolean {
    return this._connected;
  }

  async start(): Promise<void> {
    if (!this.container || !this.apiToken) {
      throw new Error('CloudKit requires CLOUDKIT_CONTAINER and CLOUDKIT_API_TOKEN env vars');
    }

    // Verify connectivity
    try {
      await this.query('Decisions', [], 1);
      this._connected = true;
      log.success('[cloudkit] Connected to CloudKit');
    } catch (err) {
      log.warn(`[cloudkit] Initial query failed, will retry: ${(err as Error).message}`);
      this._connected = true; // optimistic — polling will catch errors
    }

    // Start polling for decisions
    this.pollTimer = setInterval(() => this.pollDecisions(), POLL_INTERVAL);
    log.info(`[cloudkit] Polling every ${POLL_INTERVAL / 1000}s for decisions`);
  }

  async sendApprovalRequest(payload: ApprovalPayload): Promise<string> {
    const requestId = randomBytes(12).toString('hex');

    const record = {
      recordType: 'ApprovalRequest',
      fields: {
        requestId: { value: requestId },
        toolName: { value: payload.toolName },
        toolInput: { value: JSON.stringify(payload.toolInput) },
        riskLevel: { value: payload.riskLevel },
        timestamp: { value: Date.now() },
        timeoutAt: { value: Date.now() + 120_000 },
        status: { value: 'pending' },
      },
    };

    await this.saveRecord(record);
    log.info(`[cloudkit] Approval request saved: ${requestId}`);
    return requestId;
  }

  onDecision(cb: (id: string, action: 'allowed' | 'blocked' | 'timeout') => void): void {
    this.decisionCb = cb;
  }

  stop(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
    this._connected = false;
  }

  // ==================== CloudKit REST ====================

  private async pollDecisions(): Promise<void> {
    try {
      const results = await this.query('Decision', [
        { fieldName: 'status', comparator: 'EQUALS', fieldValue: { value: 'new' } },
      ], 20);

      for (const record of results) {
        const requestId = record.fields?.requestId?.value as string;
        const action = record.fields?.action?.value as string;

        if (!requestId || !action) continue;
        if (this.knownDecisions.has(record.recordName)) continue;

        this.knownDecisions.add(record.recordName);

        const mapped = action === 'allow' ? 'allowed' : action === 'block' ? 'blocked' : action;
        log.info(`[cloudkit] Decision: ${requestId} → ${mapped}`);
        pending.resolve(requestId, mapped as any);
        this.decisionCb?.(requestId, mapped as any);

        // Mark as processed
        await this.updateRecordField(record.recordName, 'Decision', 'status', 'processed');
      }
    } catch (err) {
      log.debug(`[cloudkit] Poll error: ${(err as Error).message}`);
    }
  }

  private async query(recordType: string, filters: any[], limit: number): Promise<any[]> {
    const body = {
      query: { recordType, filterBy: filters },
      resultsLimit: limit,
    };

    const res = await fetch(`${this.baseURL}/records/query`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Apple-CloudKit-Request-KeyID': this.apiToken,
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) throw new Error(`CloudKit query failed: ${res.status}`);
    const json = (await res.json()) as { records?: any[] };
    return json.records ?? [];
  }

  private async saveRecord(record: any): Promise<void> {
    const body = {
      operations: [{ operationType: 'create', record }],
    };

    const res = await fetch(`${this.baseURL}/records/modify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Apple-CloudKit-Request-KeyID': this.apiToken,
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) throw new Error(`CloudKit save failed: ${res.status}`);
  }

  private async updateRecordField(recordName: string, recordType: string, field: string, value: string): Promise<void> {
    const body = {
      operations: [{
        operationType: 'update',
        record: {
          recordName,
          recordType,
          fields: { [field]: { value } },
        },
      }],
    };

    await fetch(`${this.baseURL}/records/modify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Apple-CloudKit-Request-KeyID': this.apiToken,
      },
      body: JSON.stringify(body),
    }).catch(() => {}); // best-effort
  }
}
