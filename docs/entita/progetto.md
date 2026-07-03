# Entità — Project & PomodoroSession

> Le due entità della sezione [Progetti](../funzionalita/progetti.md).
> Definizioni Dart in `lib/features/projects/domain/`.
> Decisione: [ADR-0011](../decisioni/0011-pomodoro-progetti.md).

---

## Project

Sorgente canonica: `projects/{autoId}` (Firestore, **collezione top-level**
perché i progetti sono condivisibili tra utenti).

| Campo Dart | Tipo | Firestore | Note |
|---|---|---|---|
| `id` | String | doc id | Auto-id Firestore. |
| `name` | String | `name` | Nome progetto. |
| `ownerUid` | String | `ownerUid` | **Capo progetto** (ruolo unico, trasferibile). |
| `ownerName` | String | `ownerName` | Nome del capo (denormalizzato per la UI). |
| `shared` | bool | `shared` | `false` = personale, `true` = condiviso con i Collegati. |
| `memberUids` | List\<String\> | `memberUids` | Collaboratori uniti (incl. owner). |
| `colorValue` | int | `colorValue` | Colore ARGB della card. |
| `createdAt` | DateTime? | `createdAt` serverTimestamp | Audit. |

Getter: `isOwner(uid)`, `isMember(uid)`.

---

## PomodoroSession

Sorgente canonica: `projects/{id}/pomodoros/{autoId}`.

| Campo Dart | Tipo | Firestore | Note |
|---|---|---|---|
| `id` | String | doc id | Auto-id. |
| `projectId` | String | `projectId` | Progetto di appartenenza. |
| `uid` | String | `uid` | Autore del pomodoro. |
| `userName` | String | `userName` | Nome autore (denormalizzato per i contributi). |
| `dateId` | String | `dateId` `YYYY-MM-DD` | Giorno del pomodoro. |
| `focusMins` | int | `focusMins` | Minuti di focus (25 o 45). |
| `breakMins` | int | `breakMins` | Minuti di pausa (5 o 15). |
| `startedAt` | DateTime | `startedAt` Timestamp | Inizio sessione. |
| `confirmed` | bool | `confirmed` | `false` = "non confermato" (es. interrotto dall'uscita, da rivedere). |

---

## ActivePomodoro (timer in corso)

Non persistito come entità di dominio storica ma come stato:
`users/{uid}/activeTimer/current`. Campi: `projectId`, `projectName`,
`focusMins`, `breakMins`, `startedAt`. Il countdown è calcolato da `startedAt`
(wall-clock), quindi sopravvive a chiusura app/tab.

---

## Regole & persistenza

`firestore.rules` → `match /projects/{projectId}`:
- **read**: membro, oppure progetto `shared` (discovery);
- **create**: solo come `ownerUid == auth.uid` e membro di sé stesso;
- **update**: capo (pieno) o collaboratore che modifica il solo `memberUids` di
  un progetto condiviso (join/leave);
- **delete**: solo il capo;
- `pomodoros`: create dal proprio autore; delete dall'autore o dal capo.

Firestore-only (nessun mirror Drift in v1). Vedi
[`../architettura/persistence.md`](../architettura/persistence.md).
