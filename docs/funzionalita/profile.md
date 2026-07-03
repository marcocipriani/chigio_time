# Feature: Profilo

## Scopo

Mostrare e modificare i dati dell'utente (nome, ente, inquadramento, orario, soglie), statistiche personali del mese corrente, impostazioni app (tema, notifiche, privacy, widget contatori, GPS), statistiche avanzate e logout.

## File coinvolti

| Path | Ruolo |
|---|---|
| `lib/features/profile/presentation/profile_screen.dart` | UI completa |
| `lib/features/profile/presentation/stats_screen.dart` | Schermata statistiche avanzate (`/stats`) |
| `lib/features/profile/data/profile_repository.dart` | `userProfileStreamProvider`, `updateProfileFields`, `updatePhoneNumber` |
| `lib/shared/providers/global_providers.dart` | `themeModeProvider` (`Notifier<ThemeMode>`) |
| `lib/features/authentication/data/auth_repository.dart` | `signOut()` |
| `lib/shared/widgets/monthly_summary_card.dart` | `MonthlySummaryCard.defaultItems` usato nel customizer e in `StatsScreen` |
| `lib/core/services/geofencing_service.dart` | `GeofencingService` — permessi, check posizione, Haversine |
| `lib/core/constants/app_strings.dart` | Tutte le stringhe UI |
| `lib/core/constants/pcm_locations.dart` | Elenco sedi/strutture PCM |
| `lib/core/data/pcm_locations_repository.dart` | Lettura sedi PCM da Drift/fallback seed |
| `docs/ccnl/ccnl-pcm-2019-2021.md` + `docs/ccnl/ccnl-pcm-2016-2018.md` | Asset Markdown letti dal viewer CCNL |

## Routing

`/profile` — rotta push sopra la shell (`parentNavigatorKey: _rootNavigatorKey`), no bottom nav. Accesso da `GlassHeader` (tap avatar) nella dashboard.

## Sezioni UI

### 1. Avatar card

- Avatar (foto Google) o `_InitialAvatar` con iniziale.
- Nome, `employmentType · administration`.
- "Timbratonaut 🚀 dal DD mmm YYYY" (data creazione account da `FirebaseAuth.instance.currentUser?.metadata.creationTime`).
- **Statistiche personali mese corrente** (2×2 grid):

| Stat | Calcolo |
|---|---|
| Record gg | `max(entry.netWorkedMins)` formattato `Xh YYm` |
| Uscita tardiva | `max(entry.endTime)` formattato `HH:MM` |
| Uscita rapida | `min(entry.endTime)` formattato `HH:MM` |
| Smart W. | `count(entry.isRemote)` |

### 2. Dati profilo (tutti editabili — ordine di visualizzazione)

| Ordine | Campo | Widget edit | Firestore key |
|---|---|---|---|
| 1 | Nome completo | `_editTextField` | `name` |
| 2 | Ente | `_editEnteList` | `administration` |
| 3 | Dipartimento | `_editPcmStructureList` | `dipartimento` + dati sede collegati |
| 4 | Sede | `_editPcmSiteList` | `sede`, `sedeId`, `sedeAddress`, `sedeLat`, `sedeLng` |
| 5 | Piano | `_editTextField` | `piano` |
| 6 | Stanza/Ufficio | `_editTextField` | `stanza` |
| 7 | Interno ☎️ | `_editTextField` (numerico) | `interno` |
| 8 | Telefono 📱 | `_editPhone` | `phoneNumber` |
| 9 | Inquadramento | `_editEmploymentType` (chip) | `employmentType` |
| 10 | Orario standard | `_editStandardHoursPresets` (chip preset) | `standardDailyMins` |
| 11 | Soglia buono pasto | `_editSlider` (240–480 min) | `mealVoucherThresholdMins` |
| 12 | Articolo 9 mensile | `_editIntHours` (+/− + slider, 0–50 h) | `monthlyArt9Hours` |
| 13 | Tetto straordinari | `_editIntHours` (+/− + slider, 0–80 h) | `monthlyOvertimeHours` |

