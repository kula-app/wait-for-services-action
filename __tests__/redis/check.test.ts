import { vi, describe, it, expect, beforeEach } from 'vitest';
import { checkRedis } from '../../src/redis/check';
import { ServiceCheckInputs } from '../../src/shared/types';

const mockConnect = vi.fn();
const mockPing = vi.fn();
const mockDisconnect = vi.fn();
let lastConstructorArgs: unknown[] = [];

vi.mock('ioredis', () => ({
  default: class MockRedis {
    connect = mockConnect;
    ping = mockPing;
    disconnect = mockDisconnect;
    constructor(...args: unknown[]) {
      lastConstructorArgs = args;
    }
  },
}));

const inputs: ServiceCheckInputs = {
  host: 'localhost',
  port: 6379,
  timeout: 20,
  interval: 1,
  waitIndefinitely: false,
};

describe('checkRedis', () => {
  beforeEach(() => {
    mockConnect.mockReset();
    mockPing.mockReset();
    mockDisconnect.mockReset();
    lastConstructorArgs = [];
  });

  it('should resolve when PING returns PONG', async () => {
    mockConnect.mockResolvedValue(undefined);
    mockPing.mockResolvedValue('PONG');

    await expect(checkRedis(inputs)).resolves.toBeUndefined();
    expect(mockDisconnect).toHaveBeenCalled();
  });

  it('should throw when PING returns unexpected response', async () => {
    mockConnect.mockResolvedValue(undefined);
    mockPing.mockResolvedValue('ERROR');

    await expect(checkRedis(inputs)).rejects.toThrow('unexpected response');
  });

  it('should throw when connect fails', async () => {
    mockConnect.mockRejectedValue(new Error('Connection refused'));

    await expect(checkRedis(inputs)).rejects.toThrow('Connection refused');
  });

  it('should pass password when provided', async () => {
    mockConnect.mockResolvedValue(undefined);
    mockPing.mockResolvedValue('PONG');

    await checkRedis({ ...inputs, password: 'secret' });

    expect(lastConstructorArgs[0]).toEqual(expect.objectContaining({ password: 'secret' }));
  });
});
