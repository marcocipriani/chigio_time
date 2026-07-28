# ADR-0001 — Stack applicativo

- **Data:** 2026-04-26
- **Owner:** Marco Cipriani
- **Stato:** Accepted

## Contesto

L'app deve coprire mobile, desktop e Web con una sola codebase, dati realtime,
push, storage, funzionamento degradato offline e logica di dominio testabile.
La manutenzione è concentrata: velocità di iterazione e riduzione dei sistemi
operativi separati sono vincoli primari.

## Opzioni considerate

1. Flutter, Riverpod, Firebase e Drift.
2. React Native con Firebase.
3. Client nativi Kotlin e Swift.
4. Flutter con Bloc e un backend SQL gestito.

## Decisione

Adottiamo Flutter e Dart, Riverpod per lo stato, GoRouter per la navigazione,
Firebase per Auth/Firestore/Storage/Messaging e Drift per la cache SQL locale.
I provider nuovi preferiscono la generazione `@riverpod`; Drift e Riverpod
condividono la pipeline `build_runner`.

Le versioni esatte non appartengono all'ADR: `pubspec.yaml`, `pubspec.lock` e
la toolchain locale sono le fonti correnti.

## Conseguenze

- Una codebase copre sei piattaforme.
- Firebase riduce il carico backend ma aumenta il costo di una futura
  migrazione.
- Drift mantiene un modello locale tipato su native e Web/WASM.
- Firestore resta la sorgente remota; ogni repository deve esplicitare
  strategia di cache e conflitti.
- Dipendenze non usate o generatori non necessari devono essere rimossi.

Vedi [Architettura](../architettura/README.md),
[Stato](../architettura/state-management.md) e
[Persistenza](../architettura/persistence.md).

_Ultima revisione: 2026-07-29._
