# ADR-0012 — Notifiche Firebase inbox-first e multi-device

- **Data:** 2026-07-18
- **Autore/i:** Codex
- **Stato:** Accepted
- **Contesto correlato:** [`persistence.md`](../architettura/persistence.md),
  [`timer-state.md`](../entita/timer-state.md),
  [`profile.md`](../funzionalita/profile.md),
  [`social.md`](../funzionalita/social.md)

## Contesto

Le notifiche sociali e automatiche seguivano percorsi diversi: alcuni eventi
scrivevano l'inbox Firestore, altri dipendevano dal ticker Flutter o da invii
FCM diretti. Il modello non garantiva il reminder a app chiusa, una consegna
coerente a più installazioni, il rispetto uniforme del periodo Non disturbare
o un esito osservabile. I toggle legacy `notifyClockIn`, `notifyClockOut` e
`notifyWeekly` non corrispondevano inoltre a comportamenti attivi.

## Opzioni considerate

1. **Reminder e notifiche locali nel client** — semplici quando l'app è
   attiva, ma fragili a processo terminato e difficili da sincronizzare fra
   dispositivi.
2. **Invio FCM diretto da ogni produttore** — consegna in background, ma
   duplica DND, routing, token cleanup e osservabilità in più Function.
3. **Inbox Firestore come sorgente unica, con una Function di delivery** —
   ogni produttore crea prima un documento; il trigger applica il contratto
   comune e invia FCM a tutte le installazioni.

## Decisione

Adottiamo l'**opzione 3**. Ogni evento vive prima in
`users/{uid}/notifications/{notificationId}`. La Function
`onNotificationCreated` è l'unico punto di consegna FCM: applica DND, risolve
copy e route allowlisted, invia multicast, rimuove i token definitivamente
invalidi e persiste l'esito sul documento inbox.

Il client registra una voce per installazione in
`users/{uid}/private/fcm.installations.{installationId}`. Durante la migrazione
la Function legge anche `private/fcm.token` e `users/{uid}.fcmToken`; i token
legacy vengono eliminati progressivamente.

In foreground l'app mostra il messaggio nell'interfaccia. In background o a
processo terminato, Android, iOS, macOS e Web presentano il payload FCM tramite
il sistema operativo/browser. Non viene introdotto un plugin di notifiche
locali native.

### Eventi automatici e reminder

- `hourlyNotifications` crea inbox deterministiche per
  `morning_colleagues`, `weekly_recap` e `payday`;
- `onTimesheetWritten` crea `overtime_threshold` al primo superamento mensile;
- `exitReminders`, scheduled Function ogni minuto, interroga il collection
  group `activeTimer` per `reminderAt <= now`, reclama il reminder in
  transazione e crea `exit-{date}`.

Non viene creata una Cloud Task per ogni turno: la granularità al minuto e il
volume attuale rendono sufficiente `onSchedule` (Cloud Scheduler + Cloud
Functions v2). Questa scelta richiede l'indice collection-group
`activeTimer.reminderAt` versionato in `firestore.indexes.json`.

## Conseguenze

- **Positive:** l'inbox resta disponibile anche quando la push è soppressa o
  fallisce; DND è applicato server-side a tutte le push tranne `test`; route,
  copy, retry e cleanup token hanno un solo contratto; ogni installazione
  riceve lo stesso evento e il logout rimuove solo quella corrente.
- **Osservabilità:** `pushStatus` attraversa `processing` e termina in `sent`,
  `suppressed`, `no-token` o `failed`; `pushedAt`, contatori di consegna e
  campi errore restano nel documento inbox. `pushClaimedAt` e
  `pushClaimAttempt` rendono osservabili lease e tentativi di claim.
- **Piattaforme:** FCM è inizializzato su Android, iOS, macOS e Web.
  Windows/Linux restano operativi senza push. Su Apple l'upload della chiave
  APNs in Firebase e una build firmata sono prerequisiti esterni al repo.
- **Limiti:** il reminder ha precisione al minuto; ogni esecuzione legge al
  massimo 100 timer scaduti; la consegna live dipende da permessi utente,
  configurazione FCM/APNs e connettività. Il recap copre da lunedì al momento
  dell'invio, non una settimana già conclusa.
- **Migrazione:** i campi profilo `notifyClockIn`, `notifyClockOut` e
  `notifyWeekly` vengono cancellati al successivo salvataggio delle preferenze.
  I token singoli legacy restano solo come fallback temporaneo.

### Compatibilità anti-spam legacy

La versione Functions distribuita prima di questa decisione scriveva
`abuseBans/{uid}` oltre la soglia. Il backend corrente non crea nuovi ban, ma
le rules mantengono un gate **read-only** su `until > request.time`: gli
eventuali documenti già presenti restano quindi onorati fino alla scadenza e
non esiste alcun `match` client sulla collezione.

La presenza dei documenti live non è stata verificabile con le credenziali
Firebase CLI disponibili (Firestore REST ha risposto HTTP 403). Il gate potrà
essere rimosso solo dopo inventario con identità IAM autorizzata e cleanup dei
residui; fino ad allora evita una regressione rispetto alle rules già
distribuite.

## Deploy

Rules, indice e Function devono essere distribuiti nello stesso gate:

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Omettere `firestore:indexes` lascia `exitReminders` senza il contratto di query
collection-group richiesto.

Implementazione repository completata; deploy e prova live restano nel gate
operativo successivo.
