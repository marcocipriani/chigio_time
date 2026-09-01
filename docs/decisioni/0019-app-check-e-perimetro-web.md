# ADR-0019 — App Check e irrigidimento del perimetro web

- **Data:** 2026-08-31
- **Owner:** Marco Cipriani
- **Stato:** Accepted
- **Contesto correlato:** [ADR-0008](0008-firestore-read-scoping.md), `firestore.rules`, `firebase.json`, [`app_bootstrap.dart`](../../lib/app/bootstrap/app_bootstrap.dart)

## Contesto

Audit di sicurezza pre-rilascio, agosto 2026. Le regole Firestore e Storage
sono risultate solide: scoping per amministrazione sulle letture profilo
(ADR-0008), allowlist di campi sulle notifiche cross-utente, `delete: if false`
sui profili, catalogo PCM non enumerabile, Storage chiuso salvo le foto
profilo. L'**autorizzazione** è coperta.

Restava scoperta l'**autenticità del chiamante**. La configurazione Firebase
Web è pubblica per costruzione (`firebase_options.dart`, `firebase-messaging-sw.js`):
chiunque la copi e faccia login con Google può parlare con Firestore da uno
script, fuori dall'app. Le regole reggono — nessuno legge dati che non gli
spettano — ma il traffico non è legato all'applicazione pubblicata, e il rate
non è governabile. Per un'app che tiene le presenze di una PA è il controllo
più rilevante che mancava.

In parallelo, l'hosting non emetteva alcun header di sicurezza: la pagina era
incorniciabile in un iframe di terzi (clickjacking sulla timbratura) e il
`Referer` usciva completo verso terze parti.

## Opzioni considerate

1. **Nessuna attestazione, solo regole** — zero lavoro. Le regole restano
   corrette, ma il perimetro è "chiunque abbia un account Google e la config".
2. **App Check con reCAPTCHA Enterprise** — attestazione più forte su web, ma
   reCAPTCHA Enterprise richiede la fatturazione attiva; il progetto è sul
   piano Spark (vedi `functions` non distribuibili).
3. **App Check con reCAPTCHA v3 su web, Play Integrity su Android, DeviceCheck
   su iOS** — gratuito su tutti e tre, copre le piattaforme distribuite.

Il progetto è passato al piano Blaze il 2026-08-31, quindi reCAPTCHA Enterprise
sarebbe ora sostenibile; resta comunque l'opzione 3, perché v3 basta a legare il
traffico all'app e non introduce un costo variabile su ogni caricamento.

## Decisione

Adottiamo l'opzione 3. `activateAppCheck()` viene chiamata subito dopo
`Firebase.initializeApp`, prima di qualunque uso di Firestore.

La chiave del sito reCAPTCHA non sta nel sorgente: arriva da
`--dart-define=APP_CHECK_RECAPTCHA_KEY`, che `deploy.sh` passa leggendo
l'omonima variabile d'ambiente. Non è un segreto (viaggia nella pagina), ma
cambia tra progetti Firebase e non deve essere committata. Senza chiave
l'attivazione è un no-op: i build locali e i test continuano a funzionare.

Un fallimento dell'attivazione non blocca l'avvio, viene solo loggato: finché
l'enforcement è spento in console il traffico passa comunque, e un'app che non
parte per un problema di attestazione sarebbe un disservizio peggiore del
rischio che evita.

Sull'hosting (`firebase.json`, target `main`) aggiungiamo quattro header su
qualunque risorsa: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
`Referrer-Policy: strict-origin-when-cross-origin` e
`Cross-Origin-Opener-Policy: same-origin-allow-popups`.

Il valore del COOP è stato verificato, non dedotto. Il popup di
`signInWithPopup` atterra su `chigio-time-pcm.firebaseapp.com/__/auth/handler`,
che non emette alcun COOP (`unsafe-none`), e parla all'apritore via
`window.opener.postMessage`. Con Chrome headless, un apritore servito da
`firebase serve` con i nostri header e un popup cross-origin senza COOP:

