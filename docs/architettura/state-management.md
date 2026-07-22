# State management con Riverpod

Lo stato applicativo e' gestito interamente con **Riverpod 3** in
modalita' code-gen (`@riverpod`). I file `*.g.dart` sono **generati** da
`build_runner` (vedi [`../processi/code-generation.md`](../processi/code-generation.md)).

## Tipologie di provider in uso

| Pattern | Esempio nel progetto | File |
|---|---|---|
| `@riverpod` semplice (function-based) | `firebaseAuth(Ref ref)`, `appRouter(Ref ref)`, `timesheetRepository(Ref ref)` | `auth_repository.dart`, `app_router.dart`, `timesheet_repository.dart` |
| `@riverpod` Stream | `authStateChanges`, `profileGate`, `userProfileStream` | `auth_repository.dart`, `profile_repository.dart` |
| `@riverpod` class (Notifier) | `class WorkTimer extends _$WorkTimer`, `class Onboarding extends _$Onboarding` | `timer_provider.dart`, `onboarding_provider.dart` |
| `NotifierProvider` manuale | `themeModeProvider` | `shared/providers/global_providers.dart` |
| `StreamProvider.family` manuale | `monthlyTimesheetsProvider` (chiave `({year, month})`) | `timesheet_repository.dart` |

> **Convenzione.** Quando possibile si usa il code-gen `@riverpod`, ma
> per i `family` con chiave record si usa la dichiarazione manuale per
> evitare di "pesare" i `*.g.dart` (commento esplicito nel codice di
> `monthlyTimesheetsProvider`).

## Lifecycle del WorkTimer (esempio canonico)

```mermaid
stateDiagram-v2
    [*] --> notStarted
    notStarted --> working: startTurn(time)
    working --> paused: startPause(type, time)
    paused --> working: endPause(time)
    working --> [*]: endTurn(time)\n→ saveDailyTimesheet
    paused --> [*]: endTurn(time)
```

- `WorkTimer.build()` crea un `Timer.periodic(1s)` che aggiorna
  `state.currentTime` per recovery e pausa live. Le azioni strutturali cambiano
  subito `TimerState`; `TimbraturaHero` seleziona `TimerHeroSnapshot`, stabile
  dentro lo stesso minuto, mentre il solo testo della pausa osserva i secondi.
- `endTurn` calcola `netWorkedMins`, `extraMins`, applica la
  **regola delle 9 ore**, poi delega a `TimesheetRepository.saveDailyTimesheet`.
- Dopo il salvataggio lo stato viene resettato a `TimerState(currentTime: now)`.

## Reattivita' del router

Il `GoRouter` e' un provider Riverpod (`appRouterProvider`) che osserva
`authStateChangesProvider` e `profileGateProvider`: ogni emissione notifica il
router persistente, che riapplica la `redirect` pura senza ricreare lo stack. Vedi
[`navigation.md`](./navigation.md) per il dettaglio.

## Cache & memoizzazione

- I provider Riverpod sono **autoDispose-by-default disabilitato**
  (default Riverpod 3): vivono finche' lo `ProviderScope` esiste.
- `profileGateProvider` parte dal marker positivo
  `SharedPreferences['hasProfile_<uid>']`, poi ascolta Firestore includendo i
  metadata. Cache completa consente la Home; cache incompleta resta resolving;
  solo server incompleto richiede onboarding. Gli errori conservano un profilo
  già utilizzabile e non implicano mai un nuovo utente.

## Stato di bootstrap

`ChigioBootstrapApp` monta immediatamente una skeleton e conserva un'unica
`Future<AppBootstrapData>` per tentativo. Firebase, locale, preferenze e font UI
vengono inizializzati dietro questo stato; il retry crea una nuova `Future`
senza ricrearla durante i rebuild.

Plus Jakarta Sans, Noto Sans, Noto Sans Symbols e Roboto sono asset locali: il
loro caricamento non dipende dalla rete. Noto Color Emoji viene invece scaldato
best-effort dopo il bootstrap con una `Future` non attesa, quindi non ritarda
mai il passaggio dalla skeleton all'app pronta.

## Anti-pattern da evitare

- Leggere `FirebaseAuth.instance` o `FirebaseFirestore.instance`
  direttamente dentro un widget: usare il provider corrispondente
  (`firebaseAuthProvider`, `userProfileStreamProvider`, …).
- Mutare `state` da fuori del Notifier: ogni mutazione deve passare
  per un metodo della classe `extends _$Foo`.
- Mettere `Timer.periodic` in un `initState` di widget: deve stare in
  un Notifier (come `WorkTimer`), che ne gestisce il ciclo di vita.
