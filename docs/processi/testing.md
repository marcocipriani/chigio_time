# Testing

> Suite di test da eseguire **prima di ogni rilascio** (web/Android/iOS).
> Non esiste un comando unico: `flutter test` copre Dart/Flutter, mentre il
> backend richiede `npm test --prefix functions` e i syntax check Node. I test
> repository sono offline e non sostituiscono emulatori o smoke live.

## Come si lancia

```bash
flutter test            # intera suite
flutter test test/domain/daily_timesheet_test.dart   # singolo file
flutter analyze         # lint (deve restare pulito a parte info note)
npm test --prefix functions                           # logica/runtime backend
npm test --prefix scripts                             # catalogo/migrazione PCM
node --check functions/index.js
node --check functions/notification_logic.js
node --check functions/notification_runtime.js
firebase deploy --only firestore:rules --dry-run  # compila, non pubblica
```

Pre-rilascio: `flutter analyze`, `flutter test`, test Node e syntax check
Functions devono passare, poi `flutter build web` + deploy (vedi
`build-and-run.md`).

## Cosa copre

| Area | File | Cosa verifica |
|---|---|---|
| Dominio | `test/domain/daily_timesheet_test.dart` | getter tipo giornata, round-trip `toMap`/`fromMap` (anche assenze con causale). |
| Dominio | `test/domain/salary_payment_test.dart` | `SalaryPaymentType` id stabili + `fromId` fallback; `fromMap` + getter `monthId`/`dateId`/`year`. |
| Dominio | `test/domain/colleague_test.dart` | `effectiveStatus` (valido solo se data = oggi), `canReceiveCoffee`, `initials`. |
| Dominio | `test/domain/projects_test.dart` | `Project` ruoli/membership, `PomodoroSession.fromDoc`, **math pomodoro** (`ActivePomodoro` elapsed/remaining/pausa/fase). |
| Servizi | `test/services/csv_import_service_test.dart` | parsing CSV: righe valide, header, ferie/permesso, **import robusto** (salta righe rotte, importa le valide), uscita<entrata. |
| Servizi (legacy) | `test/core/services/chigio_phrase_engine_test.dart` | motore frasi Chigio: 3 generi M/F/A, pool orari, budget header. |
| Core / sicurezza | `test/core/profile_doc_complete_test.dart` | gate onboarding: flag / name+employmentType; doc solo-`photoURL` → NON completo (no bypass / no re-onboarding). |
| Core / routing | `test/core/profile_gate_test.dart`, `test/core/app_redirect_test.dart` | reducer cache/server/error, marker positive-only e truth table: solo server incompleto seleziona onboarding. |
| Bootstrap Web | `test/widget/app_bootstrap_test.dart`, `test/platform/web_bootstrap_loader_test.dart`, `test/platform/ui_font_assets_test.dart` | skeleton DOM/Flutter, retry, cache multi-tab, font UI locali e nessuna attesa font prima del primo `runApp()`. |
| Performance Home | `test/widget/home_loading_skeleton_test.dart`, `test/widget/home_mobile_scroll_view_test.dart` | un solo pulse strutturale, lazy build dei widget secondari e ripristino offset mobile. |
| Core / PCM | `test/core/pcm_catalog_test.dart`, `pcm_catalog_repository_test.dart`, `pcm_catalog_database_test.dart` | schema e 50 righe, 12 sedi, raccomandazione, precedenza remote/cache/bundled e sostituzione Drift atomica. |
| UI / PCM | `test/widget/pcm_assignment_form_test.dart`, `test/core/pcm_assignment_gate_test.dart` | nessuna auto-selezione sede, raccomandazione visibile, gate solo per profili PCM non canonici e selettori montati sotto il `Navigator`. |
| Core / leggibilità | `test/core/app_strings_test.dart` | 3 generi distinti (schwa), 5 voci navbar non vuote e `appVersion` con build number allineato al `pubspec`. |
| Feature | `test/funzionalita/social_status_test.dart` | `statusRingColor` (mappa stati→colori, uscito/assenza = nero), `statusExplanation` non vuoto. |
| Feature / leggibilità | `test/funzionalita/ccnl_format_test.dart` | `formatCcnlBody`: rimuove numeri pagina/intestazioni, ricompone capoversi. |
| Sicurezza | `test/security/firestore_rules_test.dart` | **contratto rules**: `administration` PCM set-once, delete profilo negato, schema cross-user tipizzato, progetti/pomodori membership-gated e nessuna regola world-readable. |
| Notifiche / dominio | `test/domain/app_notification_test.dart` | parsing copy/route/esito push, azioni solo per inviti pending e fallback `unknown/info` per payload legacy malformati. |
| Notifiche / client | `test/core/services/notification_routing_test.dart`, `test/core/services/fcm_service_test.dart` | route allowlisted, gate piattaforme, registrazione per-installazione, race login/logout e cleanup bounded. |
| Notifiche / UI | `test/widget/notification_preferences_sheet_test.dart` | invio test, errore inline, retry e blocco dismiss durante le write. |
| Notifiche / backend | `functions/test/notification_logic.test.js`, `functions/test/notification_runtime.test.js` | DND, copy/routing, token legacy/multi-device, claim/lease, marker pre-dispatch, finalize failure senza doppio FCM, retry Eventarc/Scheduler, cleanup, delete-race e producer idempotenti. |
| Script PCM | `scripts/test/pcm_catalog_logic.test.mjs` | validazione/hash del payload, classificazione profili, reset e idempotenza. |
| Timer / sync | `test/features/timer_state_test.dart` | calcoli turno/reminder, generation comune start/pausa/ripresa, echo pending/cache vs ack server, recovery crash pre/post-delete, dedup delete e rollback/retry. |
| Piattaforme push | `test/platform/notification_config_test.dart`, `test/platform/firebase_messaging_sw_test.js` | channel Android, entitlement/background mode Apple, click routing Web e assenza di doppia notifica browser. |
| Accessibilità | `test/accessibility/contrast_test.dart` | contrasto WCAG: body neutral900/bianco ≥ 7:1, testo bianco su colori azione ≥ 4.5:1. |
| UI | `test/widget/floating_nav_test.dart` | la navbar mostra le 5 voci e il tap invoca `onTap` con l'indice corretto. |

## Limiti noti

- **Niente test sull'emulatore Firestore** (manca `firebase_rules_unit_testing`):
  la sicurezza è verificata come *contratto testuale* sulle rules
  (`firestore_rules_test.dart`), non eseguendole. Il `--dry-run` Firebase CLI
  ne valida la compilazione, non i casi allow/deny. Per un test comportamentale
  reale servirebbe l'emulatore + Node.
- I widget test sono limitati ai componenti **senza Firebase** (es.
  `FloatingNav`); gli screen completi richiedono l'inizializzazione di Firebase.
- Per testare `CsvImportService` il parser espone un entry-point pubblico
  `parse(...)` (oltre a `pickAndParse`, che richiede il file picker).
- I test Functions usano fake deterministici: non provano Eventarc, Cloud
  Scheduler, FCM/APNs o Firestore reali. Il gate live deve verificare almeno
  una notifica `test` e il passaggio del documento a uno stato terminale.
- I test piattaforma verificano file di configurazione e routing, non permessi
  o ricezione su device. Apple richiede chiave APNs caricata in Firebase e
  build firmata; Windows/Linux sono no-op FCM per contratto.

## Gate deploy notifiche

L'indice collection-group di `activeTimer.reminderAt` è parte del contratto
del reminder. Distribuire insieme rules, indice e Functions:

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

_Ultima revisione: 2026-07-22 — bootstrap Web e gate profilo cache/server._