#### `_editPcmStructureList` / `_editPcmSiteList`

La sede non è più un campo libero quando l'elenco PCM è disponibile.
La sheet carica `pcmOfficeLocationsProvider`, mostra struttura + sede +
indirizzo, e salva:

- `dipartimento`
- `sede`
- `sedeId`
- `sedeAddress`
- `sedeLat`
- `sedeLng`

Se il DB locale non è disponibile, il repository usa i seed statici in
`pcmOfficeSeeds`.

#### `_editEnteList`

Lista `AppStrings.administrations` (25 enti PA). **Solo "Presidenza del Consiglio dei Ministri" è attiva**; gli altri sono opacizzati al 38% con label "Prossimamente" e non toccabili.

#### `_editStandardHoursPresets`

Sostituisce il vecchio slider `_editSlider` per `standardDailyMins`. Mostra chip preset in base a `employmentType`:
- **Ruolo**: 7:36 (456 min) / 6:40 (400 min)
- **Comando**: 7:12 (432 min) / 6:12 (372 min)

#### `_editEmploymentType`

Chip: Ruolo / Comando / Altro. Al cambio tipo imposta valori default:
- Ruolo → `standardDailyMins=456`, `mealVoucherThresholdMins=380`, `monthlyArt9Hours=8`
- Comando → `standardDailyMins=432`, `mealVoucherThresholdMins=380`, `monthlyArt9Hours=17`

### 3. Impostazioni

| Voce | Azione |
|---|---|
| Tema 🎨 | Picker 4 stati: ☀️ Chiaro / 🌙 Scuro / 📱 Sistema / ⏰ Auto (dark 18:00–06:00) |
| Lingua 🌐 | Toggle 🇮🇹 / 🇬🇧 |
| Dati portale PA 🏦 | `showPortaleEdit` — form ~30 campi totalizzatori |
| Widget contatori 📊 | `showCountersCustomizer` — scelta voci e barre avanzamento |
| Widget in evidenza ✨ | `_showHighlightWidgetPicker` — sceglie la card in evidenza nella Dashboard |
| Notifiche 🔔 | `_showNotifiche` — toggle entrata/uscita/report, soglia push uscita prevista, DND, colleghi mattina, recap settimanale, avviso soglia OT, **Stipendio in arrivo** (toggle + giorno accredito 1–28, salva `notifyPayday`/`paydayDay`; push gestito da `hourlyNotifications`, vedi [stipendio](./stipendio.md)) |
| Privacy 🔒 | Sheet informativo |
| Informazioni app ℹ️ | Dialog info + autore |
| CCNL PCM 📘 | Lettore completo 2019-2021 / 2016-2018 con indice articoli |
| Chigio 🐢 | `context.push('/chigio')` |

#### Widget contatori (`_CountersCustomizerSheet`)

Scelta voci visibili nel widget blu mensile + toggle barre avanzamento. Salva `summaryItems: List<String>` e `summaryShowProgress: bool` su Firestore.

Voci: `art9`, `sli`, `sbo`, `op`.

#### Widget in evidenza (`_showHighlightWidgetPicker`)

Picker sheet con 4 opzioni salvate in `profileData['highlightWidget']`:

| ID | Label | Dato mostrato |
|---|---|---|
| `none` | Nessuno | (card assente) |
| `bankHours` | Banca ore | `Totalizzatori.totaleBancaOreFruibile` |
| `overtime` | Straordinari mese | somma `extraMins > 0` del mese |
| `mealCount` | Buoni pasto | count giorni `netWorkedMins ≥ mealThreshold` |

La card viene renderizzata da `DashboardScreen._buildHighlightWidget` sopra `MonthlySummaryCard`.

### 4. Logout

`AuthRepository.signOut()` → `context.go('/login')`.

