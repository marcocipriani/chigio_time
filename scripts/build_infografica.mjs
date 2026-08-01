#!/usr/bin/env node
/**
 * Costruisce l'infografica "Come funziona l'orario in PCM" a partire dal
 * sorgente `prototypes/infografica-orario-pcm.src.html`.
 *
 * Il sorgente contiene segnaposto `__FONT_*__` e `__IMG_*__` che vengono
 * sostituiti con data URI, cosi' il file finale e' completamente autonomo:
 * nessuna richiesta di rete, apribile e condivisibile ovunque.
 *
 * Prerequisiti: le pose di Chigio ridimensionate in WebP e i font di marca
 * sottoinsiemizzati in WOFF2, prodotti da `prepare_infografica_assets.py`
 * e versionati in `prototypes/assets-infografica/`.
 *
 * Uso:
 *   node scripts/build_infografica.mjs            # → prototypes/infografica-orario-pcm.html
 *   node scripts/build_infografica.mjs --fragment # → stampa il frammento senza <html>/<head>
 */

import { readFile, writeFile, readdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const srcPath = path.join(root, 'prototypes', 'infografica-orario-pcm.src.html');
const assetsDir = path.join(root, 'prototypes', 'assets-infografica');
const outPath = path.join(root, 'prototypes', 'infografica-orario-pcm.html');

const MIME = { '.woff2': 'font/woff2', '.webp': 'image/webp', '.png': 'image/png' };

async function dataUri(file) {
  const buf = await readFile(path.join(assetsDir, file));
  const mime = MIME[path.extname(file)] ?? 'application/octet-stream';
  return `data:${mime};base64,${buf.toString('base64')}`;
}

async function build() {
  let html = await readFile(srcPath, 'utf8');
  const files = await readdir(assetsDir);

  for (const file of files) {
    const base = path.basename(file, path.extname(file));
    const token = file.endsWith('.woff2') ? `__FONT_${base}__` : `__IMG_${base}__`;
    if (!html.includes(token)) continue;
    html = html.replaceAll(token, await dataUri(file));
  }

  const oggi = new Date().toISOString().slice(0, 10);
  html = html.replaceAll('__DATA__', `Aggiornata al ${oggi}`);

  const residui = html.match(/__(FONT|IMG|DATA)_[A-Za-z0-9-]*__/g);
  if (residui) throw new Error(`Segnaposto non risolti: ${[...new Set(residui)].join(', ')}`);

  if (process.argv.includes('--fragment')) {
    process.stdout.write(html);
    return;
  }

  // Il frammento inizia con <title> e <style>: vanno nel <head>, il resto nel <body>.
  const taglio = html.indexOf('</style>');
  if (taglio === -1) throw new Error('Sorgente senza blocco <style>: impossibile comporre il documento.');
  const testa = html.slice(0, taglio + '</style>'.length).trim();
  const corpo = html.slice(taglio + '</style>'.length).trim();

  const doc = `<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="Guida visuale all'orario di lavoro in PCM: timbratura, regola delle 9 ore, buono pasto, maggior presenza e come usare Chigio Time.">
${testa}
</head>
<body>
${corpo}
</body>
</html>
`;
  await writeFile(outPath, doc, 'utf8');
  const kb = (Buffer.byteLength(doc) / 1024).toFixed(0);
  console.log(`✓ ${path.relative(root, outPath)} — ${kb} KB, autonomo`);
}

build().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
