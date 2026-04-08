"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CloudKitTransport = void 0;
const crypto_1 = require("crypto");
const pending_1 = require("../relay/pending");
const logger_1 = require("../lib/logger");
const POLL_INTERVAL = 2000;
/**
 * CloudKit transport — uses CloudKit Web Services REST API.
 *
 * Mac writes ApprovalRequest records, polls for Decision records.
 * iOS writes Decision records via CKDatabase on-device.
 *
 * Env vars: CLOUDKIT_CONTAINER, CLOUDKIT_API_TOKEN, CLOUDKIT_ENVIRONMENT
 */
class CloudKitTransport {
    mode = 'cloudkit';
    container;
    apiToken;
    environment;
    baseURL;
    pollTimer = null;
    decisionCb = null;
    knownDecisions = new Set();
    _connected = false;
    constructor() {
        this.container = process.env.CLOUDKIT_CONTAINER ?? '';
        this.apiToken = process.env.CLOUDKIT_API_TOKEN ?? '';
        this.environment = process.env.CLOUDKIT_ENVIRONMENT ?? 'development';
        this.baseURL = `https://api.apple-cloudkit.com/database/1/${this.container}/${this.environment}/private`;
    }
    get isConnected() {
        return this._connected;
    }
    async start() {
        if (!this.container || !this.apiToken) {
            throw new Error('CloudKit requires CLOUDKIT_CONTAINER and CLOUDKIT_API_TOKEN env vars');
        }
        // Verify connectivity
        try {
            await this.query('Decisions', [], 1);
            this._connected = true;
            logger_1.log.success('[cloudkit] Connected to CloudKit');
        }
        catch (err) {
            logger_1.log.warn(`[cloudkit] Initial query failed, will retry: ${err.message}`);
            this._connected = true; // optimistic — polling will catch errors
        }
        // Start polling for decisions
        this.pollTimer = setInterval(() => this.pollDecisions(), POLL_INTERVAL);
        logger_1.log.info(`[cloudkit] Polling every ${POLL_INTERVAL / 1000}s for decisions`);
    }
    async sendApprovalRequest(payload) {
        const requestId = (0, crypto_1.randomBytes)(12).toString('hex');
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
        logger_1.log.info(`[cloudkit] Approval request saved: ${requestId}`);
        return requestId;
    }
    onDecision(cb) {
        this.decisionCb = cb;
    }
    stop() {
        if (this.pollTimer) {
            clearInterval(this.pollTimer);
            this.pollTimer = null;
        }
        this._connected = false;
    }
    // ==================== CloudKit REST ====================
    async pollDecisions() {
        try {
            const results = await this.query('Decision', [
                { fieldName: 'status', comparator: 'EQUALS', fieldValue: { value: 'new' } },
            ], 20);
            for (const record of results) {
                const requestId = record.fields?.requestId?.value;
                const action = record.fields?.action?.value;
                if (!requestId || !action)
                    continue;
                if (this.knownDecisions.has(record.recordName))
                    continue;
                this.knownDecisions.add(record.recordName);
                const mapped = action === 'allow' ? 'allowed' : action === 'block' ? 'blocked' : action;
                logger_1.log.info(`[cloudkit] Decision: ${requestId} → ${mapped}`);
                pending_1.pending.resolve(requestId, mapped);
                this.decisionCb?.(requestId, mapped);
                // Mark as processed
                await this.updateRecordField(record.recordName, 'Decision', 'status', 'processed');
            }
        }
        catch (err) {
            logger_1.log.debug(`[cloudkit] Poll error: ${err.message}`);
        }
    }
    async query(recordType, filters, limit) {
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
        if (!res.ok)
            throw new Error(`CloudKit query failed: ${res.status}`);
        const json = (await res.json());
        return json.records ?? [];
    }
    async saveRecord(record) {
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
        if (!res.ok)
            throw new Error(`CloudKit save failed: ${res.status}`);
    }
    async updateRecordField(recordName, recordType, field, value) {
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
        }).catch(() => { }); // best-effort
    }
}
exports.CloudKitTransport = CloudKitTransport;
//# sourceMappingURL=cloudkit.js.map