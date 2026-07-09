# Entità: `TimerState`

> Stato del cronometro di turno visualizzato in dashboard.
> Persiste su `SharedPreferences` ad ogni transizione e viene ripristinato
> all'avvio se la data salvata è **oggi** (sopravvive ai riavvii mid-day).
> Viene consolidato in un `DailyTimesheet` al termine del turno.

## Definizione

`lib/features/dashboard/presentation/timer_provider.dart`

```dart
enum WorkState { notStarted, working, paused, completed, abandoned }
enum PauseType { none, lunch, short, leave }

class TimerState {
  final WorkState status;
  final DateTime? startTime;
  final DateTime? currentPauseStart;
  final PauseType currentPauseType;
  final int totalStandardPauseMins;   // pause brevi/caffè
  final int totalLeavePauseMins;      // permessi brevi (Art. 35)
  final int totalLunchPauseMins;      // pausa pranzo
  final int standardWorkMins;         // letto da UserProfile.standardDailyMins
  final int exitNotifMins;            // minuti prima uscita prevista; 0 = off
  final DateTime currentTime;         // tick ogni 1 secondo
  final DailyTimesheet? lastCompletedShift; // popolato dopo endTurn()
  final bool exitReminderPending;     // one-shot: true per UN tick quando remaining ≤ exitNotifMins
}
```

## Diagramma di stato

```mermaid
stateDiagram-v2
    [*] --> notStarted
    notStarted --> working    : startTurn(t)
    working --> paused        : startPause(type, t)
    paused --> working        : endPause(t)
    working --> completed     : endTurn(t) → DailyTimesheet
    paused --> completed      : endTurn(t) → DailyTimesheet
    completed --> working     : startTurn(t) (nuova giornata)
```

## Calcoli derivati (getter)

| Getter | Formula |
|---|---|
| `expectedExitTime` | `startTime + standardWorkMins + totalStandardPauseMins + totalLunchPauseMins`, + pausa forzata da `AppConstants.forcedLunchMins()` (regola 9 ore 3-zone, vedi [daily-timesheet.md](./daily-timesheet.md)) se non ancora coperta |
| `remainingTime` | `expectedExitTime − currentTime` |
| `isShiftActive` | `status == working ∥ status == paused` |

## Persistenza (SharedPreferences)

Chiavi salvate ad ogni transizione:

| Chiave | Tipo | Significato |
|---|---|---|
| `timer_date` | String | `YYYY-MM-DD` del turno attivo |
| `timer_status` | String | `WorkState.name` |
| `timer_startTime` | String | ISO 8601 |
| `timer_stdPauseMins` | int | totale pause brevi/caffè |
| `timer_leavePauseMins` | int | totale permessi brevi (Art. 35) |
| `timer_lunchPauseMins` | int | totale pause pranzo |
| `timer_pauseStart` | String? | ISO 8601 se in pausa |
| `timer_pauseType` | String | `PauseType.name` |

`_loadTimerState()` è chiamato in `WorkTimer.build()`. Se `timer_date ≠ oggi`,
lo stato salvato viene ignorato (stale da ieri).

## Lifecycle

- `WorkTimer.build()`:
  1. Legge `standardWorkMins` da `userProfileStreamProvider` (Firestore).
  2. Legge `exitNotifMins` dal profilo e lo aggiorna anche durante il turno.
  3. Tenta il ripristino dallo state salvato su `SharedPreferences`.
  4. Avvia un `Timer.periodic(1s)` per aggiornare `currentTime`.
  5. Registra `ref.onDispose(() => _ticker?.cancel())`.
- `endTurn()`: salva `DailyTimesheet` su Firestore, chiama `_clearTimerState()`,
  setta `status = completed` con `lastCompletedShift` compilato.

## Gap risolti in v0.2

- ✅ `_ticker` ora cancellato via `ref.onDispose`.
- ✅ `standardWorkMins` letto da profilo utente con `ref.listen`.
- ✅ Stato `completed` aggiunto: dashboard mostra riepilogo post-turno.
- ✅ Persistenza mid-day su `SharedPreferences`.
- ✅ Tick a 1 secondo (era 1 minuto).
- ✅ `totalLeavePauseMins` aggiunto: permessi brevi tracciati separatamente.
- ✅ `PauseType.leave` → `totalLeavePauseMins` (non più sommato a `standardPause`).
- ✅ `exitNotifMins` configurabile da profilo per promemoria uscita prevista.

> Nota CCNL 2026-06-06: nel CCNL PCM 2016-2018 i permessi brevi sono Art. 35;
> la label "Art.9" resta per compatibilita' app/portale fino a refactor.

_Ultima revisione: 2026-06-07 — aggiunto `exitNotifMins` configurabile._
