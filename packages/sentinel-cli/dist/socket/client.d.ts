import { Socket } from 'socket.io-client';
/**
 * 连接 Socket.IO，带 JWT auth 和指数退避重连
 */
export declare function connectSocket(serverURL: string, token: string): Socket;
/**
 * 发送审批请求到 server，返回 requestId
 */
export declare function emitApprovalRequest(data: {
    toolName: string;
    toolInput: Record<string, unknown>;
    riskLevel: string;
}): Promise<string>;
export declare function getSocket(): Socket | null;
export declare function disconnectSocket(): void;
export declare function isConnected(): boolean;
