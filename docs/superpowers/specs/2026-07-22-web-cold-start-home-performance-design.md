# Web cold start e Home fluida — Design

**Data:** 2026-07-22

**Stato:** approvato per la pianificazione

**Piattaforma prioritaria:** Flutter Web su Chrome e PWA. Scenario segnalato
principalmente su Samsung Galaxy S25 Ultra.

## Obiettivo

Eliminare tre difetti collegati del percorso iniziale e della Home:

1. intervallo vuoto prima del primo frame utile;
2. comparsa transitoria dell'onboarding per utenti che lo hanno già completato;
3. scrolling poco fluido della Home, anche dopo il ritorno da un'altra scheda.

L'esperienza deve essere cache-first: mostrare dati validi già disponibili e
usare una skeleton coerente con la Home soltanto quando la cache non basta.

## Evidenze e cause

### Primo frame bloccato

`main()` attende prima di `runApp`:

- download/caricamento dei font Google;
- inizializzazione Firebase;
- locale `it_IT`;
- `SharedPreferences` per tema e lingua.

Finché queste operazioni non terminano Flutter non può mostrare neppure la
skeleton già presente nella dashboard. `web/index.html` non contiene inoltre
un loader visivo durante l'avvio del motore Flutter.

### Flash onboarding

`hasProfileStreamProvider` riduce ogni `DocumentSnapshot` Firestore a un
booleano e perde `snapshot.metadata.isFromCache`. Un risultato cache mancante o
incompleto può quindi diventare `false` e portare il router su `/onboarding`
prima della risposta autorevole del server.

La precedente implementazione one-shot distingueva esplicitamente cache e
server. Il refactor reattivo ha mantenuto il caricamento e l'errore come stati
separati, ma ha eliminato questa distinzione per il valore `false`.

### Scroll Home

- Il `ListView` mobile contiene un'unica grande `Column` con tutti i widget
  ordinabili: l'albero completo viene costruito subito e non beneficia della
  costruzione lazy.
- `WorkTimer` aggiorna `currentTime` ogni secondo; `TimbraturaHero` osserva
  l'intero `TimerState`, ricostruendo un componente molto esteso per ogni tick.
- Il cursore di timbratura mantiene un'animazione periodica continua.
- La navbar web usa un `BackdropFilter` sopra contenuto in movimento: durante
  lo scroll il blur richiede compositing del livello sottostante.
- I singoli widget mantengono stream e contenuti propri anche quando si trovano
  molto sotto il viewport.

## Decisioni confermate

- Approccio cache-first mirato, senza introdurre una cache applicativa duplicata
  dell'intera Home.
- Alleggerimento grafico selettivo: si rimuovono solo effetti con costo misurabile
  nel percorso web mobile.
- Nessun onboarding derivato da un risultato Firestore solo-cache incompleto.
- Skeleton prima del caricamento quando non sono disponibili dati validi.
- Nuovi utenti: Home con la sola timbratura e un grande invito ad aggiungere il
  primo widget.
- Dopo il primo widget aggiuntivo la CTA grande scompare e resta il comando
  compatto attuale.
- Nuova posa Chigio approvata: mascotte con una singola tessera bianca e simbolo
  `+`, non la variante con una pila di tessere.

## Architettura di bootstrap

### Due skeleton coordinate

Il caricamento usa due livelli visivamente coerenti:

1. **HTML bootstrap skeleton** in `web/index.html`, visibile mentre vengono
   caricati motore e bundle Flutter;
2. **Flutter bootstrap skeleton**, montata dal primo `runApp` mentre terminano
   Firebase, preferenze, locale e configurazione cache.

La skeleton riproduce la gerarchia della Home mobile, non quattro rettangoli
generici: area hero, righe principali e una o due card. La transizione tra HTML,
Flutter bootstrap e Home deve mantenere sfondo e ingombri, evitando un flash
bianco o un salto di layout.

