# Manutenzione del catalogo PCM

Il catalogo runtime usa questa precedenza:

```text
referenceData/pcmCatalog valido
  → cache Drift valida e sostituita atomicamente
  → assets/data/pcm_catalog.json
```

## Fonti e vincoli

- Il payload bundled contiene 50 strutture associate a 12 sedi.
- Ogni aggiornamento deve superare la validazione completa prima della write.
- Struttura e sede sono salvate come coppia; la sede raccomandata non viene
  selezionata automaticamente.
- Il PDF sorgente locale non viene incluso nell'app né nel repository.

## Procedura

1. Modificare e validare `assets/data/pcm_catalog.json`.
2. Eseguire `npm test --prefix scripts`.
3. Configurare `SA_KEY` solo nell'ambiente locale, mai in file versionati.
4. Eseguire `node scripts/seed_pcm_catalog.mjs` e
   `node scripts/migrate_pcm_profiles.mjs` in dry-run.
5. Applicare esplicitamente con `--apply`.
6. Rileggere il documento e confrontare hash e conteggi.
7. Se serve una migrazione profili, eseguirla prima in dry-run; i profili non
   canonici perdono solo i campi PCM.

Esempio:

```bash
SA_KEY=/percorso/locale/service-account.json \
  node scripts/seed_pcm_catalog.mjs

SA_KEY=/percorso/locale/service-account.json \
  node scripts/seed_pcm_catalog.mjs --apply
```

Vedi [ADR-0013](../decisioni/0013-catalogo-pcm-firestore-con-fallback-offline.md).

_Ultima revisione: 2026-07-29._
