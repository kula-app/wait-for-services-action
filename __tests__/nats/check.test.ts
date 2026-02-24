import { vi, describe, it, expect, beforeEach } from 'vitest';
import { checkNats } from '../../src/nats/check';
import { ServiceCheckInputs } from '../../src/shared/types';

const mockFlush = vi.fn();
const mockClose = vi.fn();
const mockConnect = vi.fn();

vi.mock('nats', () => ({
  connect: (...args: unknown[]) => mockConnect(...args),
}));

const inputs: ServiceCheckInputs = {
  host: 'localhost',
  port: 4222,
  timeout: 20,
  interval: 1,
  waitIndefinitely: false,
};

describe('checkNats', () => {
  beforeEach(() => {
    mockConnect.mockReset();
    mockFlush.mockReset();
    mockClose.mockReset();
    mockConnect.mockResolvedValue({ flush: mockFlush, close: mockClose });
  });

  it('should resolve when connect and flush succeed', async () => {
    mockFlush.mockResolvedValue(undefined);
    mockClose.mockResolvedValue(undefined);

    await expect(checkNats(inputs)).resolves.toBeUndefined();
    expect(mockConnect).toHaveBeenCalledWith(expect.objectContaining({ servers: 'localhost:4222' }));
    expect(mockClose).toHaveBeenCalled();
  });

  it('should throw when connect fails', async () => {
    mockConnect.mockRejectedValue(new Error('Connection refused'));

    await expect(checkNats(inputs)).rejects.toThrow('Connection refused');
  });

  it('should throw when flush fails', async () => {
    mockFlush.mockRejectedValue(new Error('flush timeout'));
    mockClose.mockResolvedValue(undefined);

    await expect(checkNats(inputs)).rejects.toThrow('flush timeout');
  });
});
