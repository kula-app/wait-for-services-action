import { vi, describe, it, expect, beforeEach } from 'vitest';
import { checkPostgres } from '../../src/postgres/check';
import { ServiceCheckInputs } from '../../src/shared/types';

const mockClientConnect = vi.fn();
const mockQuery = vi.fn();
const mockEnd = vi.fn();
let lastConstructorArgs: unknown[] = [];

vi.mock('pg', () => ({
  Client: class MockClient {
    connect = mockClientConnect;
    query = mockQuery;
    end = mockEnd;
    constructor(...args: unknown[]) {
      lastConstructorArgs = args;
    }
  },
}));

const inputs: ServiceCheckInputs = {
  host: 'localhost',
  port: 5432,
  timeout: 20,
  interval: 1,
  waitIndefinitely: false,
  username: 'postgres',
  password: 'postgres',
  database: 'testdb',
};

describe('checkPostgres', () => {
  beforeEach(() => {
    mockClientConnect.mockReset();
    mockQuery.mockReset();
    mockEnd.mockReset();
    lastConstructorArgs = [];
  });

  it('should resolve when connect and SELECT 1 succeed', async () => {
    mockClientConnect.mockResolvedValue(undefined);
    mockQuery.mockResolvedValue({ rows: [{ '?column?': 1 }] });
    mockEnd.mockResolvedValue(undefined);

    await expect(checkPostgres(inputs)).resolves.toBeUndefined();
    expect(mockQuery).toHaveBeenCalledWith('SELECT 1');
    expect(mockEnd).toHaveBeenCalled();
  });

  it('should throw when connect fails', async () => {
    mockClientConnect.mockRejectedValue(new Error('Connection refused'));
    mockEnd.mockResolvedValue(undefined);

    await expect(checkPostgres(inputs)).rejects.toThrow('Connection refused');
  });

  it('should throw when query fails', async () => {
    mockClientConnect.mockResolvedValue(undefined);
    mockQuery.mockRejectedValue(new Error('Query timeout'));
    mockEnd.mockResolvedValue(undefined);

    await expect(checkPostgres(inputs)).rejects.toThrow('Query timeout');
  });

  it('should pass credentials to client', async () => {
    mockClientConnect.mockResolvedValue(undefined);
    mockQuery.mockResolvedValue({ rows: [] });
    mockEnd.mockResolvedValue(undefined);

    await checkPostgres(inputs);

    expect(lastConstructorArgs[0]).toEqual(
      expect.objectContaining({
        host: 'localhost',
        port: 5432,
        user: 'postgres',
        password: 'postgres',
        database: 'testdb',
      }),
    );
  });
});
