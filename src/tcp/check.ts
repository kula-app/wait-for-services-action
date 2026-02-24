import { checkTcp } from '../shared/tcp';
import { ServiceCheckInputs } from '../shared/types';

export async function checkTcpService(inputs: ServiceCheckInputs): Promise<void> {
  await checkTcp(inputs.host, inputs.port, 5000);
}
