# AGENTS.md — protocollo operativo

Questo file definisce il comportamento richiesto agli strumenti automatici che
intervengono su `chigio_time`. Le regole di sviluppo comuni a persone e
automazioni vivono in [CONTRIBUTING.md](./CONTRIBUTING.md).

## Prima di modificare il repository

Leggere:

1. [docs/README.md](./docs/README.md);
2. [CONTRIBUTING.md](./CONTRIBUTING.md);
3. le pagine di architettura, feature, entità e ADR collegate alla modifica.

Non assumere che un piano storico o il changelog descrivano lo stato attuale:
il codice e le pagine canoniche hanno precedenza.

## Regole vincolanti

- Architettura feature-first con layer `data`, `domain`, `presentation`.
- Riverpod 3; preferire `@riverpod` per i nuovi provider.
- Firestore è accessibile dai repository, non dai widget.
- Non modificare manualmente i file `*.g.dart`.
- Non aggiungere dipendenze senza aggiornare ADR-0001 e, se la scelta è
  significativa, creare una nuova ADR.
- Non salvare credenziali, token o chiavi nel repository.
- Conservare le modifiche preesistenti non collegate al proprio intervento.

## Documentazione obbligatoria

Ogni cambiamento di comportamento deve aggiornare nello stesso commit:

- `docs/entita/` se cambia un modello o uno schema;
- `docs/funzionalita/` se cambia un flusso utente;
- `docs/architettura/` se cambia un confine tecnico;
- `docs/decisioni/` per una scelta architetturale non ovvia;
- `docs/CHANGELOG.md`;
- `docs/navigation.json` quando viene aggiunta, spostata o rimossa una pagina.

La documentazione canonica non deve dipendere da cartelle o formati propri di
uno specifico agente.

## Verifica minima

```bash
flutter analyze
flutter test
npm test --prefix functions
npm test --prefix scripts
node scripts/check_docs.mjs
```

Per un rilascio seguire [docs/processi/README.md](./docs/processi/README.md).

## Commit

Creare commit piccoli e coerenti, poi eseguire il push. Non includere cache,
credenziali, artefatti temporanei o file utente non pertinenti.
