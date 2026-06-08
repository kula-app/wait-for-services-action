import { checkHttp } from '../shared/http';
import { ServiceCheckInputs } from '../shared/types';

export async function checkHttpService(inputs: ServiceCheckInputs): Promise<void> {
  const scheme = inputs.scheme ?? 'http';
  const path = inputs.path ?? '/';
  const method = inputs.method ?? 'GET';
  const expectedStatus = inputs.expectedStatus ?? '200';
  const url = `${scheme}://${inputs.host}:${inputs.port}${path}`;
  await checkHttp(url, method, expectedStatus, 5000);
}