`main()` monta subito un widget di bootstrap con tema leggero e senza dipendenze
Firebase. L'inizializzazione asincrona avviene dopo `runApp`; solo al termine
viene montata `ChigioTimeApp` con i provider definitivi.

### Font

I font UI necessari al primo frame vengono inclusi negli asset dell'app. Il
bootstrap non attende richieste al CDN Google Fonts. Il font colore delle emoji
resta non bloccante e può completare il caricamento dopo il primo frame.

Non viene aggiunta una nuova dipendenza. La configurazione deve continuare a
supportare i simboli e la schwa già usati dalle stringhe italiane.

### Cache Firestore web

Dopo `Firebase.initializeApp` e prima di qualunque lettura Firestore viene
abilitata la persistenza locale IndexedDB. Poiché lo stesso utente usa sia una
scheda Chrome sia la PWA, la configurazione usa il gestore multi-tab di
FlutterFire.

Se IndexedDB non è disponibile, per esempio in un contesto browser ristretto,
il bootstrap degrada alla cache in memoria e continua ad avviare l'app. Il
fallimento della cache persistente non deve produrre onboarding né blocco
permanente.

## Gate profilo e routing

Il booleano `hasProfile` non rappresenta abbastanza stati. Il provider espone
un `ProfileGateResult` con uno `status` esplicito:

```text
resolving
completeCached
completeServer
incompleteServer
failure
```

`ProfileGateResult` include inoltre `hasUsableProfile` ed eventuale `error`.
Questo permette allo stato `failure` di distinguere il caso con profilo cache
valido, che resta sulla Home, dal caso senza dati utilizzabili, che mostra il
retry. Nomi e semantica costituiscono il contratto dell'implementazione.

### Sequenza

1. Firebase Auth risolve l'utente.
2. Un marker positivo `hasProfile_<uid>` può instradare subito verso la Home.
   Il marker non autorizza a mostrare dati fittizi: se profilo o mese non sono
   ancora disponibili la dashboard mostra la skeleton.
3. Il listener profilo usa snapshot con variazioni di metadata incluse.
4. Snapshot completo proveniente dalla cache:
   - consente la Home;
   - non è considerato conferma definitiva del server.
5. Snapshot incompleto proveniente soltanto dalla cache:
   - mantiene `resolving`;
   - non indirizza mai a `/onboarding`.
6. Snapshot server completo:
   - conferma la Home;
   - aggiorna il marker positivo.
7. Snapshot server incompleto o documento server assente:
   - rimuove l'eventuale marker positivo obsoleto;
   - indirizza a `/onboarding`.
8. Errore di rete o permessi:
   - con cache completa mantiene la Home e offre un retry non bloccante;
   - senza dati mostra errore umano e `Riprova` al posto della skeleton
     infinita;
   - non mostra l'onboarding.

`profileDocIsComplete` resta l'unica funzione che decide la completezza del
contenuto; router e stream non devono duplicarne i criteri.

## Caricamento Home

La Home non aspetta tutti gli stream secondari. I dati indispensabili sono:

- profilo, per visibilità e ordine;
- timesheet del mese, per lo stato della giornata e i calcoli principali.

Quando entrambi sono in cache, viene mostrata immediatamente l'ultima Home
valida e il server aggiorna in background. Se manca uno dei due, compare la
skeleton strutturale. Widget secondari come colleghi, stipendio, progetti e
catalogo sedi gestiscono loading ed errore nel proprio spazio senza bloccare
l'intera dashboard.

Un refresh non deve sostituire dati già visualizzati con valori vuoti o con una
skeleton globale: conserva l'ultimo valore valido finché arriva il successivo.

## Rendering lazy della Home

### Mobile web

La struttura diventa un `CustomScrollView` con sliver:

- hero in `SliverToBoxAdapter`;
- eventuali prompt, nota e alert come sezioni autonome;
- widget ordinabili in `SliverList` con builder lazy;
- CTA o comando finale come sliver dedicato.

