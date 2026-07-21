import { createHash } from 'node:crypto';

const EXPECTED_STRUCTURES = 50;
const VERSION = /^\d{4}\.\d{2}\.\d{2}$/;
const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const CITY = /^\d{5} Roma$/;

export function validateCatalog(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('Il catalogo deve essere un oggetto.');
  }
  if (typeof value.version !== 'string' || !VERSION.test(value.version)) {
    throw new Error('Versione catalogo non valida.');
  }
  if (typeof value.source !== 'string' || value.source.trim() === '') {
    throw new Error('Sorgente catalogo obbligatoria.');
  }
  if (!Array.isArray(value.structures)) {
    throw new Error('structures deve essere una lista.');
  }
  if (value.structures.length !== EXPECTED_STRUCTURES) {
    throw new Error(
      `Il catalogo deve contenere ${EXPECTED_STRUCTURES} strutture.`,
    );
  }

  const ids = new Set();
  const names = new Set();
  const sortOrders = new Set();
  const sites = new Map();
  const requiredStrings = [
    'id',
    'name',
    'siteId',
    'siteName',
    'address',
    'city',
  ];

  for (const row of value.structures) {
    if (!row || typeof row !== 'object' || Array.isArray(row)) {
      throw new Error('Ogni struttura deve essere un oggetto.');
    }
    for (const key of requiredStrings) {
      if (typeof row[key] !== 'string' || row[key].trim() === '') {
        throw new Error(`${key} non valido per una struttura.`);
      }
    }
    if (!SLUG.test(row.id) || !SLUG.test(row.siteId)) {
      throw new Error(`ID non valido per ${row.name}.`);
    }
    if (ids.has(row.id)) throw new Error(`ID duplicato: ${row.id}.`);
    if (names.has(row.name)) throw new Error(`Nome duplicato: ${row.name}.`);
    if (!Number.isInteger(row.sortOrder)) {
      throw new Error(`sortOrder non valido per ${row.name}.`);
    }
    if (sortOrders.has(row.sortOrder)) {
      throw new Error(`sortOrder duplicato: ${row.sortOrder}.`);
    }
    if (!CITY.test(row.city)) {
      throw new Error(`CAP/città non valido per ${row.name}.`);
    }
    if (
      typeof row.latitude !== 'number' ||
      row.latitude < -90 ||
      row.latitude > 90
    ) {
      throw new Error(`Latitudine non valida per ${row.name}.`);
    }
    if (
      typeof row.longitude !== 'number' ||
      row.longitude < -180 ||
      row.longitude > 180
    ) {
      throw new Error(`Longitudine non valida per ${row.name}.`);
    }

    ids.add(row.id);
    names.add(row.name);
    sortOrders.add(row.sortOrder);
    const definition = JSON.stringify([
      row.siteName,
      row.address,
      row.city,
      row.latitude,
      row.longitude,
    ]);
    if (sites.has(row.siteId) && sites.get(row.siteId) !== definition) {
      throw new Error(`Sede incoerente: ${row.siteId}.`);
    }
    sites.set(row.siteId, definition);
  }

  return value;
}

export function catalogHash(value) {
  const catalog = validateCatalog(value);
  const payload = {
    version: catalog.version,
    source: catalog.source,
    structures: catalog.structures,
  };
  return createHash('sha256').update(stableJson(payload)).digest('hex');
}

export function classifyProfile(profile, validStructureNames) {
  const structure = stringValue(profile?.dipartimento);
  if (validStructureNames.has(structure)) return 'valid';

  const stringFields = ['dipartimento', 'sede', 'sedeId', 'sedeAddress'];
  const stringsEmpty = stringFields.every(
    (field) => stringValue(profile?.[field]) === '',
  );
  const coordinatesEmpty =
    profile?.sedeLat == null && profile?.sedeLng == null;
  return stringsEmpty && coordinatesEmpty ? 'alreadyEmpty' : 'clear';
}

export function profileResetPatch(deleteValue) {
  return {
    dipartimento: '',
    sede: '',
    sedeId: '',
    sedeAddress: '',
    sedeLat: deleteValue,
    sedeLng: deleteValue,
  };
}

function stableJson(value) {
  if (Array.isArray(value)) {
    return `[${value.map(stableJson).join(',')}]`;
  }
  if (value && typeof value === 'object') {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`)
      .join(',')}}`;
  }
  return JSON.stringify(value);
}

function stringValue(value) {
  return typeof value === 'string' ? value.trim() : '';
}
