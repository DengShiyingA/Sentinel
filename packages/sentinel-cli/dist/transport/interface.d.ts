/**
 * Transport interface — abstracts local (TCP) vs remote (Socket.IO) communication.
 * Both modes use the same message format for approval_request / decision.
 */
export type TransportMode = 'local' | 'cloudkit' | 'server';
export interface ApprovalPayload {
    toolName: string;
    toolInput: Record<string, unknown>;
    riskLevel: string;
}
export interface Transport {
    readonly mode: TransportMode;
    readonly isConnected: boolean;
    /** Start the transport (connect or listen) */
    start(): Promise<void>;
    /** Send an approval request, returns requestId */
    sendApprovalRequest(payload: ApprovalPayload): Promise<string>;
    /** Register callback for decision events */
    onDecision(cb: (requestId: string, action: 'allowed' | 'blocked' | 'timeout') => void): void;
    /** Shut down */
    stop(): void;
}
export declare function setTransport(t: Transport): void;
export declare function getTransport(): Transport | null;
