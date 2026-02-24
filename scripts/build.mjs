import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

const services = ['tcp', 'mongodb', 'redis', 'nats', 'kafka', 'postgres'];

for (const service of services) {
  const entry = resolve(root, 'src', service, 'index.ts');
  if (!existsSync(entry)) {
    console.error(`Entry point not found: ${entry}`);
    process.exit(1);
  }

  const outDir = resolve(root, service, 'dist');
  console.log(`Building ${service}...`);
  execSync(`ncc build ${entry} -o ${outDir} --source-map --license licenses.txt`, {
    cwd: root,
    stdio: 'inherit',
  });
  console.log(`  -> ${service}/dist/index.js`);
}

console.log('\nAll services built successfully.');
