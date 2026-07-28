# ADR-0005 — Drift su Web tramite WASM

- **Data:** 2026-05-30
- **Implementata:** 2026-07-04
- **Owner:** Marco Cipriani
- **Stato:** Accepted

## Contesto

La cache Drift nativa usa SQLite tramite FFI, non disponibile nel browser.
Disabilitare la cache sul Web avrebbe creato comportamenti divergenti e
nessuna resilienza locale per il cartellino.

## Opzioni considerate

1. Drift `WasmDatabase` con SQLite WASM e worker.
2. Un database Web diverso, con una seconda implementazione del data layer.
3. Nessuna cache locale sul Web.

## Decisione

Usiamo `WasmDatabase` e manteniamo la stessa API Drift su tutte le
piattaforme. `connection_web.dart` apre SQLite WASM; l'asset viene fornito dal
pacchetto Flutter compatibile e il worker è servito dalla build Web.

Se l'inizializzazione fallisce, il provider può degradare a Firestore-only:
la cache non deve impedire l'avvio dell'app.

## Conseguenze

- Repository e migrazioni restano condivisi.
- Il primo caricamento Web include runtime WASM e worker.
- La compatibilità tra versione SQLite, worker e Drift va verificata a ogni
  upgrade.
- La build di release deve verificare la presenza degli asset e l'apertura del
  database nel browser.

Vedi [Persistenza](../architettura/persistence.md) e
[Build Web](../processi/web-release.md).

_Ultima revisione: 2026-07-29._
