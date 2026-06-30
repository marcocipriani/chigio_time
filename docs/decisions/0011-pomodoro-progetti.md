# ADR-0011 — Pomodoro timer su Progetti

- **Stato:** Accettata (v1 — 2026-06-23)
- **Contesto:** voce **F3** del lotto bug/feature 2026-06-23, ora in
  [`ROADMAP.md`](../ROADMAP.md).

## Contesto

Oggi l'attività giornaliera è solo una casella di testo libera. Si vuole una
nuova sezione **Progetti** con un **Pomodoro timer** attivabile su progetti
specifici (personali o condivisi con i Collegati) e un riepilogo dei pomodori
svolti.

## Decisione

### Entità
- **Project** (`projects/{id}` — collezione top-level):
  - `name`, `ownerUid` (= **capo progetto**, ruolo unico e trasferibile),
    `ownerName`, `shared` (bool: personale vs condiviso), `memberUids`
    (collaboratori uniti, incl. owner), `colorValue`, `createdAt`.
- **PomodoroSession** (`projects/{id}/pomodoros/{pid}`):
  - `projectId`, `uid`, `userName`, `dateId` (`YYYY-MM-DD`), `focusMins`,
    `breakMins`, `startedAt`, `confirmed` (false = "non confermato", es. timer
    interrotto dalla timbratura di uscita).
- **Active timer** (`users/{uid}/activeTimer/current`): timer in corso reso
  persistente (timestamp-based) per sopravvivere a chiusura app/tab.

### Ruoli (ADR coerente con F1/F2)
- **Capo progetto** (creatore, trasferibile): cambia visibilità, modifica
  dettagli, rimuove pomodori altrui, cancella il progetto, cede il ruolo.
- **Collaboratore**: aggiunge solo i propri pomodori.

### Persistenza
- Firestore top-level `projects` (i progetti sono condivisibili tra utenti,
  quindi NON possono stare sotto `users/{uid}`).
- Niente Cloud Functions (piano Spark): reciprocità/condivisione gestite
  client-side con security rules. Vedi [[firestore.rules]].

### Timer
- Conteggio basato su `startedAt` (wall-clock): persiste in background.
- Preset durata: **25/5** e **45/15**.
- Il riepilogo **affianca** (non sostituisce) la casella attività.

## Conseguenze
- Nuova feature `lib/features/projects/` (domain/data/presentation).
- Nuova **tab "Progetti"** in 3ª posizione nella navbar (5 voci totali).
- Nuove regole Firestore per `projects` + subcollection `pomodoros`.

## Deferred (v2 — non in questo slice)
- Integrazione timbratura-uscita → pomodoro `confirmed=false` automatico.
- UI dedicata per: cessione capo progetto, % impegno per collaboratore,
  rimozione pomodori orfani dopo cancellazione/cambio visibilità.
- Cache locale Drift (v1 è Firestore-only; degrada offline).
