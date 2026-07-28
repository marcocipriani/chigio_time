# ADR-0015 — Logging centralizzato e failure tipizzate

- **Data:** 2026-07-25
- **Owner:** Marco Cipriani
- **Stato:** Accepted
- **Contesto correlato:** [`layering.md`](../architettura/layering.md),
  [`testing.md`](../processi/testing.md),
  [`authentication.md`](../funzionalita/authentication.md),
  [`timesheet.md`](../funzionalita/timesheet.md)

## Contesto

La diagnostica dell'app viveva in 26 `debugPrint('[tag] …')` sparsi fra
bootstrap, repository, servizi FCM e provider: nessun livello di severità,
nessun punto unico da cui inviare gli errori a una telemetria, e in release il
messaggio spariva insieme alla causa. In parallelo `lib/core/errors/failures.dart`
era un file vuoto e mai importato: la classificazione degli errori avveniva in
`AppStrings._humanError`, che faceva `contains()` su `e.toString()` per capire
se un errore fosse di rete, di permessi o di sessione. Bastava che un plugin
riformulasse un messaggio per far scivolare l'errore nel ramo generico. I
repository, dal canto loro, segnalavano l'utente non autenticato in tre modi
diversi (`Exception(AppStrings.userNotAuthenticated)`, `StateError`, niente).

Vincolo: nessuna nuova dipendenza (`logging`, `sentry`, `firebase_crashlytics`
avrebbero richiesto una propria ADR e un canale di raccolta da gestire).

## Opzioni considerate

1. **Lasciare `debugPrint` + euristiche su stringa** — costo zero, ma la
   classificazione resta fragile e non esiste un aggancio per la telemetria.
2. **Adottare `package:logging` + `firebase_crashlytics`** — completo, ma
   introduce due dipendenze e un canale di raccolta prima che ci sia un
   consumatore reale dei log.
3. **Façade interna `AppLog` + gerarchia sigillata `AppFailure`** — nessuna
   dipendenza nuova, sink sostituibile in un punto solo, classificazione fatta
   dove l'errore è ancora tipizzato (codici Firebase).

## Decisione

Adottiamo l'**opzione 3**.

`core/logging/app_logger.dart` espone `AppLog.debug/info/warning/error(tag,
message, {error, stackTrace})`. Il sink predefinito stampa con `debugPrint`
(comportamento identico a prima) e la soglia predefinita è `debug` fuori
release, `warning` in release. `AppLog.useSink(...)` sposta tutti i record
altrove — è l'unico punto da toccare il giorno in cui arriva una telemetria.

`core/errors/failures.dart` definisce `sealed class AppFailure implements
Exception` con `kind` (`FailureKind.network | authentication | permission |
notFound | validation | unknown`), `message` italiano già pronto per la UI e
`cause`/`stackTrace` riservati ai log. `AppFailure.from(error)` classifica
prima sui codici `FirebaseException` (anche namespaced, `auth/…`) e solo come
ultima risorsa sulle euristiche testuali di prima. `AppStrings._humanError`
delega a `AppFailure.from`: la UI continua a chiamare `AppStrings.errorSave(e)`
e i messaggi utente restano invariati.

I guard di sessione nei repository (`timesheet`, `profile`, `salary`) lanciano
`const AuthenticationFailure()` invece di `Exception`/`StateError`.

## Conseguenze

- **Positive:** un solo punto per instradare la diagnostica; classificazione
  stabile basata sui codici invece che sul testo; messaggi utente coerenti per
  costruzione; failure `const` e testabili senza Firebase inizializzato.
- **Negative / debiti tecnici:** `AppFailure` è ancora sollevata solo dai
  guard di sessione — le `catch` dei repository non riavvolgono ancora ogni
  errore Firestore in una failure tipizzata, quindi la classificazione avviene
  per lo più a valle, in `AppStrings`. La conversione dei rami `catch` è il
  passo successivo.
- **Migrazione:** completata per tutti i 26 call site `debugPrint` in `lib/`.
  `AppStrings.userNotAuthenticated` resta come stringa UI ma non è più il
  veicolo dell'errore.

## Note

- Test: `test/core/logging/app_logger_test.dart` (livelli, sink, formato) e
  `test/core/errors/failures_test.dart` (mappa codici Firebase, euristiche
  testuali, idempotenza di `from`, instradamento di `AppStrings`).
- `AppFailure` implementa `Exception` proprio per non rompere i `catch`
  esistenti nella presentation.
