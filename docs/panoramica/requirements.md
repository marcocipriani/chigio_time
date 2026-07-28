# Requisiti

Questo documento descrive il comportamento richiesto alla versione corrente.
Le scelte implementative non ovvie sono nelle [ADR](../decisioni/README.md).

## Requisiti funzionali

### Autenticazione e profilo iniziale

- **RF-01** — Accesso con Google oppure email e password.
- **RF-02** — Registrazione email, recupero password e logout.
- **RF-03** — L’autenticazione Firebase pilota il routing.
- **RF-04** — Un utente senza profilo server completo viene indirizzato
  all’onboarding.
- **RF-05** — Cache incompleta, loading o errore non devono essere interpretati
  come nuovo utente.
- **RF-06** — L’onboarding raccoglie dati personali, inquadramento, orario,
  soglia buono pasto, cap mensili, struttura e sede PCM.
- **RF-07** — `Dipartimento/Struttura` e sede provengono dallo stesso catalogo
  canonico; la sede consigliata non viene selezionata automaticamente.
- **RF-08** — Profili PCM non più validi ricevono un gate mirato di
  riallineamento, non un nuovo onboarding completo.

### Turno e Home

- **RF-09** — L’utente registra entrata e uscita scegliendo l’orario effettivo.
- **RF-10** — Durante il turno può registrare pausa pranzo, pausa breve e
  permesso orario.
- **RF-11** — L’app calcola ore nette, uscita prevista, deficit, maggior
  presenza e maturazione del buono pasto.
- **RF-12** — La pausa pranzo forzata usa la regola a tre zone:
  `< 9h = 0`, `9h–9h29 = eccedenza oltre 9h`, `≥ 9h30 = 30 minuti`.
- **RF-13** — Lo stato attivo sopravvive al riavvio locale ed è sincronizzato
  tra dispositivi tramite Firestore.
- **RF-14** — Echo locali, cache e conferme server devono restare distinguibili
  durante la riconciliazione del timer.
- **RF-15** — Una giornata ancora attiva alle 21:00 diventa incompleta e
  richiede correzione o annullamento esplicito.
- **RF-16** — Il reminder di uscita viene creato server-side e può funzionare
  ad app chiusa.
- **RF-17** — I widget Home possono essere ordinati, nascosti e messi in
  evidenza; la timbratura non è rimovibile.
- **RF-18** — Con zero widget secondari l’Home mostra una CTA per aggiungere il
  primo widget.

### Cartellino e assenze

- **RF-19** — Un giorno è identificato da `YYYY-MM-DD` e persiste in
  `users/{uid}/timesheets/{dateId}`.
- **RF-20** — Il Cartellino offre le viste Giorno, Lista, Settimana, Mese e
  Anno.
- **RF-21** — Una giornata può contenere più segmenti di lavoro e permessi
  orari.
- **RF-22** — I totali di una giornata con segmenti vengono ricalcolati da una
  sola funzione di dominio prima del salvataggio.
- **RF-23** — I documenti legacy senza `segments` vengono letti senza
  migrazione batch.
- **RF-24** — Sono supportati presenza, smart working, ferie e permesso.
- **RF-25** — Le causali di assenza possono registrare unità, durata, periodo,
  quota, sensibilità, nota privata e documentazione.
- **RF-26** — L’import CSV mostra anteprima, sostituzioni e righe rifiutate
  prima della conferma.
- **RF-27** — L’utente può esportare CSV, PDF e cartellino PCM.

### Colleghi e notifiche

- **RF-28** — La rubrica mostra soltanto colleghi della stessa
  amministrazione.
- **RF-29** — L’utente può creare gruppi privati e gestirne i membri.
- **RF-30** — Inviti caffè, risposte e collegamenti usano documenti tipizzati.
- **RF-31** — Ogni evento di notifica viene scritto prima nell’inbox Firestore.
- **RF-32** — Un unico delivery backend applica DND, routing, invio
  multi-device, retry e cleanup token.
- **RF-33** — Le notifiche di prova ignorano DND e mostrano nell’app l’esito
  della consegna.
- **RF-34** — Route sconosciute o payload malformati degradano a una
  destinazione neutra e non azionabile.

### Profilo, progetti e stipendio

- **RF-35** — Il profilo permette di modificare dati personali, sede,
  inquadramento, preferenze, notifiche e visibilità.
