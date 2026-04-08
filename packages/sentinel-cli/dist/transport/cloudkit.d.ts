import type { Transport, ApprovalPayload } from './interface';
/**
 * CloudKit transport — uses CloudKit Web Services REST API.
 *
 * Mac writes ApprovalRequest records, polls for Decision records.
 * iOS writes Decision records via CKDatabase on-device.
 *
 * Env vars: CLOUDKIT_CONTAINER, CLOUDKIT_API_TOKEN, CLOUDKIT_ENVIRONMENT
 */
export declare class CloudKitTransport implements Transport {
    readonly mode: "cloudkit";
    private container;
    private apiToken;
    private environment;
    private baseURL;
    private pollTimer;
    private decisionCb;
    private knownDecisions;
    private _connected;
    constructor();
    get isConnected(): boolean;
    start(): Promise<void>;
    sendApprovalRequest(payload: ApprovalPayload): Promise<string>;
    onDecision(cb: (id: string, action: 'allowed' | 'blocked' | 'timeout') => void): void;
    stop(): void;
    private pollDecisions;
    private query;
    private saveRecord;
    private updateRecordField;
}
