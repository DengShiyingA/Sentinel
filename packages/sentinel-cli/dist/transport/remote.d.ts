import type { Transport, ApprovalPayload } from './interface';
/**
 * Remote transport — wraps existing Socket.IO client for server-relay mode.
 */
export declare class RemoteTransport implements Transport {
    private serverURL;
    private token;
    readonly mode: "server";
    private socket;
    private decisionCb;
    constructor(serverURL: string, token: string);
    get isConnected(): boolean;
    start(): Promise<void>;
    sendApprovalRequest(payload: ApprovalPayload): Promise<string>;
    onDecision(cb: (id: string, action: 'allowed' | 'blocked' | 'timeout') => void): void;
    stop(): void;
}
