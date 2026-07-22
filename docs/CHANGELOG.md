# CHANGELOG della wiki e delle modifiche tracciate da Claude Code

## 2026-07-22 — Skeleton immediata durante il bootstrap Web

- **chore(release)** — versione Web aggiornata a `2026.7.22+22` e label
  profilo a `v2026.07.22+22` per il rilascio di bootstrap, gate profilo e
  ottimizzazioni Home; la versione APK resta indipendente.
- **fix/perf(bootstrap)** — il primo paint Web mostra una skeleton Home nel
  DOM, sostituita dal primo `runApp()` sincrono con una skeleton Flutter dalla
  stessa geometria; Firebase, cache Firestore persistente multi-tab, locale e
  preferenze vengono inizializzati senza lasciare una schermata vuota.
- **fix(bootstrap)** — un errore iniziale mostra un messaggio umano e `Riprova`;
  entrambe le skeleton evitano spinner isolati e disattivano l'animazione quando
  il sistema richiede movimento ridotto.
- **test(bootstrap)** — coperti contratto HTML/JS, configurazione Firestore,
  stato pending, passaggio all'app pronta e retry dopo errore.
- **perf(font)** — gli otto font UI usati nel primo frame sono inclusi come
  asset verificati e caricati dietro la skeleton, senza fetch CDN; solo il font
  color emoji resta best-effort e non bloccante. Registrate anche le licenze
  OFL nel catalogo licenze dell'app.
- **fix(auth/gate)** — sostituito il booleano profilo con un gate tipizzato che
  ascolta anche i metadata Firestore: cache completa apre la Home, cache
  incompleta resta resolving e solo un server incompleto richiede onboarding.
  Errori e loading non vengono più interpretati come nuovi utenti.
- **test/adr(auth)** — aggiunte truth table del redirect e regressioni del
  reducer; ADR-0014 registra skeleton a due livelli, font locali, cache Web
  multi-tab e autorità server per il solo esito onboarding.
- **perf(home/loading)** — il loading iniziale della Home usa una skeleton
  strutturale con hero e prime card, pilotata da un solo pulse condiviso e
  statica con movimento ridotto; i refresh con dati continuano a conservare il
  valore già disponibile.
- **perf(home/scroll)** — su mobile la Home usa sliver lazy per i widget
  secondari e conserva l'offset con `PageStorageKey`; il desktop resta a due
  colonne e il `cacheExtent` rimane quello predefinito di Flutter.
- **perf(home/timer)** — il grande hero seleziona uno snapshot stabile nello
  stesso minuto; il tick al secondo resta confinato al testo della pausa live,
  mentre le transizioni strutturali continuano ad aggiornarsi subito.
- **perf(home/effects)** — la nav orizzontale Web evita il backdrop blur e usa
  un'ombra più corta; nav native/verticali mantengono il glass. Il nudge dello
  slide è one-shot e solo le ombre di hero/widget in evidenza sono state
  ridotte, senza ridisegnare gli altri effetti.
- **feat(home/empty)** — i nuovi utenti vedono solo la timbratura e una card
  grande con il nuovo Chigio `+`, copy `Costruisci la tua Home` e CTA a tutta
  larghezza. Dal primo widget opzionale compare invece il link compatto
  `Modifica widget`; nascondendo l'ultimo torna la card grande.

## 2026-07-21 — Catalogo canonico Dipartimento/Struttura PCM

- **deploy(release)** — pubblicata su Firebase Hosting `main` la build Web
  `2026.7.21+21` (`https://chigiotime.web.app`) con il fix del gate PCM.
- **verify(release)** — `version.json` live riporta build `21`; `main.dart.js`
  live coincide byte-per-byte col build locale (SHA-256
  `3cb934f8c4a1985f21fa7989414c4d9f5aeaf9c3054c9f685752c258bd4c0e6d`),
  così come `index.html`.
- **chore(release)** — versione web aggiornata a `2026.7.21+21`; la label
  profilo espone anche il build number come `v2026.07.21+21` per distinguere
  i rilasci effettuati nello stesso giorno. La CTA Android resta separata e
  indica l'APK più recente realmente pubblicato, senza ereditare la versione Web.
- **fix(pcm/gate)** — il popup "Aggiorna la sede di lavoro" è ora montato
  dentro le route autenticate, sotto il `Navigator`: `Autocomplete` e menu sede
  aprono l'overlay senza rompere la UI. Aggiunta regressione su placement e tap.
- **deploy(pcm)** — pubblicato `referenceData/pcmCatalog` versione
  `2026.07.20` con hash
  `8b56f2fcaef9c982d18e3fdffc4b623816acac8f729530c044624f2c19e1090f`;
  migrate due profili PCM non validi azzerando soltanto struttura e sede. Il
  controllo idempotente finale rileva 1 profilo valido, 2 gia' vuoti e nessun
  altro profilo da migrare.
- **deploy(release)** — pubblicati ruleset Firestore
  `bdab901e-4202-46a7-a756-62e2a9cf8246` e Hosting `main` release
  `a90accc957ba5588` su `https://chigiotime.web.app`.
- **verify(release)** — `flutter analyze`, 181 test Flutter, 6 test script
  amministrativi e 26 test Functions passano; il bundle Web live coincide con
  quello locale (`main.dart.js` SHA-256
  `5ebed8366164a3e8fbb0fdce387f886d2980f63dec6fd25c74da06b975277263`) e
  la schermata di accesso e' stata verificata in Chrome. Lo smoke autenticato
  del gate PCM resta da eseguire: il solo profilo Chrome disponibile non aveva
  una sessione applicativa attiva.
- **chore(release)** — versione applicazione aggiornata a `2026.7.21+20` e
  label profilo a `v2026.07.21`.
- **feat(pcm/catalogo)** — introdotti payload bundled e modello validato per le
  50 coppie struttura/sede dell'Appendice A; il duplicato DIPE è unificato e le
  12 sedi fisiche includono CAP normalizzati e coordinate WGS84.
- **feat(pcm/raccomandazione)** — la sede associata è calcolata dal match esatto
  della struttura, ordinata per prima e marcata come consigliata senza essere
  selezionata automaticamente.
- **feat(pcm/offline)** — `referenceData/pcmCatalog` è letto prima della cache
  Drift e del bundled; i payload remoti malformati sono scartati prima della
  write e lo schema Drift 6 sostituisce atomicamente tutte le 50 righe usando
  il nuovo `site_id` stabile.
- **feat(pcm/ui)** — onboarding e profilo riusano lo stesso selettore
  `Dipartimento/Struttura` + sede; la raccomandazione non auto-seleziona, il
  cambio struttura richiede una nuova sede e il route planner usa le 12 sedi
  aggregate dal catalogo.
- **feat(pcm/gate)** — i profili PCM con coppia assente o legacy ricevono un
  gate mirato non dismissibile, senza ripetere l'onboarding. Rimosse le fonti
  indipendenti `kPcmDepartments` e `pcmOfficeSeeds`.
- **feat(pcm/admin)** — aggiunti seed `referenceData/pcmCatalog` e migrazione
  profili, entrambi dry-run per default e idempotenti; l'apply verifica
  versione/hash o i campi azzerati dopo la rilettura e non stampa PII estranee
  alla coppia PCM.
- **security(pcm/catalogo)** — le rules consentono soltanto il `get`
  autenticato di `referenceData/pcmCatalog`; list e scritture client restano
  negate, mentre la pubblicazione usa Firebase Admin.
- **fix(timesheet/csv)** — l'import mostra un'anteprima prima di scrivere,
  conta le giornate esistenti che saranno sostituite, elenca righe scartate e
  rifiuta date duplicate nel file dopo la prima occorrenza.
- **fix(ux/stream)** — Home e gruppi Social distinguono il primo loading,
  l'errore e l'empty state; un errore offre `Riprova`, mentre refresh e reload
  conservano l'ultimo valore invece di lampeggiare contatori o liste vuote.
- **fix(dashboard/review)** — su desktop l'uscita prevista resta fissata fuori
  dallo scroll dell'hero; Aurora mantiene lo stile ma diventa statica, senza
  ticker/repaint continuo. Rimosso il vecchio `SmartExitWidget` inutilizzato.
- **test/docs** — coperti schema, conteggio, duplicati, coordinate,
  deduplicazione sedi e label; wiki entità riallineata al payload canonico.

## 2026-07-19 — Chigio festeggia il buono pasto

- **feat(chigio)** — aggiunta posa `chigio-bavaglino.png` alla galleria e agli
  alias ufficiali. Quando i minuti lavorati attraversano la soglia personale
  del buono pasto, l'hero la mostra per 6 secondi con tre nuove frasi dedicate.
- **fix(chigio)** — il pool buono pasto non resta più attivo per tutto il turno
  dopo la soglia; concluso l'evento singolo riprende il contesto normale.
- **test** — coperti posa, testi esatti e ritorno al pool normale.

## 2026-07-19 — Notifiche distribuite e smoke infrastrutturale live

- **deploy** — pubblicati sul progetto `chigio-time-pcm` Functions, rules,
  indici Firestore e Hosting `main`; release Hosting
  `1fa05a91b32b4834`, quattro Functions Gen 2 `ACTIVE` con hash
  `a251a3dae475d46eee32a3a9731efc0ae23aa12a`.
- **verify(live)** — `https://chigiotime.web.app` risponde `200`; `index.html`
  e `firebase-messaging-sw.js` coincidono con il build locale. L'indice
  collection-group `activeTimer.reminderAt` ha raggiunto `READY` e il primo
  tick successivo di `exitReminders` è terminato senza errore alle
  `2026-07-18T23:50:25Z`.
- **operativo** — resta da eseguire lo smoke autenticato su browser/device
  reale, inclusa la ricezione APNs su build firmata. La sessione di verifica
  non disponeva di un browser controllabile. Il runtime Functions Node 20 è
  deprecato e va aggiornato prima della dismissione del 30 ottobre 2026.

## 2026-07-19 — Migrazione build Apple e verifica artefatti

- **build(ios/macos)** — applicata la migrazione automatica Flutter corrente a
  Swift Package Manager e, su iOS, al scene lifecycle con registrazione plugin
  tramite `FlutterImplicitEngineDelegate`; aggiunti i lockfile CocoaPods/SPM
  prodotti dalla risoluzione dipendenze.
- **verify** — build Web release e APK Android debug completate; build macOS
  compilata e impacchettata senza firma. Il build iOS raggiunge Xcode ma resta
  bloccato dalla toolchain locale: SDK Xcode 26.5 presente, runtime/piattaforma
  iOS 26.5 non installato.

## 2026-07-19 — Final timer review: recovery pre-delete e generation comune

- **fix(timer/recovery)** — se un riavvio trova `timer_clearPending == true`
  ma il primo snapshot server contiene ancora il timer, l'handshake emette
  `shouldDeleteRemote`; stream e load iniziale attendono un solo retry delete.
  Il marker resta persistito fino al successivo `null`; un fallimento riabilita
  il retry al prossimo evento/riavvio senza lanciare delete concorrenti.
- **fix(timer/generation)** — `markLocalMutation()` viene invocato prima di
  `startTurn`, `startPause` ed `endPause`. Un ack asincrono della transizione
  precedente diventa no-op e, se aveva già rimosso il marker, ripristina
  `timer_pendingRemoteSync` per la mutazione più recente.
- **test/docs** — regressioni RED→GREEN per restart pre-delete completo,
  recovery fallita e ack working→pause / paused→resume concorrenti. Membership
  PCM e rules restano esplicitamente fuori scope e invariate.

## 2026-07-19 — Race finali timer: ack server e clear crash-safe

- **fix(timer/metadata)** — `ActiveTimerRepository.watch()` include i cambi
  metadata e propaga `hasPendingWrites`/`isFromCache`. Un echo matching locale
  o da cache resta una no-op: `timer_pendingRemoteSync` viene rimosso soltanto
  da un ack matching confermato dal server.
- **fix(timer/clear)** — `timer_clearPending` viene persistito prima del delete
  remoto. Un riavvio dopo delete riuscito consuma il primo `null` server,
  elimina stato e flag locali senza risincronizzare; un delete fallito esegue
  rollback sia del marker persistito sia della guardia RAM e resta retryable.
  La guardia RAM viene attivata prima dell'await di persistenza per chiudere
  anche la finestra di un echo concorrente.
- **test/docs** — aggiunte regressioni RED→GREEN separate per echo pending/cache,
  ack server, crash window, snapshot remoto durante persistenza/clear e
  rollback delete.
  Nessuna modifica al finding membership PCM, esplicitamente fuori scope.

## 2026-07-18 — Seconda re-review: delivery at-most-once e timer provenance

- **fix(functions)** — prima di FCM viene persistito
  `pushDispatchStartedAt` con il numero di target. Se la finalizzazione fallisce
  due volte, il retry dopo la lease non reinvia: chiude `failed` con
  `notification/delivery-unknown`. Un errore di scrittura del marker resta
  pre-FCM, viene rilanciato e non chiama Messaging.
- **fix(timer)** — SharedPreferences salva `timer_pendingRemoteSync`: solo un
  turno locale attivo con marker `true` può prevalere sul primo remote `null`.
  L'echo matching cancella il marker; prefs attive senza marker sono stale e
  vengono eliminate. Il delete remoto è realmente awaited e il clear locale
  è annunciato all'handshake per non risincronizzare il proprio delete.
- **fix(security/inbox)** — il client non può cancellare `users/{uid}` e
  aggirare l'immutabilità legacy con delete+recreate. Payload malformati
  degradano a `unknown/info`, mai a un invito caffè azionabile.
- **open(security)** — il set-once PCM impedisce cambi tenant successivi ma
  non prova che un nuovo account appartenga davvero a PCM. Serve una decisione
  prodotto su inviti/allowlist o altra authority server-side; nessuna
  membership è stata inventata in questo hardening.

## 2026-07-18 — Hardening final review notifiche e confine tenant

- **fix(security)** — `users/{uid}.administration` non è più una tenant
  authority auto-assegnabile: documenti parziali possono ometterla, il primo
  valore client ammesso è solo PCM e poi resta immutabile; profili legacy
  conservano il proprio valore mentre aggiornano altri campi. Il create
  cross-user valida schema comune e specifico per type, timestamp/status/enum,
  ETA 1–60 e limiti testuali. Rules contract GREEN e Firebase dry-run compilato.
- **fix(functions)** — errori operativi dopo il claim restano non terminali e
  vengono rilanciati a Eventarc; FCM esaurito il retry chiude ancora `failed`.
  La finalizzazione usa `update` per non ricreare documenti cancellati. Gli
  scheduler attendono tutti i task e propagano almeno un fallimento con
  `retryCount: 3`; il trigger timesheet usa `retry: true` e gli ID
  deterministici mantengono i retry idempotenti.
- **fix(timer/inbox)** — il primo remote `null` preserva un turno locale Web
  attivo, lo risincronizza e mantiene le guardie generation; un `null`
  successivo a uno stato remoto visto resta una cancellazione reale.
  `AppNotification.fromMap` tollera tipi legacy malformati senza avvelenare lo
  stream inbox.
- **test/docs** — aggiunte riproduzioni RED→GREEN per profile/fcm post-claim,
  lease/reclaim, delete-race, hourly/exit con fallimenti parziali, config retry,
  timer offline reload e parser legacy; ADR-0008/0012, wiki e audit riallineati.

## 2026-07-18 — Implementazione notifiche inbox-first completata; deploy/live pending

- **feat(functions)** — delivery unificata da
  `users/{uid}/notifications/{id}`: DND server-side, claim/lease, multicast a
  tutte le installazioni, retry transitori, cleanup puntuale token stale e
  stati osservabili `processing` → `sent|suppressed|no-token|failed`.
  Produttori automatici per colleghi presenti, recap da lunedì al momento
  dell'invio, stipendio, soglia straordinario e reminder uscita ogni minuto.
- **feat(client)** — FCM per-installazione in
  `private/fcm.installations.{installationId}`, routing allowlisted per
  initial/background/foreground, logout bounded e no-op su Windows/Linux.
  Inbox generica con copy automatici, esito della notifica di prova e
  preferenze reali; rimossi via migrazione lazy `notifyClockIn`,
  `notifyClockOut`, `notifyWeekly`.
- **feat(timer)** — `activeTimer/state` persiste `reminderAt` e
  `reminderLeadMins`; sincronizzazione multi-device protetta da
  handshake/generation e apply/no-op. Il reminder è prodotto server-side
  anche ad app chiusa, senza segnale client one-shot duplicato.
- **feat(platform)** — channel Android `chigio_notifications`, entitlement e
  background mode iOS/macOS, click Web same-origin e prevenzione doppia
  notifica browser. APNs su Firebase e smoke su build firmata restano gate
  operativi esterni al repo.
- **fix(security)** — il backend corrente non crea nuovi `abuseBans`; le rules
  conservano un gate read-only per onorare fino a `until` gli eventuali ban
  legacy creati dalla Function già distribuita, senza esporre un match client.
  Inventario e cleanup richiedono credenziali IAM: il tentativo Firestore REST
  via Firebase CLI ha restituito HTTP 403. Restano invariati ownership, stessa
  amministrazione, whitelist e limiti testuali; il cap effettivo resta a 10
  notifiche/24h per coppia nella Function. Il campo legacy opzionale `until`
  è letto con `data.get('until', null)`: documenti malformati o incompleti non
  causano un deny indefinito, mentre timestamp futuri validi restano onorati.
- **test** — copertura TDD Dart/Node per logica e runtime Functions, reminder,
  routing, lifecycle FCM, inbox/preferenze e configurazioni Android/Apple/Web;
  contratto rules aggiornato al comportamento reale e compilazione rules
  verificata con Firebase CLI `--dry-run`.
- **docs** — nuova
  [ADR-0012](./decisioni/0012-notifiche-firebase-inbox-first.md) e wiki
  allineata a schema, flussi, multi-device, DND, piattaforme e limiti. Il
  deploy reminder deve includere `firestore:indexes` per l'indice
  collection-group `activeTimer.reminderAt`. Deploy e prova live restano nel
  gate Task 8.

## 2026-07-10 — A11y web + gerarchia Home (P2 della critique)

- **feat(shared)** — `AppTappable` accetta `tooltip` (hover su web,
  fallback per il semantic label). Bottoni icona convertiti da
  `GestureDetector` puro: campanella e avatar (header + hero) ora con
  tooltip, cursore click, focus da tastiera e hit area 44px (cerchio
  visivo invariato 38-40px). Tab della floating nav con
  `Semantics(button, selected)` + cursore.
- **feat(dashboard)** — gerarchia a 3 tier nella Home: hero/featured >
  card ricche (`GlassCard`) > tile mono-metrica compatte (`GlassTile`):
  `BancaOreTile` e `_MaggiorPresenzaCard` passano al tier compatto come
  `FavoriteColleaguesCard`.
- **fix(copy)** — conferma eliminazione giornata non promette piu'
  irreversibilita' (ora esiste l'undo dalla snackbar).

## 2026-07-10 — UX harden: errori umani, retry, undo, skeleton

- **feat(shared)** — da critique 31/40 (`.impeccable/critique/`), fix dei
  2 P1: `AppStrings.errorGeneric` non mostra piu' l'eccezione raw ma un
  messaggio umano (mappa rete/permessi/sessione → testo azionabile; un
  solo punto, 14 chiamanti). Nuovi widget condivisi in
  `shared/widgets/skeleton_tile.dart`: `SkeletonTile`/`SkeletonList`
  (ghost card pulsanti, statiche con `disableAnimations`) e `ErrorRetry`
  (messaggio + Riprova con `ref.invalidate`).
- **fix(social)** — stati colleghi resi esclusivi (errore > loading >
  vuoto): prima, con stream in errore, comparivano insieme messaggio
  d'errore ed empty state. Spinner → skeleton; errore con Riprova.
- **feat(timesheet)** — snackbar «Giornata eliminata» ora con azione
  Annulla: ripristina l'entry cancellata (`saveDailyTimesheet` con
  `fullOverwrite`). Loading mese → skeleton; errore con Riprova.
- **fix(profile, notifiche)** — stessi rimpiazzi spinner→skeleton e
  errore→`ErrorRetry` nei `.when()` principali.

## 2026-07-09 — Perf: rimosso BackdropFilter dalle GlassCard

- **perf(shared)** — scroll laggoso (soprattutto web): ogni `GlassCard`
  applicava `BackdropFilter` blur σ28 → 8-12 saveLayer + readback per frame
  per schermata durante lo scroll. Le card stanno su sfondo gradiente
  statico: blur visivamente quasi nullo, costo raster pieno. Rimosso il
  filtro in `glass_card.dart` (un solo punto, ~40 usi), alpha del bg alzata
  0.56/0.58 → 0.80/0.82 per compensare. Il blur resta solo dove copre
  contenuto in scroll: floating nav, glass header, shell.

## 2026-07-09 — Widget in evidenza: redesign «Aurora»

- **feat(dashboard)** — `_FeaturedWidget` non replica piu' il gradiente blu
  dell'hero (leggeva come "secondo hero"): nuovo stile «Aurora» — base blu
  notte, 3 blob radiali blu/verde/viola in deriva (`_AuroraPainter`, falloff
  radiale senza `ImageFilter.blur`), velo glass, shine periodico, bordo
  conico iridescente rotante (`_FeaturedRingPainter`). Un solo
  `AnimationController` 12s, statico con `MediaQuery.disableAnimations`.
  Prototipo HTML (A «Aurora» vs B «Anello») approvato: scelta A senza badge.
- Aggiornato [`docs/funzionalita/dashboard.md`](./funzionalita/dashboard.md).

## 2026-07-06 — Pausa pranzo: regola 9 ore unificata ovunque, remote senza pausa

- **fix(timesheet)** — inserimento manuale e import CSV tagliavano sempre
  30min (o 60min "Buono Pasto" in CSV) di pausa pranzo indipendentemente
  dalle ore effettive. Estratta la regola 9 ore 3-zone (gia' corretta nel
  timer live ma triplicata in `timer_provider.dart`) in
  `AppConstants.forcedLunchMins()` — root cause fix, un solo punto per tutti
  i chiamanti: timer live (`expectedExitTime`/`previewDeficit`/`endTurn`),
  editing manuale (`timesheet_screen.dart`), import CSV (fallback quando la
  nota non specifica una pausa esplicita).
- **fix(timesheet)** — giornate `remote`/smart-working: rimossa la pausa
  pranzo del tutto (`lunchPauseMins: 0`, niente piu' `+30m` sull'orario
  fittizio) in tutti e 3 i punti che le costruiscono
  (`timesheet_repository.saveRemoteWorkDay`, editing manuale, import CSV) —
  orario dichiarato, non un timbro reale: la pausa non si applica.
- Aggiornati [`docs/entita/daily-timesheet.md`](./entita/daily-timesheet.md),
  [`docs/entita/timer-state.md`](./entita/timer-state.md),
  [`docs/funzionalita/timesheet.md`](./funzionalita/timesheet.md).

## 2026-07-06 — Upgrade dipendenze major + fix WASM dry-run

- **chore(deps)** — `flutter pub upgrade --major-versions`: 37 pacchetti.
  Sbloccati i pin storici win32: share_plus 12→13.2, geolocator 13→14,
  file_picker 11→12.0.0-beta.7 (beta: unica major con win32 ^6 — commento in
  pubspec), sqlite3 2→3.3 + sqlite3_flutter_libs 0.6.0+eol (EOL: native
  assets; da rimuovere alla prossima revisione drift), drift 2.34,
  riverpod 3.3.2. Fix API file_picker 12: `readAsBytes()` al posto di
  `withData/bytes` in `csv_import_service`.
- **fix(wasm)** — l'import condizionale del DB usava `dart.library.html`
  (falso su WASM → path nativo dart:ffi → 16 warning "wasm dry run" nel
  build web). Ora `dart.library.js_interop`: **Wasm dry run succeeded**.
  `csv_download_web.dart` resta su dart:html/stub (migrazione a package:web
  = nuova dipendenza, ADR-gated).
- **deploy** — hosting ricompilato (flutter clean post-upgrade, vedi nota
  build) e rideployato v2026.7.6+19.

## 2026-07-06 — Blaze: anti-spam completo + deploy produzione (v2026.7.6+19)

- **feat(anti-spam)** — protezione bolletta Blaze sulle notifiche cross-user:
  function `onNotificationCreated` cancella (niente push) oltre **10
  notifiche/24h** stesso mittente→stesso destinatario; oltre **20 tentativi**
  ban 24h in `abuseBans/{uid}`, che le rules leggono per NEGARE il create a
  monte (lo spam smette di costare scritture). Size-limit nelle rules
  (`fromName≤60`, `message≤280`, `scheduledAt≤20`), throttle client 60s per
  destinatario, `setGlobalOptions({maxInstances: 10})`. Test contratto +3.
- **deploy** — firestore.rules + storage.rules (A2/A3/anti-spam ATTIVI),
  functions `onNotificationCreated` (europe-west1) e `hourlyNotifications`
  (us-central1) — C2/M6 attivi; primo deploy Eventarc richiesto un retry.
  Hosting v2026.7.6+19 (fix client C1/M2/M4 in produzione). Cleanup policy
  immagini container (1 giorno) su entrambe le region.
