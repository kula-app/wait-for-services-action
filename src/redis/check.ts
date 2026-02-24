import Redis from 'ioredis';
import { ServiceCheckInputs } from '../shared/types';

export async function checkRedis(inputs: ServiceCheckInputs): Promise<void> {
  const redis = new Redis({
    host: inputs.host,
    port: inputs.port,
    password: inputs.password,
    connectTimeout: 5000,
    maxRetriesPerRequest: 0,
    retryStrategy: () => null,
    lazyConnect: true,
  });

  try {
    await redis.connect();
    const result = await redis.ping();
    if (result !== 'PONG') {
      throw new Error(`Redis PING returned unexpected response: ${result}`);
    }
  } finally {
    await redis.disconnect();
  }
}
