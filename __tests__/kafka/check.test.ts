import { vi, describe, it, expect, beforeEach } from 'vitest';
import { checkKafka } from '../../src/kafka/check';
import { ServiceCheckInputs } from '../../src/shared/types';

const mockAdminConnect = vi.fn();
const mockListTopics = vi.fn();
const mockAdminDisconnect = vi.fn();

vi.mock('kafkajs', () => ({
  Kafka: class MockKafka {
    admin() {
      return {
        connect: mockAdminConnect,
        listTopics: mockListTopics,
        disconnect: mockAdminDisconnect,
      };
    }
  },
}));

const inputs: ServiceCheckInputs = {
  host: 'localhost',
  port: 9092,
  timeout: 20,
  interval: 1,
  waitIndefinitely: false,
};

describe('checkKafka', () => {
  beforeEach(() => {
    mockAdminConnect.mockReset();
    mockListTopics.mockReset();
    mockAdminDisconnect.mockReset();
  });

  it('should resolve when admin connect and listTopics succeed', async () => {
    mockAdminConnect.mockResolvedValue(undefined);
    mockListTopics.mockResolvedValue(['topic1']);
    mockAdminDisconnect.mockResolvedValue(undefined);

    await expect(checkKafka(inputs)).resolves.toBeUndefined();
    expect(mockAdminDisconnect).toHaveBeenCalled();
  });

  it('should throw when admin connect fails', async () => {
    mockAdminConnect.mockRejectedValue(new Error('Connection refused'));
    mockAdminDisconnect.mockResolvedValue(undefined);

    await expect(checkKafka(inputs)).rejects.toThrow('Connection refused');
  });

  it('should throw when listTopics fails', async () => {
    mockAdminConnect.mockResolvedValue(undefined);
    mockListTopics.mockRejectedValue(new Error('Not authorized'));
    mockAdminDisconnect.mockResolvedValue(undefined);

    await expect(checkKafka(inputs)).rejects.toThrow('Not authorized');
  });
});
