import { Client } from 'pg';
import { ServiceCheckInputs } from '../shared/types';

export async function checkPostgres(inputs: ServiceCheckInputs): Promise<void> {
  const client = new Client({
    host: inputs.host,
    port: inputs.port,
    user: inputs.username,
    password: inputs.password,
    database: inputs.database,
    connectionTimeoutMillis: 5000,
    query_timeout: 5000,
  });

  try {
    await client.connect();
    await client.query('SELECT 1');
  } finally {
    await client.end().catch(() => {});
  }
}
