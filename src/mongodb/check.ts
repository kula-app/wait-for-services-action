import { MongoClient } from 'mongodb';
import { ServiceCheckInputs } from '../shared/types';

export async function checkMongodb(inputs: ServiceCheckInputs): Promise<void> {
  const uri = `mongodb://${inputs.host}:${inputs.port}`;
  const client = new MongoClient(uri, {
    connectTimeoutMS: 5000,
    serverSelectionTimeoutMS: 5000,
    directConnection: true,
  });

  try {
    await client.connect();
    const result = await client.db('admin').command({ ping: 1 });
    if (!result.ok) {
      throw new Error(`MongoDB ping returned ok=${result.ok}`);
    }
  } finally {
    await client.close().catch(() => {});
  }
}
