# Catalogo PCM Dipartimento/Struttura e Sede — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** sostituire gli elenchi PCM divergenti con un catalogo canonico di 50 coppie struttura/sede, distribuito da Firestore, disponibile offline e condiviso da onboarding, profilo, geofencing e gate di riallineamento.

**Architecture:** un payload JSON versionato alimenta il documento `referenceData/pcmCatalog`, il fallback bundled e gli script amministrativi. Un repository valida atomicamente il remoto e applica la precedenza Firestore → Drift → bundled. UI e migrazione usano lo stesso modello `PcmStructureSite`; i campi profilo Firestore restano retrocompatibili.

**Tech Stack:** Flutter 3, Dart 3.10+, Riverpod 3, Firebase Auth/Firestore, Drift, Node.js ESM, Firebase Admin SDK, Firebase Security Rules.

## Global Constraints

- Eseguire il lavoro direttamente su `main`, come richiesto dall'utente, con commit piccoli e push dopo ogni blocco coerente.
- Non committare `Appendice A-elenco strutture.pdf`, credenziali o file generati manualmente.
- Non modificare a mano file `*.g.dart`; eseguire `build_runner` solo quando richiesto da modifiche annotate o allo schema.
- Conservare il campo profilo `dipartimento`; cambiare solo la terminologia UI in `Dipartimento/Struttura`.
- Non aggiungere dipendenze: modello, parser e test usano SDK Dart/Node esistenti.
- Ogni modifica in `lib/` richiede aggiornamento wiki e `docs/CHANGELOG.md` nello stesso rilascio.
- La sede consigliata è ordinata per prima e marcata, ma mai selezionata automaticamente.
- Un catalogo remoto malformato non deve alterare la cache valida.
- Gli script sono dry-run per default e scrivono solo con `--apply`.

---

## Task 1: Payload canonico e modello validato

**Files:**

- Create: `assets/data/pcm_catalog.json`
- Create: `lib/core/data/pcm_catalog.dart`
- Modify: `pubspec.yaml`
- Create: `test/core/pcm_catalog_test.dart`

- [ ] Scrivere prima i test fallenti per parsing, versione, conteggio esatto di 50 righe, ID e nomi univoci, coordinate WGS84, aggregazione delle sedi e raccomandazione deterministica.
- [ ] Eseguire `flutter test test/core/pcm_catalog_test.dart` e verificare che fallisca perché modello e asset non esistono.
- [ ] Implementare `PcmCatalog`, `PcmStructureSite`, `PcmSiteOption`, `PcmCatalogValidationException` e `PcmCatalog.fromMap`.
- [ ] Esporre funzioni pure `validatePcmCatalog`, `pcmSitesFromStructures`, `sortedSitesForStructure`, `recommendedSiteIdForStructure` e `pcmSiteLabel`.
- [ ] Trascrivere le 50 righe normalizzate dalla prima e seconda colonna del PDF; unificare il duplicato DIPE, espandere `L.go` e correggere il CAP di Largo Chigi da `00178` a `00187`.
- [ ] Inserire coordinate WGS84 verificate per le 12 sedi uniche e registrare nel payload `version: 2026.07.20` e `source: Appendice A - indirizzario strutture PCM`.
- [ ] Dichiarare `assets/data/` in `pubspec.yaml`.
- [ ] Rieseguire il test mirato fino al verde, poi `dart format lib/core/data/pcm_catalog.dart test/core/pcm_catalog_test.dart`.
- [ ] Commit e push: `feat(pcm): add canonical structure and site catalog`.

## Task 2: Repository remoto, cache Drift e fallback bundled

**Files:**

- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/core/data/pcm_locations_repository.dart`
- Modify: `lib/core/providers/core_providers.dart` se necessario per l'iniezione delle dipendenze
- Replace/remove: `lib/core/constants/pcm_departments.dart`
- Replace/remove: `lib/core/constants/pcm_locations.dart`
- Create: `test/core/pcm_catalog_repository_test.dart`
- Modify: `test/core/pcm_locations_test.dart`
- Modify/generated: `lib/core/database/app_database.g.dart` solo tramite `build_runner` se il generatore rileva variazioni

- [ ] Scrivere test fallenti con loader iniettati per: remoto valido, remoto malformato con cache valida, errore remoto con cache valida, cache vuota con bundled valido e tutte le fonti invalide.
- [ ] Scrivere il test Drift che parte da una riga obsoleta e verifica la sostituzione transazionale completa.
- [ ] Eseguire i test mirati e confermare i fallimenti attesi.
- [ ] Implementare `PcmCatalogRepository.load()` con precedenza remote → cache → bundled e validazione completa prima della scrittura cache.
- [ ] Leggere Firestore esclusivamente da `referenceData/pcmCatalog`; loggare solo origine e versione.
- [ ] Aggiungere a `AppDatabase` lettura e `replacePcmOfficeLocations` in transazione con cancellazione delle righe obsolete.
- [ ] Adattare `pcmOfficeLocationsProvider` e `pcmSiteLocationsProvider` al catalogo condiviso.
- [ ] Rimuovere le due vecchie fonti dati Dart dopo avere eliminato tutti i loro utilizzi.
- [ ] Eseguire `dart run build_runner build --delete-conflicting-outputs` solo se necessario, poi test mirati e formattazione.
- [ ] Commit e push: `feat(pcm): load catalog from firestore with offline fallback`.

## Task 3: Onboarding e selettore riusabile

**Files:**

- Create: `lib/shared/widgets/pcm_assignment_form.dart`
- Modify: `lib/features/authentication/presentation/onboarding_screen.dart`
- Modify: `lib/features/authentication/presentation/providers/onboarding_provider.dart`
- Modify: `lib/core/constants/app_strings.dart`
- Create: `test/shared/widgets/pcm_assignment_form_test.dart`
- Modify: `test/features/authentication/presentation/onboarding_screen_test.dart` se presente, altrimenti creare un test mirato equivalente

- [ ] Scrivere test widget fallenti: etichetta `Dipartimento/Struttura`, 50 strutture ricercabili, nessuna sede preselezionata, sede associata in cima con stella e dicitura `Sede consigliata`.
- [ ] Implementare il form condiviso con callback esplicite per struttura e sede; una modifica della struttura azzera solo la selezione locale della sede quando incompatibile.
- [ ] Collegare l'onboarding al provider del catalogo e rimuovere accessi alle vecchie costanti.
- [ ] Conservare il salvataggio dei campi `dipartimento`, `sede`, `sedeId`, `sedeAddress`, `sedeLat`, `sedeLng`.
- [ ] Gestire caricamento/errore con `Riprova`; il repository deve già avere esaurito cache e bundled prima di mostrare errore.
- [ ] Eseguire test mirati, `dart format` e una ricerca `rg 'kPcmDepartments|pcmOfficeSeeds|Dipartimento\b' lib test` per eliminare fonti e label obsolete.
- [ ] Commit e push: `feat(onboarding): use canonical pcm assignment catalog`.

## Task 4: Profilo e gate mirato di riallineamento

**Files:**

- Create: `lib/shared/widgets/pcm_assignment_gate.dart`
- Modify: `lib/features/profile/presentation/profile_screen.dart`
- Modify: `lib/features/authentication/data/profile_repository.dart`
- Modify: `lib/app/main_shell_screen.dart` o il file effettivo che costruisce la shell autenticata
- Create: `test/shared/widgets/pcm_assignment_gate_test.dart`
- Modify: `test/features/profile/presentation/profile_screen_test.dart` se presente, altrimenti creare un test mirato equivalente

- [ ] Scrivere test fallenti per il predicato del gate: PCM con coppia mancante/invalida mostra il gate; coppia valida o organizzazione non PCM non lo mostra.
- [ ] Scrivere test widget fallenti: gate non dismissibile, richiede entrambi i campi e scompare dopo salvataggio riuscito.
- [ ] Aggiungere al repository profilo un aggiornamento atomico dei sei campi PCM.
- [ ] Avvolgere la shell autenticata con `PcmAssignmentGate`, mantenendo visibile ma non interattivo il contenuto richiesto finché la coppia non è valida.
- [ ] Riutilizzare `PcmAssignmentForm` nel profilo: cambiare struttura non salva implicitamente una sede; una sede incompatibile richiede una nuova scelta prima del salvataggio.
- [ ] Eseguire test mirati e formattazione.
- [ ] Commit e push: `feat(profile): require valid pcm structure and site assignment`.

## Task 5: Script amministrativi e test Node

**Files:**

- Create: `scripts/pcm_catalog_logic.mjs`
- Create: `scripts/seed_pcm_catalog.mjs`
- Create: `scripts/migrate_pcm_profiles.mjs`
- Create: `scripts/test/pcm_catalog_logic.test.mjs`
- Modify: `scripts/package.json`

- [ ] Scrivere test Node fallenti per validazione payload, hash stabile, classificazione profili, patch di azzeramento e idempotenza.
- [ ] Eseguire `npm test --prefix scripts` e verificare il fallimento iniziale.
- [ ] Implementare funzioni pure condivise: validazione, canonicalizzazione per hash, classificazione `valid/clear/alreadyEmpty` e patch con `FieldValue.delete()` delegata al bordo Firebase.
- [ ] Implementare seed dry-run di default; con `--apply` scrivere `updatedAt` server-side, rileggere e confrontare versione/hash.
- [ ] Implementare migrazione dry-run/apply a batch: preservare match esatti, azzerare i quattro campi stringa, eliminare lat/lng, stampare solo UID e valori PCM coinvolti, verificare rilettura.
- [ ] Eseguire test Node, `node --check` sui tre moduli e un dry-run locale che si arresti chiaramente se mancano credenziali/progetto.
- [ ] Commit e push: `feat(admin): seed pcm catalog and migrate invalid profiles`.

## Task 6: Security Rules a privilegio minimo

**Files:**

- Modify: `firestore.rules`
- Modify: `test/security/firestore_rules_test.dart`
- Temporary, not committed: `/tmp/chigio-firestore-pcm-catalog-analysis.md`

- [ ] Documentare prima dell'edit in `/tmp/chigio-firestore-pcm-catalog-analysis.md`: path, query, operazioni, autenticazione e analisi avversaria dei tentativi anonimi/client-write/list/wildcard.
- [ ] Scrivere test di contratto fallenti per `get` autenticato del solo `referenceData/pcmCatalog`, `list` negato e ogni scrittura client negata.
- [ ] Aggiungere la regola più stretta possibile: `allow get` solo autenticato e solo per `pcmCatalog`; `allow list, create, update, delete: if false`.
- [ ] Eseguire `flutter test test/security/firestore_rules_test.dart`.
- [ ] Eseguire `firebase deploy --only firestore:rules --dry-run` e controllare il diff rules prima del deploy reale.
- [ ] Commit e push: `security(firestore): allow authenticated pcm catalog reads`.

## Task 7: Wiki, ADR e versione

**Files:**

- Create: `docs/decisioni/0014-catalogo-pcm-firestore-con-fallback-offline.md` usando il prossimo numero libero verificato
- Modify: `docs/entita/dipartimenti-pcm.md`
- Modify: `docs/entita/sedi-pcm.md`
- Modify: `docs/entita/user-profile.md`
- Modify: `docs/entita/onboarding-state.md`
- Modify: `docs/funzionalita/authentication.md`
- Modify: `docs/funzionalita/onboarding.md`
- Modify: `docs/funzionalita/profile.md`
- Modify: `docs/architettura/persistence.md`
- Modify: `docs/CHANGELOG.md`
- Modify: `pubspec.yaml`

- [ ] Verificare il prossimo numero ADR e descrivere decisione, alternative, fallback e conseguenze operative.
- [ ] Allineare entità e flussi alla terminologia `Dipartimento/Struttura`, al documento Firestore e al gate mirato.
- [ ] Documentare seed, migrazione, cache atomica e procedura di rollback.
- [ ] Incrementare la versione patch in `pubspec.yaml` una sola volta per il rilascio.
- [ ] Aggiungere una voce completa al changelog, includendo catalogo, UI, migrazione, rules e fallback.
- [ ] Verificare link e riferimenti con `rg 'pcm_departments|pcm_locations|kPcmDepartments|pcmOfficeSeeds' docs lib test`.
- [ ] Commit e push: `docs: document pcm catalog rollout`.

## Task 8: Verifica review, build, deploy e smoke

**Files:**

- Inspect: `.impeccable/critique/2026-07-10T05-54-51Z__chigio-time-full-app-review.md`
- Inspect: `firebase.json`, `.firebaserc`, workflow e script di deploy esistenti
- Modify only if evidence requires it: file relativi a issue della review non ancora completate

- [ ] Riesaminare ogni issue della review contro il codice corrente; annotare completata, superata o ancora aperta e implementare solo i gap reali con test dedicati.
- [ ] Eseguire `dart format --output=none --set-exit-if-changed lib test`.
- [ ] Eseguire `flutter analyze`.
- [ ] Eseguire `flutter test`.
- [ ] Eseguire `npm test --prefix scripts` e i test Functions/rules previsti dal repository.
- [ ] Eseguire `flutter build web --release`.
- [ ] Eseguire dry-run e poi deploy del catalogo, migrazione profili e Security Rules; verificare readback versione/hash e report migrazione senza PII.
- [ ] Eseguire il deploy applicativo con il comando documentato dal repository.
- [ ] Verificare in produzione: caricamento autenticato, fallback non attivato, ricerca struttura, sede consigliata non preselezionata, salvataggio profilo e gate di riallineamento.
- [ ] Controllare `git status`, non includere PDF/credenziali, integrare eventuali commit coerenti rimasti e pushare `main`.
- [ ] Commit finale solo se necessario: `chore(release): deploy pcm catalog update`.
