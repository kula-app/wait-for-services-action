import { Kafka } from 'kafkajs';
import { ServiceCheckInputs } from '../shared/types';

export async function checkKafka(inputs: ServiceCheckInputs): Promise<void> {
  const kafka = new Kafka({
    clientId: 'wait-for-services-action',
    brokers: [`${inputs.host}:${inputs.port}`],
    connectionTimeout: 5000,
    requestTimeout: 5000,
  });

  const admin = kafka.admin();
  try {
    await admin.connect();
    await admin.listTopics();
  } finally {
    await admin.disconnect();
  }
}
