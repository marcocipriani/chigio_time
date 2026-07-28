# Sicurezza

Questa pagina descrive confini di fiducia, protezioni correnti e rischi aperti.
Le Security Rules versionate sono il contratto eseguibile; la documentazione
non le sostituisce.

## Confini

| Dato | Accesso previsto |
|---|---|
| profilo directory `users/{uid}` | proprietario e utenti della stessa amministrazione |
| `users/{uid}/private/*` | solo proprietario e backend autorizzato |
| timesheet, timer, gruppi, colleghi | solo proprietario |
| notifiche social cross-user | create ristretto, lettura del destinatario |
| progetti | membri o progetto condiviso; scritture per ruolo |
| catalogo PCM | `get` autenticato sul documento esatto; nessuna write client |
| foto profilo | lettura autenticata; write soltanto sul proprio file e con limiti |

## Profilo pubblico e dati privati

Il documento `users/{uid}` alimenta la rubrica. Non deve contenere:

- totalizzatori HR;
- token FCM;
- credenziali;
- note sanitarie;
- dati non necessari ai colleghi.

Totalizzatori e installazioni FCM vivono in `private/portale` e `private/fcm`.

## Autorità dell’amministrazione

`administration` è impostabile dal client una sola volta al valore PCM e poi
immutabile. Questo impedisce cambi tenant successivi, ma **non dimostra la
membership reale**: oggi qualunque account autenticato può dichiararsi PCM al
primo set.

La chiusura richiede una scelta prodotto esplicita:

- invito;
- allowlist;
- custom claim o attestazione server-side equivalente.

Non va simulata un’autorità inesistente solo nelle rules client.

## Notifiche

Le notifiche cross-user:

- richiedono stessa amministrazione;
- vincolano `fromUid` all’utente autenticato;
- accettano soltanto type e campi allowlisted;
- applicano limiti di lunghezza e tipo;
- sono sottoposte a rate limit backend e concorrenza limitata.

Il rate limit avviene dopo la create Firestore/Eventarc: limita push e abuso
funzionale, non elimina il costo di invocazioni malevole. Una protezione più
forte richiederebbe endpoint atomico server-side e App Check.

## Privacy social

`isPrivate` è oggi una convenzione applicativa: la discovery filtra il profilo,
ma le rules non implementano una ACL basata su quel campo. Cambiare questo
comportamento richiede ridisegnare directory pubblica e profilo privato per non
rompere le query Firestore.

## Credenziali e operazioni amministrative

- Nessuna service-account key nel repository.
- Le variabili che puntano a credenziali restano locali.
- Gli script amministrativi sono dry-run per default.
- Gli output non devono stampare token o profili completi.
- Dopo una write è obbligatorio il read-back dei soli campi coinvolti.

## Verifica

```bash
flutter test test/security/firestore_rules_test.dart
firebase deploy --only firestore:rules --dry-run
node --check functions/index.js
node --check functions/notification_logic.js
node --check functions/notification_runtime.js
```

Il test Dart verifica il contratto testuale delle rules, non i casi allow/deny
su emulatore. Prima di modifiche ad alto rischio va aggiunto uno smoke o un test
comportamentale appropriato.

## Rischi aperti

1. Membership PCM auto-dichiarabile al primo profilo.
2. `isPrivate` applicato lato client.
3. Alcune collezioni owner-only non hanno schema completo nelle rules.
4. Il rate limit non previene il costo Eventarc di create abusive.

Vedi [ADR-0008](../decisioni/0008-firestore-read-scoping.md) e
[ADR-0012](../decisioni/0012-notifiche-firebase-inbox-first.md).

_Ultima revisione: 2026-07-29._
