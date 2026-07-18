# Final review blockers — root cause, fix e verifica

> L'esito iniziale sotto è storico. La seconda re-review, documentata in fondo,
> lo supera: delivery e timer sono ulteriormente corretti, mentre la membership
> PCM dei nuovi account resta un blocker decisionale esplicitamente aperto.

Data: 2026-07-18

Perimetro: sicurezza Firestore, retry Functions, timer remoto e parsing inbox.
Vincoli rispettati: nessuna custom claim inventata, nessuna dipendenza aggiunta,
nessun file generato modificato, nessun push o deploy.

## Esito

Sono chiusi tutti i finding Critical/Important ricevuti e il finding minore
sulla race di cancellazione. Le regole mantengono la compatibilità con profili
parziali e legacy; i retry non possono duplicare una consegna FCM già
terminalizzata; un primo snapshot remoto `null` non cancella più un timer
locale valido.

## Cause radice e correzioni

### 1. Confine tenant auto-assegnabile

**Causa radice.** Il proprietario poteva aggiornare liberamente
`users/{uid}.administration`, mentre lo stesso campo autorizzava letture e
scritture cross-user. Era quindi possibile spostarsi autonomamente nel tenant
di destinazione.

**Correzione.** Per i nuovi profili `administration` può essere assente/null
durante l'onboarding oppure essere impostata una sola volta al valore PCM. Una
volta non-null è immutabile. I profili legacy con amministrazioni diverse
restano aggiornabili negli altri campi, ma non possono cambiare tenant. Gli
accessi alle mappe usano `get(..., null)` per tollerare documenti parziali.

### 2. Retry del trigger neutralizzato

**Causa radice.** Il trigger poteva ritentare, ma il runtime catturava errori
precedenti a un esito FCM (lettura profilo/token e anti-spam), marcava il
documento `failed` e risolveva la Promise. Eventarc non riceveva più il
fallimento.

**Correzione.** Gli errori pre-esito sono registrati come errore operativo e
rilanciati, lasciando il claim `processing` recuperabile dopo la lease. Solo
gli esiti FCM terminali vengono finalizzati. Il trigger Firestore dichiara
esplicitamente `retry: true`.

### 3. Errori dei producer persi

**Causa radice.** Hourly reminder, timesheet ed exit reminder isolavano gli
errori trasformandoli in valori `false`; lo scheduler risultava riuscito anche
con uno o più utenti falliti.

**Correzione.** I batch attendono tutti i job con `Promise.allSettled` e poi
rilanciano un errore, così i job riusciti non vengono interrotti e il producer
fallito viene ritentato. Gli ID deterministici preservano l'idempotenza. Gli
scheduler hanno `retryCount: 3`; il trigger timesheet ha retry Eventarc.

### 4. Primo snapshot remoto null distruttivo sul Web

**Causa radice.** Il restore leggeva lo stato locale ma, al primo snapshot
remoto `null`, ignorava un timer locale attivo e cancellava le preferenze.

**Correzione.** Il primo `null` preserva e applica lo stato locale attivo, poi
lo risincronizza verso Firestore usando la stessa protezione a generazioni. Un
`null` osservato dopo uno snapshot remoto resta invece una cancellazione
autorevole.

### 5. Documento cross-user malformato avvelena l'inbox

**Causa radice.** `AppNotification.fromMap` usava cast diretti; un solo campo
con tipo errato poteva interrompere la deserializzazione dello stream.

**Correzione.** Le rules applicano allowlist, tipi, enum, stato, timestamp,
limiti e combinazioni ETA per ogni tipo social. Il parser resta tollerante verso
documenti legacy o corrotti e usa fallback sicuri senza propagare cast error.

### 6. Race di cancellazione durante il finalize

**Causa radice.** Il risultato veniva persistito con `set(..., merge: true)`;
se il destinatario eliminava la notifica dopo FCM, il finalize la ricreava.

**Correzione.** Il finalize usa `update`. Un documento eliminato non viene
ricreato e il retry successivo non duplica la push perché l'evento non esiste
più.

## TDD

Prima delle modifiche sono stati aggiunti test che riproducevano:

- amministrazione mutabile e schema cross-user non tipizzato;
- configurazione retry assente, errori pre-esito terminalizzati e producer che
  risolvevano nonostante fallimenti;
- race delete/finalize;
- primo snapshot remoto null con timer locale attivo;
- payload inbox con tipi incompatibili.

Il run Functions mirato era RED con 6 failure attese. I test Dart mirati erano
RED perché i nuovi contratti/comportamenti non esistevano ancora. Dopo le
correzioni, le stesse regressioni e l'intera suite sono GREEN.

## Verifica finale

