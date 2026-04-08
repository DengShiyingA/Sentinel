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

  start(): Promise<void>;
  sendApprovalRequest(payload: ApprovalPayload): Promise<string>;
  onDecision(cb: (requestId: string, action: 'allowed' | 'blocked' | 'timeout') => void): void;
  stop(): void;

  /** Send fire-and-forget event to iOS (terminal, activity, notification) */
  sendEvent?(data: Record<string, unknown>): void;
  sendNotification?(title: string, message: string): void;
}

/** Global transport instance — set by start command */
let _transport: Transport | null = null;

export function setTransport(t: Transport): void { _transport = t; }
export function getTransport(): Transport | null { return _transport; }
