# ADR-0005 — Drift su Web via WASM

- **Data:** 2026-05-30 (implementata: 2026-07-04)
- **Autore/i:** Marco Cipriani
- **Stato:** Accepted / Implemented
- **Contesto correlato:** [`docs/architettura/persistence.md`](../architettura/persistence.md), [`ADR-0001`](./0001-stack-iniziale.md)

## Contesto

`AppDatabase` usa Drift + `sqlite3_flutter_libs` per la cache SQLite locale. Su web, `sqlite3_flutter_libs` dipende da `dart:ffi` che non è disponibile nei browser standard. La soluzione attuale (`kIsWeb → null`, `connection_web.dart` lancia `UnsupportedError`) disabilita la cache offline sul web. L'app web funziona esclusivamente via Firestore. Un'eventuale modalità offline completa su web richiede SQLite compilato in WASM.

## Opzioni considerate

1. **Drift `WasmDatabase`** — usa `sqlite3.wasm` servito come asset statico + un web worker (`drift_worker.dart.js`). Supporta IndexedDB o OPFS come storage persistente. Pro: stessa API di Drift, unica codebase. Contro: richiede generare `drift_worker.dart.js` (`dart compile js`), scaricare `sqlite3.wasm` (~800KB) come asset, refactorare `AppDatabase` con provider asincrono (`FutureProvider` invece di `Provider`), configurare service worker. Non supportato da `drift_dev web-wasm` in drift 2.x.

2. **`sqflite_web` / `sembast`** — database alternativi già compatibili con web. Contro: richiedono una seconda implementazione del layer `data/`; viola "single source of truth" del modello Drift.

3. **Nessuna cache su web** (stato attuale) — web usa solo Firestore. Pro: zero complessità. Contro: nessuna resilienza offline su web.

## Decisione

**Rimandiamo** l'implementazione di Drift WASM. L'opzione 3 (corrente) è accettabile per l'uso target (app web su rete PA affidabile). Procederemo con `WasmDatabase` quando:
- `drift_dev` rilascerà supporto ufficiale al tool `web-wasm` per drift 2.x
- O si presenterà un requisito reale di offline su web

La migrazione richiederà anche il refactoring di `appDatabaseProvider` da `Provider<AppDatabase?>` a `FutureProvider<AppDatabase?>` con relative modifiche ai repository.

## Conseguenze

- **Positive (future):** cache offline identica su tutte le piattaforme; riduzione dipendenza da Firestore in scenari di rete intermittente.
- **Negative / debiti tecnici:** `connection_web.dart` rimane uno stub; `kIsWeb` check in `appDatabaseProvider` rimane. Tag `// TODO ADR-0005` aggiunto nel codice per ricordare il punto di intervento.
- **Migrazione (quando applicabile):** 1) aggiungere `sqlite3_wasm` a pubspec; 2) creare `drift_worker.dart` + compilare; 3) copiare `sqlite3.wasm` in `web/`; 4) aggiornare `connection_web.dart` con `WasmDatabase.open()`; 5) rendere `appDatabaseProvider` asincrono.

## Esito (2026-07-04)

L'opzione 1 (`WasmDatabase`) è stata implementata: `connection_web.dart`
usa `WasmDatabase.open()` con `sqlite3Uri: 'sqlite3.wasm'` e
`driftWorkerUri: 'drift_worker.dart.js'`, entrambi asset statici in `web/`.
`sqlite3.wasm` va scaricato dalle **release GitHub di `sqlite3.dart`**
(https://github.com/simolus3/sqlite3.dart/releases, tag `sqlite3-X.Y.Z`
allineato alla versione del package `sqlite3` in `pubspec.lock`) — il
package `sqlite3_flutter_libs` NON pubblica l'asset wasm (il vecchio URI
`packages/sqlite3_flutter_libs/assets/sqlite3.wasm` produceva 404 →
"Failed to execute 'compile' on 'WebAssembly'"). In caso di init fallito
l'app degrada a Firestore-only.

## Note

- Drift docs: https://drift.simonbinder.eu/web/
- `drift_dev web-wasm` non disponibile in drift 2.16.0 (verificato 2026-05-30).
