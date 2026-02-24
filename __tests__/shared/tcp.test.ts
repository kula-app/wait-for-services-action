import { describe, it, expect } from 'vitest';
import { checkTcp } from '../../src/shared/tcp';

describe('checkTcp', () => {
  it('should resolve when connection succeeds', async () => {
    const { createServer } = await import('node:net');
    const server = createServer();
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
    const addr = server.address();
    const port = typeof addr === 'object' && addr ? addr.port : 0;

    try {
      await expect(checkTcp('127.0.0.1', port)).resolves.toBeUndefined();
    } finally {
      server.close();
    }
  });

  it('should reject when connection fails', async () => {
    // Port 1 is almost certainly not listening
    await expect(checkTcp('127.0.0.1', 1, 500)).rejects.toThrow();
  });

  it('should reject on timeout', async () => {
    // Use a non-routable address to trigger timeout
    await expect(checkTcp('10.255.255.1', 80, 500)).rejects.toThrow();
  });
});