La funzione che risolve un ID (`favorites`, `maggiorPresenza`, ecc.) in un
widget resta privata alla feature e conserva ordine, visibilità ed evidenza.
Non viene creato un nuovo layer di dominio per una scelta puramente
presentazionale.

Il delegate usa i repaint boundary standard di Flutter. Non si aumenta
arbitrariamente il `cacheExtent`: l'obiettivo è evitare di montare in anticipo
tutta la pagina.

### Desktop

Il layout a due colonne resta invariato a livello visivo. La riorganizzazione
estrae gli stessi builder riutilizzabili senza forzare una riscrittura desktop
non necessaria al problema prioritario.

## Isolamento dei tick live

`WorkTimer` può continuare ad avere risoluzione al secondo per la pausa live e
gli eventi temporali, ma non deve invalidare tutto l'hero.

Il consumo dello stato viene separato in tre granularità:

- **strutturale:** stato turno, timestamp di entrata/pausa, totali e preferenze;
  ricostruisce la sezione soltanto a un'azione reale o a una sincronizzazione;
- **al minuto:** progresso, uscita prevista e valori che non cambiano ogni
  secondo;
- **al secondo:** solo testo della pausa/countdown e altri indicatori che
  mostrano esplicitamente i secondi.

Riverpod `select` o provider derivati devono restituire valori stabili tra due
tick irrilevanti. I piccoli consumer live sono confinati vicino al testo che
aggiornano.

Il timer Pomodoro resta indipendente e viene creato soltanto se la relativa
card è visibile nel viewport.

## Alleggerimento grafico mirato

Su Flutter Web mobile:

- la floating navbar sostituisce `BackdropFilter` con una superficie
  traslucida/gradiente equivalente, mantenendo bordo, pill attiva e contrasto;
- il cursore della timbratura esegue un singolo invito animato dopo il montaggio
  e poi si ferma; riparte solo dopo una nuova fase rilevante, non in loop
  permanente;
- ombre molto ampie vengono ridotte solo nei componenti che scorrono;
- Aurora resta statica come già implementato.

Non vengono rimossi microfeedback di tap, transizioni di stato, identità glass
su native o animazioni funzionali. L'approccio 3 è quindi applicato con
parsimonia e soltanto al percorso che produce jank.

## Skeleton UI

La skeleton Flutter usa un'unica animazione condivisa per l'intera schermata,
rispetta `MediaQuery.disableAnimations` e non crea un controller per ogni tile.

Sagome previste:

- hero con header, due righe e controllo principale;
- eventuale CTA/area introduttiva;
- una o due card con altezza coerente con il primo viewport.

Su cache valida la skeleton globale non viene mostrata. I placeholder dei
singoli widget possono comparire solo dentro il relativo sliver.

## Home vuota e nuovo Chigio

L'onboarding continua a salvare tutti gli ID di `AppConstants.homeWidgetIds` in
`hiddenHomeWidgets`, quindi un nuovo utente vede:

1. `TimbraturaHero`;
2. una grande card di invito;
3. nessun widget secondario.

La stessa card compare ogni volta che il numero di widget aggiuntivi visibili è
zero, anche se un utente esistente li nasconde manualmente tutti.

### Contenuto approvato

- Asset: `assets/images/chigio-aggiungi-widget.png`.
- Posa: Chigio con una singola tessera bianca arrotondata e simbolo blu `+`.
- Titolo: `Costruisci la tua Home`.
- Testo: `Scegli i widget che ti servono ogni giorno. Puoi cambiarli quando
  vuoi.`
- CTA primaria full-width: `Aggiungi widget`.

Il tap apre il pannello esistente `showHomeWidgetsPanel`.

