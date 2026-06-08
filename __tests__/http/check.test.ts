import { describe, it, expect, afterEach } from 'vitest';
import { createServer, Server } from 'node:http';
import { AddressInfo } from 'node:net';
import { checkHttpService } from '../../src/http/check';
import { ServiceCheckInputs } from '../../src/shared/types';

let server: Server | undefined;

async function startServer(handler: (method: string) => { status: number; location?: string }): Promise<number> {
  server = createServer((req, res) => {
    const { status, location } = handler(req.method ?? 'GET');
    if (location) {
      res.setHeader('Location', location);
    }
    res.statusCode = status;
    res.end();
  });
  await new Promise<void>((resolve) => server!.listen(0, '127.0.0.1', resolve));
  return (server!.address() as AddressInfo).port;
}

function baseInputs(port: number, overrides: Partial<ServiceCheckInputs> = {}): ServiceCheckInputs {
  return {
    host: '127.0.0.1',
    port,
    timeout: 5,
    interval: 1,
    waitIndefinitely: false,
    scheme: 'http',
    path: '/',
    method: 'GET',
    expectedStatus: '200',
    ...overrides,
  };
}

afterEach(() => {
  server?.close();
  server = undefined;
});

describe('checkHttpService', () => {
  it('resolves when the status code matches', async () => {
    const port = await startServer(() => ({ status: 200 }));
    await expect(checkHttpService(baseInputs(port))).resolves.toBeUndefined();
  });

  it('rejects when the status code does not match', async () => {
    const port = await startServer(() => ({ status: 500 }));
    await expect(checkHttpService(baseInputs(port))).rejects.toThrow(/returned 500/);
  });

  it('resolves when the status code falls within an expected range', async () => {
    const port = await startServer(() => ({ status: 204 }));
    await expect(checkHttpService(baseInputs(port, { expectedStatus: '200-299' }))).resolves.toBeUndefined();
  });

  it('honours the configured method', async () => {
    const port = await startServer((method) => ({ status: method === 'POST' ? 201 : 405 }));
    await expect(
      checkHttpService(baseInputs(port, { method: 'POST', expectedStatus: '201' })),
    ).resolves.toBeUndefined();
  });

  it('does not follow redirects and asserts the raw status', async () => {
    const port = await startServer(() => ({ status: 302, location: '/elsewhere' }));
    // Expecting a redirect family succeeds because the redirect is not followed.
    await expect(checkHttpService(baseInputs(port, { expectedStatus: '300-399' }))).resolves.toBeUndefined();
    // Expecting 200 fails because we see the raw 302, not the redirect target.
    await expect(checkHttpService(baseInputs(port, { expectedStatus: '200' }))).rejects.toThrow(/returned 302/);
  });
});
