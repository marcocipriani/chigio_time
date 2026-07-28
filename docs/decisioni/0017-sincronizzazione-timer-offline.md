# ADR-0017 — Sincronizzazione offline del timer

- **Data:** 2026-07-19
- **Documentata:** 2026-07-29
- **Owner:** Marco Cipriani
- **Stato:** Accepted

## Contesto

Il timer deve rispondere subito, sopravvivere a riavvio e rete instabile e
sincronizzarsi tra dispositivi. Snapshot Firestore da cache o con write pending
non provano che il server abbia accettato la mutazione. Cancellazioni
interrotte possono inoltre resuscitare un turno già chiuso.

## Opzioni considerate

1. Stato solo remoto, bloccando l'interazione durante la rete.
2. Stato locale ottimistico senza protocollo di riconciliazione.
3. Stato locale responsivo con marker persistiti, metadata Firestore e
   generazioni monotone.

## Decisione

Adottiamo l'opzione 3.

- SharedPreferences conserva stato del giorno e
  `timer_pendingRemoteSync` finché arriva un echo server confermato.
- Snapshot pending o provenienti dalla cache non cancellano il marker.
- Ogni start, pausa e ripresa incrementa una generazione; risultati asincroni
  vecchi non possono sovrascrivere una mutazione più recente.
- Fine turno e reset persistono `timer_clearPending` prima del delete remoto.
  Lo stato locale viene ripulito solo dopo il completamento coerente.
- Al riavvio un clear incompleto riprende la cancellazione invece di
  risincronizzare il turno.

## Conseguenze

- La UI resta immediata e la semantica offline è deterministica.
- Il protocollo richiede test di race, metadata e crash-recovery.
- Firestore resta autoritativo sul multi-device, ma non può annullare una
  mutazione locale più recente.
- Il documento attivo è `users/{uid}/activeTimer/state`; il Pomodoro usa un
  documento distinto nel proprio repository.

Vedi [TimerState](../entita/timer-state.md),
[Orario e presenza](../funzionalita/orario-e-presenza.md) e
[Notifiche](./0012-notifiche-firebase-inbox-first.md).

_Ultima revisione: 2026-07-29._
