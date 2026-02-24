import * as net from 'node:net';

export function checkTcp(host: string, port: number, timeoutMs: number = 5000): Promise<void> {
  return new Promise((resolve, reject) => {
    const socket = new net.Socket();

    const timer = setTimeout(() => {
      socket.destroy();
      reject(new Error(`TCP connection to ${host}:${port} timed out after ${timeoutMs}ms`));
    }, timeoutMs);

    socket.connect(port, host, () => {
      clearTimeout(timer);
      socket.destroy();
      resolve();
    });

    socket.on('error', (err) => {
      clearTimeout(timer);
      socket.destroy();
      reject(new Error(`TCP connection to ${host}:${port} failed: ${err.message}`));
    });
  });
}
