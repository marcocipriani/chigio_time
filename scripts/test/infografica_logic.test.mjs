import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '../..',
);
const source = await readFile(
  path.join(repoRoot, 'prototypes/infografica-orario-pcm.src.html'),
  'utf8',
);

test('il simulatore include i permessi nella copertura del saldo', () => {
  assert.match(source, /var copertura = netto \+ permessi;/);
  assert.match(source, /var saldo = copertura - standard;/);
  assert.doesNotMatch(source, /var saldo = netto - standard;/);
});