### CCNL PCM

La card `_CcnlProfileCard` apre `_CcnlReaderSheet`, un viewer full-screen che
legge i Markdown inclusi negli asset Flutter:

- `docs/ccnl/ccnl-pcm-2019-2021.md` — etichetta "Nuovo".
- `docs/ccnl/ccnl-pcm-2016-2018.md` — etichetta "Precedente".

Il parser interno estrae gli articoli (`Art. N ...`) e costruisce un indice
navigabile. Il viewer serve per consultazione personale: non crea richieste,
workflow autorizzativi o scadenze.

## Flusso dati

```mermaid
flowchart LR
    UI[ProfileScreen] -->|watch| UP[userProfileStreamProvider]
    UI -->|watch| MT[monthlyTimesheetsProvider]
    UI -->|watch| TM[themeModeProvider]
    UP --> FS[(Firestore users/uid)]
    MT --> FS
    UI -->|updateProfileFields| PR[ProfileRepository]
    PR --> FS
    UI -->|tap logout| AR[AuthRepository.signOut]
    UI -->|push /chigio| Router
```

## Note

- `_editIntHours` mostra un numero grande (48px) + bottoni +/− + slider; salva come `int` (ore).
- `_editEnteList`: solo PCM abilitato; gli altri enti sono disabilitati con trasparenza 38%.
- `_editStandardHoursPresets`: chip visivi grandi (28px), selezione in memoria + `_SaveButton` esplicito.
- `themeModeProvider` è persistito su `SharedPreferences` tramite `global_providers.dart`.

## Schermata Statistiche avanzate (`/stats`)

Rotta push sopra la shell, accessibile dal link "Statistiche avanzate →" in fondo alla avatar card del profilo.

### Sezioni

| Sezione | Dati | Chart |
|---|---|---|
| Contatori mese corrente | `MonthlySummaryCard` non-navigabile | — |
| Widget in evidenza | Valore scelto in preferenze | Colored banner |
| Media ore giornaliere | `avgDailyMins` per gli ultimi 6 mesi | BarChart blu |
| Straordinari per giorno settimana | OT aggregato Lun–Ven, ultimi 3 mesi | BarChart arancione |
| Permessi e ferie | `leaveDays` + `holidayDays` per mese, 6 mesi | Grouped BarChart |
| Orario medio entrata | `avgEntryTime` per mese + giorni presenza | Tabella |
| Statistiche personali avanzate | record streak, pausa media, puntualità ±15 min | Pill metriche |

Tutti i dati vengono da `monthlyTimesheetsProvider` watchato per i 6 mesi precedenti. La classe `_MonthStats` aggrega i calcoli.

## GPS auto-timbratura (`_GpsSettingsCard`)

Sezione GlassCard tra "Dati profilo" e "Impostazioni". Campi Firestore gestiti: `gpsAutoClockIn`, `officeLat`, `officeLng`, `officeRadiusM`.

### Flusso impostazione

1. Utente abilita toggle "Auto-timbratura GPS".
2. Se `officeLat` è null → apre `_GpsSettingsSheet` prima di salvare.
3. `_GpsSettingsSheet`: bottone "Usa posizione attuale" → `GeofencingService.getCurrentPosition()` → salva lat/lng. Slider raggio 50–500m (default 150m).

### Flusso utilizzo (Dashboard)

1. `_GpsPromptCard` appare nella heroCard quando: turno non iniziato + `gpsAutoClockIn` + posizione impostata + ora 06:00–11:00.
2. Utente tap → `GeofencingService.checkInOffice()` → se `inside` → dialog conferma → `notifier.startTurn()`.
3. Prompt si auto-chiude dopo il check (dismissed) o se l'utente chiude la ×.

Vedi **ADR-0004** per la scelta `geolocator` foreground vs. background.

_Ultima revisione: 2026-06-07 — aggiunti sede PCM strutturata, lettore CCNL e notifica uscita prevista._
