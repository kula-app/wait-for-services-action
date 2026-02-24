import * as core from '@actions/core';
import { parseInputs } from '../shared/inputs';
import { logConfiguration, logSuccess, logFailure } from '../shared/logging';
import { waitForService } from '../shared/wait';
import { checkTcpService } from './check';

async function run(): Promise<void> {
  try {
    const inputs = parseInputs();
    logConfiguration('tcp', inputs);
    await waitForService(inputs, checkTcpService);
    logSuccess('tcp', inputs);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const inputs = (() => {
      try {
        return parseInputs();
      } catch {
        return undefined;
      }
    })();
    if (inputs) {
      logFailure('tcp', inputs, message);
    }
    core.setFailed(message);
  }
}

run();
