import type { Transport, TransportMode } from './interface';
import { LocalTransport } from './local';
import { RemoteTransport } from './remote';
import { CloudKitTransport } from './cloudkit';

export interface TransportOptions {
  serverUrl?: string;
  token?: string;
}

export function createTransport(mode: TransportMode, opts?: TransportOptions): Transport {
  switch (mode) {
    case 'local':
      return new LocalTransport();
    case 'cloudkit':
      return new CloudKitTransport();
    case 'server':
      if (!opts?.serverUrl || !opts?.token) {
        throw new Error('Server mode requires serverUrl and token');
      }
      return new RemoteTransport(opts.serverUrl, opts.token);
  }
}
