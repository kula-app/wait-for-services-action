import { vi, describe, it, expect, beforeEach } from 'vitest';
import * as core from '@actions/core';
import { waitForService } from '../../src/shared/wait';
import { ServiceCheckInputs } from '../../src/shared/types';

vi.mock('@actions/core');

describe('waitForService', () => {
  const baseInputs: ServiceCheckInputs = {
    host: 'localhost',
    port: 5432,
    timeout: 5,
    interval: 0.1,
    waitIndefinitely: false,
  };

  beforeEach(() => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
  });

  it('should resolve immediately when check succeeds on first try', async () => {
    const check = vi.fn().mockResolvedValue(undefined);

    await waitForService(baseInputs, check);

    expect(check).toHaveBeenCalledTimes(1);
    expect(core.startGroup).toHaveBeenCalled();
    expect(core.endGroup).toHaveBeenCalled();
  });

  it('should retry and resolve when check eventually succeeds', async () => {
    const check = vi
      .fn()
      .mockRejectedValueOnce(new Error('not ready'))
      .mockRejectedValueOnce(new Error('not ready'))
      .mockResolvedValue(undefined);

    await waitForService(baseInputs, check);

    expect(check).toHaveBeenCalledTimes(3);
  });

  it('should throw after timeout when check keeps failing', async () => {
    const check = vi.fn().mockRejectedValue(new Error('not ready'));

    const inputs = { ...baseInputs, timeout: 1, interval: 0.1 };

    await expect(waitForService(inputs, check)).rejects.toThrow('did not become ready within 1 seconds');
  });
});
