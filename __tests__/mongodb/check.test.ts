import { vi, describe, it, expect, beforeEach } from 'vitest';
import { checkMongodb } from '../../src/mongodb/check';
import { ServiceCheckInputs } from '../../src/shared/types';

const mockCommand = vi.fn();
const mockConnect = vi.fn();
const mockClose = vi.fn();

vi.mock('mongodb', () => ({
  MongoClient: class {
    connect = mockConnect;
    db = () => ({ command: mockCommand });
    close = mockClose;
  },
}));

const inputs: ServiceCheckInputs = {
  host: 'localhost',
  port: 27017,
  timeout: 20,
  interval: 1,
  waitIndefinitely: false,
};

describe('checkMongodb', () => {
  beforeEach(() => {
    mockConnect.mockReset();
    mockCommand.mockReset();
    mockClose.mockReset();
  });

  it('should resolve when ping returns ok: 1', async () => {
    mockConnect.mockResolvedValue(undefined);
    mockCommand.mockResolvedValue({ ok: 1 });
    mockClose.mockResolvedValue(undefined);

    await expect(checkMongodb(inputs)).resolves.toBeUndefined();
    expect(mockCommand).toHaveBeenCalledWith({ ping: 1 });
  });

  it('should throw when ping returns ok: 0', async () => {
    mockConnect.mockResolvedValue(undefined);
    mockCommand.mockResolvedValue({ ok: 0 });
    mockClose.mockResolvedValue(undefined);

    await expect(checkMongodb(inputs)).rejects.toThrow('ping returned ok=0');
  });

  it('should throw when connect fails', async () => {
    mockConnect.mockRejectedValue(new Error('Connection refused'));
    mockClose.mockResolvedValue(undefined);

    await expect(checkMongodb(inputs)).rejects.toThrow('Connection refused');
  });

  it('should always close the client', async () => {
    mockConnect.mockRejectedValue(new Error('fail'));
    mockClose.mockResolvedValue(undefined);

    await expect(checkMongodb(inputs)).rejects.toThrow();
    expect(mockClose).toHaveBeenCalled();
  });
});