| COOP dell'apritore          | esito             |
|-----------------------------|-------------------|
| assente (baseline)          | opener conservato |
| `same-origin-allow-popups`  | opener conservato |
| `same-origin`               | **opener perso**  |

Il controllo negativo conferma che il test discrimina davvero: con
`same-origin` il login si romperebbe, con `same-origin-allow-popups` no.

## Conseguenze

- **Positive:** il traffico Firestore/Storage diventa attribuibile all'app
  pubblicata; la pagina non è più incorniciabile; il `Referer` non esce intero.
- **Negative / debiti tecnici:** l'attestazione non serve a niente finché
  l'enforcement resta spento in console — il codice è la metà del lavoro.
  Accendere l'enforcement con un build privo di chiave **spegne l'app
  pubblicata**: prima verificare in console che le richieste verificate
  risultino ~100%. E vedi il vincolo Play Integrity qui sotto: oggi
  l'enforcement romperebbe l'APK distribuito via GitHub.
- **Migrazione:** vedi il runbook sotto. Nessuna migrazione dati.

## Enforcement: resta spento (deciso il 2026-09-01)

**Play Integrity attesta solo le app installate da Google Play.** L'APK di
Chigio Time viene distribuito come asset di una release GitHub, quindi
un'installazione sideload non ottiene un verdetto valido e App Check non emette
il token.

L'enforcement però **si accende per servizio Firebase, non per piattaforma**:
attivarlo su Firestore vale insieme per web, Android e iOS. Accenderlo oggi
significherebbe quindi far smettere di funzionare l'app Android installata da
GitHub, lasciando funzionante solo il web.

Opzioni valutate:

1. Pubblicare l'app su Google Play, anche solo in *internal testing*: basta a
   far funzionare Play Integrity. Il certificato di firma da registrare ha
   SHA-256 `73403383a641ea06e37ddf33cc6b8a5ff0b48c0c8d6c4dde27c364146c533d2d`.
2. **Tenere l'enforcement spento e usare App Check come misura**: la console
   mostra quanta parte del traffico non è attestata, senza bloccare nulla.
3. Accendere l'enforcement accettando di rompere l'APK sideload.

**Decisione: opzione 2.** L'enforcement senza la pubblicazione su Play sarebbe
un autogol, e la sola visibilità su quanto traffico non è attestato è già più
di quello che si aveva prima. Da rivedere se e quando l'app arriva su Play:
a quel punto l'opzione 1 sblocca l'enforcement per tutte le piattaforme.

Finché la decisione regge, **registrare comunque i provider**: senza, la console
non ha metriche da mostrare e App Check non serve nemmeno come misura.

## Runbook di attivazione (console, non automatizzabile da qui)

0. **Abilitare App Check** — al 2026-09-01 l'API `firebaseappcheck.googleapis.com`
   risulta **disattivata** sul progetto: nessun provider registrato, nessuna
   metrica. Basta aprire Firebase console › App Check per abilitarla.
1. **reCAPTCHA v3** — console Google reCAPTCHA (tipo *v3*, non Enterprise:
   Enterprise vuole la fatturazione). Domini: `chigiotime.web.app`,
   `chigiotime.firebaseapp.com` e l'eventuale dominio custom. Copiare la
   **site key**.
2. **Firebase console › App Check › app Web** — registrare il provider
   reCAPTCHA v3 con quella site key.
3. **App Check › app Android** — provider Play Integrity. Attenzione: attesta
   solo le installazioni provenienti da Google Play, vedi la sezione
   sull'enforcement. **App Check › app iOS** — provider DeviceCheck (App Attest
   richiede iOS 14+); oggi non c'è comunque un build iOS distribuibile.
4. **Debug token** per gli emulatori e i build di sviluppo, altrimenti dopo
   l'enforcement lo sviluppo locale non legge più nulla.
5. Rilasciare con la chiave: `APP_CHECK_RECAPTCHA_KEY=<site-key> ./deploy.sh`.
6. Lasciare l'enforcement **spento** e guardare le metriche App Check
   (Firestore e Storage). Per la decisione presa sopra questo è il punto di
   arrivo, non un passaggio: l'enforcement si accende solo dopo la
   pubblicazione su Google Play, una API alla volta e con le richieste
   verificate stabilmente vicine al 100%.

