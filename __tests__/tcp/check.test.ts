import { describe, it, expect } from 'vitest';
import { checkTcpService } from '../../src/tcp/check';
import { ServiceCheckInputs } from '../../src/shared/types';

describe('checkTcpService', () => {
  it('should resolve when port is reachable', async () => {
    const { createServer } = await import('node:net');
    const server = createServer();
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
    const addr = server.address();
    const port = typeof addr === 'object' && addr ? addr.port : 0;

    const inputs: ServiceCheckInputs = {
      host: '127.0.0.1',
      port,
      timeout: 5,
      interval: 1,
      waitIndefinitely: false,
    };

    try {
      await expect(checkTcpService(inputs)).resolves.toBeUndefined();
    } finally {
      server.close();
    }
  });

  it('should reject when port is not reachable', async () => {
    const inputs: ServiceCheckInputs = {
      host: '127.0.0.1',
      port: 1,
      timeout: 5,
      interval: 1,
      waitIndefinitely: false,
    };

    await expect(checkTcpService(inputs)).rejects.toThrow();
  });
});
