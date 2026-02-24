import * as core from '@actions/core';
import { ServiceCheckInputs, CheckFunction } from './types';

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function waitForService(inputs: ServiceCheckInputs, check: CheckFunction): Promise<void> {
  const startTime = Date.now();
  const timeoutMs = inputs.timeout * 1000;
  let lastError: Error | undefined;

  core.startGroup(`Waiting for service at ${inputs.host}:${inputs.port}`);
  core.info(
    `Timeout: ${inputs.timeout}s | Interval: ${inputs.interval}s | Wait indefinitely: ${inputs.waitIndefinitely}`,
  );

  try {
    while (true) {
      try {
        await check(inputs);
        core.info('Service is ready!');
        return;
      } catch (err) {
        lastError = err instanceof Error ? err : new Error(String(err));
        core.debug(`Check failed: ${lastError.message}`);
      }

      const elapsed = Date.now() - startTime;
      if (!inputs.waitIndefinitely && elapsed >= timeoutMs) {
        throw new Error(
          `Service at ${inputs.host}:${inputs.port} did not become ready within ${inputs.timeout} seconds. Last error: ${lastError?.message}`,
        );
      }

      const elapsedSec = Math.floor(elapsed / 1000);
      if (elapsedSec > 0 && elapsedSec % 5 === 0) {
        core.info(`Still waiting... (${elapsedSec}s elapsed)`);
      }

      await sleep(inputs.interval * 1000);
    }
  } finally {
    core.endGroup();
  }
}