- **chore(migrazione)** — `scripts/migrate_private_fields.mjs` (pattern
  SA_KEY, dry-run default): sposta portaleJson/fcmToken dei dormienti in
  private/. Da eseguire a mano con la service-account key.
- Wiki: persistence.md sezione anti-spam; review aggiornata (A3 completo,
  checklist produzione ridotta a budget alert GCP + run migrazione).

## 2026-07-06 — Residui code review: M1-M6, B1, B2, B5 (batch 2)

- **fix(M1)** — nuovo `core/utils/date_utils.dart` (`dateIdOf`/`todayId`,
  sempre ora LOCALE): sostituite le 6 copie sparse del formato `YYYY-MM-DD`;
  `updateCurrentStatus` non usa più la data UTC (status colleghi sbagliato
  tra mezzanotte UTC e locale).
- **fix(M2)** — export "Scarica i miei dati": rimosso `orderBy('createdAt')`
  che escludeva tutte le notifiche social; scoperto e fixato anche il crash
  di `jsonEncode` sui `Timestamp` (l'export era rotto per qualsiasi profilo
  con `updatedAt` serverTimestamp) — sanitize ricorsivo nel repository.
- **refactor(M3)** — nuovo `ActiveTimerRepository`
  (`features/dashboard/data/`): save/load/watch/clear del doc activeTimer +
  promemoria uscita; `timer_provider` non tocca più Firestore direttamente
  (parsing prima triplicato, ora in un punto). Export dati spostato in
  `ProfileRepository.fetchMyData()`.
- **fix(M4)** — restore del timer all'avvio: guardia contro la
  sovrascrittura di un turno avviato durante il restore async + try/catch
  su prefs corrotte.
- **test(M5)** — `test/features/timer_state_test.dart`: 11 casi su
  `expectedExitTime` (pranzo forzato a 3 zone CCNL), pause, remainingTime,
  copyWith sentinel. Suite: 74 test.
- **perf(M6)** — functions job orario: `select()` projection sulla scansione
  utenti, `getAll` con fieldMask sui colleghi (1 RPC invece di N get),
  soglia buono pasto dal profilo (era hardcoded 380).
- **chore(B1)** — rimosse 8 dipendenze mai usate: flutter_secure_storage,
  table_calendar, badges, percent_indicator, freezed_annotation,
  json_annotation (+ freezed, json_serializable dai dev). CLAUDE.md e
  `docs/processi/code-generation.md` allineati.
- **docs(B2)** — convenzione provider chiarita in CLAUDE.md: `@riverpod`
  codegen per i provider nuovi, manuali legacy tollerati (la wiki
  state-management già li documentava come pattern accettato).
- **fix(B5)** — minori: CSV rifiuta date impossibili (2026-02-31), 
  `respondToInvite` non lancia su notifica cancellata, inbox notifiche
  limit 50→200 (stats caffè), `select` su status/standardWorkMins in
  dashboard (niente rebuild dell'intera Home a ogni tick), `debugPrint`
  nei catch FCM, updatedAt cache Drift senza doppio `toMap()`.
- Review `code-review-2026-07-05.md` aggiornata con esiti + nuova sezione
  finale **"Resta a te (produzione)"** (deploy rules, Blaze, migrazione
  utenti dormienti, B3/B4 incrementali).

## 2026-07-06 — Fix security dalla code review (C1, C2, A2, A3)

- **fix(security C1)** — `portaleJson` (totalizzatori HR) e `fcmToken` migrati
  da `users/{uid}` (leggibile dai colleghi della stessa amministrazione) a
  `users/{uid}/private/portale` e `private/fcm` (owner-only). Migrazione lazy:
  il primo save/login cancella il campo legacy; lettura con fallback
  (`portaleRawProvider`, `_getToken()` nelle functions). Wiki aggiornata:
  persistence, user-profile, dashboard, orario-e-presenza, README funzionalità.
- **fix(security C2)** — `process.env.TZ = 'Europe/Rome'` in `functions/index.js`:
  prima girava in UTC → notifiche orarie sfasate di 1-2h. Il job orario ora
  legge il token FCM solo per gli utenti con notifiche effettivamente dovute.
- **fix(security A3)** — `firestore.rules`: create di notifiche cross-user
  consentito solo tra utenti della stessa amministrazione (anti spam/push
  cross-amministrazione). Test contratto aggiornato.
- **fix(security A2)** — nuovo `storage.rules` versionato + sezione `storage`
  in `firebase.json`: foto profilo scrivibili solo dal proprietario
  (`{uid}.jpg`, immagini, <5MB), default deny sul resto. **Da deployare.**
- A1 (VAPID key web push) sistemato a mano da Marco. Dettagli e findings
  residui (M1-M6, B1-B5) in `code-review-2026-07-05.md`.

## 2026-07-05 — Code review completa del repository

- **docs(review)** — nuova pagina [`code-review-2026-07-05.md`](./code-review-2026-07-05.md):
  review dura dell'intero repo (lib/ 44k righe, firestore.rules, functions,
  test, pubspec). 2 critici (dati HR/fcmToken leggibili da tutta
  l'amministrazione; functions in UTC), 3 alti (VAPID placeholder, storage
  rules assenti, spam notifiche cross-amministrazione), 6 medi, pulizia
  (6 dipendenze inutilizzate). Con priorità di fix consigliata.

## 2026-07-05 — Art. 9 = maggior presenza (non permesso) + polish timesheet/hero

- **fix(dominio)** — **Art. 9 chiarito ovunque**: è l'istituto CCNL delle ore
  di maggior presenza (ore extra subito dopo l'orario standard, cap mensile
  8h ruolo / 17h comando), NON un permesso. I permessi brevi sono Art. 35.
  Corretti: label `AbsenceKind.shortLeave` → "Permesso breve (Art. 35)",
  commenti in `timer_provider`, colonna CSV dettagliato `pausa_art9_min` →
  `pausa_permesso_min` (solo analisi, l'import usa il CSV semplice). Wiki
  allineata: glossario, orario-e-presenza, entita/(daily-timesheet,
  timer-state, user-profile, README ER), articoli-app, requirements, chigio.
- **fix(timesheet+stats)** — la voce **Art.9** di `MonthlySummaryCard`
  sommava le pause permesso (`leavePauseMins`): ora mostra lo straordinario
  del mese clampato al cap `monthlyArt9Hours` (waterfall come la Dashboard),
  sia nel timesheet sia in `stats_screen`.
- **feat(timesheet/Giorno)** — rimossa la barra quick-add
  (Presenza/SW/Ferie/Permesso): si usa il FAB. Navigatore giorno: "↩ Oggi" a
  sinistra, profilo orario del giorno a destra (es. `7:36`, nascosto per
  weekend/festivi), titolo centrato tra slot simmetrici.
- **fix(timesheet)** — pillole cambio vista: su schermi < 600px larghezza
  proporzionale al testo ("Settimana" non va più in overflow).
- **feat(ui)** — `MonthlySummaryCard` in stile **glass S-19** (via
  `GlassCard`): niente più header blu pieno, testi theme-aware, badge SW
  mensile e annuale entrambi con icona 🖥.
- **feat(home/hero)** — bottoni timbratura: su schermi piccoli copy compatta
  **"Timbra"** con icona direzione sul pomello (login/logout); su schermi
  grandi resta la versione estesa "Timbra Entrata/Uscita".

## 2026-07-05 — S-19b: pausa live, polish widget/header/profilo, GPS check (release +18)

- **feat(hero)** — **pausa a intervallo chiaro**: tap su Pranzo/Pausa/Permesso
  avvia la pausa **subito** all'ora corrente (niente time-picker); durante la
  pausa l'hero mostra i **minuti che scorrono live** (MM:SS) + etichetta "In
  pausa pranzo/pausa/permesso". "Riprendi" chiude all'ora corrente.
  **Long-press** su chip o Riprendi per scegliere un orario custom. Chip più
  leggibili: icona+testo su una riga, espansi.
- **feat(home)** — `HomeWidgetHeader`: Chigio più grande (box 36→40, mini
  24→28); nuovo flag `hasOpenLink` → freccia "apri" a destra sui widget che
  linkano a una pagina dedicata (Pomodoro → /projects, Stipendio → /salary).
  Titoli widget title-case (niente maiuscolo forzato).
- **feat(home)** — link centrale **"Modifica widget"** in fondo alla Home
  (solo se >1 widget visibile) → apre `showHomeWidgetsPanel`.
- **feat(header)** — Chigio nell'header delle pagine (non-Home) ora ha lo
  **stesso stile boxed** dei widget (riquadro arrotondato accent, 44×44,
  Chigio 30) invece del cerchio.
- **fix(timesheet)** — barra data in vista Giorno: il chip "Oggi" era un
  `Flexible` tra data e freccia → data decentrata. Spostato **sotto** la data
  (↩ Oggi), frecce simmetriche, data centrata.
- **feat(profilo)** — card personale **compatta**: immagine a sinistra (80→60),
  info a destra su una riga, chevron; chip stato del giorno con **icona
  modifica**. Sezione **Funzionalità (GPS)** spostata in basso, prima di CCNL.
- **check(gps)** — verificato end-to-end: permessi Android (FINE/COARSE/
  BACKGROUND) e iOS (NSLocation*/UIBackgroundModes), `GeofencingService`
  (position/permission/checkInOffice/exit-monitor), settings che salvano
  `officeLat/Lng/RadiusM`, prompt Home che li rilegge. Tutto coerente; su web
  resta no-op per design (`kIsWeb`).
- **chore(release)** — pubspec 2026.7.5+18; build web + deploy hosting.

## 2026-07-05 — Fix Home lenta + warning Noto font (release +17)

- **perf(web)** — la Home era lenta a comparire: `main.dart` faceva
  `await GoogleFonts.pendingFonts([...])` includendo **notoColorEmoji**
  (~10 MB, scaricato dal CDN Google Fonts) → il primo frame restava bloccato
  finché il download non finiva. Ora si aspettano solo i font piccoli
  (Plus Jakarta Sans + Noto Sans + Noto Sans Symbols/Symbols2, ~1.5 MB); il
  color-emoji è precaricato **senza bloccare** il primo frame.
- **fix(font)** — warning `Could not find a set of Noto fonts to display all
  missing characters`: glifi UI non coperti dal fallback. Aggiunti alla catena
  `fontFamilyFallback` (`app_theme.dart`) **Noto Sans** (Latin Extended, schwa
  `ə` del linguaggio inclusivo) e **Noto Sans Symbols** (frecce/math/geometrici
  `→ − ≈ ↑ ↓ ▶`). notoSansSymbols2 già presente per i simboli monocromatici.
- **chore(release)** — pubspec 2026.7.5+17; build web + deploy hosting
  (verificato via `version.json` = 2026.7.5/17).

## 2026-07-05 — Release web v2026.07.05 (+16)

- **chore(release)** — bump `appVersion` v2026.07.05 / pubspec 2026.7.5+16;
  `flutter build web` + deploy hosting (chigiotime.web.app, verificato via
  `version.json` = 2026.7.5/16). Contiene tutto lo sprint S-19.
- **fix(profilo)** — riga "Data presa servizio" mostrava la data ISO grezza
  (`2026-07-05`): ora formattata `dd/mm/yyyy`.

## 2026-07-05 — Sprint S-19: nuovi widget Home, uniformità, onboarding, presa servizio

- **fix(hero)** — cancellazione giornata dal widget sollevava `Assertion
  failed … RenderBox.size accessed beyond the scope of layout` (box.dart:2268)
  su web: l'`AnimatedSize` attorno all'`AnimatedSwitcher` con i `LayoutBuilder`
  interni degli slide button. Rimosso `AnimatedSize`, `AnimatedSwitcher` con
  `layoutBuilder` a `Stack`.
- **feat(home)** — tre nuovi widget ordinabili: **Tabella orari**
  (`OrariTableCard`, variante preselezionata da `stdMinsForDate` per il giorno
  corrente + selettore), **Pomodoro** (`PomodoroCard`, timer live o avvio
  rapido) e **Stipendio** (`SalaryCard`, countdown accredito + stima netto).
  La tabella orari non è più uno sheet: è un widget.
- **feat(home)** — **header uniformi** stile "Percorsi PCM": nuovo
  `HomeWidgetHeader` (contenitore 36×36 con mini-Chigio + titolo grande +
  sottotitolo/trailing) applicato a preferiti, maggior presenza, contatori,
  banca ore, totalizzatori, percorsi. `HomeWidgetEmpty` per gli stati vuoti.
- **fix(home)** — i widget **flaggati visibili** ma senza dati non spariscono
  più: mostrano un empty state con CTA. **Nuovi account**: solo la timbratura
  (tutti i widget nascosti via `hiddenHomeWidgets` = `AppConstants.homeWidgetIds`
  nell'onboarding) + CTA "Aggiungi widget" che apre il pannello.
- **revert(profilo)** — annullato lo sheet unico "Widget e visibilità"
  (dava errore di caricamento): sezione dedicata con **tre pannelli separati**
  (`showHomeWidgetsPanel`, `_showNavViewsPanel`, `_showStatHighlightPanel`),
  ognuno con il suo sheet.
- **feat(profilo/social)** — **stato del giorno** spostato fuori da Dati
  personali (chip nella card personale) con **scadenza** opzionale (1h / 4h /
  fine giornata / senza): campi `statusMessage` + `statusMessageUntil`; i
  colleghi mostrano solo lo stato non scaduto (`activeStatusMessage`). Sheet
  condiviso `showStatusMessageSheet`.
- **feat(profilo/onboarding)** — nuovo campo **Data presa servizio**
  (`hireDate`, mai nel futuro) in Dati personali e onboarding; marker
  "entrata in servizio" registrato in automatico in fondo alla timeline di
  `/sau`.
- **fix(sau)** — naming corretto (**Straordinario autorizzato mensile**, SLI +
  SBO = SAU), mese esteso ("Luglio" non "Lug") nella riga di registrazione;
  **storico orario** aggiunto nello Storico inquadramenti (variante schedule
  per periodo); riga "Andamento straordinario" spostata **sotto** lo Storico
  inquadramenti.
- **refactor(onboarding)** — step **11 → 9**: uniti "nome + genere" (Chi sei?)
  e "Art. 9 + SLI/SBO" (SAU); step container ora scrollabile; verificato che
  tutti i campi vengano salvati in `saveOnboardingData`.
- **docs** — **README** riscritto stile top-repo (badge, Chigio, presentazione,
  funzionalità, dettagli tecnici, comandi di configurazione); ROADMAP S-19.

## 2026-07-04 — Sprint S-18b: widget pass, /sau, CCNL leggibile, roadmap ristrutturata

- **feat(hero)** — pomello `_SlideButton` con **bounce periodico** a riposo
  (TweenSequence ~2.6s, rientro elastico) che invita allo swipe; icona
  entrata → **badge** (`Icons.badge_rounded`).
- **fix(web)** — errore console post-timbratura `TypeError:
  LegacyJavaScriptObject is not a subtype of DiagnosticsNode`: ricompilato
  `web/drift_worker.dart.js` (era del 2026-06-11, incompatibile col nuovo
  `sqlite3.wasm` 2.9.4) + `.ignore()` sui future fire-and-forget di
  `startTurn`/`startPause`/`endPause` in `timer_provider`.
- **feat(home)** — **widget in evidenza**: nuovo campo Firestore
  `featuredHomeWidgets`; il widget ★ è avvolto in `_FeaturedWidget`
  (gradiente blue600→800 + `Theme` dark forzato). **Mini-Chigio** in ogni
  widget Home (`ChigioMini` condiviso, posa per widget).
- **feat(profilo)** — sheet unificato **"Widget e visibilità"**
  (`_showWidgetsVisibilitySheet`): widget Home (drag + checkbox + ★),
  schede navbar, statistica in evidenza — sostituisce 3 voci separate.
- **refactor(profilo)** — sezione **Inquadramento e orario** spostata in
  **Dati personali** (`/profile/edit`, widget `_InquadramentoCard`);
  "Scarica i tuoi dati" spostato nella card Info app accanto a Privacy.
- **feat(sau)** — nuova schermata **`/sau`** (`sau_screen.dart`): explainer
  della registrazione mese-per-mese, grafico barre impilate SLI+SBO ultimi
  12 mesi, **storico variazioni** (range consecutivi con stesso valore:
  valore, da mese, a mese, "in corso"). Link dalla card Inquadramento.
- **feat(ccnl)** — lettore leggibile: `cleanCcnlPreamble` (via indice coi
  puntini, firme, indirizzi), corpo articolo a capoversi stilizzati (numero
  comma blu bold, lettere indentate), **ricerca** nell'indice articoli.
  Fix warning "ListTile background color or ink splashes may be invisible"
  (righe custom `AppTappable` al posto di `ListTile` su sheet trasparente).
- **docs** — **ROADMAP.md ristrutturata** nel formato fisso a 4 sezioni:
  Attività (Stato·Sprint·Data·Feature·Note, sprint retroattivi S-1…S-18),
  Prossimo sprint (S-19: widget Pomodoro + widget Stipendio in Home),
  Evoluzioni per argomento con stime Impatto/Complessità (8 proposte nuove),
  Fuori scopo. `profile.md` e `dashboard.md` aggiornate.

## 2026-07-04 — Hero: polish interazioni, transizioni animate, header desktop, resetDay

- **feat(hero)** — `_SlideButton`: icona **badge** sull'entrata (al posto di
  play), tick aptici a ogni quarto di corsa, pomello che scala durante il
  drag, `mediumImpact` sul long-press, **spinner** sul pomello (pinnato a
  fine corsa) finché il salvataggio è in volo, gesture disabilitate mentre
  è busy.
- **feat(hero)** — transizioni di fase animate: `AnimatedSwitcher`
  (fade+slide) su colonna destra e sezione full-width, `AnimatedSize` per
  l'altezza della card, cross-fade con scala sulla posa di Chigio.
- **fix(hero)** — cancellazione giornata dallo sheet inline: nuovo
  `WorkTimer.resetDay()` (riusato da `dismissAbandoned`) riporta l'hero
  alla fase 1; `_EntrySheet` ha ora un callback `onDeleted` distinto da
  `onSaved`. I contatori mensili si aggiornano già da soli
  (`monthlyTimesheetsProvider` è StreamProvider su Firestore).
- **feat(home)** — `HomeHeaderActions` (campanella+avatar) estratto come
  widget pubblico: su desktop (`>=800px`) l'hero lo nasconde e il dashboard
  lo monta in overlay in alto a destra (colori adattivi fuori dal
  gradiente); su mobile resta nell'header dell'hero.
- **docs** — `funzionalita/dashboard.md` aggiornata (feedback slide,
  transizioni, header desktop, resetDay).

## 2026-07-04 — Hero: slide-to-confirm, resoconto con contatori, modifica inline + fix Drift WASM

- **feat(hero)** — `_HoldButton` sostituito da `_SlideButton`: **slide** del
  pomello (≥90% corsa) timbra entrata/uscita con l'ora corrente,
  **long-press** apre il time picker per timbrare con orario scelto.
  Rimossi gli snackbar "Entrata/Uscita timbrata alle HH:MM" con azione
  "Modifica orario" (e le stringhe correlate): il cambio fase è il feedback.
- **feat(hero)** — resoconto giornaliero (`_DailySummary`): nuova riga
  **contatori maggior presenza di oggi** (totale extra + riparto Banca ore
  SBO / Liquidato SLI quando > 0); rimosso il chip "Straordinario" ridondante.
- **feat(hero)** — "Modifica giornata" apre **inline** lo sheet condiviso
  `showDayEntrySheet` (nuova funzione pubblica in `timesheet_screen.dart`
  che riusa `_EntrySheet`), senza navigare al Timesheet; al salvataggio
  `WorkTimer.invalidateLastCompletedShift()` scarta la copia in-memory.
- **refactor(timer)** — eliminato `WorkTimer.correctLastExit` (orfano dopo
  la rimozione dello snackbar); correzioni post-uscita passano dallo sheet.
- **fix(web)** — cache Drift su web rotta: `sqlite3.wasm` non è pubblicato
  da `sqlite3_flutter_libs` → 404 → "Failed to execute 'compile' on
  'WebAssembly'" a ogni write. Scaricato `sqlite3.wasm` (release
  `sqlite3-2.9.4` di sqlite3.dart) in `web/` e aggiornato l'URI in
  `connection_web.dart`. ADR-0005 marcata Implemented,
  `architettura/persistence.md` aggiornata.
- **docs** — `funzionalita/dashboard.md` aggiornata (slide/long-press,
  contatori, modifica inline, sequence diagram).

## 2026-07-03 — Rivoluzione widget timbratura: TimbraturaHero a 3 fasi

Redesign della Home deciso in intervista (8 scelte chiave: anello eliminato,
long-press, tutte le barre, resoconto senza contesto mensile, Chigio sempre
in scena, pause+SW+smart-exit nel widget, header assorbito, hero blu).