Il PNG generato viene rifinito come cutout trasparente, ridimensionato alla
risoluzione effettivamente necessaria e verificato su sfondo chiaro/scuro. Non
contiene testo rasterizzato; copy e accessibilità restano widget Flutter.

### Passaggio alla modalità compatta

Appena esiste **un solo** widget aggiuntivo visibile:

- la card grande scompare;
- compare il link compatto attuale `Modifica widget` in fondo alla Home.

Se tutti i widget vengono nascosti, la card grande ritorna. La condizione
attuale basata su più di un widget deve quindi diventare `zero` contro `uno o
più`, non `uno` contro `più di uno`.

## Errori e fallback

- Loader HTML: se il bundle impiega tempo, resta visibile senza pagina bianca.
- Bootstrap Flutter: errore Firebase recuperabile con messaggio umano e retry.
- Cache IndexedDB non disponibile: fallback memoria, senza onboarding.
- Profilo cache completo ma rete assente: Home leggibile, indicazione non
  bloccante soltanto se serve un'azione online.
- Profilo senza cache e rete assente: errore con retry; mai presunzione di nuovo
  utente.
- Widget secondario in errore: errore locale alla card, senza sostituire la
  dashboard completa.

## Test e verifica

### Automatici

- gate profilo: cache incompleta non causa onboarding;
- gate profilo: server incompleto causa onboarding;
- gate profilo: cache completa consente Home e server completo la conferma;
- gate profilo: errore non reindirizza a onboarding;
- configurazione cache web multi-tab applicata prima della prima lettura;
- bootstrap: skeleton iniziale, successo e retry errore;
- loader HTML presente e rimosso/occultato all'avvio Flutter;
- dashboard con zero widget: mascotte, copy e CTA grande;
- dashboard con un widget: nessuna card grande, comando compatto presente;
- dashboard con più widget: lista ordinata e comando compatto;
- nascondere l'ultimo widget ripristina l'empty state;
- builder sliver non costruisce widget molto fuori viewport al primo pump;
- tick al secondo non ricostruisce le parti stabili dell'hero;
- contrasto e semantics della CTA;
- `flutter analyze`, `flutter test` e build Web release.

### Smoke su dispositivo

Sul Galaxy S25 Ultra, sia Chrome sia PWA:

1. hard refresh da sessione autenticata;
2. chiusura e riapertura PWA;
3. cold start con cache valida;
4. cold start dopo cancellazione dati sito;
5. avvio offline con cache valida;
6. passaggio Home → altra scheda → Home;
7. scroll completo con tutti i widget attivati;
8. nuovo account con sola timbratura e aggiunta del primo widget.

Criteri visibili:

- nessun frame di login/onboarding per un profilo completo;
- skeleton o Home cache, mai pagina vuota;
- nessun salto da valori vuoti a valori reali;
- scroll fluido anche dopo il ritorno alla Home;
- CTA grande presente solo con zero widget aggiuntivi.

Per la diagnosi prestazionale finale si usa Chrome Performance/DevTools in
build profile o release, controllando long frame, raster/compositing e rebuild.
Il solo superamento di test widget non è prova sufficiente dello scroll reale.

## Documentazione da aggiornare durante l'implementazione

- nuova ADR per bootstrap cache-first e gate server-autorevole;
- `docs/architettura/navigation.md`;
- `docs/architettura/state-management.md`;
- `docs/architettura/persistence.md`;
- `docs/funzionalita/authentication.md`;
- `docs/funzionalita/dashboard.md`;
- `docs/processi/testing.md`;
- `docs/CHANGELOG.md`.

## Fuori scope

- cache applicativa duplicata dell'intero modello Home;
- redesign generale dell'identità glass;
- rimozione indiscriminata delle animazioni native;
- modifica dei contenuti o delle regole di dominio dei widget;
- refactor delle altre schermate solo perché condividono componenti visivi;
- misurazioni definitive su dispositivi diversi dal Galaxy prioritario prima
  che il percorso principale sia verificato.