```text
flutter test
139 test passati

flutter analyze
No issues found!

npm test --prefix functions
25 test passati, 0 falliti

node --test test/platform/firebase_messaging_sw_test.js
1 test passato, 0 falliti

node --check functions/index.js
node --check functions/notification_logic.js
node --check functions/notification_runtime.js
exit code 0

firebase deploy --only firestore:rules --dry-run
rules file firestore.rules compiled successfully
Dry run complete

git diff --check
exit code 0
```

Il comando Firebase era esclusivamente `--dry-run`: non ha pubblicato regole.
Il warning preesistente sulla proprietà `flutter` di `firebase.json` non
impedisce la compilazione.

## Rivalutazione rules audit

Lo score passa da 1 a 3. I blocker sul confine tenant, schema cross-user e
fail-open anti-spam sono chiusi. Restano fuori dal perimetro corrente:

- moderato: `isPrivate` è ancora una convenzione client e non una ACL rules;
- moderato: il rate limit avviene dopo create/Eventarc, quindi limita le push ma
  non il costo delle invocazioni abusive;
- minore: collezioni strettamente owner-only restano in parte schemaless.

La mitigazione strutturale dei primi due punti richiede rispettivamente una
separazione tra directory pubblica e profilo privato e un endpoint server
atomico con App Check; non sono modifiche sicure da introdurre come side-effect
di questo fix.

## Documentazione aggiornata

Aggiornati ADR 0008 e 0012, persistenza, profilo, onboarding, timer, social,
testing e changelog. Non è stata aggiunta una nuova ADR: le correzioni rendono
effettivi i confini e i retry già decisi, senza introdurre una nuova scelta
architetturale.

---

## Seconda re-review — finalize at-most-once e timer provenance

### Esito

Chiusi i due nuovi finding Important e i due hardening non controversi. Non è
stata introdotta alcuna authority fittizia. Resta aperto il confine di
membership per nuovi account: il set-once PCM impedisce cambi successivi ma
qualunque account autenticato può ancora dichiararsi PCM. La soluzione richiede
una scelta del prodotto tra inviti, allowlist o altra attestazione server-side.

### Delivery: doppio finalize failure

**Causa radice.** Dopo FCM, due errori consecutivi di `update` lasciavano il
documento `processing` senza prova che il dispatch esterno fosse già iniziato.
Il reclaim dopo la lease ripercorreva quindi il ramo FCM e poteva duplicare la
push.

**Fix.** Prima di FCM il runtime persiste `pushDispatchStartedAt` e
`pushDispatchTargetCount`. Un reclaim con marker non terminalizzato non
reinvia: finalizza `failed` con `notification/delivery-unknown`. Se la write
del marker fallisce, l'errore viene rilanciato prima di Messaging e il retry
post-lease può ancora consegnare normalmente. È una scelta at-most-once: un
crash tra marker e chiamata FCM può produrre unknown senza invio, ma non un
duplicato.

### Timer: provenance del locale e clear remoto

**Causa radice.** Le prefs non distinguevano una transizione offline ancora da
sincronizzare da una copia stale già confermata. Inoltre
`ActiveTimerRepository.clear()` ignorava il Future del delete, quindi i caller
proseguivano prima della rimozione Firestore.

**Fix.** `timer_pendingRemoteSync` viene scritto prima della write remota. Solo
un turno attivo con flag `true` prevale sul primo null; l'echo matching rimuove
il flag, mentre prefs attive con flag false/assente vengono cancellate. Il
delete è awaited. `markLocalClear()` impedisce che il null prodotto dal proprio
delete venga scambiato per assenza offline e risincronizzi il turno; end/reset
attendono il remoto prima di eliminare le prefs.

### Rules e parser

- delete client di `users/{uid}` negato, per bloccare il bypass legacy
  delete+recreate dell'amministrazione immutabile;
- fallback malformato `AppNotification` cambiato da azionabile
  `coffee_invite/pending` a neutro `unknown/info`.

### Evidenza TDD

```text
RED Functions mirato
26 test eseguiti: 24 pass, 2 fail attesi

RED Flutter mirato
6 failure attese: delete profilo, timer provenance/echo/clear-order, parser

RED clear-intent aggiuntivo
1 failure attesa: markLocalClear assente

GREEN mirato
Functions 26/26
Flutter 55/55
```

### Gate completo

```text
flutter test
144 test passati

flutter analyze
No issues found!

npm test --prefix functions
26 test passati, 0 falliti

node --test test/platform/firebase_messaging_sw_test.js
1 test passato, 0 falliti

node --check functions/index.js
node --check functions/notification_logic.js
node --check functions/notification_runtime.js
exit code 0

firebase deploy --only firestore:rules --dry-run
rules file firestore.rules compiled successfully
Dry run complete

git diff --check
exit code 0
```

Il comando Firebase è rimasto un dry-run: nessuna regola, Function o build è
stata pubblicata.
