import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import {
  catalogHash,
  classifyProfile,
  profileResetPatch,
  validateCatalog,
} from '../pcm_catalog_logic.mjs';

const payload = JSON.parse(
  readFileSync(new URL('../../assets/data/pcm_catalog.json', import.meta.url)),
);

test('canonical payload has 50 structures and 12 sites', () => {
  const catalog = validateCatalog(payload);

  assert.equal(catalog.structures.length, 50);
  assert.equal(new Set(catalog.structures.map((row) => row.siteId)).size, 12);
});

test('validation rejects duplicate ids and malformed coordinates', () => {
  const duplicate = structuredClone(payload);
  duplicate.structures[1].id = duplicate.structures[0].id;
  const invalidCoordinate = structuredClone(payload);
  invalidCoordinate.structures[0].latitude = 120;

  assert.throws(() => validateCatalog(duplicate), /duplicato/i);
  assert.throws(() => validateCatalog(invalidCoordinate), /latitudine/i);
});

test('hash is stable across object key order and ignores updatedAt', () => {
  const reordered = {
    structures: payload.structures,
    updatedAt: 'server value',
    source: payload.source,
    version: payload.version,
  };

  assert.equal(catalogHash(payload), catalogHash(reordered));
});

test('profile classification preserves exact canonical structures', () => {
  const validNames = new Set(payload.structures.map((row) => row.name));

  assert.equal(
    classifyProfile(
      {
        dipartimento: 'Dipartimento per le politiche antidroga',
        sedeId: 'legacy-office-id',
      },
      validNames,
    ),
    'valid',
  );
});

test('profile classification clears unknown values and skips empty profiles', () => {
  const validNames = new Set(payload.structures.map((row) => row.name));

  assert.equal(
    classifyProfile(
      { dipartimento: 'Struttura rimossa', sede: 'Vecchia sede' },
      validNames,
    ),
    'clear',
  );
  assert.equal(
    classifyProfile(
      {
        dipartimento: '',
        sede: '',
        sedeId: '',
        sedeAddress: '',
      },
      validNames,
    ),
    'alreadyEmpty',
  );
});

test('reset patch clears strings and delegates coordinate deletion', () => {
  const deleted = Symbol('delete');

  assert.deepEqual(profileResetPatch(deleted), {
    dipartimento: '',
    sede: '',
    sedeId: '',
    sedeAddress: '',
    sedeLat: deleted,
    sedeLng: deleted,
  });
});
