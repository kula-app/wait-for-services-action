import * as core from '@actions/core';
import { parseInputs } from '../shared/inputs';
import { logConfiguration, logSuccess, logFailure } from '../shared/logging';
import { waitForService } from '../shared/wait';
import { checkMongodb } from './check';

async function run(): Promise<void> {
  try {
    const inputs = parseInputs();
    logConfiguration('mongodb', inputs);
    await waitForService(inputs, checkMongodb);
    logSuccess('mongodb', inputs);
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
      logFailure('mongodb', inputs, message);
    }
    core.setFailed(message);
  }
}

run();
