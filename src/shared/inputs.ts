import * as core from '@actions/core';
import { ServiceCheckInputs } from './types';

export function parseInputs(): ServiceCheckInputs {
  const host = core.getInput('host', { required: true });
  const port = parseInt(core.getInput('port', { required: true }), 10);
  const timeout = parseInt(core.getInput('timeout') || '20', 10);
  const interval = parseInt(core.getInput('interval') || '1', 10);
  const waitIndefinitely = core.getInput('wait-indefinitely') === 'true';
  const username = core.getInput('username') || undefined;
  const password = core.getInput('password') || undefined;
  const database = core.getInput('database') || undefined;

  if (isNaN(port)) {
    throw new Error(`Invalid port value: ${core.getInput('port')}`);
  }
  if (isNaN(timeout) || timeout <= 0) {
    throw new Error(`Invalid timeout value: ${core.getInput('timeout')}. Must be a positive number.`);
  }
  if (isNaN(interval) || interval <= 0) {
    throw new Error(`Invalid interval value: ${core.getInput('interval')}. Must be a positive number.`);
  }

  return { host, port, timeout, interval, waitIndefinitely, username, password, database };
}
