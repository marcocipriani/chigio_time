# ADR-0013 — Catalogo PCM Firestore con fallback offline

- **Data:** 2026-07-21
- **Autore/i:** Codex
- **Stato:** Accepted
- **Contesto correlato:** [`persistence.md`](../architettura/persistence.md),
  [`dipartimenti-pcm.md`](../entita/dipartimenti-pcm.md),
  [`sedi-pcm.md`](../entita/sedi-pcm.md),
  [`onboarding.md`](../funzionalita/onboarding.md)

## Contesto

Onboarding, profilo e route planner mantenevano elenchi PCM separati, con nomi
e sedi divergenti. L'Appendice A fornisce la coppia ufficiale
Dipartimento/Struttura-Sede, ma il PDF non è adatto al runtime e non deve
essere distribuito nell'app. Il catalogo deve poter essere aggiornato senza
release, restare disponibile al primo avvio offline e non lasciare cache
parziali o obsolete.

## Opzioni considerate

1. **Solo costanti Dart bundled** — semplice e offline, ma ogni correzione
   richiede una nuova release e tende a ricreare fonti divergenti.
2. **Solo documento Firestore** — aggiornabile centralmente, ma blocca
   onboarding e riallineamento profilo quando la rete non è disponibile.
3. **Documento Firestore validato, cache Drift e payload bundled** — mantiene
   un'origine remota aggiornabile con due fallback locali deterministici.

## Decisione

Adottiamo l'**opzione 3**. Il documento canonico è
`referenceData/pcmCatalog`; il repository usa l'ordine remoto valido, cache
Drift non vuota, JSON bundled. Tutto il payload viene validato prima di
sostituire la cache in una transazione.

Il client autenticato può leggere con un singolo `get` il solo documento
`pcmCatalog`; query, list e scritture sono negate dalle Security Rules. Seed e
migrazione profili sono script Firebase Admin dry-run per default. Il campo
profilo resta `dipartimento` per compatibilità, mentre la UI usa
`Dipartimento/Struttura`.

## Conseguenze

- **Positive:** onboarding, profilo, geofencing e percorsi condividono 50
  coppie validate; il catalogo è aggiornabile senza release e utilizzabile
  offline; una risposta remota malformata non corrompe la cache.
- **Negative / debiti tecnici:** il deploy del catalogo e la migrazione
  richiedono credenziali Firebase Admin; il singolo documento va monitorato
  rispetto al limite Firestore di 1 MiB se il catalogo cresce molto.
- **Migrazione:** il seed pubblica il payload bundled. I profili con struttura
  non canonica perdono solo i sei campi PCM e ricevono un gate mirato per
  scegliere nuovamente struttura e sede. Le vecchie liste Dart separate sono
  rimosse.

## Note

Il PDF sorgente resta locale e non viene versionato. La sede associata alla
struttura è solo raccomandata e non viene selezionata automaticamente.
