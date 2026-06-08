import { build } from 'esbuild';
import { existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

const services = ['tcp', 'http', 'mongodb', 'redis', 'nats', 'kafka', 'postgres'];

for (const service of services) {
  const entry = resolve(root, 'src', service, 'index.ts');
  if (!existsSync(entry)) {
    console.error(`Entry point not found: ${entry}`);
    process.exit(1);
  }

  const outfile = resolve(root, service, 'dist', 'index.js');
  console.log(`Building ${service}...`);
  await build({
    entryPoints: [entry],
    outfile,
    bundle: true,
    platform: 'node',
    target: 'node20',
    format: 'cjs',
    sourcemap: true,
    legalComments: 'external',
  });
  console.log(`  -> ${service}/dist/index.js`);
}

console.log('\nAll services built successfully.');
