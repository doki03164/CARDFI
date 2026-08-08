import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const blueprintPath = resolve(root, 'contracts', 'plutus.json');
const manifestPath = resolve(root, 'deploy', 'preprod.manifest.json');

const blueprintText = await readFile(blueprintPath, 'utf8');
const blueprint = JSON.parse(blueprintText);
const validators = [];
const seen = new Set();

for (const validator of blueprint.validators) {
  if (seen.has(validator.hash)) continue;
  seen.add(validator.hash);
  validators.push({
    title: validator.title,
    hash: validator.hash,
    compiledCodeBytes: validator.compiledCode.length / 2,
    parameters: validator.parameters.map((parameter) => ({
      name: parameter.title,
      schema: parameter.schema.$ref ?? parameter.schema,
      value: `<${parameter.title.toUpperCase()}_CBOR>`,
    })),
  });
}

const manifest = {
  schemaVersion: 1,
  network: { name: 'preprod', networkMagic: 1 },
  status: 'parameterization-required',
  blueprint: {
    path: 'contracts/plutus.json',
    sha256: createHash('sha256').update(blueprintText).digest('hex'),
    plutusVersion: blueprint.preamble.plutusVersion,
    compiler: blueprint.preamble.compiler,
  },
  validators,
};

const rendered = `${JSON.stringify(manifest, null, 2)}\n`;
if (process.argv.includes('--check')) {
  const current = await readFile(manifestPath, 'utf8').catch(() => '');
  if (current !== rendered) {
    console.error('Preprod manifest is stale. Run: npm run deploy:manifest');
    process.exit(1);
  }
  console.log(`OK: ${validators.length} validator manifests match the CIP-57 blueprint`);
} else {
  await mkdir(dirname(manifestPath), { recursive: true });
  await writeFile(manifestPath, rendered, 'utf8');
  console.log(`Wrote ${manifestPath} with ${validators.length} validators`);
}
