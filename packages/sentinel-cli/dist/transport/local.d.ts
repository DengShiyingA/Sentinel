import type { Transport, ApprovalPayload } from './interface';
/**
 * Local transport — TCP server + Bonjour (mDNS) for LAN-direct mode.
 *
 * - Opens a TCP server on port 7750
 * - Publishes _sentinel._tcp via Bonjour so iOS can auto-discover
 * - iOS connects directly, same JSON message format as remote mode
 * - Messages are newline-delimited JSON over raw TCP
 */
export declare class LocalTransport implements Transport {
    readonly mode: "local";
    private server;
    private bonjour;
    private iosSocket;
    private buffer;
    private decisionCb;
    get isConnected(): boolean;
    start(): Promise<void>;
    private publishBonjour;
    /** Process newline-delimited JSON from buffer */
    private processBuffer;
    private handleMessage;
    /** Send a JSON message to connected iOS */
    private send;
    sendApprovalRequest(payload: ApprovalPayload): Promise<string>;
    onDecision(cb: (id: string, action: 'allowed' | 'blocked' | 'timeout') => void): void;
    stop(): void;
    /** Get info for pairing display */
    getConnectionInfo(): {
        ip: string;
        port: number;
    };
}
