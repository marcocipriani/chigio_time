# State management

Riverpod 3 gestisce dipendenze, stream e stato applicativo. I nuovi provider
usano preferibilmente `@riverpod`; i provider manuali esistenti restano validi
quando una migrazione non aggiunge valore.

## Pattern in uso

| Pattern | Esempio |
|---|---|
| provider function codegen | repository e servizi |
| provider stream codegen | auth, profilo e gate |
| Notifier codegen | timer e onboarding |
| `NotifierProvider` manuale | tema e locale |
| `StreamProvider.family` manuale | timesheet mensile |
| provider derivato/select | snapshot minuto/secondo del timer |

I file `*.g.dart` sono generati e non si modificano a mano.

## Bootstrap

`ChigioBootstrapApp` monta immediatamente una skeleton e conserva una singola
`Future<AppBootstrapData>` per tentativo. Il bootstrap inizializza:

- Firebase;
- cache Firestore Web multi-tab;
- locale;
- SharedPreferences;
- font UI bundled.

Un errore mostra un’azione di retry e non ricrea Future durante rebuild
ordinari.

## Gate profilo

`profileGateProvider` non espone un booleano ambiguo. Distingue:

- resolving;
- profilo completo da cache;
- profilo completo da server;
- profilo incompleto da server;
- failure con o senza profilo utilizzabile.

Il router usa questa semantica senza duplicare
`profileDocIsComplete`.

## Timer

`WorkTimer` aggiorna l’orologio ogni secondo, ma la UI non osserva
indiscriminatamente l’intero stato:

- dati strutturali ricostruiscono dopo azioni o sync;
- `TimerHeroSnapshot` cambia al minuto;
- il testo pausa può cambiare al secondo.

La riconciliazione remota è delegata a `RemoteTimerHandshake`, che distingue
snapshot pending, cache e server e protegge le mutazioni con una generation.
Vedi [ADR-0017](../decisioni/0017-sincronizzazione-timer-offline.md).

## Gestione degli `AsyncValue`

Ogni consumer deve distinguere:

- loading senza dati;
- refresh con ultimo dato valido;
- errore con retry;
- lista realmente vuota.

Non usare `.asData?.value ?? []` quando un errore diventerebbe
silenziosamente uno stato vuoto.

## Regole

- Nessun `Timer.periodic` di dominio dentro un widget.
- Nessuna mutazione di stato dall’esterno del Notifier.
- Nessun accesso Firebase diretto dalla UI.
- `select` e provider derivati devono restituire valori stabili tra tick
  irrilevanti.
- Gli stream che governano authority o sync devono conservare i metadata
  Firestore necessari alla decisione.

_Ultima revisione: 2026-07-29._
