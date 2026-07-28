import { readFile, readdir, stat } from 'node:fs/promises';
import { dirname, extname, join, normalize, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptsDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptsDir, '..');
const docsRoot = join(root, 'docs');
const errors = [];

async function walk(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...await walk(path));
    else files.push(path);
  }
  return files;
}

const allDocs = (await walk(docsRoot))
  .filter((path) => extname(path) === '.md')
  .map((path) => relative(docsRoot, path).split(sep).join('/'))
  .filter((path) => !path.startsWith('superpowers/'))
  .sort();

const manifest = JSON.parse(await readFile(join(docsRoot, 'navigation.json'), 'utf8'));
const manifestPaths = manifest.sections.flatMap((section) =>
  section.items.map((item) => item.path));
const pathCounts = new Map();
for (const path of manifestPaths) {
  pathCounts.set(path, (pathCounts.get(path) || 0) + 1);
  try {
    const info = await stat(join(docsRoot, path));
    if (!info.isFile()) errors.push(`Manifest: non è un file: ${path}`);
  } catch {
    errors.push(`Manifest: pagina assente: ${path}`);
  }
}
for (const [path, count] of pathCounts) {
  if (count !== 1) errors.push(`Manifest: ${path} compare ${count} volte`);
}
for (const path of allDocs) {
  if (!pathCounts.has(path)) errors.push(`Manifest: pagina non indicizzata: ${path}`);
}

const markdownLink = /!?\[[^\]]*]\(([^)\s]+)(?:\s+["'][^"']*["'])?\)/g;
const rootsToCheck = [
  join(root, 'README.md'),
  join(root, 'CONTRIBUTING.md'),
  join(root, 'AGENTS.md'),
  ...allDocs.map((path) => join(docsRoot, path)),
];

for (const file of rootsToCheck) {
  const content = await readFile(file, 'utf8');
  const relativeFile = relative(root, file);
  for (const match of content.matchAll(markdownLink)) {
    const raw = match[1];
    if (/^(https?:|mailto:|tel:|#)/i.test(raw)) continue;
    const decoded = decodeURIComponent(raw.split('#')[0].split('?')[0]);
    if (!decoded) continue;
    const target = normalize(resolve(dirname(file), decoded));
    if (!target.startsWith(root + sep) && target !== root) {
      errors.push(`${relativeFile}: link fuori repository: ${raw}`);
      continue;
    }
    try {
      await stat(target);
    } catch {
      errors.push(`${relativeFile}: link non trovato: ${raw}`);
    }
  }
}

const canonicalDocs = allDocs.filter((path) => !path.startsWith('archivio/'));
const forbidden = /docs\/superpowers|\.superpowers|\.impeccable|CLAUDE\.md/gi;
const codePath =
  /`((?:lib|test|functions|scripts|web|assets|android|ios)\/[A-Za-z0-9_./-]+\.(?:dart|js|mjs|json|md|png|html|plist|yaml))`/g;
for (const path of canonicalDocs) {
  const content = await readFile(join(docsRoot, path), 'utf8');
  if (forbidden.test(content)) errors.push(`${path}: riferimento operativo rimosso`);
  forbidden.lastIndex = 0;
  if (path !== 'CHANGELOG.md') {
    for (const match of content.matchAll(codePath)) {
      try {
        await stat(join(root, match[1]));
      } catch {
        errors.push(`${path}: file di codice non trovato: ${match[1]}`);
      }
    }
  }
}

const portal = await readFile(join(docsRoot, 'index.html'), 'utf8');
if (!portal.includes('fetch("navigation.json"')) {
  errors.push('docs/index.html: navigation.json non è la fonte del menu');
}

if (errors.length) {
  console.error(`Controllo documentazione fallito (${errors.length}):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exitCode = 1;
} else {
  console.log(
    `Documentazione valida: ${allDocs.length} pagine, ` +
    `${manifest.sections.length} sezioni, ${manifestPaths.length} voci.`,
  );
}
