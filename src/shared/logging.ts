import * as core from '@actions/core';
import { ServiceCheckInputs } from './types';

export function logConfiguration(serviceName: string, inputs: ServiceCheckInputs): void {
  core.startGroup('Service readiness check configuration');
  core.info(`Service type: ${serviceName}`);
  core.info(`Host: ${inputs.host}`);
  core.info(`Port: ${inputs.port}`);
  core.info(`Timeout: ${inputs.timeout} seconds`);
  core.info(`Check interval: ${inputs.interval} seconds`);
  core.info(`Wait indefinitely: ${inputs.waitIndefinitely}`);
  if (inputs.username) {
    core.info(`Username: ${inputs.username}`);
  }
  if (inputs.database) {
    core.info(`Database: ${inputs.database}`);
  }
  core.endGroup();
}

export function logSuccess(serviceName: string, inputs: ServiceCheckInputs): void {
  core.startGroup('Service status check summary');
  core.info(`Service type: ${serviceName}`);
  core.info(`Host: ${inputs.host}`);
  core.info(`Port: ${inputs.port}`);
  core.info('Status: READY');
  core.endGroup();
}

export function logFailure(serviceName: string, inputs: ServiceCheckInputs, error: string): void {
  core.startGroup('Service status check summary');
  core.info(`Service type: ${serviceName}`);
  core.info(`Host: ${inputs.host}`);
  core.info(`Port: ${inputs.port}`);
  core.info('Status: FAILED');
  core.info(`Last error: ${error}`);
  core.endGroup();
}
