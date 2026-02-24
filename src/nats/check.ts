import { connect } from 'nats';
import { ServiceCheckInputs } from '../shared/types';

export async function checkNats(inputs: ServiceCheckInputs): Promise<void> {
  const nc = await connect({
    servers: `${inputs.host}:${inputs.port}`,
    timeout: 5000,
    maxReconnectAttempts: 0,
  });

  try {
    await nc.flush();
  } finally {
    await nc.close();
  }
}
