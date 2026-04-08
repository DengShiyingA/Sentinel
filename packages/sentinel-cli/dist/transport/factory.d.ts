import type { Transport, TransportMode } from './interface';
export interface TransportOptions {
    serverUrl?: string;
    token?: string;
}
export declare function createTransport(mode: TransportMode, opts?: TransportOptions): Transport;
