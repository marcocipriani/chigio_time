# Feature — Progetti & Pomodoro

> Sezione **Progetti** (3ª voce della navbar) con **Pomodoro timer** su
> progetti personali o condivisi con i Collegati.
> Codice: `lib/features/projects/`. Decisione: [ADR-0011](../decisions/0011-pomodoro-progetti.md).

---

## Scopo

Affianca alla casella "descrizione attività giornaliera" un tracciamento
strutturato del tempo: l'utente crea progetti e vi avvia **pomodori** (sessioni
di focus a tempo). Un riepilogo mostra quanti pomodori sono stati svolti, su
quali progetti e — per i progetti condivisi — chi ha contribuito.

I pomodori sono **statistica a parte**: non incidono sul tempo lavorato del
cartellino.

---

## Modello

- **Project** (`projects/{id}`, collezione top-level): personale o condiviso.
- **PomodoroSession** (`projects/{id}/pomodoros/{pid}`): un pomodoro svolto.
- **Active timer** (`users/{uid}/activeTimer/current`): timer in corso,
  persistente.

Dettagli campi in [`../entities/progetto.md`](../entities/progetto.md).

---

## Ruoli

| Ruolo | Permessi |
|---|---|
| **Capo progetto** (creatore, **trasferibile**) | cambia visibilità, modifica dettagli, rimuove pomodori altrui, cancella il progetto, cede il ruolo |
| **Collaboratore** (Collegato unito) | aggiunge solo i **propri** pomodori |

Ruolo unico e trasferibile: cedere il ruolo trasferisce *tutti* i permessi.

---

## Flussi UI (`ProjectsScreen`)

- **Lista "I miei progetti"** — card con nome, badge condiviso, n. pomodori
  oggi/totali.
- **FAB +** — crea progetto (nome + toggle "Condividi con i Collegati").
- **Scopri progetti condivisi** — sheet con i progetti condivisi dai Collegati
  a cui non si è ancora uniti → "Unisciti".
- **Card timer attivo** — countdown (mm:ss), "Concludi" (salva) / "Annulla"
  (scarta). Auto-completa allo scadere del focus.
- **Dettaglio progetto** (bottom sheet):
  - contatori **Oggi / Settimana / Mese / Sempre**;
  - avvio pomodoro con preset **25/5** e **45/15**, o **+ manuale**;
  - **Contributi** (progetti condivisi): conteggio e **%** per collaboratore;
  - elenco pomodori recenti (🍅 confermato / ⚠️ non confermato) con rimozione
    (proprio o, se capo, di chiunque);
  - azioni capo: rinomina, rendi personale/condividi, elimina; collaboratore:
    abbandona.

---

## Timer

Conteggio basato su `startedAt` (wall-clock): persiste a chiusura app/tab. Un
ticker da 1s aggiorna il countdown e, allo scadere del focus, finalizza il
pomodoro (`confirmed: true`) e libera l'`activeTimer`.

---

## Persistenza & regole

Firestore top-level `projects` + subcollection `pomodoros` (i progetti sono
condivisibili, quindi non possono stare sotto `users/{uid}`). Regole dedicate
in `firestore.rules`: lettura ai membri (i condivisi sono visibili per la
discovery), scrittura del progetto al capo, join/leave del solo `memberUids` al
collaboratore, pomodori creabili dal proprio autore e rimovibili dall'autore o
dal capo. Vedi [`../architecture/persistence.md`](../architecture/persistence.md).

---

## Deferred (v2)

- Stop automatico del pomodoro alla timbratura di **uscita** → `confirmed:false`.
- UI dedicata per cessione del ruolo capo progetto.
- Pulizia dei pomodori **orfani** dopo cancellazione/cambio visibilità.
- Cache locale Drift (v1 è Firestore-only).