## Rischi accettati consapevolmente

- **Nessuna allowlist di campi su `users/{userId}` in update.** Il proprietario
  può scrivere qualunque campo del proprio documento, inclusi quelli che altri
  utenti e `hourlyNotifications` leggono (`currentStatus`, `statusDate`,
  `name`). Sono tutti dati auto-dichiarati: mentire su di essi equivale a
  mentire nell'interfaccia. Una allowlist su un documento con decine di campi
  in evoluzione si romperebbe a ogni nuovo campo, e ogni rottura sarebbe un
  salvataggio profilo che fallisce in produzione. Non ne vale il prezzo finché
  nel documento non entra un campo con valore per qualcun altro.
- **API key Web pubbliche nel repository.** Sono identificatori di progetto,
  non credenziali: Firebase le progetta per stare nel client. Vanno comunque
  ristrette per referrer HTTP in *Google Cloud console › API e servizi ›
  Credenziali*, così la chiave del progetto non è riusabile da un altro sito.
- **`sentAt` delle notifiche cross-utente è fornito dal client.** Le regole ne
  verificano il tipo, non il valore. L'anti-spam nel backend usa già il
  `createTime` di Firestore e non `sentAt` — c'è un test che lo verifica — per
  cui la manipolazione non aggira nulla.

## Privacy del profilo: modalità incognito

`isPrivate` era applicato solo lato client: nascondeva dalla ricerca ma non
impediva la lettura, quindi un collega della stessa amministrazione che
chiamasse l'API leggeva comunque il profilo. La semantica scelta è **incognito**:
un profilo privato usa l'app senza la parte social e non è leggibile da nessun
altro utente, nemmeno da chi lo aveva già tra i colleghi — che se lo vede
sparire dalla lista, per il fallback per-documento già presente in
`watchColleagues`.

Tre punti da tenere insieme, perché uno solo non basta:

1. **Regola** — la lettura non-proprietario richiede
   `resource.data.get('isPrivate', false) == false`.
2. **Query** — `getUsersInAdministration` filtra `isPrivate == false`. Firestore
   valuta la regola su ogni documento del risultato: una query che ne
   restituisse anche un privato verrebbe negata **per intero**, non per
   documento, e la rubrica sparirebbe per tutti.
3. **Backfill** — `isPrivate == false` non seleziona i documenti in cui il campo
   manca. Senza il campo ovunque, la regola e la query fanno sparire dalla
   rubrica chi non l'ha. Da qui i tre backfill: alla creazione in
   `saveOnboardingData`, per gli account attivi in `profileGate`, e una tantum
   su tutta la collection con `functions/scripts/backfill_is_private.js`.

L'Admin SDK non passa dalle regole, quindi il filtro va ripetuto anche nel
backend: `_createMorningNotification` salta i profili privati, altrimenti la
presenza che l'utente ha chiesto di non condividere ricomparirebbe nel
conteggio "colleghi oggi" degli altri.

**Ordine di rilascio obbligato** — lo script prima, altrimenti fra il deploy
delle regole e la prima riapertura dell'app di ciascun utente la rubrica resta
vuota:

1. `node functions/scripts/backfill_is_private.js` (`--dry-run` per contare)
2. `firebase deploy --only firestore:rules,firestore:indexes`
3. `./deploy.sh`

## Note

L'avviso `Cross-Origin-Opener-Policy policy would block the window.close call`
che compare in console durante il login Google arriva dalla pagina di Google,
non dall'app: il popup si chiude comunque e l'autenticazione va a buon fine.
Non è un sintomo di questo ADR e non cambia con l'header aggiunto qui.

Il titolo dell'ADR dice "perimetro" e non "privacy" perché la modalità
incognito è arrivata dopo, nello stesso giro di audit: le due parti condividono
l'ordine di rilascio e conviene leggerle insieme.