- **RF-36** — I cap contrattuali sono storicizzati per periodo mensile.
- **RF-37** — Progetti personali o condivisi supportano timer Pomodoro 25/5 e
  45/15 e riepiloghi per utente.
- **RF-38** — Il proprietario del progetto gestisce visibilità e membership;
  ogni collaboratore scrive soltanto le proprie sessioni.
- **RF-39** — Lo storico stipendiale registra data, tipologia, lordo, netto e
  note.
- **RF-40** — La pagina Stipendio calcola il prossimo accredito e una stima
  basata sui pagamenti ordinari registrati.

### Catalogo PCM e riferimenti

- **RF-41** — Il catalogo PCM contiene 50 strutture e 12 sedi fisiche
  validate.
- **RF-42** — La precedenza è remoto valido, cache Drift valida, payload
  bundled.
- **RF-43** — Un payload remoto parziale o malformato non sostituisce la cache.
- **RF-44** — Il lettore CCNL offre i testi 2016–2018 e 2019–2021 con indice e
  ricerca nell’indice.

## Requisiti non funzionali

| Codice | Requisito |
|---|---|
| RNF-01 | Un’unica codebase Flutter per Web, Android, iOS, macOS, Windows e Linux. |
| RNF-02 | UI e dominio in italiano; localizzazione framework IT/EN disponibile, copy applicativo oggi prevalentemente italiano. |
| RNF-03 | Errori, loading e stato vuoto devono essere rappresentati separatamente. |
| RNF-04 | Primo paint Web con skeleton HTML e Flutter; nessuna pagina bianca durante il bootstrap. |
| RNF-05 | Cache Firestore persistente multi-tab sul Web con fallback in memoria. |
| RNF-06 | Drift cache per timesheet e catalogo PCM; su errore di inizializzazione il client degrada senza bloccare l’app. |
| RNF-07 | Dati sensibili owner-only; credenziali e token mai nel repository. |
| RNF-08 | `flutter analyze` e suite automatiche verdi prima del rilascio. |
| RNF-09 | Animazioni rispettano `disableAnimations`; touch target minimi e contrasti sono coperti da test mirati. |
| RNF-10 | Migrazioni amministrative idempotenti, dry-run per default e verificate con read-back. |

## Vincoli di dominio

- Il portale istituzionale resta la fonte autoritativa.
- L’app non gestisce autorizzazioni amministrative.
- Le date operative usano il fuso `Europe/Rome`.
- `dateId` è la chiave naturale giornaliera.
- Art.9 indica maggior presenza; i permessi brevi sono Art.35; BOE è un
  modificatore intra-giornaliero.
- Le causali e i conteggi personali non sostituiscono un’interpretazione
  giuridica o un calcolo dell’amministrazione.

## Fuori scope

- timbratura biometrica, NFC o integrazione con tornelli;
- sincronizzazione bidirezionale con il sistema ufficiale;
- workflow autorizzativo o pannello manager;
- geofencing in background senza conferma;
- push su Windows e Linux;
- import NoiPA tramite scraping autenticato.

## Tracciabilità

| Area | Codice principale | Documentazione |
|---|---|---|
| Auth e gate profilo | `lib/features/authentication/`, `lib/features/profile/domain/profile_gate.dart` | [Autenticazione](../funzionalita/authentication.md), [ADR-0014](../decisioni/0014-bootstrap-web-cache-first.md) |
| Timer | `lib/features/dashboard/` | [Orario e presenza](../funzionalita/orario-e-presenza.md), [ADR-0017](../decisioni/0017-sincronizzazione-timer-offline.md) |
| Cartellino | `lib/features/timesheet/` | [Timesheet](../funzionalita/timesheet.md), [ADR-0016](../decisioni/0016-segmenti-giornalieri.md) |
| Notifiche | `lib/core/services/`, `functions/` | [ADR-0012](../decisioni/0012-notifiche-firebase-inbox-first.md) |
| Catalogo PCM | `lib/core/data/pcm_catalog.dart` | [ADR-0013](../decisioni/0013-catalogo-pcm-firestore-con-fallback-offline.md) |
| Sicurezza | `firestore.rules`, `storage.rules` | [Sicurezza](../architettura/sicurezza.md), [ADR-0008](../decisioni/0008-firestore-read-scoping.md) |

_Ultima revisione: 2026-07-29 — requisiti riallineati alla versione
2026.7.22+22._