- **feat(dashboard)** — nuovo `lib/features/dashboard/widgets/timbratura_hero.dart`:
  card gradiente blu (`blue600→blue800` light, `#12142E→#0A0C20` dark) con
  **Chigio grande a sinistra** in posa contestuale (ciao/timer/caffe/corre/
  festeggia/avviso, tap → `/chigio`) e contenuto di fase a destra.
  - Fase 1: tasto **entrata a pressione prolungata** (`_HoldButton`, ~0.9s,
    riempimento progressivo + haptic, timbra con l'ora corrente) + Smart
    Working; snackbar "Entrata timbrata alle HH:MM" con azione
    **Modifica orario**.
  - Fase 2: contatore lavorato + orari in evidenza (Entrata → Uscita
    prevista), **barra giornata** con gate BP/std/**9h** e prosecuzione OT
    arancione, **barra buono pasto** → badge ✓, indicatore 9h/pranzo
    virtuale, scenari smart-exit, chip pause, tasto **uscita long-press**
    (BOE sheet se deficit).
  - Fase 3: **resoconto giornaliero** (orari chiave, dettaglio pause, extra
    maturati: straordinario/buono/banca ore) + "Modifica giornata".
  - L'hero assorbe saluto grande "Ciao, {nome}!", frase `ChigioPhraseEngine`,
    campanella e avatar: in Home il `GlassHeader` non è più montato (resta
    nelle altre sezioni).
- **feat(timer)** — `WorkTimer.correctLastExit(t)`: correzione post-uscita
  dell'orario (dallo snackbar), ricalcola pranzo forzato/net/extra con le
  stesse regole di `endTurn` e risalva la giornata.
- **refactor(dashboard)** — `dashboard_screen.dart` da ~3300 a ~1500 righe:
  heroCard/anello/badge/pause/CTA/BOE-sheet/9h-banner/smart-exit migrati o
  sostituiti dall'hero; GPS card ora autonoma sotto l'hero; link "Tabella
  orari" spostato in fondo alla lista Home.
- **chore** — eliminato `lib/shared/widgets/shift_ring.dart` (orfano dopo il
  redesign); nuove stringhe hero in `app_strings.dart`.
- **docs** — `funzionalita/dashboard.md` riscritta nelle sezioni hero,
  `widget-inventory.md` e `architettura/layering.md` aggiornati,
  `proposta-home-v2.md` marcata SUPERATA con le differenze decise.

## 2026-07-03 — Release web v2026.07.03 (+15)

- **chore(release)** — bump `appVersion` v2026.07.03 / pubspec 2026.7.3+15;
  `flutter clean` + build web + deploy hosting (chigiotime.web.app, verificato
  via `version.json`). Contiene il pass bulletproof di oggi.

## 2026-07-03 — Bulletproof pass: scorciatoie, sheet sopra navbar, FAB unificati

- **fix(shell)** — scorciatoie tastiera desktop affidabili: l'ordine
  `Focus(autofocus)` → `CallbackShortcuts` era invertito (i KeyEvent risalgono
  dal nodo focalizzato: con lo shortcuts-widget *figlio* del nodo con focus i
  binding restavano muti finché non si cliccava dentro il contenuto). Estratto
  `lib/shared/widgets/shell_shortcuts.dart` con guardia anti-digitazione
  (digitare "1" in un campo testo non cambia più scheda). Test di regressione
  in `test/widget/shell_shortcuts_test.dart`.
- **fix(ui)** — tutti i 40 `showModalBottomSheet` ora aprono con
  `useRootNavigator: true` + `useSafeArea: true`: prima vivevano nel navigator
  del branch e finivano **sotto** la FloatingNav (e ereditavano il padding
  fittizio di +88px). Corretti anche 3 pop di dialog che usavano il context
  dello screen (branch navigator) invece del context del dialog.
- **fix(ui)** — overflow a finestra stretta: `minSize` 360×500 nel runner
  macOS; chip "Oggi" del navigatore giorno (Cartellino) reso `Flexible`.
- **feat(ui)** — `lib/shared/widgets/add_fab.dart`: FAB "+" unico (58×58,
  gradiente blu→verde) usato in Stipendio, Progetti, Social e — nuovo — nel
  Cartellino (rimossi i due bottoni "+" dalle toolbar vista lista/mese).
  La creazione progetto passa da `AlertDialog` a bottom sheet con lo stesso
  pannello (GlassCard radius 28 + handle) dello sheet Stipendio.
- **feat(profile)** — card avatar: priorità a `photoURL` del profilo
  Firestore con fallback su account Google; fallback finale nuovo asset
  `avatar-default.png`. Fogli slider (es. soglia buono pasto): aggiunti
  bottoni **+ / −** con passo pari alla granularità dello slider (5 min).
- **feat(ui)** — sigle esplicitate nelle etichette: "Straordinario liquidato
  mensile (SLI)", "Straordinario in banca ore mensile (SBO)", "Straordinari
  autorizzati ulteriori mensili (SAU)", "Estensione orario mensile (Art. 9)".
- **chore(assets)** — nuove espressioni Chigio nel bundle (`chigio.png`,
  `-festeggia`, `-lista`, `-avviso`, `-timer`, `-corre`, `-ok-cammina`,
  `avatar-default.png`) cablate in `chigio_quotes.dart` (alias `wow`,
  `scrivania`, `telefono`, `tartaruga` ora puntano ad arte dedicata) e nel
  carosello pagina Chigio. Moodboard, mockup, zip sorgenti e background
  (per ora non usati) spostati in `design/` fuori dal bundle (~13MB in meno).
- **docs** — wiki riorganizzata con cartelle in italiano: `00-overview`→
  `panoramica`, `architecture`→`architettura`, `entities`→`entita`,
  `features`→`funzionalita`, `decisions`→`decisioni`, `processes`→`processi`;
  link interni, `CLAUDE.md` e `README.md` aggiornati. Unificati i due doc
  Chigio: `chigio-visual-identity.md` fuso in `chigio-identita-visiva.md`
  (sezioni 14-15 + inventario asset corrente); item ROADMAP chiuso.
- **docs** — nuova proposta (solo carta): `funzionalita/proposta-home-v2.md`
  — hero blu con saluto grande + mascotte e card "Obiettivo giornaliero",
  basata su `design/how-i-want-home-look-like.png`.

## 2026-07-03 — Asset mascotte con sfondo trasparente

- **chore(assets)** — rimossi gli sfondi dai PNG mascotte in
  `assets/images`, lasciando intatti ZIP, asset Google, moodboard, mockup,
  background, app icon e sorgenti originali. Rigenerato `chigio-festeggia.png`
  per recuperare una versione celebrativa pulita dopo lo scontorno.

## 2026-06-29 — Feedback aptico (vibrazioni) su alcuni tap

- **feat(ux)** — nuovo `lib/core/utils/haptics.dart`: wrapper sottile su
  `HapticFeedback` di Flutter (nessuna dipendenza nuova, no-op su desktop/web,
  rispetta l'impostazione aptica dell'OS). Tre punti:
  - `Haptics.selection()` al **passaggio tra schermate** (branch switch nello
    shell, solo a cambio reale di scheda).
  - `Haptics.success()` a **timbratura salvata** (success path di `_save` nel
    timesheet).
  - `Haptics.light()` sui **tap delle voci di profilo** (in `_SettingsRow`,
    copre l'intero menu profilo con un solo punto).

## 2026-06-29 — Revisione UI: accessibilità AA + parità multi-piattaforma

Revisione guidata da intervista (skill `ui-ux-pro-max`). Direzione confermata:
glassmorphism ovunque, tono friendly+mascotte, **WCAG AA requisito hard**,
**parità reale** iOS/Android/desktop/web. Tre interventi sistemici allineano il
codice a quelle scelte.

- **B — contrasto testo (AA 4.5:1):**
  - `textSub` (testo secondario) era `neutral400` (#9e9eb8 ≈ 2.6:1) in light e
    `white@0.4` in dark: portato a `neutral600` (≈5.1:1) / `white@0.6` su **62**
    definizioni in tutti gli screen, più gli usi diretti `color: neutral400` come
    testo/icona.
  - Label inattive della navbar (pill mobile + pill desktop + icona scorciatoie)
    da `neutral400`/`white@0.40` → `neutral600`/`white@0.6`.
  - Badge di stato dashboard (`_PauseBadge`, `_CompletedBadge`, `_MealBadge`):
    il testo usava la tinta 500 sulla stessa tinta al 15% (≈2.1:1) ed era
    theme-agnostic. Ora theme-aware: light → shade 700, dark → shade 300.
- **C — reduced motion (WCAG 2.3.3 / iOS / Android):** nuovo
  `lib/app/theme/app_motion.dart` con `context.motion(ms)` che collassa a
  `Duration.zero` quando l'OS chiede meno animazioni. Applicato alla chrome
  persistente: crossfade di branch nello shell, slide/scale/switch della navbar,
  pill desktop, e `GlassBtn`. Prima: **zero** gestione reduced-motion.
- **A — target tap accessibili (parità + AA):** nuovo
  `lib/shared/widgets/app_tappable.dart` (`AppTappable`): semantica `button` +
  `semanticLabel`, focus da tastiera con attivazione Enter/Spazio
  (`FocusableActionDetector`/`ActivateIntent`), cursore pointer su desktop/web,
  press-scale gated da reduced-motion. Migrati **104** `GestureDetector`
  (onTap+child) → `AppTappable` in tutti gli screen; i 2 residui usano gesture
  complesse (drag/onTapDown) e restano `GestureDetector`. `GlassBtn` riscritto
  stateless su `AppTappable` (propaga l'accessibilità a tutti i bottoni glass).
  Etichette aggiunte ai FAB icona-sola (`Crea progetto`, `Aggiungi collega`,
  `Condividi invito`, `Rinomina gruppo`).
- **note:** mascotte/emoji (🐢/☕) e tono friendly **mantenuti** (scelta
  d'intervista). Restano da etichettare alcuni bottoni icona-sola minori (ora
  annunciati come "button" e raggiungibili da tastiera) e da uniformare le chip
  di stato colorate fuori dalla dashboard.
- **verifica:** `flutter analyze` pulito, `flutter test` verde (56 test).

## 2026-06-29 — Bump versione + upgrade dipendenze

- **chore(release)** — `version` → `2026.6.29+14` (pubspec) e
  `AppStrings.appVersion` → `v2026.06.29`.
- **chore(deps)** — upgrade in-constraint (`flutter pub upgrade`, 91 pacchetti):
  firebase_core 4.3→4.11, cloud_firestore 6.1→6.6, firebase_auth 6.1→6.5,
  firebase_messaging/storage, go_router 17.0→17.3, drift 2.30→2.31,
  build_runner 2.10→2.15, riverpod 3.1→3.3, ecc.
- **chore(deps)** — upgrade major (constraint bump in pubspec):
  - `file_picker` ^8 → **^11** — API redesign: i metodi statici non passano più
    da `FilePicker.platform.*`. Migrati `FilePicker.platform.pickFiles/saveFile`
    → `FilePicker.pickFiles/saveFile` in `csv_import_service` e `csv_export_service`.
  - `share_plus` ^10 → **^12** — `Share.share`/`Share.shareXFiles` deprecati →
    `SharePlus.instance.share(ShareParams(...))`. Migrati 3 call site
    (social invito, profilo export dati, csv export).
  - `google_fonts` ^6 → **^8** (nessun cambio API). `PdfGoogleFonts` nel PDF
    arriva da `printing`, non toccato.
  - `flutter_launcher_icons` ^0.13 → **^0.14** (solo tool di build).
- **deps tenute indietro (motivate):**
  - `share_plus` a ^12 e non ^13.2: >=13.1 richiede win32 ^6, in conflitto con
    file_picker stabile (win32 ^5). v12 ha già l'API ShareParams.
  - `geolocator` a ^13.0.4 e non ^14: v14 tira win32 ^6 (via geolocator_linux →
    package_info_plus 10). Il codice usa già `LocationSettings` (compat v13).
  - `file_picker` a ^11 (stabile) e non ^12: la 12 è solo `-beta`.
  - `sqlite3_flutter_libs` a ^0.5: la 0.6 è marcata `+eol`.
- **chore(analyzer)** — `analysis_options.yaml`: escluso `build/**`. Firebase è
  migrato a Swift Package Manager e i checkout SPM sotto `build/` portavano ~130
  errori di esempi di terze parti dentro `flutter analyze`.
- **verifica** — `flutter analyze` pulito, `flutter test` verde (56 test).

## 2026-06-29 — Fix posizione FAB "aggiungi" sopra la navbar

- **fix(ui)** — i pulsanti `+` flottanti non erano allineati alla floating
  navbar. La shell inietta `kNavClearance = 88` nel `MediaQuery.padding.bottom`
  dei figli; alcuni schermi lo consumavano via `SafeArea`, altri leggendo
  `navClearance` a mano, ma i FAB non erano coerenti:
  - **Progetti/Pomodoro** (`projects_screen`): FAB con `bottom: 16` senza
    `SafeArea` né `navClearance` → finiva **dietro** la navbar. Ora
    `bottom: navClearance + 16` (pattern di `salary_screen`, di riferimento).
  - **Social** (`social_screen`): FAB e toast caffè con `bottom: 90` **dentro**
    una `SafeArea` che già aggiunge 88 → flottavano ~74px troppo in alto, sopra
    le card. Portati a `bottom: 16`. Ridotto anche il padding di coda della
    lista colleghi (`100` → `24`) per togliere il vuoto sotto l'ultima card.
  - `salary_screen` era già corretto e resta invariato (riferimento).

## 2026-06-28 — Hardening sicurezza + fix functions

- **fix(robustezza)** — parsing date a prova di dati corrotti/legacy:
  `DailyTimesheet.fromMap` non lanciava più (`DateTime.parse(map['startTime']
  as String)` su un doc senza start/end — es. una giornata di solo permesso o
  un doc parziale — crashava l'**intero** stream timesheet del mese). Ora
  fallback tollerante (mezzanotte del `dateId`, poi epoch), coerente con gli
  altri campi null-safe. Stessa difesa su `_fromRow` (cache Drift offline) e su
  `MonthlySau.year/month` (`monthId` malformato) + guardia su `doc.data()` null.
  Nuovo test `fromMap tollera start/end mancanti o corrotti`. 60 test verdi.
- **fix(robustezza)** — cast numerici da Firestore resi a prova di tipo: i
  campi letti con `as int?`/`as double?` diretti (`standardDailyMins`,
  `paydayDay`, `mealVoucherThresholdMins`, `etaMinutes`, `officeLat`/`Lng`)
  lanciavano se il valore arrivava come sottotipo `num` diverso (es. `480.0`).
  Passati all'idioma sicuro già usato altrove (`(x as num?)?.toInt/toDouble()`).
- **fix(functions)** — `_sendPush` (push schedulate: colleghi del mattino,
  recap settimanale, stipendio) puliva il token FCM stale scrivendo su
  `users/[DEFAULT]` (il nome dell'app Firebase, non lo `uid`): il doc reale non
  veniva mai ripulito e il job orario riprovava all'infinito un token morto.
  Ora `_sendPush` riceve `db` + `uid` e azzera `fcmToken` sul profilo corretto.
- **fix(security/rules)** — `notifications` create cross-user: aggiunta whitelist
  sui `type` ammessi (`colleague_added`, `coffee_invite`, `coffee_accepted`).
  Impedisce a un mittente di iniettare notifiche di sistema (es. `exit_reminder`)
  nella casella altrui. Il ramo self-create (`uid == userId`) resta libero.
- **fix(security/rules)** — progetti condivisi: il ramo `update` del
  collaboratore permetteva di riscrivere `memberUids` per intero (espellere
  altri membri o aggiungerne di arbitrari). Ora join/leave sono vincolati al
  **proprio** uid (`hasAll`/`hasOnly` + `concat([request.auth.uid])`),
  combaciando con `joinProject`/`leaveProject` (arrayUnion/arrayRemove di sé).
  Il ramo owner resta a controllo pieno.
- **nota(storage)** — Firebase Storage richiede il piano **Blaze** (il bucket
  `chigio-time-pcm.firebasestorage.app` non è provvisionabile su Spark), quindi
  oggi non esiste alcun bucket attivo: nessuna superficie da proteggere. Il
  caricamento foto custom (`uploadProfilePhoto`) di fatto non funziona su Spark
  (fallisce con snackbar, gestito); la foto mostrata è quella sincronizzata da
  Google (`syncPhotoUrl`, nessuna Storage). Niente `storage.rules`/blocco
  `storage` in `firebase.json` finché Storage non viene abilitato su Blaze:
  wired-in adesso sarebbe solo un *landmine* che fa abortire `firebase deploy`
  come già accade per le functions.
- **test** — 1 test sul contratto whitelist `type` + 1 su join/leave progetti.
  `flutter analyze` pulito (azzerati
  4 lint info: `avoid_types_as_parameter_names`, doc-comment HTML, e i due
  web-only su `csv_download_web.dart` via `ignore_for_file` motivato).

## 2026-06-26 — Gate onboarding reattivo (fix: onboarding ricompare)

- **fix(onboarding)** — il router non ri-mostra piu' l'onboarding a chi l'ha
  gia' completato. Causa: il `redirect` faceva un check **async** (cache
  `SharedPreferences` + `Firestore.get()`) che andava in race con le emissioni
  concorrenti di `authStateChanges`, lasciando vincere un risultato stale.
- **refactor(router)** — `redirect` reso **sincrono**: legge
  `hasProfileStreamProvider` (unica fonte di verita', `profileDocIsComplete`).
  `_RouterNotifier` ora ascolta sia `authStateChangesProvider` sia
  `hasProfileStreamProvider`; il router `keepAlive` mantiene vivo lo stream
  auto-dispose. Rimossi prefs e `Firestore.get()` dal gate (la cache offline di
  Firestore copre l'uso senza rete). `loading`/`error` → nessun redirect forzato.
- **refactor(onboarding_screen)** — rimossa la scrittura manuale di
  `hasProfile_{uid}` su `SharedPreferences` **e** il `go('/dashboard')`
  esplicito a fine onboarding: navigare a mano correva contro lo stream
  (ancora `false` quando la `set` locale risolve) e rimbalzava per `/onboarding`.
  Ora si fa solo `nav.pop()` del dialog e il gate reattivo sposta
  `/onboarding → /dashboard`. Rimossi import `firebase_auth`/`shared_preferences`/
  `go_router`.
- **docs** — [`funzionalita/onboarding.md`](./funzionalita/onboarding.md): nuova sezione
  "Gate del profilo (reattivo)" + diagramma aggiornato.

## 2026-06-24 — Suite di test pre-rilascio

- **test** — aggiunti ~13 file di test (offline, `flutter test`): dominio
  (`daily_timesheet`, `salary_payment`, `colleague`, `projects`+`ActivePomodoro`),
  servizi (`csv_import_service`), core/sicurezza (`profileDocIsComplete`,
  `pcm_locations`, `app_strings`), feature (`statusRingColor`/`statusExplanation`,
  `formatCcnlBody`), **contratto rules** (`firestore_rules_test`), accessibilità
  (contrasto WCAG) e UI (`FloatingNav`). 53 test totali, verdi.
- **chore** — `CsvImportService.parse(...)` pubblico per i test.
- **docs** — nuova [`processi/testing.md`](./processi/testing.md) (cosa copre,
  come si lancia, limiti); CLAUDE.md §5 rimanda alla suite pre-rilascio.

## 2026-06-24 — Rifiniture UI + audit sicurezza

- **fix(social)** — azioni del popup dettaglio collega ora affidabilmente
  cliccabili (`HitTestBehavior.opaque`) e stella "preferito" reattiva; banner
  "Presenti oggi" più compatto (avatar 30px, niente titolone).
- **fix(dashboard)** — il widget "Colleghi preferiti" mostra le foto profilo.
- **feat(ccnl)** — corpo articoli del lettore più leggibile: rimossi numeri di
  pagina/intestazioni correnti, capoversi ricomposti, font non monospace
  (`formatCcnlBody`). I `.md` non sono modificati: il parser dipende dal
  formato grezzo.
- **fix(security)** — l'auto-accept dei collegamenti (F1) accetta ora solo
  mittenti con profilo leggibile (stessa amministrazione): chiunque poteva
  creare una notifica `colleague_added` (spoof `fromUid`) e forzare una
  connessione. Vedi audit sotto.
- **chore(release)** — `v2026.6.24+12`.

### Audit sicurezza/permessi (note)
- **Risolto** — connessioni forzate cross-amministrazione (sopra).
- **Noto/limitazione** — la directory colleghi è per-amministrazione, ma
  `administration` è impostata dal client: un client malevolo potrebbe
  cambiarla per leggere un'altra amministrazione. Mitigazione vera richiede
  validazione server-side (Cloud Functions, piano Blaze).
- **Noto/v2** — su progetto condiviso un collaboratore può modificare
  `memberUids` (anche rimuovere altri): accettabile tra Collegati, da irrigidire
  (ADR-0011).
- **Noto** — la Cloud Function FCM non ha un case per `colleague_added` (push
  generica); non deployabile su Spark. Notifica in-app ok.
- **Debito di layering** — alcuni provider di presentation
  (`timer_provider.dart`) leggono `FirebaseFirestore.instance` direttamente.

## 2026-06-23 — Rifiniture social/timesheet/projects + sicurezza

- **fix(security)** — `firestore.rules`: i pomodori sono leggibili/creabili solo
  dai membri del progetto; update consentito solo all'autore.
- **fix(social)** — caricamento colleghi non andava più in errore con un collega
  privato (privacy spostata client-side, non nelle rules); fetch profili
  resiliente (fallback per-doc).
- **feat(social)** — toggle "disponibile per caffè" compatto su "Presenti oggi"
  (stats in Profilo › Statistiche); badge stato leggibile anche per "Non in
  ufficio"; azioni chiama/caffè/preferito nel popup dettaglio collega; modifica
  "Stato del giorno" anche dal Social.
- **fix(art9)** — solo valori 0/8/17 (toggle), titolo corretto (non "smart
  working"), bottoni centrati, integrità in tutta l'app.
- **fix(profile)** — foto come prima voce in "Dati personali"; customizer schede
  di navigazione allineato (include Progetti e Stipendio).
- **feat(timesheet)** — Ferie/Permesso quick-add anche su giorno vuoto; import
  CSV con overwrite pieno (niente campi stale al cambio tipo).
- **feat(projects)** — pomodoro con pausa/ripresa, fasi focus/pausa con "Salta",
  e modifica dei pomodori passati (autore).

## 2026-06-23 — Lotto bug/feature (integrato in `ROADMAP.md`)

### Bug
- **fix (B1)** — onboarding: rimosso il tasto "Salta" (a step 10 bypassava il
  salvataggio finale). **Ri-onboarding cross-device**: `profileDocIsComplete`
  richiedeva anche `containsKey('standardDailyMins')`, assente su alcuni
  account completati → su device nuovi (senza cache prefs) il redirect
  rispediva all'onboarding. Allentato a `name`+`employmentType` (scritti solo
  dal completamento, non da `syncPhotoUrl` che setta solo `photoURL`); il router
  fa backfill di `hasCompletedOnboarding`.
- **fix (B2)** — `profile_screen.dart`: gli sheet di modifica Genere e
  Inquadramento dichiaravano `String selected = current` **dentro** il builder
  dello `StatefulBuilder` → la selezione si resettava a ogni rebuild. Hoisted
  fuori dal builder. Il genere è già sempre modificabile da Profilo.
- **fix (B3)** — onboarding: titoli con sigle esplicite — "Straordinario
  Liquidabile (SLI)" / "Banca Ore (SBO)".
- **fix (B4)** — `pcm_locations.dart`: CAP aggiunti a tutte le sedi (campo
  `city` → "00187 Roma", entra anche in `mapsQuery`), confrontati con
  `Appendice A`; getter `fullAddress`/`displayLabel` + helper `pcmSedeLabel`
  eliminano la ripetizione "Via X — Via X" in onboarding/profilo/route planner.
- **fix (B6)** — vista Anno responsive: 2 colonne su mobile, 3 da 800px, 4 da
  1200px (i mesi non sono più sovradimensionati su desktop).
- **fix (F6)** — icone import/export più chiare: import `file_open_rounded`,
  export `save_alt_rounded`.
- **fix** — **3 generi M/F/A** (Neutro 'N' già rimosso il 2026-06-11):
  riallineato `chigio_phrase_engine.dart` — `_applyGender` mappa legacy 'N' →
  schwa ('A'), default di `resolve()` `'N'`→`'A'`, e rimosso il 4° alternante
  morto dai 4 marker in `chigio_quotes.dart` (`{M|F|A}`). Test
  `chigio_phrase_engine_test` aggiornato (legacy N → schwa). Risolve la suite
  rossa preesistente.

### Feature
- **feat (B5)** — anello colorato sull'avatar dei colleghi per stato di
  timbratura (verde=in sede, blu=smart, giallo=pausa, **nero**=uscito/assenza
  uniti); label breve nella card, spiegazione nel profilo collega
  (`_SocialAvatar.ringColor`, `statusRingColor`, `statusExplanation`).
- **feat (F1)** — collegamenti "amichevoli" reciproci e auto-accettati: `addColleague`
  aggiunge lato mittente + notifica `colleague_added`; il destinatario
  riconcilia in automatico (`reconcileIncomingConnections`, init di SocialScreen).
  Niente più richiesta/conferma né rimozione. Termine UI "Collegati con" / "+".
- **feat (F2)** — profilo privato: toggle in Profilo › Impostazioni
  (`isPrivate`); i privati non compaiono in ricerca, non sono aggiungibili e
  non possono aggiungere (FAB nascosto). Privacy **client-side** (non nelle
  rules: la clausola `isPrivate != true` romperebbe le query di lista/batch
  colleghi).
- **feat (F5)** — import CSV robusto: niente blocco, le righe valide vengono
  importate (sovrascrivono le esistenti), le malformate vengono saltate e
  riportate in un **riepilogo** finale (salvate + scartate con motivo).
- **feat (F3)** — nuova sezione **Progetti** (`lib/features/projects/`) con
  Pomodoro timer: progetti personali/condivisi (collezione top-level
  `projects` + `pomodoros`), ruolo unico trasferibile (capo progetto), timer
  persistente basato su timestamp (preset 25/5 e 45/15), riepilogo per
  giorno/settimana/mese/sempre, contributi per collaboratore, scoperta dei
  progetti condivisi dai Collegati. Rules dedicate. Vedi
  [ADR-0011](./decisioni/0011-pomodoro-progetti.md).
- **feat (F4)** — scorciatoie da tastiera desktop (`1–5` schede, `T`
  Cartellino, `O` Home, `Esc` Home, `?` aiuto) via `CallbackShortcuts`, con
  popup "i" nell'header desktop.
- **feat** — navbar a **5 voci**: nuova tab **Progetti** in 3ª posizione
  (`floating_nav.dart` tab `timer_rounded`, larghezza `76→64`;
  `main_shell_screen.dart` chiave `projects` + voce header desktop; nuovo
  branch `/projects`).
- **docs** — nuova [ADR-0011](./decisioni/0011-pomodoro-progetti.md); feature
  `progetti.md`, entità `progetto.md`; aggiornati `social.md`, `navigation.md`,
  `persistence.md` e gli indici. L'intervista bug/feature (ex `docs/backlog.md`)
  è confluita in [`ROADMAP.md`](./ROADMAP.md).

## 2026-06-15 — Pagina Stipendio (4ª tab) + notifica del giorno-paga

### Stipendio (nuova feature)
- **feat** — `lib/features/salary/` (NEW): `SalaryPayment` + enum `SalaryPaymentType` (`ordinaria`/`straordinaria`/`buoniPasto`/`altro`); `SalaryRepository` Firestore-only su `users/{uid}/salaryPayments`; provider `salaryPaymentsStreamProvider`. `SalaryScreen` con hero "Prossimo accredito" (countdown al giorno-paga + stima netto = media ultimi 3 ordinari), strip statistiche anno (netto/cedolini/media), storico raggruppato per mese con tipologia colorata e badge "manuale", FAB + sheet add/edit (tipo, data, lordo, netto, note). Vedi [ADR-0010](./decisioni/0010-stipendio-quarta-tab.md), [feature](./funzionalita/stipendio.md), [entità](./entita/salary-payment.md).
- **feat** — Navigazione: 4ª `StatefulShellBranch` `/salary`; `floating_nav.dart` nuova tab `payments_rounded` (larghezza tab `88→76`, padding laterale `20→12` per restare entro ~360 px); `main_shell_screen.dart` chiave nav `salary` + voce nell'header pill desktop.
- **feat** — Notifica "Stipendio in arrivo": toggle in Profilo › Notifiche (`notifyPayday` + stepper `paydayDay` 1–28, default 23); `functions/index.js` (`hourlyNotifications`) invia push FCM alle 08:00 del giorno-paga.
- **feat** — `firestore.rules`: `users/{uid}/salaryPayments/{id}` owner-only.
- **feat** — `app_strings.dart`: blocco `salary*`, `navSalary`, `notifPayday*`.
- **docs** — nuove pagine `funzionalita/stipendio.md`, `entita/salary-payment.md`, `decisioni/0010-stipendio-quarta-tab.md`; aggiornati `persistence.md`, `navigation.md`, `concetti-pagine.md`, `funzionalita/README.md`, `entita/README.md`, `decisioni/README.md`, `funzionalita/profile.md`, `ROADMAP.md`.
- **chore** — versione → `v2026.06.15` / `2026.6.15+9`.

## 2026-06-14 — S-14: redesign "Inquadramento e orario" + cap storicizzati

### Profilo / Dominio
- **feat** — cap storicizzati (ADR-0009): `CapPeriod` + `capsForMonth` resolver; sub-collezione `users/{uid}/capPeriods`. Cambiando inquadramento i nuovi massimali valgono dal mese successivo, i mesi passati conservano i loro cap. Regola Firestore owner-only. Script `migrate_cap_periods.mjs` (seed periodo aperto da campi flat).
- **feat** — `dashboard_screen.dart`: la card maggior presenza risolve i cap (Art.9/SLI/SBO) del **mese selezionato** via `capsForMonth` (fallback campi flat).
- **feat** — sezione "Inquadramento e orario" ridisegnata: riga Orario unificata (5-uguali/3+2, ore predeterminate; rimosso override per-giorno), Art.9 con toggle ON/OFF + tap-to-edit, "Tetto maggior presenza" (auto = Art.9+SLI+SBO) al posto del duplicato "Tetto straordinari".
- **feat** — cambio inquadramento con dialog di conferma → `changeInquadramento` (chiude periodo corrente, apre nuovo dal mese prossimo).
- **feat** — sotto-pagina `StoricoInquadramentiPage` (lista periodi cap, range da/a + snapshot).
- **refactor** — "Avviso soglia straordinari" spostato dalla sezione Inquadramento allo sheet Notifiche (stepper 0–80h, 0 = off).
- **fix** — barra maggior presenza: label Art.9/SLI/SBO centrate ognuna sul proprio segmento.
- **chore** — rimosso codice morto: `_editWeeklySchedule`, `_weeklyScheduleSummary`, override `weeklyScheduleMins`.

## 2026-06-13 — Fix onboarding redirect, dedup profile-check, split SBO/SLI

### Bug fix
- **refactor** — dedup del check "profilo completo": estratto `profileDocIsComplete(Map?)` in `profile_repository.dart`, unica fonte di verità usata sia dal redirect del router sia da `hasProfileStream`. Eliminata la tripla copia (router inline + path A/B dello stream) — era il "doppione" della logica di verifica profilo.
- **fix** — `app_router.dart`: redirect non forza più l'onboarding quando il `get()` Firestore restituisce un doc incompleto **dalla cache offline** (`doc.metadata.isFromCache`). Causa del "re-show onboarding" su primo avvio offline / device nuovo per utenti che hanno già un profilo. Su risultato da cache incompleto → `return null` e si attende lo snapshot server.

### Dati (one-off Firestore)
- **data** — account `marcocipriani.pcm@gmail.com`: impostati i cap mensili straordinario mancanti (`monthlySliHours` 0→3, `monthlySboHours` 0→3; Art.9 invariato a 8h).
- **data** — ricalcolata la ripartizione SBO/SLI per giorno su 25 timesheet via cascata Art.9→SLI→SBO→OPE (distribuzione largest-remainder proporzionale a `extraMins`). Prima i giorni recenti scaricavano tutto lo straordinario su `sboMins` ignorando i cap; ora SLI=6h00, SBO=0h51 sull'anno, coerente con la card "maggior presenza" della dashboard. `extraMins` invariato.
- **chore** — `scripts/`: tooling di manutenzione Firestore (firebase-admin) — `inspect_user.mjs`, `set_caps.mjs`, `migrate_straordinario.mjs` (dry-run di default). Chiavi service-account ignorate da git.

> Nota: la logica di salvataggio per-giorno in `timer_provider.dart` (`sboMins = extraMins`) è stata lasciata invariata su richiesta; la ripartizione corretta resta quella della cascata sui cap.

### Sicurezza
- **security** — rimossa dal repo la chiave service-account admin (`chigio-time-pcm-firebase-adminsdk-*.json`); pattern aggiunti a `.gitignore` (mai committata).
- **security** — `firestore.rules`: letture di `users/{userId}` ristrette a proprietario **o** stessa `administration` (prima: qualunque autenticato leggeva ogni profilo → harvesting telefoni cross-amministrazione). Aggiunta sub-collezione owner-only `users/{uid}/private/{docId}`. Vedi [ADR-0008](./decisioni/0008-firestore-read-scoping.md). **Da deployare**: `firebase deploy --only firestore:rules`.

### Android / Icona
- **fix (manuale)** — Google Sign-In non funziona sull'APK: `android/app/google-services.json` ha `oauth_client: []` (nessun client OAuth → idToken null). Causa: nessun fingerprint SHA registrato per l'app Android. Azione richiesta in Firebase Console: aggiungere SHA-1/SHA-256 (release + debug) e riscaricare `google-services.json`.
- **fix** — icona app: le icone launcher generate erano ancora il vecchio uccellino; `app_icon.png` era già la tartaruga. Rigenerate android+iOS con `flutter_launcher_icons` da `app_icon.png` (tartaruga blu Chigio).

### Docs / Manutenzione
- **chore** — file `.md` di radice riorganizzati in `docs/`: `departments.md`→`entita/dipartimenti-pcm.md`, `identita_visiva_chigio.md`→`funzionalita/chigio-identita-visiva.md` (overlap con `chigio-visual-identity.md` da unire — nuovo item backlog), `sedi.md` obsoleto rimosso. Link aggiornati. Radice ora solo `CLAUDE.md` + `README.md`.

## 2026-06-11 — S-12b: chiusura S-12 + bug urgenti (sedi PCM, drag handle, privacy GDPR, viste timesheet)

### Bug fix
- **fix** — `pcm_locations_repository.dart`: `getOfficeLocations()` con try/catch — se il DB Drift WASM fallisce (worker/asset mancanti su web) o restituisce 0 righe, fallback a `activePcmOfficeSeeds()`. Chiude il Bug B delle sedi PCM; il Bug A (ID mismatch) era già risolto dal match per nome in `_PcmSiteSheet`.
- **fix** — `profile_screen.dart`: `buildDefaultDragHandles: false` su `ReorderableListView.builder` del customizer Widget Home — la maniglia custom non confligge più con i listener di default (item che "saltava" senza drag).
- **verify** — flag `hasCompletedOnboarding`: percorso scrittura/lettura/backfill verificato corretto, nessun fix necessario.

### Profilo
- **feat** — `app_strings.dart` + `profile_screen.dart`: sheet Privacy estesa con 3 nuove righe — riferimenti normativi (GDPR Reg. UE 2016/679, D.Lgs. 196/2003 e s.m.i.), tecnologie usate (Firebase Firestore/Auth/Storage/FCM — Google LLC, server EU), diritti GDPR con portabilità via "Scarica i tuoi dati".

### Timesheet
- **feat** — `monthly_summary_card.dart`: nuovo parametro `swYearCount`; badge `YYYY: N SW` accanto al badge SW mensile nell'header.
- **feat** — `timesheet_screen.dart`: `swYearCount` calcolato su tutti i 12 mesi dell'anno selezionato; badge `🖥 N SW` annuale anche nell'header della vista Anno.
- **feat** — `timesheet_screen.dart`: vista Mese — celle con cerchio pieno colore-tipo e numero giorno al centro (stile vista Anno); bordo blu selezione, bordo neutro per oggi; griglia più compatta (aspect 1.45); legenda `_ColorLegend` al posto della vecchia riga dot.
- **feat** — `timesheet_screen.dart`: vista Settimana — nuovo pannello con tutte e 7 le giornate (cerchio colorato, nome giorno, orari/tipo, netto); riga selezionata evidenziata con bordo blu; tap seleziona.
- **feat** — `timesheet_screen.dart/_DayNoteSection`: dirty-check — pulsante Salva visibile solo quando il testo è diverso dall'ultimo salvataggio.

### Statistiche
- **feat** — `stats_screen.dart/_AdvancedStatsCard`: aggiunta riga "Uscita tipica" (ora di uscita più frequente) e "Giorno più OT" (giorno settimana con più straordinari, finestra 3 mesi).
- **feat** — `stats_screen.dart/_FunnyStatsCard`: aggiunti "Caffè ↑/↓" (inviati/ricevuti del mese, da `coffeeStatsProvider`) e confronto "Mese più OT" / "Mese meno OT" su finestra 6 mesi.

### Social
- **feat** — `social_screen.dart/_GroupMembersSheet`: pulsante "Elimina gruppo" con dialog di conferma in fondo al sheet gestione membri. Gruppi in `users/{uid}/groups` → il proprietario è sempre il creatore.

### Wiki
- **wiki** — [`funzionalita/widget-inventory.md`](./funzionalita/widget-inventory.md) allineata allo stato corrente: long-press edit `_HomeCountersRow`, `_TimbraturaBarra`, badge SW `MonthlySummaryCard`, dirty-check `_DayNoteSection`, gap Drift WASM chiuso.
- **wiki** — [`ROADMAP.md`](./ROADMAP.md): S-12/S-13 chiusi, sezione "Bug urgenti" risolta e spostata in Completato (S-12b).

## 2026-06-11 — S-12/S-13: onboarding rework, timesheet improvements, import fix

### Sprint S-12 — Onboarding
- **feat** — `onboarding_screen.dart`: Art.9 con chip binari (0/max per Ruolo/Comando), slider altrimenti; step SLI+SBO+tetto calcolato; dipartimento e sede unificati in un unico step; suggerimento sede in base al dipartimento (★); immagine Chigio al posto dell'emoji 👋.
- **feat** — `pcm_departments.dart` (nuovo): costante `kPcmDepartments` con 62 strutture PCM e `primarySedeId`; `sortedOfficesForDepartment()` mette la sede suggerita in cima.
- **feat** — `app_strings.dart`: stringhe Art.9/SLI+SBO onboarding aggiunte.
- **feat** — `onboarding_provider.dart`: `setMonthlySliHours`/`setMonthlySboHours` ora aggiornano `monthlyOvertimeHours = sli + sbo` automaticamente.

### Sprint S-12 — Profilo
- **fix** — `profile_screen.dart`: tetto (monthlyOvertimeHours) ora read-only = SLI+SBO; variabile `overtime` rimossa.
- **feat** — `profile_screen.dart`: modifica SLI o SBO salva anche `monthlyOvertimeHours` su Firestore atomicamente tramite `extraFields` in `_editIntHours`.

### Sprint S-12 — Timesheet
- **feat** — `monthly_summary_card.dart`: badge "🖥 N SW" in header accanto al mese quando ci sono giorni SW nel mese.
- **feat** — `timesheet_screen.dart`: cerchi settimana colorati per tipo giornata (verde=presenza, blu=SW, viola=permesso, ambra=ferie, arancione=OT); bordo today quando nessuna entry; legenda colori in vista settimana e mese.
- **feat** — `timesheet_screen.dart/_DayDetailCard`: bottoni "Ferie" e "Permesso" come CTA rapide su giorni non già assenza.
- **feat** — `timesheet_screen.dart/_ColorLegend`: widget legenda riutilizzabile con 5 voci colorate.

### Sprint S-12 — Dashboard
- **feat** — `dashboard_screen.dart/_HomeCountersRow`: long-press su ogni chip apre il foglio di modifica inline tramite `showCounterEditSheet()`.
- **feat** — `totalizzatori_section.dart`: `showCounterEditSheet()` helper pubblico per aprire l'editor da fuori.

### Sprint S-12 — Stats
- **feat** — `stats_screen.dart/_FunnyStatsCard`: nuova card con statistiche curiose — percentuale lunedì presenti, giorno della settimana preferito, totale giorni SW, orario di entrata più precoce.

### Sprint S-12 — Social
- **feat** — `social_screen.dart`: messaggio d'invito personalizzato con nome utente, ente e frase Chigio casuale da `ChigioQuotes.invite`.
- **feat** — `chigio_quotes.dart`: lista `ChigioQuotes.invite` con 7 frasi.

### Sprint S-13 — Fix import CSV per marcocipriani.pcm
- **fix** — `csv_import_service.dart`: `_parsePauseMins` estrae la durata reale dalla "Pausa Pranzo dalle HH:MM alle HH:MM" (correzione da 30 min hardcoded → pausa reale portale, tipicamente 60 min).
- **fix** — `csv_import_service.dart`: `_parsePortaleMins` estrae sliMins da "Maggior Presenza"/"Indennità Art.9" e sboMins da "Banca Ore" nel campo nota CSV; quando presenti, sovrascrivono il calcolo dai timestamp.
- **feat** — `csv_import_service.dart`: `_cleanNote` rimuove i token portale (contatori, timbrature) dal campo nota archiviato, preservando solo le descrizioni leggibili.

## 2026-06-11 — S-11 completato: genere neutro rimosso, OT alert, Drift WASM web

- **refactor** — rimossa opzione genere 'N' (neutro) da tutta l'app: picker profilo, default `ChigioContext`, default `OnboardingState`, fallback `glass_header.dart`; backward-compat: valori Firestore `'N'` mappati a `'A'` in `_applyGender`; costante `AppStrings.genderNeutral` rimossa.
- **feat** — `app_strings.dart`: `AppStrings.otAlertThreshold`, `AppStrings.otAlertMessage(h, total)`, `AppStrings.otAlertDisabled`.
- **feat** — `profile_screen.dart`: nuova riga `monthlyOtAlertHours` in card Inquadramento — mostra "Disabilitato" se 0, altrimenti `X h/mese`; editabile con `_editIntHours` (min 0, max 80).
- **feat** — `dashboard_screen.dart`: calcolato `otAlertThresholdMins` e `otAlertActive`; banner `_OtAlertBanner` in statsSection quando soglia superata.
- **feat** — `dashboard_screen.dart/_OtAlertBanner`: banner arancio con icona notifica e messaggio dinamico `AppStrings.otAlertMessage`.
- **feat** — `drift_worker.dart.js` compilato in `web/` (`dart compile js`); `kIsWeb` guard rimosso da `appDatabaseProvider` — Drift WASM attivo su web.
- **chore** — `app_database.dart`: rimossa import `flutter/foundation.dart` (kIsWeb non più necessario).
- **docs** — `ROADMAP.md`: sprint S-11 completato → sezione "✅ Completato (S-11)"; S-12 e S-13 spostati in Backlog.

## 2026-06-10 — S-11: SAU mensile, foto profilo upload, gruppi membri, chart storico

- **feat** — `monthly_sau.dart`: nuovo domain model `MonthlySau` (monthId, sliHours, sboHours, sauHours, note, recordedAt); toFirestore/fromFirestore.
- **feat** — `profile_repository.dart`: `saveMonthlySau()` scrive su `users/{uid}/sau_monthly/{YYYY-MM}`; `monthlySauHistoryStream()` legge ultimi 12 mesi; `uploadProfilePhoto()` carica su Firebase Storage `profile_photos/{uid}.jpg` e aggiorna `photoURL` su Firestore.
- **feat** — `profile_repository.dart`: provider `monthlySauHistoryStreamProvider` generato via Riverpod.
- **feat** — `profile_screen.dart/_SauMonthlyUpdateRow`: riga interattiva in card Inquadramento — mostra record corrente (mese SAU) o prompt "Registra SAU per [mese]"; dialog con stepper SLI/SBO e SAU calcolato.
- **feat** — `profile_screen.dart/_PhotoUploadCard`: avatar tappabile in ProfileEditScreen — seleziona da galleria, carica su Storage, aggiorna Firestore; indicatore di upload.
- **feat** — `profile_screen.dart/_IntStepper`: helper widget stepper +/− per dialogs numerici.
- **feat** — `stats_screen.dart/_SauHistoryChart`: grafico a barre grouped (SLI/SBO/SAU per mese) negli ultimi 6 record; mostrato solo se sauHistory non vuoto.
- **feat** — `social_screen.dart/_GroupMembersSheet`: bottom sheet gestione membri gruppo — lista corrente con pulsante rimozione; ricerca e aggiunta da lista colleghi.
- **feat** — `social_screen.dart/_MemberRow`: riga collega con avatar, nome e azione (add/remove).
- **feat** — `social_screen.dart/_GroupTile`: nuovo campo `onManageMembers` con icona gruppo blu; passato in desktop panel e mobile sheet.
- **refactor** — `social_screen.dart`: `_avatarColor` estratto in funzione top-level `_colleagueAvatarColor` accessibile da tutti i widget del file.

## 2026-06-10 — ShiftRing redesign S-11: time labels, OT ticks, monthly %, Chigio

- **feat** — `shift_ring.dart`: parametri `stdMins` e `mealThresholdMins` ora passati dall'esterno (profile-driven, non hardcoded).
- **feat** — `shift_ring.dart`: etichette orario (entry/exit) disegnate fuori dal cerchio tramite `TextPainter` — entrata a 12 o'clock, uscita vicino al punto di progresso.
- **feat** — `shift_ring.dart`: tick marks OT ring a 30, 60, 90 min (cap 9h) disegnati come trattini radiali con stile contrastante quando raggiunti.
- **feat** — `dashboard_screen.dart`: calcolato `monthlyOtPct` (OT mensile / cap mensile %) dalla somma `entries.extraMins` e dai cap da profilo (Art.9 + SLI + SBO).
- **feat** — `dashboard_screen.dart/_ChigioMini`: piccola immagine Chigio (`chigio-ok.png`, 26px) nei ring center working/OT/completed.
- **feat** — `dashboard_screen.dart/_MonthlyOtHint`: badge `↑ X% mese` mostrato nel ring center quando cap mensile configurato; colore arancio se ≥80%.
- **feat** — `dashboard_screen.dart`: ring center stato OT mostra `monthlyOtPct` badge invece di `_MealBadge`.
- **feat** — `dashboard_screen.dart`: ring center stato completed mostra maggior presenza oggi (`+Xm Maggior presenza`) se OT, più `monthlyOtPct` badge.
- **fix** — `dashboard_screen.dart/_NoteSection`: `], // end if (_expanded)` mancante — fix sintassi spread.
- **refactor** — `shift_ring.dart`: `_kMealFrac` rimosso; `mealFrac` calcolato dinamicamente da `mealThresholdMins/stdMins`.

## 2026-06-10 — Profilo riorganizzato, drag fix, attività dirty, foto colleghi, SAU

- **feat** — `profile_screen.dart`: sezionamento in 6 sezioni — Card personale (avatar tappabile), Inquadramento e orario, Statistiche (+link /stats), Funzionalità (GPS), Opzioni app, CCNL, Info app. CCNL spostato prima di Info app. Privacy spostata in Info app.
- **feat** — `profile_screen.dart`: card avatar tappabile → naviga a `/profile/edit` (nuova schermata dati personali). Badge edit blu in basso a destra.
- **feat** — `ProfileEditScreen` aggiunta in `profile_screen.dart`: schermata dedicata per nome, genere, ente, dipartimento, sede, piano, stanza, interno, telefono, stato del giorno.
- **feat** — `app_router.dart`: rotta `/profile/edit` collegata a `ProfileEditScreen`.
- **feat** — `profile_screen.dart`: card Inquadramento separata con tipo contratto, orario (variante), ore standard, orario settimanale, soglia buono pasto, Art.9, SLI, SBO, SAU (calcolato = SLI+SBO, read-only), cap straordinari.
- **feat** — `app_strings.dart`: aggiunte costanti `sectionInquadramento`, `sectionFeatures`, `sauMonthly`, `seeAllGraphs`, `editPersonalDetails`, `personalDetails`, `appFeaturesGps`, `appInfoFull`, `editDay`.
- **feat** — `app_strings.dart`: `appInfoBody` aggiornato con elenco funzionalità complete.
- **feat** — `profile_screen.dart/_showHomeWidgetsCustomizer`: drag handle ora usa `ReorderableDragStartListener` — trascina solo dalla maniglia, non da tutta la riga.
- **feat** — `dashboard_screen.dart/_NoteSectionState`: pulsante Salva visibile solo quando il testo attività è stato modificato (`_dirty = _ctrl.text != _originalText`). Reset `_originalText` dopo salvataggio.
- **feat** — `dashboard_screen.dart`: pulsante "Nuova giornata" sostituito con "Modifica giornata" (→ naviga a `/timesheet` per correggere timbrature sbagliate).
- **feat** — `colleague.dart`: campo `photoURL` aggiunto a `ColleagueProfile`.
- **feat** — `social_repository.dart`: `photoURL` mappato da Firestore in `watchColleagues`.
- **feat** — `social_screen.dart/_SocialAvatar`: mostra `Image.network` se `photoURL` disponibile, fallback a iniziali. Propagato a tutti e 3 i call site con ColleagueProfile.
- **feat** — `profile_repository.dart`: `syncPhotoUrl` salva `photoURL` su Firestore. `saveOnboardingData` include `photoURL` da Firebase Auth se presente.
- **feat** — `login_screen.dart`: dopo Google sign-in chiama `syncPhotoUrl` fire-and-forget.
- **fix** — `main.dart`: font pre-loading con `GoogleFonts.pendingFonts` (già committato).

## 2026-06-10 — Font pre-loading per eliminare warning Noto su CanvasKit web

- **fix** — `main.dart`: aggiunto `GoogleFonts.pendingFonts([...])` prima di `runApp()`. Pre-carica Plus Jakarta Sans (4 pesi), NotoColorEmoji, NotoSansSymbols2 per eliminare "Could not find a set of Noto fonts" su CanvasKit. Wrapped in `try-catch` per resistere a avvio offline.

---

## 2026-06-10 — Schedule CCNL refactor, profilo cleanup, widget reorder, anno dots

- **feat** — `app_constants.dart`: aggiunti `stdDailyMinsRuoloShort=400`, `stdDailyMinsComandoShort=360`, `stdDailyMinsLong=540`, `weeklyMinsRuolo/Comando`, `art9MonthlyCapMins*`, `scheduleUniform/Mixed`, helper `stdMinsForDate(profile, date)`.
- **fix** — `app_strings.dart`: `mealMinsByType` restituisce 380 per tutti i tipi (era 360 per Comando). Aggiunte stringhe `scheduleVariant*`.
- **feat** — `onboarding_provider.dart`: campi `scheduleVariant` e `longWorkDays` in `OnboardingState`; metodi `setScheduleVariant`, `toggleLongWorkDay`; `setEmploymentType` resetta variant+days.
- **feat** — `onboarding_screen.dart`: step 5 per Ruolo/Comando mostra picker variante orario (uniforme/misto 3+2) + selezione 2 giorni lunghi (lun–ven); validazione 2 giorni se misto. Widget `_VariantChip`.
- **feat** — `profile_repository.dart`: `saveOnboardingData` persiste `scheduleVariant` e `longWorkDays` su Firestore.
- **fix** — `timer_provider.dart`: `standardWorkMins` ora calcolato via `AppConstants.stdMinsForDate(profile, today)` invece di leggere `standardDailyMins` statico.
- **fix** — `dashboard_screen.dart`: `mealMins` rimossa formula proporzionale (era `stdMins*380/456`); ora costante 380 per tutti.
- **fix** — `totalizzatori_section.dart`: campo `standardWorkMins` → `standardDailyMins`.
- **fix** — `timesheet_screen.dart`: `_save()` usa `stdMinsForDate(profile, base)` + `.clamp().toInt()`; aggiunto import `app_constants.dart`.
- **feat** — `profile_screen.dart`: riga `scheduleVariant` (con giorni lunghi) dopo employmentType per Ruolo/Comando; bottom sheet `_editScheduleVariant` con variant chip + day picker.
- **feat** — `timesheet_screen.dart/_MiniMonthGrid`: dot anno più piccoli (0.62 da 0.76), numero del giorno visibile dentro ogni dot.
- **feat** — `profile_screen.dart/_showHomeWidgetsCustomizer`: `ReorderableListView` + checkbox per ogni widget; salva `homeWidgetsOrder` su Firestore.
- **feat** — `dashboard_screen.dart`: legge `homeWidgetsOrder` da Firestore e renderizza widget nell'ordine salvato via `switch` pattern.
- **refactor** — `profile_screen.dart`: rimossi stat items (record, uscite, SW) dalla card avatar; rimosso link "Statistiche avanzate →"; stats disponibili solo in `/stats`. Rimossi `_StatItem`, `maxMins`, `latestEnd`, `earliestEnd`, `swDays`, `fmtEnd`, `fmtMax`, `monthlyEntries`.

---

## 2026-06-10 — Sprint completato: 23 task (H0–H6, T2–T4/Tbug/Tcheck, S1–S5, P1–P6, I1–I2)

- **fix** — `timesheet_screen.dart/_save()`: tre `456` hardcoded → `stdMins` da profilo (Tbug).
- **fix** — `firestore.rules`: regola `notifications/{notifId}` consente self-write per `exit_reminder`; `functions/index.js`: aggiunto `case 'exit_reminder'` in `_buildNotification` (I1).
- **feat** — `social_screen.dart` + `colleague.dart` + `social_repository.dart`: campo `statusMessage` in `ColleagueProfile`; visualizzato in `_ColleagueCard` e `_ColleagueDetailSheet` (S4).
- **feat** — `profile_screen.dart/_NotificationSheet`: toggle DND + picker fascia oraria `silenceFrom`/`silenceTo` (P1).
- **feat** — `social_screen.dart/_ColleagueDetailSheet`: bottom sheet con `DraggableScrollableSheet`, info collega, storico caffè filtrato per uid (S3).
- **feat** — `profile_screen.dart/_showHomeWidgetsCustomizer` + `dashboard_screen.dart`: toggle 6 widget; lista `hiddenHomeWidgets` su Firestore; dashboard legge e nasconde (P6).
- **feat** — `timesheet_screen.dart`: pill "Anno" nel selettore viste; `_YearView` + `_MiniMonthGrid` con dot colorati per tipo (T3).
- **feat** — `dashboard_screen.dart/_SmartExitScenarios`: 3 chip uscita (giornaliero/+1h/mensile); deficit mensile calcolato da giorni lavorativi trascorsi (H4).
- **feat** — `profile_screen.dart/_NotificationSheet` + `functions/index.js`: notifica mattutina colleghi (`morningColleaguesHour`) e recap settimanale (`weeklyRecapDay`/`Hour`) (S2, P2).
- **feat** — `profile_screen.dart/_downloadMyData()`: export GDPR — profilo JSON + timesheets CSV + notifiche JSON via `share_plus`; web usa `XFile.fromData` (P4).
- **feat** — `profile_screen.dart`: 4 sezioni con `_SectionLabel` (Card personale / Statistiche / Opzioni app / Info app); `_OtTrendCard` spostata in Statistiche; appInfo/chigio in card separata (P5).
- **feat** — `dashboard_screen.dart/_TimbraturaBarra`: barra progress orizzontale con 3 gate (Art.9/BP/FS) integrata nel heroCard; import `day_checkpoints.dart` e rendering separato rimossi (H0).
- **feat** — `social_screen.dart/_AddColleagueSheet`: sezione link — condividi URL `chigiotime.web.app/add?uid=…` via `share_plus`/clipboard; campo paste link/UID con parsing query param + regex (S5).
- **feat** — `app_database.dart`: schema v4, 10 nuove colonne assenza in `TimesheetEntries` + migrazione `from < 4` con ALTER TABLE (I2).
- **fix** — `pdf_export_service.dart`: note mascherate con `'—'` quando `e.sensitive`; entrata/uscita mostrate come `'—'` per ferie e permessi giornalieri (Tcheck).
- **docs** — `docs/ROADMAP.md`: tutte le 23 task del sprint spostate in "✅ Completato" con data 2026-06-10; sezione "Prossimo sprint" svuotata.

---

## 2026-06-10 — Dashboard cleanup: remove widget blu, OPE sempre visibile, roadmap H0/H6/P6

- **feat** — `dashboard_screen.dart`: rimossa `MonthlySummaryCard` (widget blu) dalla statsSection. Rimosse anche le variabili non più usate nel build: `totalNetMins`, `totalOtMins`, `art9UsedMins`, `sliUsedMins`, `sboUsedMins`, `orePerseMins`, `mealCount`, `art9Cap`, `otCap`, `mealThreshold`, `sliCap`, `sboCap`, `visibleItems`, `showProgressBars`. Rimossa importazione `monthly_summary_card.dart` e `showCountersCustomizer` dall'import `profile_screen.dart`.
- **feat** — `dashboard_screen.dart/_MaggiorPresenzaCard`: chip OPE ora sempre visibile quando `totalCap > 0` (anche a 0h/no sforamento); colore `neutral400` quando OPE = 0, `red700` quando OPE > 0.
- **docs** — `docs/ROADMAP.md`: aggiunto H0 (barra timbratura con cancelli orari, redesign heroCard + DayCheckpoints), H6 (tempi istituzionali spostamenti PCM in `PcmRoutePlannerCard`), P6 (visibilità widget Home personalizzabile da Profilo). Aggiunte righe ✅ per le due feature completate oggi.

---

## 2026-06-10 — Roadmap sprint review

- **roadmap** — `docs/ROADMAP.md`: revisione sprint per pagina. H1 semplificato (rimossa previsione smaltimento, aggiunto calcolo giorni coperti da BOE). H4 espanso (3 scenari SmartExit: pareggio giornaliero, pareggio mensile, ora extra). H2/H3 → backlog. T1 rimosso (CSV/PDF già esistenti; aggiunto Tcheck per verifica). T2 colori per tipo giornata. T3 nuova pill "Anno". T5 rimosso, sostituito con Tbug fix straordinari `marcocipriani.pcm`. S2 notifica mattutina configurabile. S3 schermata dettaglio collega con storico caffè. S4 stato del giorno + asterisco in lista. P1 silenzio semplificato. P2 recap venerdì 18:00 configurabile. P3 → backlog. P4 → "Scarica i tuoi dati". P5 nuova: ristrutturazione sezioni Profilo. I1/I2 segnati ⚠️ priorità alta.

---

## 2026-06-09 — Chigio visual identity doc + prompt generativi

- **docs** — `docs/funzionalita/chigio-visual-identity.md`: nuova pagina dedicata all'identità visiva di Chigio. Contiene analisi stile (3D clay render, palette cromatica con hex esatti, token per ogni parte del corpo), scheda per ogni asset esistente (7), prompt di generazione pronti all'uso per tutti i 17 asset (7 esistenti + 10 proposti), tabella riepilogativa stato asset, note tecniche e checklist di consistenza visiva.
- **docs** — `docs/funzionalita/chigio.md`: aggiunto link alla nuova pagina identità visiva.
- **docs** — `docs/funzionalita/README.md`: aggiunta voce indice per `chigio-visual-identity.md`.

---

## 2026-06-09 — Social: rename gruppi, caffè sempre visibile, due telefoni, chip gruppo

- **feat** — `social_screen.dart`: pulsante ☕ sempre visibile su ogni collega; disabilitato (grigio) quando status è `completed`/`remote`/`holiday`/`leave`/`notStarted`. Rimossa condizione `showCoffeeButton`.
- **feat** — `social_screen.dart`: due pulsanti telefono separati — Interno (☎ verde, `interno`) e Cellulare (📱 blu, `phoneNumber`) — visibili solo se il campo è compilato nel profilo.
- **feat** — `social_screen.dart/_ColleagueCard`: chip gruppo/i accanto al nome (tag blu piccoli) calcolati live da `groupsStreamProvider`.
- **refactor** — `social_screen.dart/_ColleagueCard`: info ristrutturata — Dipartimento riga 1, Sede·Piano·Stanza riga 2; azioni (telefono/caffè/stella/stato) spostate in riga sotto il testo.
- **feat** — `social_screen.dart`: pulsante matita ✏️ su ogni `_GroupTile` per rinominare il gruppo; dialog con testo pre-compilato; attivo sia nel pannello desktop che nel foglio mobile.
- **feat** — `social_repository.dart`: aggiunto `renameGroup(id, newName)`.
- **feat** — `app_strings.dart`: aggiunte costanti `rename`, `renameGroup`, `cellulare`.

---

## 2026-06-09 — Fix DayCheckpoints widget (pausa pranzo e uscita reale)

- **fix** — `lib/shared/widgets/day_checkpoints.dart`: rimossa euristica errata `pausaDone = workedMins > 180` (si attivava dopo 3h indipendentemente dalla pausa). Ora `pausaDone = lunchPauseMins > 0` basato sul dato reale.
- **fix** — `lib/shared/widgets/day_checkpoints.dart`: `exitMin` ora usa `endTime` effettivo per turni completati; fallback a `entrataMin + standardWorkMins` per turni attivi.
- **fix** — `lib/shared/widgets/day_checkpoints.dart`: rimossi `_stdMins` e `_mealMins` hardcoded (`AppConstants.stdDailyMinsRuolo` / `defaultMealVoucherThresholdMins`). Widget ora riceve `standardWorkMins` e `mealThresholdMins` dal chiamante.
- **refactor** — `lib/features/dashboard/presentation/dashboard_screen.dart`: entrambe le call site di `DayCheckpoints` aggiornate per passare `lunchPauseMins`, `endTime`, `standardWorkMins`, `mealThresholdMins` da `effectiveShift` (turno completato) o `state` (turno attivo).

---

## 2026-06-09 — 9h 3-zone rule, OP vs Deficit, art9 cascade

- **fix** — `timer_provider.dart`: regola 9 ore corretta con logica a 3 zone in `endTurn`, `previewDeficit` e `expectedExitTime`. Zona 1 (`effectiveElapsed < 540`): nessuna pausa forzata. Zona 2 (`540–569`): pausa forzata = `effectiveElapsed − 540`. Zona 3 (`≥ 570`): pausa forzata = 30 min. Precedente: addeva sempre 30 min se `workedSoFar ≥ 540`, ignorando la zona 2.
- **fix** — `dashboard_screen.dart`: `art9UsedMins` calcolato via cascata mensile (`totalOtMins.clamp(0, art9Cap * 60)`) invece dell'erroneo `sum(leavePauseMins)`.
- **fix** — `_NineHourBanner`: condizione basata su `effectiveElapsed` (non `workedMins`); messaggio dinamico "Pausa pranzo virtuale +Xm inclusa" con `X` corretto per zona 2/3.
- **refactor** — `AppStrings.deficitLabel`: rinominato da `'Ore perse'` a `'Deficit'`; aggiunta `lunchVirtualBanner(int mins)`.
- **docs** — `glossario.md`, `funzionalita/orario-e-presenza.md`, `entita/daily-timesheet.md`, `entita/README.md`, `panoramica/requirements.md`: documentazione regola 9h aggiornata con le 3 zone; chiarita distinzione OP (straordinario oltre tutti i cap) vs Deficit (giornate sotto standard); tabella widget contatori corretta.

---

## 2026-06-09 — Centralizzazione stringhe — completamento

- **refactor** — `lib/features/social/presentation/social_screen.dart`: `'In ufficio'`, `'Da remoto'`, `'In pausa'` nei chip `_PresenceCount` sostituiti con `AppStrings.statusWorking`, `AppStrings.statusRemote`, `AppStrings.statusPaused`.
- **refactor** — `lib/features/authentication/presentation/onboarding_screen.dart`: `'Inquadramento'` → `AppStrings.employmentType`; chip Ruolo/Comando/Altro → `AppStrings.etRuolo/etComando/etAltro`; rimosso import `app_constants.dart` non più usato.
- **refactor** — `lib/features/authentication/presentation/onboarding_provider.dart`: comparazioni `== 'Ruolo'`/`'Comando'` in `setEmploymentType` → `AppStrings.etRuolo/etComando`; aggiunto import `app_strings.dart`.
- **refactor** — `lib/features/profile/presentation/profile_screen.dart`: lista chip `['Ruolo', 'Comando', 'Altro']` e comparazioni di tipo contratto → `AppStrings.etRuolo/etComando/etAltro`.
- **feat** — `lib/core/constants/app_strings.dart`: aggiunte costanti `etRuolo = 'Ruolo'`, `etComando = 'Comando'`, `etAltro = 'Altro'`; `employmentTypes` refactored per usarle; switch `stdMinsByType`/`mealMinsByType` aggiornati.

---

## 2026-06-07 — Audit approfondito wiki docs, Persistenza e Indice feature

- **docs** — `docs/index.html`: menu laterale portato a copertura completa (48 pagine Markdown), aggiunta sezione CCNL PCM, ADR-0000/0006/0007, widget inventory e indice processi; `ALL_PAGES` allineato per la ricerca; badge versione aggiornato a `v2026.06.07`; link Markdown interni normalizzati anche con `../`.
- **docs** — `docs/architettura/persistence.md`: riscritta come mappa completa Firestore/SharedPreferences/Drift, con subcollection reali (`timesheets`, `activeTimer`, `colleagues`, `groups`, `notifications`, `coffeeLog`), differenza native/web, schema Drift v3, seed sedi PCM, FCM token, regole e gap noti.
- **docs** — `docs/funzionalita/README.md`: dipendenze e stato feature riallineati a sedi PCM, CCNL in app, assenze P0/P1, totalizzatori manuali, notifiche e Drift web.
- **docs** — `docs/README.md`, `docs/architettura/README.md`, `docs/entita/README.md`, `docs/decisioni/README.md`, `docs/processi/README.md`: indici e overview aggiornati alle pagine/ADR/processi correnti.
- **docs** — `docs/entita/daily-timesheet.md`, `docs/ROADMAP.md`: documentato gap Drift schema v4 per cache offline dei campi `absence*`.
- **verify** — Link-check locale: 48 Markdown, 48 voci menu, 48 pagine indicizzate nella ricerca, 0 link rotti.

---

## 2026-06-07 — Docs riallineate a auth, sedi PCM, route planner e Chigio quotes

- **docs** — `README.md`, `docs/funzionalita/README.md`, `docs/panoramica/README.md`, `docs/panoramica/requirements.md`: aggiornati stato feature, auth Google+email, notifiche FCM, Drift, lettore CCNL, percorsi PCM e Chigio.
- **docs** — `docs/funzionalita/authentication.md`: documentati login email/password, registrazione, reset password, bottone Google branded con PNG e card login a larghezza massima.
- **docs** — `docs/funzionalita/dashboard.md`: aggiunti `FavoriteColleaguesCard`, `_HomeCountersRow`, `PcmRoutePlannerCard`, sorgente `portaleJson` e repository sedi PCM.
- **docs** — `docs/funzionalita/profile.md` + `docs/entita/onboarding-state.md`: documentati sede PCM strutturata, coordinate, genere Chigio, target SLI/SBO e lettore CCNL integrato.
- **docs** — `docs/funzionalita/chigio.md`, `docs/funzionalita/widget-inventory.md`, `docs/ROADMAP.md`: allineati a `ChigioQuotes`, frasi brevi per header, route planner Home, sedi PCM e gap residui aggiornati.

---

## 2026-06-07 — Confronto consumo permessi (P1, CCNL PCM 2019-2021)

- **feat** — Nuovo `lib/features/timesheet/domain/absence_consumption.dart`: `AbsencePlafonds` (plafond annui personali — `short_leave` 38h, `personal_family_hourly` 18h, `specialist_visit` 18h), `SicknessPeriod` (raggruppa giorni consecutivi di malattia in periodi), `AbsenceConsumption` + `computeAbsenceConsumption()` (somma `absenceMins`/conta documentazione per le entries `leave` con `absenceKind` valorizzato nell'anno corrente).
- **feat** — Nuovo `lib/features/dashboard/presentation/personal_absence_consumption_provider.dart`: `personalAbsenceConsumptionProvider` legge le entries dell'anno via `TimesheetRepository.fetchRange` e calcola il consumo personale.
- **feat** — `TotalizzatoriSection` (sezione PERMESSI): ogni chip `Permesso breve` / `Motivi personali` / `Visita specialist.` mostra ora una riga di confronto "App: Xh su Yh plafond (anno)" col consumo tracciato in app, con evidenza ambra se il plafond CCNL personale e' superato. Vedi tabella "Integrazione con totalizzatori" in [`docs/ccnl/permessi-assenze-congedi.md`](../docs/ccnl/permessi-assenze-congedi.md).
- **feat** — Nuova sotto-sezione "MALATTIA — periodi (anno)" in `TotalizzatoriSection`: elenca i periodi di malattia multi-giorno tracciati in app (raggruppamento giorni consecutivi), con conteggio periodi e giorni totali — copre il punto P1 "sickness come periodo multi-giorno, senza workflow amministrativo".
- **note** — Il portale resta sorgente di verita': l'app mostra solo un confronto informativo, nessun blocco né sincronizzazione bidirezionale.

---

## 2026-06-07 — Backfill storico cartellino (script una tantum)

- **data** — Eseguito script Python una tantum (OAuth via refresh token + Firestore REST API, poi rimosso dal repo) per importare in produzione le 112 giornate di `2026-cartellino-import.csv` nell'account `marcocipriani.pcm@gmail.com` (`users/{uid}/timesheets/{dateId}`).
- **import** — Create 103 giornate mancanti (gennaio–giugno 2026), replicando la logica di mappatura di `CsvImportService._parse` (`presenza`→`presence`, `smart_working`→`remote` con `standardDailyMins=456` + pausa 30 min, `ferie`/`permesso`→`holiday`/`leave` a zero ore).
- **fix-data** — Corrette 3 giornate in conflitto col cartellino ufficiale, sovrascritte coi dati corretti: `2026-04-27` (`remote`→`presence` 11:01–19:13), `2026-05-13` (`remote`→`presence` 09:40–18:21), `2026-06-01` (`remote`→`holiday`, Festività Soppresse).
- **verify** — Riletta l'intera sotto-collezione `timesheets`: tutte le 112 date del cartellino presenti, 0 mancanti, conflitti risolti. Le 2 giornate preesistenti non presenti nel CSV (`2026-03-14`, `2026-04-26`) lasciate intatte (fuori dallo scope autorizzato).

---

## 2026-06-07 — Tassonomia assenze (P0 fondazione, CCNL PCM 2019-2021)

- **feat** — `absence_kind.dart` (NEW): `AbsenceKind` con 20 causali (permessi orari/giornalieri, malattia, congedi, studio/formazione, istituti sensibili) + `AbsenceUnit` (`hourly`/`daily`/`period`), label IT e raggruppamento per categoria. Specifica in `docs/ccnl/permessi-assenze-congedi.md`.
- **feat** — `daily_timesheet.dart`: aggiunti campi opzionali `absenceKind`, `absenceUnit`, `absenceMins`, `absenceDays`, `periodStart`/`periodEnd`, `quotaYear`, `countsAsSicknessPeriod`, `sensitive`, `personalNote`, `hasDocumentation` (tutti nullable/default — nessuna entry storica invalidata).
- **feat** — `_EntrySheet` (`timesheet_screen.dart`): selettore causale raggruppato per categoria quando il tipo giornata è "Permesso/assenza", scelta unità (ore/giorni/periodo) con picker condizionali, switch "Assenza riservata" e "Documentazione presente", nota privata.
- **feat** — `csv_export_service.dart`/`csv_import_service.dart`: nuove colonne `assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a` su CSV semplice (re-importabile) e dettagliato; oscuramento automatico di causale/periodo/nota quando `sensitive == true` (colonna `riservata` nel dettagliato); validazione causale in import contro `AbsenceKind`.
- **docs** — `articoli-app.md`: aggiornato stato implementativo `DailyTimesheet`/`Timesheet export-import` con i nuovi campi e copertura CSV.
- **chore** — Backfill sulle entries storiche Firestore rimandato: da concordare come script separato prima di girarlo su prod (vedi `docs/ROADMAP.md`).

---

## 2026-06-07 — CCNL PCM 2019-2021: conversione, confronto e adeguamenti app

- **docs** — `docs/ccnl/ccnl-pcm-2019-2021.md` (NEW): conversione Markdown del PDF locale `2025_10_28_CCNL_C_PCM_2019-2021_Pubblicazione.pdf` con intestazione di provenienza.
- **docs** — `docs/ccnl/confronto-2016-2018-2019-2021.md` (NEW): mappa degli articoli sostituiti/disapplicati, istituti della base precedente ancora utili e confronto con implementazione attuale.
- **docs** — `docs/ccnl/articoli-app.md` + `docs/ccnl/permessi-assenze-congedi.md`: aggiornati riferimenti per permessi, visite, malattia, gravi patologie, congedi riservati, studio, formazione, welfare e diritto alla disconnessione come preferenza notifiche.
- **docs** — `docs/ccnl/README.md`, `docs/README.md`, `docs/ROADMAP.md`: aggiunti collegamenti, adeguamenti di dominio e backlog post CCNL 2019-2021.
- **feat** — `profile_screen.dart`: nuova sezione `CCNL PCM` nel Profilo con lettore full-screen dei contratti 2019-2021 e 2016-2018, switch nuovo/precedente e indice articoli navigabile.
- **chore** — `pubspec.yaml`: aggiunti come asset i Markdown completi `ccnl-pcm-2019-2021.md` e `ccnl-pcm-2016-2018.md`.

---

## 2026-06-07 — Hosting: nuovo dominio web `chigiotime.web.app`

- **infra** — Aggiunto hosting site secondario `chigiotime` al progetto `chigio-time-pcm` (i siti Hosting sono indipendenti dal project ID, che resta immutabile e continua a servire Auth/Firestore). Target hosting `main` ripuntato su `chigiotime` in `firebase.json`/`.firebaserc`. `deploy.sh` e tutti i link in-app/doc (`README.md`, `install.html`, `profile_screen.dart`, `android-deploy.md`, `ios-deploy.md`) aggiornati a `https://chigiotime.web.app`.
- **infra** — Default Hosting site `chigio-time-pcm.web.app` non eliminabile (`Cannot delete default Hosting Site`): trasformato in redirect 301 verso `https://chigiotime.web.app` tramite secondo entry hosting (target `legacy`, `public: web/legacy_redirect`, `redirects` in `firebase.json`). Risultato: una sola URL live funzionante, nessuna rottura per chi ha ancora il vecchio link in cache/bookmark.

---

## 2026-06-07 — Header Chigio: label chip + colori leggibili per tema

- **fix** — `glass_header.dart`: sezione sinistra header riscritta con gerarchia visiva a due livelli. Label Chigio (es. "In marcia!", "Pausa!") esposta come chip colorato bold sopra la frase. Colori tema-consapevoli: label `blue300/blue700`, frase `white α0.72` (dark) / `neutral800` (light). Rimosso `textSub` opaco precedente.
- **chore** — `pubspec.yaml` + `AppStrings.appVersion`: bump `2026.6.5+3` → `2026.6.7+4`.
- **fix** — `timer_provider.dart`: normal tick preserva `exitReminderPending` — notifica FCM non si ripete ogni tick.
- **fix** — `pdf_export_service.dart`: `DateTime.tryParse(e.dateId)` sostituisce `day.clamp(1,31)` — nessun overflow per mesi corti.
- **fix** — `stats_screen.dart`: streak itera `allEntries` ordinati per dateId, non solo `presenceEntries` — il reset su assenza/ferie funziona correttamente.

---

## 2026-06-07 — CCNL: dettaglio permessi/assenze come registro personale

- **docs** — `docs/ccnl/permessi-assenze-congedi.md` (NEW): specifica dettagliata dei permessi mancanti come gestione personale, non workflow autorizzativo PA. Include tassonomia `absenceKind`, campi suggeriti, priorita' P0-P3 e integrazione con totalizzatori.
- **docs** — `docs/ccnl/articoli-app.md`: riorientata l'analisi su residui, consumi e note personali; rimossi come obiettivo i workflow richiesta/autorizzazione/scadenze.
- **docs** — `docs/ROADMAP.md`: aggiunti riferimenti al registro assenze personali, permessi orari/visite, malattia/comporto, ferie residue e congedi.

---

## 2026-06-07 — Sprint: notifiche, colleghi, filtri, contatori, PDF ufficiale, GPS bg, stats, Drift WASM

### Notifica push FCM uscita prevista
- **feat** — `timer_provider.dart` `TimerState.exitNotifMins`: soglia configurable (default 15 min). `build()` legge `exitNotifMins` dal profilo Firestore e aggiorna con `ref.listen`. `_sendExitNotifToFirestore()`: scrive doc in `users/{uid}/notifications` quando la soglia scatta (attiva Cloud Function FCM esistente).
- **feat** — `profile_screen.dart` `_NotificationSheet`: nuova riga "Notifica push uscita prevista" con `ChoiceChip` picker (Off/5/10/15/30 min). Persistita su Firestore come `exitNotifMins`.

### Widget colleghi preferiti in Home
- **feat** — `favorite_colleagues_card.dart` (NEW): `FavoriteColleaguesCard` mostra fino a 4 colleghi preferiti come avatar circolari con iniziali. Tap → `_ColleagueActionSheet` con azioni "Manda caffè" e "Chiama".
- **feat** — `dashboard_screen.dart`: `FavoriteColleaguesCard` inserita nella `statsSection` sopra `_MaggiorPresenzaCard`.

### Contatori custom su Dashboard Home
- **feat** — `dashboard_screen.dart` `_HomeCountersRow`: strip orizzontale scorrevole di chip colorati con valore+unità+etichetta. Appare solo se `customCounters` non è vuota. Posizionata prima di `MonthlySummaryCard`.

### Filtri colleghi per Sede/Dipartimento/Stato
- **feat** — `social_screen.dart` `_ColleagueFilterBar` (NEW): chip animati scroll orizzontale per `sede`, `dipartimento` e `effectiveStatus`. Filtri cumulativi, tap su chip attivo per resettarlo. Valori unici estratti dinamicamente dalla lista colleghi. Reset automatico quando il valore scompare dalla lista.

### Cartellino mensile ufficiale PCM
- **feat** — `pdf_export_service.dart` `exportOfficialCartellino()`: layout PCM con header ente/dipendente/dipartimento/sede, tabella 11 colonne (G/Giorno/Tipo/Entrata/Uscita/Lav./P.Lun/P.Brv/OT-Def/BP/Nota), righe week-end evidenziate, blocco firme (Dipendente/Responsabile/Ufficio Personale), footer "Generato con Chigio Time · Pag. N/N".
- **feat** — `timesheet_screen.dart`: pulsante `assignment_rounded` nella `_GlassToolbar` → `_exportOfficialCartellino()`. Legge `dipartimento` e `sede` dal profilo.

### GPS auto clock-out background
- **feat** — `geofencing_service.dart` `startExitMonitor()`: stream `Geolocator.getPositionStream()` con `distanceFilter: 50 m` e `accuracy: medium` (battery-friendly). Chiama `onExit` una volta quando il device supera `radiusM` dalla sede, poi cancella la subscription. Restituisce `StreamSubscription` che il chiamante gestisce.
- **feat** — `geofencing_service.dart` `requestBackgroundPermission()`: richiede `LocationPermission.always` dopo che `whileInUse` è già stato concesso.
- **chore** — `AndroidManifest.xml`: `ACCESS_BACKGROUND_LOCATION` aggiunto.
- **chore** — `ios/Runner/Info.plist`: `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`, `UIBackgroundModes: location` aggiunti.

### Statistiche personali avanzate
- **feat** — `stats_screen.dart` `_AdvancedStatsCard`: 3 pill (🔥 Record streak presenze / ☕ Pausa media / 🎯 Puntualità ±15 min da 09:00) calcolati sugli ultimi 6 mesi.

### Drift WASM su web (logica)
- **feat** — `connection_web.dart`: usa `WasmDatabase.open()` con `sqlite3Uri` da `sqlite3_flutter_libs` e `drift_worker.dart.js`. Fallback graceful se asset mancanti.
- **feat** — `drift_worker.dart` (NEW): entry point per `dart compile js` → `web/drift_worker.dart.js`.
- **feat** — `app_database.dart`: rimosso guard `kIsWeb → null`; provider ora restituisce DB su tutte le piattaforme. Asset build richiesti: `sqlite3.wasm` e `drift_worker.dart.js` in `web/`.

### ROADMAP
- Sprint completato spostato in `## ✅ Completato`.
- Nuovo sprint: import portale HTTP, predefiniti altri enti, alert banca ore, tipi assenza avanzati, XLSX.
- Sezione `## 🚫 Non realizzabile` creata: Widget nativo, Traduzione EN, Richiesta ferie in-app, QR code timbratura.
- Rimossa: Dashboard dipartimento (Social) — out of scope.

---

## 2026-06-06 — CCNL PCM in Markdown e analisi articoli app

- **docs** — `docs/ccnl/ccnl-pcm-2016-2018.md`: conversione completa del PDF locale `CCNL_PCM 16-18.pdf` con Microsoft MarkItDown `0.1.6`, con intestazione di provenienza.
- **docs** — `docs/ccnl/articoli-app.md`: analisi degli articoli 17-48 con stato di copertura app, gap e backlog consigliato; evidenziato il riallineamento necessario della nomenclatura "Art.9".
- **docs** — `docs/ccnl/README.md` + `docs/README.md`: nuova sezione CCNL collegata dall'indice wiki.

---

## 2026-06-06 — BOE: Banca Ore come Esonero

- **feat** — `daily_timesheet.dart`: nuovi campi `bancaOreMins: int` (BOE usati) e `boeSlot: String?` (`pre_entry` / `pause` / `post_exit`). Nuova classe `BoeSlot` con costanti. Persistiti su Firestore + Drift.
- **feat** — `app_database.dart`: schema v2 — colonne `banca_ore_mins` e `boe_slot` aggiunte via `customStatement` (migration sicura SQLite). `build_runner` rigenerato.
- **feat** — `timer_provider.dart` `previewDeficit(DateTime)`: calcola il deficit atteso senza mutare stato. `endTurn()` esteso con params opzionali `bancaOreMins` e `boeSlot`; calcola `effectiveMins = net + BOE` per determinare overtime e buono pasto.
- **feat** — `dashboard_screen.dart` pulsante "Timbra Uscita": intercetta il deficit prima di `endTurn`. Se `deficit > 0` e banca ore disponibile, apre `_BoeSheet`.
- **feat** — `_BoeSheet` (bottom sheet): mostra deficit, breakdown deduzione AP→AC, copertura parziale con avviso, slot picker animato (pre-entrata / pausa / post-uscita). Pulsanti "Salta" e "Conferma BOE".
- **feat** — `BancaOreTile`: ora `ConsumerWidget` legge `monthlyTimesheetsProvider` — mostra delta live mese corrente (`+Xhm SBO accumulati`, `−Yhm BOE usati`). Chip riordinati AP → AC (ordine di deduzione). Calcolo fruibile aggiornato live.
- **docs** — ADR-0007: rationale BOE, modello dati, ordine deduzione AP→AC, scelte scartate. — [`docs/decisioni/0007-banca-ore-esonero.md`](./decisioni/0007-banca-ore-esonero.md)
- **docs** — `docs/funzionalita/widget-inventory.md` (NEW): inventario completo widget con punti forza/debolezza per categoria. Gap BOE documentato.

---

## 2026-06-06 — Export/Import CSV + Glass toolbar timesheet

### Nuove feature

- **feat** — `csv_export_service.dart` (NEW): `CsvExportService.exportBoth()` genera e condivide via share sheet **due file CSV** — semplice re-importabile (`data;tipo;entrata;uscita;nota`) + completo con tutti i campi calcolati (`pausa_std_min`, `pausa_art9_min`, `pausa_pranzo_min`, `netto_min`, `netto_hhmm`, `extra_min`, `extra_hhmm`, `sbo_min`, `sli_min`, `buono_pasto`, `nota`). `downloadTemplate()` condivide il template `.csv` da compilare.
- **feat** — `timesheet_repository.dart` `fetchRange(start, end)`: query Firestore con range su `dateId` ISO (ordinamento lessicografico = cronologico). Usato dall'export CSV per recuperare dati su periodo libero.
- **feat** — `timesheet_screen.dart` — barra strumenti completamente ridisegnata: `_GlassToolbar` glass pill Apple-style (ClipRRect + BackdropFilter 24σ) sostituisce il vecchio PopupMenuButton + `_ViewSelector`. Layout: pills vista (Giorno/Lista/Settimana/Mese) + divisore + 3 icone inline (PDF, CSV export, Import/Template).
- **feat** — `_exportCsv()`: apre `showDateRangePicker` Flutter Material per selezione periodo libero → chiama `fetchRange()` → `CsvExportService.exportBoth()`.
- **feat** — `_showImportSheet()`: bottom sheet `_ImportSheet` con due azioni — "Importa CSV" (file picker) e "Scarica Template" (share file `.csv`). Sostituisce le vecchie voci menu ⋮.
- **chore** — `pubspec.yaml`: aggiunto `share_plus: ^10.1.0` (risolto a 10.1.4). — [ADR-0006](./decisioni/0006-share-plus-file-export.md)
- **docs** — ADR-0006: `share_plus` per export file CSV — API v10: `Share.shareXFiles(List<XFile>, subject: String)`. Web: `XFile.fromData(Uint8List)`.

### Analisi allineamento schema DB ↔ `2026-cartellino-import.csv`

| Campo | Stato | Note |
|---|---|---|
| `dateId` | ✅ mappato | ISO `YYYY-MM-DD`, tutti i 113 record validi |
| `workType` | ✅ mappato | `smart_working→remote`, `ferie→holiday`, `presenza→presence`, `permesso→leave` |
| `startTime`/`endTime` | ✅ presenza | vuoti per smart_working/ferie/permesso (9:00 sintetico) |
| `netWorkedMins` | ⚠️ approssimato | pausa pranzo fissa 30 min; pausa reale varia (es. 65 min il 2026-01-08 → errore +35 min) |
| `note` | ✅ preservata | nessun `;` nel campo nota — split by `;` sicuro su questo dataset |
| `sboMins` | ⬜ 0 post-import | dati Art.9 presenti in nota (es. `2:09Indennità Art.9`) ma non parsati — assegnazione manuale |
| `sliMins` | ⬜ 0 post-import | dati Banca Ore in nota (es. `0:36Banca Ore`) ma non parsati |
| `leavePauseMins` | ⬜ 0 post-import | non derivabile da entrata/uscita senza parse della nota |
| `standardPauseMins` | ⬜ 0 post-import | idem |

Tutte le 113 righe importano senza errori. Limitazione nota: netto minuti approssimato (+30 min fisso anziché pausa reale). Classificazione SBO/SLI richiede assegnazione manuale post-import come da design.

---

## 2026-06-06 — Security audit + bug-fix sprint (Claude Code impeccable audit)

### Sicurezza
- **security** — `firestore.rules`: regola `create` su `notifications` rafforzata — il mittente deve essere `request.auth.uid == fromUid`, i campi sono limitati a allowlist (`hasOnly`), e `read` deve essere `false`. Previene injection di notifiche arbitrarie da utenti autenticati.

### Bug-fix critici
- **fix** — `timesheet_repository.dart`: `publishStatus` era invertito (`type != WorkType.presence`) — le giornate in presenza non aggiornavano mai `currentStatus`. Fix: pubblica sempre per oggi; le presenze usano `'completed'`, gli altri tipi usano il loro `workType` string.
- **fix** — `timer_provider.dart` `_saveToFirestore`: `.ignore()` sostituito con `.onError(debugPrint)` — le failure di sync Firestore su mid-shift vengono ora loggiate invece di essere silenziose.
- **fix** — `social_repository.dart` `watchColleagues`: N letture individuali `doc.get()` per snapshot sostituite con query `whereIn` a batch (ceil(N/30) letture) — riduzione drastica delle letture Firestore su team numerosi.
- **fix** — `timer_provider.dart` `build()`: `ref.listen` su `userProfileStreamProvider` ora passa `prev` — il primo emit (cold-start) aggiorna `standardWorkMins` anche se il turno è già attivo, correggendo la race condition avvio rapido.
- **fix** — `timer_provider.dart` Firestore sync listener: `standardWorkMins: stdMins` (valore catturato al build) → `state.standardWorkMins` — evita che il secondary device usi un valore stale dopo un aggiornamento profilo.
- **fix** — `auth_repository.dart` `signInWithGoogle()`: `initialize()` ora chiamato al massimo una volta (flag statico `_googleSignInInitialized`) — impedisce crash su re-login senza riavvio app.
- **fix** — `auth_repository.dart` `signInWithGoogle()`: `authentication.idToken` (nullable in google_sign_in v7) ora verificato non-null prima di passarlo a `GoogleAuthProvider.credential` — previene crash con `invalid-credential`.
- **fix** — `auth_repository.dart` `signOut()`: `disconnect()` wrappato in try/catch separato — `_auth.signOut()` viene sempre eseguito anche se `disconnect()` fallisce.
- **fix** — `timesheet_repository.dart`: rimossa la funzione locale `void unawaited(Future _) {}` che oscurava `dart:async`'s `unawaited`. Tutte le scritture Drift ora hanno `.onError(debugPrint)`.
- **fix** — `shared/models/timesheet_entry.dart`: eliminata — classe morta che collideva per nome con il tipo generato da Drift `TimesheetEntry`.

### Bug-fix medi
- **fix** — `profile_repository.dart` `updateCurrentStatus`: `DateTime.now()` → `DateTime.now().toUtc()` per `statusDate` — evita date errate su dispositivi con fuso orario/orologio sbagliato.
- **fix** — `profile_repository.dart`: tutti i metodi di scrittura che facevano `return` silenzioso su `user == null` ora lanciano `StateError('User not authenticated')` — le chiamate post-logout non appaiono più come successo.
- **fix** — `profile_repository.dart` `hasProfileStream` + `userProfileStream`: reattivi ai cambi auth tramite `ref.watch(authStateChangesProvider)` (Riverpod rebuild = switchMap semantico) — non più fermi sull'uid del precedente utente dopo sign-out/sign-in.
- **fix** — `profile_repository.dart` `hasProfileStream`: back-fill `hasCompletedOnboarding` ora eseguito al massimo una volta per sessione (flag locale `backfilled`) — niente scritture ripetute per utenti offline.
- **fix** — `totalizzatori_provider.dart`: restituisce `null` invece di fixture zero-filled quando `portaleJson` mancante — gli utenti nuovi non vedono badge verdi su dati fasulli. Factory wrappata in try/catch.
- **fix** — `custom_counters_provider.dart`: `CustomCounter.fromJson` wrappato in try/catch per elemento — un valore malformato nel profilo non azzera più l'intera sezione dashboard.
- **fix** — `onboarding_provider.dart` `addDailyMinutes`/`addMealMinutes`: soglia minima alzata da `0` a `60` min — impedisce `standardDailyMins = 0` che causerebbe divisione per zero e falsi straordinari.
- **fix** — `csv_import_service.dart`: `sboMins` non viene più auto-assegnato dall'importer (`sboMins: 0`) — la categoria straordinario spetta all'utente.
- **fix** — `csv_import_service.dart` `_validDateId`: usa `DateTime.tryParse` invece di check manuali — date come `2026-02-30` vengono ora rifiutate.
- **fix** — `pdf_export_service.dart`: `int.tryParse(...) ?? 0` → `?? 1).clamp(1, 31)` — un `dateId` malformato non produce più `DateTime(y, m, 0)` (ultimo giorno del mese precedente).
- **fix** — `geofencing_service.dart`: `catch (_)` in `checkInOffice` ora distingue `TimeoutException` (→ `GeofenceResult.timeout`) da errori hardware (→ `GeofenceResult.error`). Aggiunto `GeofenceResult.timeout` all'enum.
- **fix** — `profile_screen.dart` `_editEmploymentType`: rimosso `StatefulBuilder` esterno morto (il `setState` non era mai usato). Singolo `StatefulBuilder` con `setLocalState`.
- **fix** — `profile_screen.dart` `_editEmploymentType`: i default contrattuali (`standardDailyMins`, `mealVoucherThresholdMins`, `monthlyArt9Hours`) vengono sovrascritti solo se `selected != current` — un salvataggio no-op non distrugge più le personalizzazioni utente.

### Miglioramenti architetturali
- **arch** — `app_database.dart`: aggiunto override `MigrationStrategy` con hook `onUpgrade` — impedisce corruzione silenziosa del DB locale a versioni future dello schema Drift.
- **arch** — `global_providers.dart` `ThemeModeNotifier`: `build()` installa un `Timer.periodic(1 min)` quando `_savedName == 'auto'` — il tema automatico ora commuta realmente a 06:00 e 18:00 senza richiedere un riavvio.
- **arch** — `totalizzatori.dart`: costanti `bancaOreMinMins`, `bancaOreMaxMins`, `permessoBreveGreenThresholdMins` estratte da magic numbers inline.

### Polish
- **polish** — `profile_repository.dart`: rimosso blocco commento duplicato (8 righe ripetute), eliminato commento pianificativo `// Use a Batch or a simple set with merge`, rimosso `// Extra safety flag`.
- **polish** — `profile_repository.dart` `saveOnboardingData`: `throw Exception(...)` → `throw StateError(...)` — coerente con tutti gli altri metodi di scrittura.
- **polish** — `daily_timesheet.dart` `toMap()` e `timesheet_repository.dart` `saveNote`: `DateTime.now().toIso8601String()` → `DateTime.now().toUtc().toIso8601String()` — timestamp UTC coerenti con `updateCurrentStatus`.
- **polish** — `onboarding_provider.dart`: rimossi commenti `// <-- ...` (Preimpostato, Di default 0, Default Ruolo, Default Comando) — valori auto-esplicativi.
- **polish** — `csv_import_service.dart`: rimosso commento what-doc su `pickAndParse` — nome funzione già descrittivo.

## 2026-06-05 — Sprint 3: UX polish — Chigio, banca ore, maggior presenza mensile, pill switcher

- **feat** — `glass_header.dart`: `GlassHeader` → `ConsumerStatefulWidget`. Frase Chigio **italic**, contrasto alzato (alpha 0.7). Tap su area sinistra (avatar + frase) incrementa seed → cambia frase immediatamente.
- **feat** — `timesheet_screen.dart` `_ViewSelector`: pill switcher ora **full-width** su mobile (ogni voce `Expanded`). Altezza 34 px. Padding end corretto.
- **feat** — `timesheet_screen.dart`: icona festività cambiata da 🏛️ → 🌴 in vista Giorno e lista giornaliera.
- **feat** — `totalizzatori_section.dart` `BancaOreTile`: convertita a `ConsumerWidget`. Layout ridisegnato: icona + header + **tasto edit** (matita), **totale fruibile in grande** (32 px), chips AC / AP separate. Tap edit → bottom sheet con due campi HH:MM per AC e AP; salva su `portaleJson` e ricalcola il totale.
- **feat** — `dashboard_screen.dart` `_MaggiorPresenzaCard`: ora `ConsumerStatefulWidget` **auto-contenuto** (legge profilo e timesheet internamente). **Month switcher** inline (< Mag 2026 >) per sfogliare i mesi. Barra segmentata aggiornata a `_SegmentedBarThresholds` con **linee verticali** ai confini Art.9 / SLI / SBO. Etichette proporzionali ai segmenti. Chip breakdown invariati.

## 2026-06-05 — Sprint 2: maggior presenza, vista giorno, festivita', orario settimanale, social compact

- **version** — `pubspec.yaml` → `2026.6.5+3`; `AppStrings.appVersion` → `v2026.06.05`.
- **feat** — `dashboard_screen.dart`: rimosso `_buildHighlightWidget` (multi-modalità). Nuovo widget `_MaggiorPresenzaCard` sempre visibile: barra progressiva segmentata (blu=Art.9, verde=SLI, arancio=SBO), chip breakdown con valori/cap, badge OPE (rosso) se si supera il totale dei cap. Logica allocazione sequenziale: Art.9 → SLI → SBO → OPE.
- **feat** — `profile_screen.dart`: campi **SLI mensile** e **SBO mensile** ora editabili nel profilo (erano già letti da Firestore ma non modificabili).
- **feat** — `social_screen.dart`: su mobile, `_GroupsMobileTile` e `_CoffeeToggleCard` sostituiti da `_SocialQuickBar` — barra compatta 44px con gruppi a sinistra e toggle caffè a destra. Desktop invariato.
- **feat** — `timesheet_screen.dart` `_ViewMode.day`: vista Giorno ora **default**; navigatore con tasto "Oggi", nome festività 🏛️ e orario pianificato del giorno; `_DayNoteSection` supporta `Key` per reset corretto al cambio giorno.
- **feat** — `italian_holidays.dart` (NEW): `ItalianHolidays.forYear()` calcola festività nazionali italiane (fisse + Pasqua/Lunedì Angelo via algoritmo Gregoriano) + Natale di Roma (21/04). `label()` restituisce il nome della festività. Usato nel timesheet: liste giornaliere mostrano nome festività, warning ⚠️ non appare su giorni festivi.
- **feat** — `profile_screen.dart`: nuova sezione **Orario settimanale** — permette di impostare ore diverse per ciascun giorno (Lun-Ven) con slider 0-600 min. Salvato in Firestore come `weeklyScheduleMins: {"1": 456, ...}`. La vista Giorno del timesheet mostra "Standard: Xh Ym" quando l'orario personalizzato differisce dall'orario uniforme.
- **feat** — `onboarding_screen.dart` + `onboarding_provider.dart`: passo **Genere** aggiunto come step 2 (dopo il nome). Valori M/F/A (Altrə). `saveOnboardingData` salva `gender`. `_editGender` in profile screen aggiornato con opzione "Altrə". `ChigioPhraseEngine._applyGender` supporta 'A' → schwa `ə`.
- **fix** — `onboarding_screen.dart`: tutti i case numerici spostati di +1 dopo inserimento step genere; `_totalSteps = 12`; validazione step 2→3, 3→4.

## 2026-06-05 — UX sprint: Chigio genere/dipartimento/stipendio, header monofrase, vista giorno timesheet, note su giorni passati, fix tastiera

- **fix** — `dashboard_screen.dart` `_NoteSection`: aggiunto `scrollPadding: EdgeInsets.only(bottom: 220)` al `TextField` note attività → risolve il bug in cui la tastiera copriva il campo.
- **feat** — `chigio_phrase_engine.dart`: riscrittura completa. Nuovi parametri `gender` ('M'/'F'/'N'), `department` (String), `isPayDay` (bool — 23 del mese). Placeholder `{o|a}` per accordo grammaticale di genere. Frasi più goffe e divertenti. Pool speciale per il 23 (stipendio). ~70 frasi totali nelle 12 pool.
- **refactor** — `glass_header.dart`: rimosso il titolo di saluto separato (`Buongiorno, Marco 👋`). L'header ora mostra **una sola frase dinamica** Chigio (`maxLines: 2`, nessun troncamento). Legge `gender` e `dipartimento` dal profilo Firestore; calcola `isPayDay` da `DateTime.now().day == 23`.
- **feat** — `profile_screen.dart`: aggiunto picker **Genere (per Chigio)** (♂ Maschile / ♀ Femminile / ⚥ Neutro) → salvato in Firestore come `gender`. Usato da `ChigioPhraseEngine` per accordo grammaticale.
- **feat** — `timesheet_screen.dart`: aggiunta **vista Giorno** (`_ViewMode.day`) con navigazione giorno per giorno, `_DayDetailCard` + sezione note editabile `_DayNoteSection`. Permette aggiungere/modificare note su qualsiasi giorno passato.
- **refactor** — `timesheet_screen.dart` `_ViewSelector`: selettore ripulito — icona + etichetta solo per vista attiva, icona sola per le inattive. Altezza aumentata a 32 px. Tooltip su ogni voce. 4 modalità: Giorno / Lista / Settimana / Mese.

## 2026-05-30 — UX sprint: concetti, Chigio header, gruppi mobile, profilo desktop, contatori custom

- **refactor** — `glass_header.dart`: Chigio avatar **non più cliccabile** (decorativo, solo pulse); versione pill rimossa dall'header (rimane solo in ProfileScreen). Sottotitolo dinamico: frase contestuale `ChigioPhraseEngine` in italic sotto il saluto.
- **refactor** — `GlassHeader`: rimosso parametro `subtitle` (non più necessario); tutte le schermate aggiornate.
- **feat** — `social_screen.dart`: gruppi accessibili su **mobile** via tile + bottom sheet `_GroupsMobileSheet` (lista gruppi, crea/elimina/invia caffè). Su desktop rimane il pannello laterale.
- **feat** — `profile_screen.dart`: layout **desktop constraint** `maxWidth: 720` centrato. Emoji Chigio 🐦 → 🐢.
- **feat** — `custom_counter.dart` (NEW): modello `CustomCounter` (id, label, value, unit, colorIndex, sortOrder). `kPcmDefaultCounters`: 6 contatori predefiniti PCM.
- **feat** — `custom_counters_provider.dart` (NEW): `customCountersProvider` (Riverpod @riverpod) — legge `users/{uid}.customCounters[]` dal profilo Firestore.
- **feat** — `profile_repository.dart`: `saveCustomCounters(List<Map>)` — scrive `customCounters` nel documento utente.
- **feat** — `totalizzatori_section.dart`: `CustomCountersSection` (ConsumerWidget) — sezione chip contatori custom con add/edit/delete + "Importa predefiniti PCM". `_CounterEditSheet`: form nome + valore + unità + color picker (6 colori).
- **feat** — `dashboard_screen.dart`: `CustomCountersSection` aggiunta sotto `TotalizzatoriSection`.
- **feat** — `app_strings.dart`: `customCounters`, `addCounter`, `counterLabel`, `counterValue`, `counterUnit`, `importDefaults`, `importDefaultsDone`, `noCustomCounters`, `noGroups`, `deleteCounterConfirm`.
- **docs** — `docs/architettura/`: aggiunte pagine concetto per Home, Timesheet, Social.
- **docs** — ROADMAP aggiornata.

## 2026-05-30 — Chigio mascotte: header avatar, frasi contestuali, doc

- **feat** — `chigio_phrase_engine.dart` (NEW): `ChigioPhraseEngine.resolve()` genera frasi personalizzate con nome utente in base a pagina, stato turno e ora del giorno. 12 pool di frasi (mattina/pomeriggio/sera × stato turno + timesheet/social/profilo/stats). Rotazione ogni 5 min.
- **feat** — `glass_header.dart`: Chigio avatar (38px, pulse 0.96↔1.04 loop) aggiunto in alto a sinistra di ogni header. Al tap → `_ChigioPhraseDialog` con avatar 140px contestuale + frase speech bubble + bottone "Vai da Chigio →".
- **feat** — `GlassHeader`: nuovo parametro `chigioPage: ChigioPage` (default `dashboard`). Cablato in `DashboardScreen`, `TimesheetScreen`, `SocialScreen`.
- **fix** — `AppStrings.chigioSubtitle`: "La tartaruga di Chigio Time" (era "La mascotte"). Chigio è una **tartaruga** 🐢.
- **fix** — `AppStrings.chigioLabels[6]`: 🐦 → 🐢.
- **feat** — `AppStrings`: aggiunti `chigioVisit` ("Vai da Chigio →").
- **docs** — `docs/funzionalita/chigio.md`: pagina dedicata completa con tono di voce, API engine, avatar esistenti, **10 proposte nuovi avatar tartaruga** (corsa, spiaggia, computer, champagne, pensiero, lente, ombrello, sole, trofeo, banca ore).

## 2026-05-30 — sprint features: stats, GPS, exit reminder

- **feat** — `stats_screen.dart` (NEW): schermata statistiche avanzate (`/stats`). 4 sezioni: contatori mese (MonthlySummaryCard), widget in evidenza, 3 bar chart (ore giornaliere / OT per giorno settimana / permessi-ferie), tabella orario medio entrata. Usa `fl_chart`, dati da `monthlyTimesheetsProvider` × 6 mesi.
- **feat** — `profile_screen.dart`: link "Statistiche avanzate →" in fondo all'avatar card; navigazione a `/stats`.
- **feat** — `app_router.dart`: aggiunta rotta `/stats` → `StatsScreen`.
- **feat** — `timer_provider.dart`: `TimerState.exitReminderPending` (bool, one-shot) — il ticker lo imposta a `true` quando `remainingTime ≤ 15 min` e lo resetta automaticamente a ogni `copyWith`.
- **feat** — `dashboard_screen.dart`: `ref.listen` su `exitReminderPending` → SnackBar arancione floating "⏰ Mancano N min all'uscita prevista."
- **feat** — `geofencing_service.dart` (NEW): `GeofencingService` — `checkInOffice()`, `getCurrentPosition()`, `requestPermission()`, formula Haversine. Nessuna dipendenza esterna oltre `geolocator`.
- **feat** — `pubspec.yaml`: aggiunto `geolocator: ^13.0.2`.
- **feat** — `AndroidManifest.xml`: `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION`.
- **feat** — `ios/Runner/Info.plist`: `NSLocationWhenInUseUsageDescription`.
- **feat** — `profile_screen.dart`: sezione `_GpsSettingsCard` con toggle auto-timbratura + `_GpsSettingsSheet` (acquisizione posizione attuale, slider raggio 50–500m). Salva `officeLat`, `officeLng`, `officeRadiusM`, `gpsAutoClockIn` su Firestore.
- **feat** — `dashboard_screen.dart`: `_GpsPromptCard` — appare quando turno non iniziato + GPS auto abilitato + 06:00–11:00 → rileva posizione → dialog conferma → `startTurn`.
- **docs** — ADR-0004: GPS geofencing `geolocator` foreground (accepted).
- **docs** — ADR-0005: Drift WASM su web (proposed, rimandato — `drift_dev web-wasm` non disponibile in 2.16).
- **feat** — `AppStrings`: aggiunte costanti stats (`advancedStats`, `statsAvgDaily`, `statsOtByWeekday`, …) e GPS (`gpsAutoClockIn`, `gpsOfficeLocation`, `gpsLocationSaved`, …).

## 2026-05-30 — bugfix sprint 2

- **fix** — `timer_provider.dart`: `expectedExitTime` non contava la pausa in corso (`currentPauseStart`) in `minsToAdd`, mostrando l'uscita prevista troppo presto durante qualsiasi pausa. Fix: aggiunto `ongoingPauseMins` a `minsToAdd` e alla verifica soglia 9h.
- **fix** — `app_router.dart`: errore Firestore durante check `hasProfile` impostava `hasProfile=false` e reindirizzava all'onboarding. Fix: `return null` dal catch (nessun reindirizzamento), il check viene rieseguito al prossimo cambio auth.
- **fix** — `profile_repository.dart`: `updatePhoneNumber` non aggiornava `updatedAt`. Fix: aggiunto `FieldValue.serverTimestamp()`.
- **fix** — `profile_screen.dart`: `_editStandardHoursPresets` usava doppio `StatefulBuilder` con `selected` nella closure esterna (reset su rebuild); `setLocal` dead code. Fix: singolo `StatefulBuilder`, `selected` nel suo stato.
- **fix** — `profile_screen.dart`: `Padding(right:8)` su tutti i chip preset incluso l'ultimo. Fix: `SizedBox(width:8)` solo tra chip.
- **fix** — `dashboard_screen.dart`: `_buildHighlightWidget` tipava `totData: dynamic` e `textSub` inutilizzato. Fix: `Totalizzatori?`, parametro rimosso.
- **fix** — `profile_screen.dart` / `dashboard_screen.dart`: `_memberSince` e `_italianDate` ridichiaravano array mesi/giorni. Fix: usano `AppStrings.monthsShort`/`.months`/`.weekdaysFull`.
- **fix** — `firestore.rules`: sub-collections `groups`, `coffeeLog`, `activeTimer` mancanti → `permission-denied` su web. Fix: regole aggiunte, deployate.
- **feat** — `firestore.indexes.json`: aggiunto indice composito `administration + hasCompletedOnboarding` per query `getUsersInAdministration`. Deployato.
- **chore** — `firebase.json`: aggiunta sezione `firestore` per abilitare deploy rules/indexes via CLI.
- **docs** — Roadmap: rimossa traduzione EN da next sprint (solo italiano per PCM), aggiunto backlog con 11 feature proposals.

## 2026-05-30 (UX multi-sprint: strings audit, profilo, colleghi, timesheet, dashboard)

- **feat** — `AppStrings`: `viewWeek`→`'Settimana'`; aggiunti `downloadCsvTemplate`, `csvTemplateContent`, `orarioPreset*`, `highlightWidget*`, `callColleague`, `noOtherUsers`, `coffeeToastSent`, `inOfficeCount`, `presidenzaPCM`.
- **feat** — `timesheet_screen.dart`: voce menu "Scarica template CSV" → bottom sheet con `SelectableText` + pulsante copia clipboard. Pill `_ViewSelector` compatte (non-expanded, padding ridotto, font 9).
- **feat** — `profile_screen.dart`: riordino campi → Dipartimento → Sede → Piano → Stanza → Interno → Telefono → Inquadramento. Lista Ente: solo PCM attiva, altri opacizzati con "Prossimamente". "Orario standard" → chips preset (7:36/6:40 per Ruolo, 7:12/6:12 per Comando) al posto dello slider. Aggiunto row settings "Widget in evidenza" con picker (nessuno / banca ore / straordinari / buoni pasto). Stringhe hardcoded sostituiti con `AppStrings.*`.
- **feat** — `social_screen.dart`: pulsante telefono su `_ColleagueCard` se `interno` o `phoneNumber` impostati; chiama via `tel:` URI con `url_launcher`. Stringhe hardcoded → `AppStrings`.
- **feat** — `dashboard_screen.dart`: `_OrariTableSheet` — modalità riordinate ascending (6:12, 6:40, 7:36), etichette semplificate. Aggiunto `_buildHighlightWidget` che mostra card colorata (banca ore / straordinari / buoni) basata su `profileData['highlightWidget']`.

## 2026-05-29 (v2026.05.29 — Roadmap completa: push, offline, auth, stats, PDF/CSV, i18n)

### Next sprint completato
- **fix** — `timesheet_screen.dart`: `mealVoucherThresholdMins` letto da profilo invece di 380 hardcoded; propagato a `_buildDayList`, `_buildListView`, `_buildEntryInfo`, `_DayDetailCard`.
- **feat** — FCM push notifiche: `FcmService` (token → Firestore, permission, refresh); background handler; foreground SnackBar + tap → `/notifications`. `app.dart` → `ConsumerStatefulWidget` con `AppLifecycleListener`. `web/firebase-messaging-sw.js` service worker. `functions/index.js` Cloud Function trigger su `notifications/{id}`.
- **feat** — Drift offline cache: `AppDatabase` con `TimesheetEntries`; `TimesheetRepository` write-through su ogni save; `StreamTransformer` fallback su Drift in caso di errore Firestore.

### Backlog completato
- **feat** — Auth email/password: `signInWithEmail`, `registerWithEmail`, `sendPasswordReset` in `AuthRepository`; `LoginScreen` con form toggle login/registrazione, campo conferma password, link reset.
- **feat** — Dark mode automatica: `ThemeModeNotifier` → modalità `'auto'` (dark 18:00–06:00); pulsante ⏰ in `_ThemePicker`; `AppLifecycleListener` refresh al resume.
- **feat** — Multi-ente: `AppStrings.administrations` espanso a 25 enti PA; `employmentTypes` con preset `stdMinsByType` / `mealMinsByType`.
- **feat** — Statistiche avanzate: `_OtTrendCard` (bar chart OT 6 mesi, `fl_chart`) in profilo.
- **feat** — Onboarding multi-step: step 9 Dipartimento + step 10 SLI/SBO target; salvati su Firestore.
- **feat** — Gruppi stato aggregato: `_GroupTile` mostra "X/N 🏢" in verde; cross-reference `colleaguesStreamProvider`.
- **feat** — Export PDF: `PdfExportService` — tabella A4 + summary chip; menu ⋮ in timesheet. ADR-0003.
- **feat** — Import CSV: `CsvImportService` — file picker + parser semicolon CSV; menu ⋮ in timesheet. ADR-0003.
- **feat** — Internazionalizzazione: `LocaleNotifier` + `localeProvider`; toggle 🇮🇹/🇬🇧 in profilo; `MaterialApp` wired `flutter_localizations`; `main.dart` carica locale da SharedPreferences.
- **chore** — `pubspec.yaml`: `pdf ^3.11`, `printing ^5.13`, `file_picker ^8.1`, `flutter_localizations`, `path_provider ^2.1`, `path ^1.9`. ADR-0003.
- **chore** — Versione → `2026.5.29+1`.

---

> Questo file è un **log cronologico** delle modifiche a codice + wiki
> effettuate con assistenza LLM. **Una riga per cambiamento significativo.**
> Formato: `YYYY-MM-DD — <ambito> — <sintesi> — <link a ADR / pagina wiki>`.

## 2026-05-28 (v2026.05.28 — CalVer, auto-abandon, strings, timesheet list fix)

### Versioning
- **chore** — `pubspec.yaml`: versione migrata a CalVer `2026.5.28+1`.
- **chore** — `AppStrings.appVersion` → `v2026.05.28`.
- **docs** — `README.md`: aggiornato con nuove funzionalità, versioning CalVer, sezione deploy.

### Auto-abandon (uscita non timbrata dopo le 21:00)
- **feat** — `WorkState.abandoned` aggiunto all'enum.
- **feat** — `timer_provider.dart`: ticker controlla `now.hour >= 21 && state.isShiftActive` ogni secondo; chiama `_autoAbandon()`.
- **feat** — `_autoAbandon()`: pubblica `currentStatus = notStarted` su Firestore (il collega sparisce da "In ufficio"), cancella `activeTimer/state`, persiste stato `abandoned` in SharedPreferences (warning sopravvive al riavvio).
- **feat** — `endTurnFromAbandoned(DateTime)`: timbra retroattivamente dallo stato abandoned (delega a `endTurn`).
- **feat** — `dismissAbandoned()`: ignora la giornata senza salvare; reset a `notStarted`.
- **feat** — `AppStrings`: `abandonedBadge`, `abandonedTitle`, `abandonedBody`, `registerExit`, `dismissDay`.
- **feat** — `dashboard_screen.dart`: flag `isAbandoned`; ring center orange con ⚠️ e ore al cut-off 21:00; badge `_AbandonedBadge`; card `_AbandonedCta` con "Registra uscita" + "Ignora giornata".

---

## 2026-05-27 (v1.0.11 — Strings, timesheet list fix)

### Strings
- **feat** — `lib/core/constants/app_strings.dart`: aggiunte ~30 nuove costanti (greetings, timesheet detail stats, ETA/time-ago, notif response labels + templates, totalizzatori helpers, `chigioCounter`, `bankHoursDetail`, `phoneNumber`, ecc.).
- **refactor** — `lib/shared/widgets/glass_header.dart`: `_timeGreeting()` usa `AppStrings.greetingMorning/Afternoon/Evening`.
- **refactor** — `lib/features/chigio/presentation/chigio_screen.dart`: `tapToChange` + `chigioCounter` cablati.
- **refactor** — `lib/features/social/presentation/notifications_screen.dart`: tutte le stringhe UI → AppStrings (notif titles, response labels, time-ago, ETA picker, cancel).
- **refactor** — `lib/features/dashboard/widgets/totalizzatori_section.dart`: AVVISI, BANCA ORE, TOTALIZZATORI PORTALE, disponibile, Salva → AppStrings.
- **refactor** — `lib/features/dashboard/presentation/dashboard_screen.dart`: tutti i badge di stato, ore lavorate, STRAORDINARIO, note, Salva → AppStrings.
- **refactor** — `lib/features/social/presentation/social_screen.dart`: Annulla, Crea, Elimina, Rimuovi, Nome gruppo, Rimuovi collega → AppStrings.
- **refactor** — `lib/features/profile/presentation/profile_screen.dart`: Profilo, Chiudi, Dati portale PA, Telefono, Voci visibili, Numero di telefono, Salva, OK → AppStrings.
- **refactor** — `lib/shared/widgets/monthly_summary_card.dart`: Personalizza → AppStrings.
- **refactor** — `lib/features/timesheet/presentation/timesheet_screen.dart`: Entrata, Lavorato, Uscita, Giorno, tipo-giornata labels, Salva giornata; array `_italianMonths/_months/_dayLabels` sostituiti con `AppStrings.months/monthsShort/weekdayLetters`.

### Timesheet — List view
- **feat** — `lib/features/timesheet/presentation/timesheet_screen.dart`: `summaryCard` spostato sopra la lista (pinned), la lista scorre indipendentemente; auto-scroll a "oggi" al primo render del mese corrente (`_listScrollController`, `_listScrollKey`).

---

## 2026-05-27 (v1.0.11 — Polish, iOS infra, download banner profilo)

### App
- **fix** — `lib/features/authentication/data/auth_repository.dart`: rimosso import `flutter_riverpod` inutilizzato; `print` → `debugPrint`.
- **fix** — `lib/features/dashboard/widgets/smart_exit_widget.dart`: `withOpacity` → `withValues` (deprecato).
- **feat** — `lib/features/profile/presentation/profile_screen.dart`: banner download in fondo (Android APK + iOS coming soon); usa `url_launcher`.
- **feat** — `pubspec.yaml`: aggiunto `url_launcher ^6.3.1`; versione → `1.0.11+11`.
- **feat** — `lib/core/constants/app_strings.dart`: `appVersion` → `v1.0.11`.

### iOS
- **feat** — `ios/ExportOptions.plist`: template per export IPA (Ad Hoc; da aggiornare con Team ID).
- **feat** — `deploy.sh`: supporto `--ios` flag (disabilitato di default); upload IPA su GitHub Release.
- **docs** — `docs/processi/ios-deploy.md`: guida completa firma, build IPA, distribuzione Ad Hoc e futuro App Store.

### Web / Install page
- **feat** — `web/android/install.html`: tab Android/iOS; pannello iOS "prossimamente" con link web app.
- **feat** — Refactor install page: titolo generico, tab platform switcher JS.

### Cleanup
- **chore** — Rimosso `lib/features/settings/` (cartella vuota).
- **chore** — Rimosso `lib/features/timesheet/presentation/social_screen.dart` (placeholder comment).

---

## 2026-05-27 (v1.0.10 — Build Android, distribuzione APK)

### Android
- **feat** — `android/app/build.gradle.kts`: configurazione release signing con `key.properties` + `keystore/release.jks` (gitignored). Rimosso TODO debug-signing.
- **feat** — `pubspec.yaml`: versione aggiornata a `1.0.10+10`.
- **feat** — `android/app/src/main/AndroidManifest.xml`: `android:label` → "Chigio Time" (era "chigio_time").
- **feat** — `web/android/install.html`: pagina di installazione guidata (sideloading) con istruzioni step-by-step in italiano.
- **feat** — `deploy.sh`: script unificato web + APK + AAB + GitHub Release.
- **feat** — GitHub Release `v1.0.10` creata con APK allegato; repository reso pubblico.
- **docs** — `docs/processi/android-deploy.md`: guida completa build, firma, distribuzione sideload e futuro Play Store.

### Docs
- `firebase.json`: rimossa regola headers `/android/**` (APK non più su Firebase Hosting — Spark plan vieta eseguibili).

---

## 2026-05-26 (v0.10 — Proposte caffè (5), piano/stanza profilo e colleghi)

### Social — 5 proposte caffè
- **feat** — `AppNotification`: nuovi campi `scheduledAt: String?` e `etaMinutes: int?`.
- **feat** — `ColleagueProfile`: nuovo campo `coffeeAvailable: bool?`.
- **feat** — `SocialRepository.setCoffeeAvailable(bool)`: scrive `coffeeAvailable` su Firestore.
- **feat** — `SocialRepository.sendCoffeeInvite`: param opzionale `scheduledAt`; scrive anche su `users/{uid}/coffeeLog/{id}` per tracciare gli inviati.
- **feat** — `SocialRepository.respondToInvite`: param opzionale `etaMinutes`; incluso nel back-notify.
- **feat** — `SocialRepository.sendGroupCoffee(groupId)`: invia invito caffè a tutti i membri del gruppo.
- **feat** — `SocialRepository.watchCoffeeLog()`: stream del coffeeLog per statistiche.
- **feat** — `coffeeLogStreamProvider` + `coffeeStatsProvider` (`{sent, received, accepted}` per mese corrente).
- **feat** — `_CoffeeToggleCard` in social screen: toggle "Disponibile per caffè" + statistiche mese (inviati/ricevuti/accettati).
- **feat** — Badge `coffeeAvailable` visibile nella card collega (verde ☕ se disponibile).
- **feat** — `_showCoffeeOptions`: tap ☕ apre `_CoffeeScheduleSheet` con scelta "Adesso" o "Pianifica" (time picker).
- **feat** — `_GroupTile`: pulsante ☕ su gruppi con membri; `_sendGroupCoffee` invia a tutti e mostra snackbar.
- **feat** — `_NotifCard`: 4° risposta "🚶 Sto arrivando" apre dialog ETA (5/10/15 min); `responseType: 'arriving'` + `etaMinutes` nel back-notify.
- **feat** — Mappe `_responseEmoji/Label/Color` aggiornate per `'arriving'`. `_inviteTitle` gestisce ETA e `scheduledAt`. `_ResponseChip` supporta suffisso.

### Profilo + Social — Piano e Stanza
- **feat** — `ColleagueProfile`: nuovi campi `piano: String?` e `stanza: String?`.
- **feat** — `SocialRepository.watchColleagues`: legge `piano` e `stanza` dal profilo Firestore del collega.
- **feat** — Profilo: due nuove righe editabili "Piano" e "Stanza / Ufficio" (dopo Dipartimento, prima di Inquadramento).
- **feat** — `_ColleagueCard`: mostra riga compatta "📍 Piano X · St. Y" quando uno o entrambi i campi sono impostati.

### Docs
- **docs** — `docs/funzionalita/social.md`: schema Firestore aggiornato (piano, stanza, coffeeAvailable, coffeeLog, scheduledAt, etaMinutes); flusso principale aggiornato.

---

## 2026-05-26 (v0.9 — Cross-device sync, quick-edit inline, per-chip portale, dipartimento colleghi)

### Timer — Cross-device sync
- **feat** — `timer_provider.dart`: stato turno scritto su `users/{uid}/activeTimer/state` (Firestore) a ogni transizione (`startTurn`, `startPause`, `endPause`). Al riavvio: se `SharedPreferences` vuoto per oggi, legge da Firestore come fallback. Al completamento turno: cancella sia locale che Firestore.

### Dashboard + Timesheet — Quick-edit inline
- **fix** — `MonthlySummaryCard.onEditTap` in dashboard/timesheet non naviga più a `/profile`; apre direttamente `_CountersCustomizerSheet` via `showCountersCustomizer(context, ref, profileData)`.
- **fix** — `TotalizzatoriSection.onEdit` in dashboard non naviga più a `/profile`; apre direttamente `showPortaleEdit(context, ref, profileData)`.
- **refactor** — `_showCountersCustomizer` e `_showPortaleEdit` in `profile_screen.dart` rinominati pubblici (`showCountersCustomizer`, `showPortaleEdit`). Rimossi import `go_router` inutilizzati da dashboard e timesheet screen.

### Totalizzatori portale — Quick-edit per singolo contatore
- **feat** — `_Chip` ha nuovi campi `jsonKey`, `jsonKeyTotal`, `isMinutes`. Tutti i chip hanno le chiavi JSON mappate.
- **feat** — `_MetricChip`: chip con `jsonKey` mostra icona matita (9px); tap apre `_QuickChipEditSheet` con campo "Valore attuale" + "Spettante" (se applicabile).
- **feat** — `TotalizzatoriSection` ha nuovo callback `onChipEdit(Map<String, dynamic>)`. Dashboard salva via `profileRepositoryProvider.savePortaleData` aggiornando solo i campi modificati.
- **feat** — `_CategorySection` thread `onChipEdit` fino a ogni `_MetricChip`.

### Social — Dipartimento nella card colleghi
- **feat** — `ColleagueProfile` ha nuovo campo `dipartimento: String?`.
- **feat** — `SocialRepository.watchColleagues` legge `p['dipartimento']` dal profilo Firestore del collega.
- **feat** — `_ColleagueCard`: sotto il nome mostra dipartimento (se impostato) o inquadramento. Telefono sempre visibile quando presente (riga separata, 10px).

### Docs
- **docs** — `docs/funzionalita/social.md`: aggiornato flusso principale + aggiunta sezione "Proposte evoluzione caffè" con 6 idee.

---

## 2026-05-25 (v0.8.1 — Retroattivo timesheet, fix counters widget, version chip, profilo versione)

### Timesheet — Inserimento retroattivo
- **feat** — `_EntrySheet` accetta parametro `existingEntry: DailyTimesheet?`; `initState` pre-popola tipo, orario entrata/uscita dall'entry esistente.
- **feat** — Titolo sheet cambia in "Modifica giornata" quando si edita un'entry esistente.
- **feat** — `_DayDetailCard`: aggiunto parametro `onEdit: VoidCallback?`; mostra pulsante matita (blu) nell'header quando valorizzato.
- **feat** — Tapping su riga lista (vista Lista) apre `_EntrySheet` pre-popolato con l'entry esistente.
- **feat** — `_showEntrySheet` aggiornato con parametro `existingEntry`; passato ai `_DayDetailCard` in vista Settimana e Mese.

### UX — Versione app
- **feat** — `AppStrings.appVersion = 'v0.8-dev'` aggiunto a `app_strings.dart`.
- **feat** — `GlassHeader`: chip versione (blu traslucido, 9px, bold) tra campanella e avatar.
- **feat** — `ProfileScreen`: stringa versione centrata in fondo alla pagina (sotto logout).

### MonthlySummaryCard — Fix + UX
- **fix** — Header blu non riempiva tutta la larghezza: rimosso `Stack`, usato `Container(width: double.infinity)`.
- **ux** — Link "Personalizza" (icona tune) spostato dall'header blu alla sezione espansa (visibile solo dopo espansione).

---

## 2026-05-25 (v0.8 — Coffee 3 risposte + messaggio, nota attività, colleghi live stream, coffee su tutti)

### Social — Coffee 3 risposte + messaggio
- **feat** — `AppNotification` ha due nuovi campi opzionali: `responseType: String?` (`accepted|maybe|declined`) e `message: String?`.
- **feat** — `SocialRepository.respondToInvite` aggiornato: accetta `responseType` e `message?`; invia back-notification per **tutte** le risposte (non più solo accept).
- **feat** — `NotificationsScreen`: rimpiazzati i 2 pulsanti Accetta/Rifiuta con 3 icone ✅ Ci sono / 🤔 Forse / ❌ Non posso + textarea messaggio opzionale (max 160 char).
- **feat** — Card `coffee_accepted` mostra chip colorato (verde/arancio/grigio) con la risposta e il messaggio se presente.
- **feat** — Icona ☕ visibile su **tutti** i colleghi nella lista (rimosso filtro `canReceiveCoffee`).

### Dashboard + Timesheet — Nota attività giornaliera
- **feat** — `DailyTimesheet.note: String?` aggiunto a dominio + `toMap`/`fromMap`.
- **feat** — `TimesheetRepository.saveNote(dateId, note)`: `set merge:true` su Firestore.
- **feat** — `DashboardScreen`: sezione `_NoteSection` mostrata quando `isCompleted` (turno normale o smart working). Textarea 3 righe, bottone Salva, conferma "Salvata ✓". Pre-popola da `todayEntry.note`.
- **feat** — `TimesheetScreen._buildEntryInfo`: nota mostrata in corsivo sotto le info orario nella lista giornaliera (max 2 righe).

---

## 2026-05-25 (v0.7 — Coffee handshake, Portale edit, Dipartimento, tema sistema, widget link)

### Social — Coffee handshake completo
- **feat** — `respondToInvite` invia ora una notifica `coffee_accepted` al mittente originale quando l'invito viene accettato (sub-collezione `users/{uid}/notifications`).
- **feat** — `NotificationsScreen._NotifCard` gestisce tipo `coffee_accepted`: mostra "XXX ha accettato il tuo caffè ☕" come card informativa (no pulsanti azione).

### Totalizzatori portale — editabile dall'utente
- **feat** — `ProfileRepository.savePortaleData(Map)`: salva `portaleJson` nel documento Firestore dell'utente.
- **feat** — `totalizzatoriProvider` legge `portaleJson` dal profilo utente (tramite `userProfileStreamProvider`); usa la fixture solo se il campo è assente.
- **feat** — `TotalizzatoriSection`: aggiunto parametro `onEdit: VoidCallback?` e icona matita nell'header. Dashboard passa `() => context.push('/profile')`.
- **feat** — `ProfileScreen`: nuovo menù "🏦 Dati portale PA" → `_PortaleEditSheet` con form scrollabile per tutti i campi (30+ campi suddivisi in sezioni: Identificativo, Ferie, Festività, Straordinari, Banca Ore, Permessi, Buoni Pasto).

### Profilo — Dipartimento
- **feat** — Campo `dipartimento: String?` aggiunto al documento Firestore. Nuova `_InfoRow` nel profilo tra "Ente" e "Inquadramento".

### Profilo — Tema automatico (3 stati)
- **feat** — Sostituito toggle binario "Tema scuro" con `_ThemePicker` a 3 pulsanti: ☀️ Chiaro / 🌙 Scuro / 📱 Sistema. Sistema usa `ThemeMode.system` (già supportato da `themeModeProvider`).

### MonthlySummaryCard — link a impostazioni widget
- **feat** — Parametro `onEditTap: VoidCallback?`. Quando valorizzato, mostra icona `tune` nell'angolo in alto a destra dell'header blu.
- **feat** — Dashboard e Timesheet passano `onEditTap: () => context.push('/profile')`.

### Web — favicon e manifest
- **fix** — Spostati file favicon aggiornati da `favicon/` (root) a `web/icons/`; rimossa cartella stray `favicon/`.
- **fix** — `web/manifest.json`: aggiornati path icone ai file reali (`icons/web-app-manifest-192x192.png`, `512x512`, `apple-touch-icon.png`). Corretti nome app, colori tema.
- **fix** — `web/index.html`: link favicon aggiornati a `icons/favicon.ico`, `icons/favicon.svg`, `icons/favicon-96x96.png`.
- **fix** — `web/favicon.ico` aggiornato alla versione recente; `web/favicon.svg` rimosso (duplicato).

### MonthlySummaryCard — background fix (light mode)
- **fix** — Container esterno e sezione espansa ora usano `Colors.white` (opaco) in light mode, eliminando il bleed-through del gradiente di sfondo.

---

## 2026-05-21 (v0.6f — README + docs update)

### Documentazione
- **docs** — `README.md` (root): riscritto da zero (era template Flutter). Aggiunta live URL, feature table, stack table, comandi dev e deploy.
- **docs** — `panoramica/README.md`: stato attuale aggiornato con tabella feature; mindmap esteso con widget contatori, Totalizzatori, Social gruppi, Chigio.
- **docs** — `funzionalita/profile.md`: riscritta completamente (era obsoleta — diceva "read-only").
- **docs** — `funzionalita/dashboard.md`: aggiornato — rimosso Straordinari bar, aggiornata sezione MonthlySummaryCard, aggiunti dettagli Totalizzatori chip used/total + fetchedAt.
- **docs** — `funzionalita/timesheet.md`: aggiornato con 3 viste, alert giornate mancanti, summary card condivisa.
- **docs** — `funzionalita/chigio.md`: creata (nuova feature).
- **docs** — `funzionalita/README.md`: aggiornata mappa dipendenze + tabella stato.
- **docs** — `entita/README.md`: ER aggiornato con `leavePauseMins`, `sliMins`, `sboMins`, `workType` su DailyTimesheet; nuovi campi profilo (`summaryItems`, `notifyClockIn`, ecc.).
- **fix** — `docs/.DS_Store` rimosso.

---

## 2026-05-21 (v0.6e — Dashboard polish, background fix, Totalizzatori)

### MonthlySummaryCard — background fix
- **fix** — Aggiunto `color:` alla `BoxDecoration` del Container esterno: dark `#0a1628`, light `white@80%`. Risolve il problema di sfondo trasparente/incoerente visible in Home.

### Dashboard — rimozione widget Straordinari
- **remove** — Rimossi entrambi i `GlassTile` "Straordinari" (erano duplicati) e `SizedBox(height:4)` orfano.

### Totalizzatori portale — polish
- **feat** — `_Chip.total: String?`: quando valorizzato, `_MetricChip` mostra `valore / totale` con slash e colore attenuato.
- **feat** — `fetchedAt: String?` aggiunto a `Totalizzatori` (campo `fetched_at` nel JSON). Header mostra badge "Agg. DD/MM/YYYY" in alto a destra.
- **feat** — `periodo` mostrato inline accanto al titolo ("TOTALIZZATORI PORTALE · Aprile 2026").
- **feat** — FERIE: chip `Fruito annuo / Spettanza`, `Residuo ac / Spettanza`. FESTIVITÀ: `Fruito / Spettanza`, `Residuo / Spettanza`. STRAORDINARI: `Liquidati / Autorizzato`, `Liquidabili / Autorizzato`. Rimosso chip `Spettanza` ridondante.

---

## 2026-05-21 (v0.6d — Fix OP/Ore Perse, background card, docs)

### MonthlySummaryCard — fix OP
- **fix** — `'op'` ora mappa `deficitMins` (Ore Perse = giorni con ore < standard). Rimosso item duplicato `'perse'`. `defaultItems` = `['art9','sli','sbo','op']`.
- **fix** — Colore OP = `AppColors.red700` (era teal). Progress bar OP mostra deficit senza cap.
- **fix** — Sfondo sezione espansa: dark mode `#0a1628` @ 82% (era quasi trasparente), light mode `white` @ 80%.

### Profilo — customizer OP
- **fix** — Label "OP — Ore perse" (era "OP — Ore di produzione"). Label Art.9 = "Estensione orario mensile". Lista `_kAllItems` aggiornata a 4 item.

### Docs
- **docs** — `daily-timesheet.md`: aggiunto glossario contatori mensili; Art.9 = istituto opzionale; OP = `extraMins < 0`.
- **docs** — `user-profile.md`: aggiunti campi `monthlySliHours`, `monthlySboHours`, `summaryItems`, `summaryShowProgress`, `notifyClockIn/Out/Weekly`; corretto Art.9 description.

---

## 2026-05-21 (v0.6c — Widget contatori personalizzabile)

### MonthlySummaryCard — voci dinamiche
- **feat** — Aggiunto `overtimeCap`, `visibleItems`, `showProgressBars` al costruttore. Default: `['art9','sli','sbo','op','perse']`. La card legge `summaryItems` e `summaryShowProgress` dal profilo Firestore e rende header e barre dinamicamente.
- **feat** — Nuovo item `op` (OP — Ore di produzione) mappa `totalOtMins` con cap `monthlyOvertimeHours`. Colore teal `#00ACC1`.
- **feat** — Header usa `Wrap` per gestire 4-5 voci senza overflow.
- **rename** — `deficitLabel` = `'Ore perse'` ovunque (era `'Deficit'`).

### Profilo — Widget contatori (impostazioni)
- **feat** — Nuova voce "Widget contatori 📊" nel pannello Impostazioni del profilo. Apre `_CountersCustomizerSheet`: 5 tile con toggle colorati (Art.9/SLI/SBO/OP/Ore perse), switch "Mostra barre di avanzamento", pulsante "Ripristina default", salvataggio su Firestore. Funzione `_showCountersCustomizer`, widget `_CountersCustomizerSheet`.

---

## 2026-05-21 (v0.6b — UX profilo, alert timesheet, redesign card mensile)

### MonthlySummaryCard — redesign header
- **feat** — Header blu ora mostra Art.9 / SLI / SBO / Perse come 4 stat hero (ore extra del mese a colpo d'occhio). Sezione espansa mostra Ore tot / Straord / Buoni + barre di avanzamento Art9/SLI/SBO. Aggiunto widget `_SecStat` per le stat secondarie. `accent` color opzionale su `_BigStat` per il valore Perse (rosso chiaro se > 0).

### Timesheet — alert giorni passati senza timbrature
- **feat** — In vista Lista, le giornate feriali passate senza entry vengono evidenziate con bordo arancio, sfondo arancio tenue e icona ⚠️. I chip "Presenza / SW" restano cliccabili per inserimento retroattivo.

### Profilo — statistiche personali
- **feat** — La card avatar ora mostra 4 stat calcolate dai dati del mese corrente: Record gg (massimo ore/giorno), Uscita tardiva (max endTime), Uscita rapida (min endTime), Smart W. (gg in remoto). Rimossi i contatori generici Giorni/Ore mese/Buoni.

### Profilo — Notifiche
- **feat** — Schermata Notifiche implementata: bottom sheet con 3 toggle (Promemoria entrata, Promemoria uscita, Report settimanale). Preferenze salvate su Firestore come `notifyClockIn`, `notifyClockOut`, `notifyWeekly`. Widget `_NotificationSheet` + `_NotifToggle`.

### Profilo — Privacy
- **feat** — Schermata Privacy implementata: bottom sheet informativo con 3 sezioni (Dati al sicuro, Nessuna condivisione, Diritto cancellazione). Widget `_PrivacyRow`.

### Profilo — Ente picker
- **fix** — Lista amministrazioni ridotta a sola "Presidenza del Consiglio dei Ministri" (`AppStrings.administrations`).

---

## 2026-04-30 (v0.5d — Fix dialog Social, Totalizzatori portale Dashboard)

### Social — fix dialog gruppi
- **fix** — `_createGroup` e `_deleteGroup` in `_GroupsPanelState`: `Navigator.pop()` ora usa il `BuildContext` del builder della dialog (`dialogCtx`) invece del contesto esterno del widget. L'uso del contesto esterno in GoRouter causava `AssertionError: currentConfiguration.isNotEmpty` perché veniva fatto pop allo stack GoRouter invece che alla dialog. — [`social_screen.dart`](../lib/features/social/presentation/social_screen.dart)

---

## 2026-04-30 (v0.5c — Totalizzatori portale nella Dashboard)

### Dashboard — Totalizzatori portale
- **feat** — Nuovo modello `Totalizzatori` con tutti i campi del portale PA (FERIE, FESTIVITÀ SOPPRESSE, STRAORDINARI, BANCA ORE, PERMESSI, BUONI PASTO, DEBITI). — [`lib/features/dashboard/domain/totalizzatori.dart`](../lib/features/dashboard/domain/totalizzatori.dart)
- **feat** — `totalizzatoriProvider` (`@riverpod`) con fixture statica di sviluppo; sostituibile con una chiamata HTTP al portale. — [`lib/features/dashboard/presentation/totalizzatori_provider.dart`](../lib/features/dashboard/presentation/totalizzatori_provider.dart)
- **feat** — `TotAlertBanner` — banner in cima alla sezione statistiche con chip colorati (amber/red) per le condizioni di alert (ferie anno prec., accumulo ferie >30 gg, maggior presenza >8h, straordinari in sospeso, ore da recuperare).
- **feat** — `BancaOreTile` — tile full-width prominente con totale fruibile (hh:mm), breakdown AC/AP, badge verde se banca ore è tra 1h e 8h.
- **feat** — `TotalizzatoriSection` — sezione in fondo alla dashboard con tutte le categorie in `_MetricChip` colorati per livello di alert (info / amber / red).
- **feat** — Tile "BUONI PASTO" nel grid mostra il conteggio ufficiale del portale (`buoni_pasto_mensili`) e affianca il conteggio calcolato localmente da Firestore.

---

## 2026-04-30 (v0.5b — Profilo editabile, fix architettura background)

### Profilo
- **feat** — Tutti i campi del profilo sono ora editabili direttamente dalla schermata Profilo: nome, ente, inquadramento (chip), orario standard (slider), soglia buono pasto (slider), Articolo 9 (slider), tetto straordinari (slider), telefono (field).
- **feat** — `ProfileRepository.updateProfileFields(Map)` — metodo generico per aggiornare uno o più campi Firestore in un unico `update`. [`profile_repository.dart`](../lib/features/profile/data/profile_repository.dart)
- **feat** — Bottom sheet riutilizzabile `_EditSheet` + widget `_SaveButton` con stato di loading integrato.
- **feat** — `_editSlider` bottom sheet con slider e preview live del valore formattato.
- **feat** — Cambio inquadramento aggiorna automaticamente `standardDailyMins`, `mealVoucherThresholdMins`, `monthlyArt9Hours` ai valori predefiniti del contratto.
- **feat** — Settings rows (`Notifiche`, `Privacy`, `Informazioni app`) ora con `onTap`: le prime due mostrano snackbar "prossimamente", la terza apre un dialog informativo.
- **fix** — Rimosso `Container(gradient)` duplicato nel body di `ProfileScreen`: il gradiente è già fornito da `AppBackground` in `app.dart`.

### Architettura background (fix definitivo)
- **fix** — `AppBackground` rimosso da `MainShellScreen` e centralizzato in `app.dart` per tutte le dimensioni schermo. Elimina la doppia istanza con sistemi di coordinate diversi che causava una linea visibile al bordo del contenitore 430 px su viewport intermedi.
- **fix** — `GlassButton` — `Text` wrappato in `Flexible` con `TextOverflow.ellipsis`; elimina overflow di sub-pixel durante il resize della finestra.

---

## 2026-04-29 (v0.5 — pianificato: desktop adattivo, FloatingNav overlay, gruppi Social)

### Architettura
- **plan** — `MainShellScreen`: passaggio da `Column` a `Stack` per rendere `FloatingNav` un vero overlay; elimina la riga separatrice tra contenuto e gradiente. — [`architettura/navigation.md`](./architettura/navigation.md)
- **plan** — `FloatingNav` convertita in `StatefulWidget` con sliding pill animata (`TweenAnimationBuilder`, 300 ms, `Curves.easeOutCubic`). — [`architettura/navigation.md`](./architettura/navigation.md)
- **plan** — Aggiunto breakpoint `kDesktopBreakpoint = 800 px`; su schermi ≥ 800 px rimosso il vincolo 430 px, ogni screen gestisce il proprio layout split-view. — [`architettura/navigation.md`](./architettura/navigation.md)

### Dashboard
- **plan** — Saluto dinamico in `GlassHeader`: Buongiorno (05–13) / Buon pomeriggio (13–18) / Buona sera (18–05). — [`funzionalita/dashboard.md`](./funzionalita/dashboard.md)
- **plan** — Pulsante Smart Working compatto: stessa riga di "Timbra Entrata", solo icona + "SW" su mobile, "Smart Working" su desktop. — [`funzionalita/dashboard.md`](./funzionalita/dashboard.md)
- **plan** — Layout desktop: timer + CTA a sinistra, riepilogo giornaliero a destra, stats full-width sotto. — [`funzionalita/dashboard.md`](./funzionalita/dashboard.md)

### Timesheet
- **plan** — Layout desktop split-view: scroll list giornate a sinistra (280 px), calendario + dettaglio a destra. — [`funzionalita/timesheet.md`](./funzionalita/timesheet.md)

### Social — Gruppi (nuova feature)
- **plan** — Nuova sub-collezione Firestore `users/{uid}/groups/{groupId}` con `name`, `createdAt`, `memberUids`. — [ADR-0002](./decisioni/0002-social-groups.md)
- **plan** — Operazioni: crea gruppo, aggiungi membro, rimuovi membro, elimina gruppo. — [`funzionalita/social.md`](./funzionalita/social.md)
- **plan** — Layout desktop Social: pannello sinistro gruppi (240 px), pannello destro lista colleghi filtrata. — [`funzionalita/social.md`](./funzionalita/social.md)

### Bug fix (rilasciati)
- **fix** — `appRouterProvider` ora `keepAlive: true` + `_RouterNotifier` con `refreshListenable`; elimina la ricreazione del `GoRouter` ad ogni emissione di `authStateChanges`. — [`architettura/navigation.md`](./architettura/navigation.md)
- **fix** — Redirect `hasProfile` usa `Firestore.get()` diretto invece di `hasProfileStreamProvider.future`; elimina l'errore "disposed during loading state" che mandava l'utente all'onboarding. — [`architettura/navigation.md`](./architettura/navigation.md)
- **fix** — `AppBackground` usato come wrapper full-screen nel builder desktop di `app.dart`; gradiente ora copre l'intera larghezza dello schermo (non solo i 430 px centrali).

---

## 2026-04-27 (v0.4 — Social, Notifiche, Riepilogo mensile dashboard)

### Social (nuovo)
- **feat** — Schermata Social completamente riscritta con dati reali Firestore. — [`funzionalita/social.md`](./funzionalita/social.md)
- **feat** — Lista colleghi personalizzabile: aggiungi/rimuovi utenti della stessa amministrazione.
- **feat** — Preferiti (⭐) in cima alla lista; long-press per rimuovere.
- **feat** — Stato presenza in tempo reale (`working`/`paused`/`remote`/`completed`/`notStarted`) pubblicato su `users/{uid}.currentStatus` ad ogni transizione del timer.
- **feat** — Pulsante ☕ invia invito caffè a colleghi presenti/in pausa → notifica Firestore.

### Notifiche (nuovo)
- **feat** — Schermata `/notifications` con inviti caffè ricevuti; Accetta/Rifiuta aggiorna `status` del documento. — [`funzionalita/social.md`](./funzionalita/social.md)
- **feat** — Badge rosso sul campanello in `GlassHeader` quando ci sono notifiche non lette (`hasUnreadProvider`).
- **feat** — Tutte le notifiche marcate come lette all'apertura della schermata.

### Profilo
- **feat** — Campo `phoneNumber` editabile via bottom sheet (pulsante ✏️ nella riga Telefono).
- **feat** — Numero di telefono visibile nelle card colleghi della schermata Social.

### Dashboard — Riepilogo mensile (nuovo)
- **feat** — **Riga 1** (4 tile): Art.9 svolte | SLI svolte | SBO svolte | Deficit ore. — [`funzionalita/dashboard.md`](./funzionalita/dashboard.md)
- **feat** — **Riga 2** (3 tile): Ore mancanti al target (Art9+SLI+SBO) | Giorni lavorativi rimanenti (escluse ferie/permessi dal timesheet) | Extra ore/giorno necessarie.
- **feat** — **Riga 3**: Buoni pasto maturati con soglia visibile.
- **feat** — `_remainingWorkingDays()` conta lun–ven rimanenti escludendo giorni con `workType: leave|holiday` già registrati nel timesheet.

### Modello dati
- **schema** — `DailyTimesheet` — aggiunto `sliMins: int` (straordinario liquidato, default 0) e `sboMins: int` (banca ore, default 0). — [`entita/daily-timesheet.md`](./entita/daily-timesheet.md)
- **feat** — `WorkTimer.endTurn()` imposta `sboMins = max(extraMins, 0)` di default; l'utente può modificare la ripartizione SLI/SBO nel Timesheet.

### Sicurezza
- **infra** — Creato `firestore.rules` con regole aggiornate: profili leggibili da tutti gli utenti autenticati; `notifications` creabili da chiunque sia autenticato (per ricevere inviti).

### Wiki
- **wiki** — Aggiornate: [`funzionalita/social.md`](./funzionalita/social.md), [`entita/daily-timesheet.md`](./entita/daily-timesheet.md), [`funzionalita/dashboard.md`](./funzionalita/dashboard.md).

---

## 2026-04-26 (v0.3 — Art. 9, dati reali profilo, oggi auto-detect)

### Dashboard
- **feat** — **Art. 9 tracking reale**: `Σ entry.leavePauseMins` da Firestore; card mostra `usate / cap` con progress bar + colore arancione al raggiungimento del tetto. — [`entita/daily-timesheet.md`](./entita/daily-timesheet.md)
- **feat** — Target mensile ore calcolato con `_workingDaysInMonth()` (conta lun–ven effettivi) invece di valore fisso 22. — [`funzionalita/dashboard.md`](./funzionalita/dashboard.md)
- **feat** — **Oggi auto-detect**: dopo un riavvio, se il turno del giorno è già su Firestore, la dashboard lo mostra in stato `completed` senza richiedere una nuova timbratura. — [`funzionalita/dashboard.md`](./funzionalita/dashboard.md)

### Timer
- **feat** — `totalLeavePauseMins` aggiunto a `TimerState` + chiave `timer_leavePauseMins` su SharedPreferences. — [`entita/timer-state.md`](./entita/timer-state.md)
- **fix** — `PauseType.leave` ora accumula in `totalLeavePauseMins` (non più in `totalStandardPauseMins`): i permessi brevi Art. 9 sono separati dalle pause caffè nel calcolo del `netWorkedMins`.

### Modello dati
- **schema** — `DailyTimesheet` — aggiunto campo `leavePauseMins: int` (default 0, backwards-compat). — [`entita/daily-timesheet.md`](./entita/daily-timesheet.md)
- **fix** — `netWorkedMins` ora sottrae anche `leavePauseMins` oltre a `standardPauseMins` e `lunchPauseMins`.

### Profilo
- **feat** — `GlassHeader` usa nome reale da Firestore/Firebase Auth e foto Google.
- **feat** — `ProfileScreen` mostra foto Google, sottotitolo `employmentType · administration`, statistiche mensili reali (giorni, ore, buoni pasto).

### Wiki
- **wiki** — Aggiornate: [`entita/timer-state.md`](./entita/timer-state.md), [`entita/daily-timesheet.md`](./entita/daily-timesheet.md), [`funzionalita/dashboard.md`](./funzionalita/dashboard.md).

---

## 2026-04-26 (v0.2 — Glass Redesign + Funzionalità complete)

### UI / Design system
- **ui** — Redesign completo glass-morphism su tutti gli schermi (Login, Onboarding, Dashboard, Timesheet, Social, Profile) basato su design file Claude Design. — [`funzionalita/dashboard.md`](./funzionalita/dashboard.md)
- **ui** — Layout **mobile-first**: su desktop/tablet il contenuto è centrato a 430 px su backdrop scuro. — [`app.dart`](../lib/app/app.dart)
- **ui** — `FloatingNav` glass pill a 3 tab (Home / Timesheet / Social); Profile via avatar in header. — [`architettura/navigation.md`](./architettura/navigation.md)
- **ui** — `ShiftRing` custom painter: arco blu → verde, dot buono pasto, anello OT arancione.
- **ui** — `DayCheckpoints` timeline: Entrata → Pausa → Buono → Fine turno → Straordinario.
- **ui** — Icone nav aggiornate: `home_rounded`, `calendar_month_rounded`, `group_rounded`.

### Dashboard
- **feat** — Stato `WorkState.completed` aggiunto: dopo "Timbra Uscita" la dashboard mostra il riepilogo della giornata. — [`entita/timer-state.md`](./entita/timer-state.md)
- **feat** — Pulsante **Smart Working** 🏠 one-tap affianco a "Timbra Entrata": registra giornata remota + buono pasto automatico. — [`funzionalita/dashboard.md`](./funzionalita/dashboard.md)
- **feat** — Statistiche mensili (ore, buoni, straordinari, Art. 9) collegate a **dati reali Firestore** via `monthlyTimesheetsProvider` e `userProfileStreamProvider`.

### Timer
- **fix** — `_ticker` ora cancellato con `ref.onDispose` → nessun memory leak.
- **feat** — Tick a **1 secondo** (era 1 minuto) → anello live fluido.
- **feat** — `standardWorkMins` letto da `userProfile.standardDailyMins` via `ref.listen` (non più hardcoded 456).
- **feat** — **Persistenza mid-day su SharedPreferences**: se l'app viene chiusa durante il turno, lo stato viene ripristinato all'avvio se la data è ancora oggi. — [`entita/timer-state.md`](./entita/timer-state.md)

### Timesheet
- **fix** — Frecce di navigazione mensile (`‹` `›`) ora visibili e cliccabili — rimpiazzate con `Icon` Material + container touch-friendly 30 px.
- **feat** — Calendario più compatto (`childAspectRatio: 1.25`, celle 24 px).
- **feat** — **Inserimento manuale** giornate: bottom sheet con selettore data, tipo (Presenza / Smart Working / Permesso / Ferie) e TimePicker per entrata/uscita. — [`funzionalita/timesheet.md`](./funzionalita/timesheet.md)
- **feat** — Dot calendario colorati per `workType`: verde, arancione (OT), blu (remote), grigio (assenza).
- **feat** — Card dettaglio giornata mostra badge `workType` e barra colore coerente con il tipo.

### Modello dati
- **schema** — `DailyTimesheet` — aggiunto campo `workType: String?` (backwards-compatible: `null` → `'presence'`). — [`entita/daily-timesheet.md`](./entita/daily-timesheet.md)
- **schema** — `TimesheetRepository` — aggiunto metodo `saveRemoteWorkDay(stdMins)`.

### Autenticazione / Onboarding
- **fix** — `onboarding_screen.dart`: sostituito `ref.read(authStateChangesProvider).value` (lancia eccezione in Riverpod 3 se stream in loading) con `FirebaseAuth.instance.currentUser`. Questo era la causa principale del loop onboarding.
- **feat** — Tema persiste su `SharedPreferences`: scelta light/dark sopravvive ai riavvii. — [`shared/providers/global_providers.dart`](../lib/shared/providers/global_providers.dart)
- **feat** — `hasProfileStream` ora verifica `hasCompletedOnboarding == true` (non solo `doc.exists`) → onboarding non viene risaltato se il documento esiste parzialmente.

### Wiki
- **wiki** — Aggiornate: [`entita/timer-state.md`](./entita/timer-state.md), [`entita/daily-timesheet.md`](./entita/daily-timesheet.md), [`funzionalita/dashboard.md`](./funzionalita/dashboard.md), [`funzionalita/timesheet.md`](./funzionalita/timesheet.md).

---

## 2026-04-26 (v0.1 — Init)

- **wiki** — Creata struttura iniziale della wiki (`docs/`) e `CLAUDE.md` di radice. Documentate entità, feature, architettura. — [`README.md`](./README.md)
- **adr** — `ADR-0001 — Stack iniziale: Flutter + Riverpod 3 + Firebase + Drift`. — [`decisioni/0001-stack-iniziale.md`](./decisioni/0001-stack-iniziale.md)

---

## Convenzioni di compilazione

- **Una riga per cambiamento utente-visibile** (feature, refactor con effetto su API, modifica schema dati, dipendenza nuova).
- **Non duplicare** quello che già c'è in `git log`: questo file è per il *significato* del cambiamento, non per il diff.
- Per ogni modifica architetturale linkare la ADR corrispondente.
- Per ogni modifica a un'entità linkare la sua scheda in `docs/entita/`.
