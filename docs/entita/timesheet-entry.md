# Entita': `TimesheetEntry` *(legacy / non usata)*

> Modello presente nel codice ma **non utilizzato** dal flusso attivo.
> Documentato per scelta esplicita (non eliminare in silenzio: serve una
> decisione su deprecazione vs. ricondurre a un caso d'uso).

## Definizione

`lib/shared/models/timesheet_entry.dart`

```dart
class TimesheetEntry {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;       // null = turno in corso
  final bool isSmartWorking;
}
```

Espone `fromFirestore(DocumentSnapshot)` e `toFirestore()` con `Timestamp`
nativi.

## Stato d'uso

- **Nessuna** referenza nel resto di `lib/` (verifica: `grep -R "TimesheetEntry"`).
- E' un residuo plausibile della prima iterazione del modello, dove ogni
  timbratura era un record indipendente.

## Decisione attesa

Esistono due strade plausibili (da formalizzare con una ADR):

1. **Deprecare e rimuovere.** Il modello canonico per giornata e'
   `DailyTimesheet`; non c'e' bisogno di un evento "timbratura
   singola".
2. **Riusarlo per audit log.** Ogni `startTurn` / `endTurn` /
   `startPause` / `endPause` salva un `TimesheetEntry` dedicato per
   ricostruire la cronologia degli eventi. Utile se in futuro si vorra'
   tracciare timbrature grezze in modo indipendente dal record
   consolidato.

## Mappatura ipotetica (se si scegliesse l'opzione 2)

```
users/{uid}/raw_punches/{auto-id}
```

con campi `userId`, `startTime`, `endTime` (nullable), `isSmartWorking`,
`type` (entrata / uscita / pranzo / pausa / permesso).

> Aggiornare questa pagina **non appena** la decisione sara' presa.
