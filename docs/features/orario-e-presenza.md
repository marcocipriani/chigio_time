# Orario di lavoro e Maggior Presenza

> Documento di riferimento per la logica contrattuale (CCNL comparto
> Funzioni Centrali — ex Ministeri) e la sua implementazione in Chigio Time.
> Aggiornare ad ogni modifica ai calcoli del timer, alle soglie di profilo
> o al modello `DailyTimesheet`.

---

## 1. Concetti teorici (CCNL)

> Nota 2026-06-06: dopo la conversione del CCNL PCM 2016-2018 in
> [`../ccnl/ccnl-pcm-2016-2018.md`](../ccnl/ccnl-pcm-2016-2018.md), la label
> "Art.9" usata storicamente dall'app va trattata come convenzione app/portale.
> Nel CCNL PCM 2016-2018 l'Art. 9 riguarda clausole sindacali; i permessi brevi
> sono Art. 35 e la banca ore e' Art. 26.

### 1.1 Orario di lavoro standard

Il CCNL Funzioni Centrali definisce due profili tipici:

| Profilo | Minuti/giorno | HH:MM | Note |
|---|---|---|---|
| **Ruolo** (dipendente MO) | 456 | 7h 36m | orario più comune |
| **Comando** (distaccato) | 432 | 7h 12m | orario ridotto per il personale comandato |

L'orario è definito per giornata lavorativa (lun–ven). Sabato, domenica e festività sono esclusi dal conteggio contrattuale.

### 1.2 Pausa pranzo obbligatoria

Il contratto prevede una pausa pranzo di almeno **30 minuti** per turni superiori a 6 ore. La **regola delle 9 ore** estende questa logica:

> Se il dipendente ha lavorato ≥ 9 ore (540 min) **ed** ha usato meno di 30 min di pausa pranzo, vengono aggiunti automaticamente 30 min di pausa pranzo d'ufficio.

Questo abbassa il netto lavorato ma garantisce la compliance contrattuale.

### 1.3 Maggior presenza

**Maggior presenza** = ore lavorate *in eccesso* rispetto all'orario contrattuale standard, *indipendentemente dall'autorizzazione formale* a straordinario.

È distinta dallo **straordinario autorizzato**:

| Istituto | Richiede autorizzazione | Come viene compensato |
|---|---|---|
| **Straordinario autorizzato** | Sì (preventiva, capo ufficio) | Busta paga (SLI) o Banca Ore (SBO) |
| **Maggior presenza** | No (lavoro spontaneo) | Dipende dall'accordo: spesso liquidabile come SLI o accumulabile come SBO — fino a soglia definita |

Nel portale PA la maggior presenza appare come voce separata (`maggior_presenza`). Finché non viene formalmente "liquidata" o assegnata a SBO, rimane come debito del datore verso il dipendente.

> **Alert**: il portale genera un avviso amber quando la maggior presenza supera le **8 ore** — indica un eccesso non liquidato che rischia di scadere o non essere riconosciuto.

### 1.4 Straordinari: SLI vs SBO

| Sigla | Nome | Meccanismo |
|---|---|---|
| **SLI** | Straordinario Liquidato Immediatamente | Pagato nella busta paga del mese corrente o del mese successivo |
| **SBO** | Straordinario Banca Ore | Accantonato nella banca ore; il dipendente lo consuma come riposo compensativo |

Entrambi contribuiscono al contatore `straordinarioAutorizzato` del portale. Il totale mensile liquidabile è soggetto al **tetto straordinari** configurato nel profilo utente (`monthlyOvertimeHours`).

### 1.5 Label "Art.9" — due contatori storici da riallineare

Il nome "Art.9" e' usato in app e in alcuni dati portale per due concetti
operativi spesso confusi. Non va pero' letto come riferimento diretto
all'Art. 9 del CCNL PCM 2016-2018:

#### A) Permessi brevi (CCNL PCM Art. 35)
- Uscite brevi durante la giornata lavorativa (es. visita medica, commissione personale).
- Il tempo assente è **recuperabile** entro il mese.
- Tetto mensile configurabile dall'utente (`monthlyArt9Hours`):
  - Ruolo: 8h/mese
  - Comando: 17h/mese
- In Chigio Time: tracciato come `leavePauseMins` / `totalLeavePauseMins` (campo separato da `standardPauseMins`).

#### B) Protrazioni Art.9 (label portale/accordi integrativi)
- Il dipendente rimane in servizio **oltre** l'orario di fine turno su richiesta del superiore.
- Non è straordinario formale, ma viene contabilizzato a parte.
- Nel portale: `protrazioni_art9_effettuate` e `protrazioni_art9_da_recuperare`.
- In Chigio Time: attualmente solo visibile dal portale (non calcolato localmente).

### 1.6 Ore Perse (OP)

Giorni in cui `netWorkedMins < standardWorkMins` generano un **deficit**:

```
orePerse += (standardWorkMins − netWorkedMins)   solo se negativo
```

Il deficit può derivare da:
- Uscita anticipata non giustificata
- Permesso breve (Art. 9) non completamente recuperato
- Inserimento manuale retroattivo con orari sottostimati

Il portale traccia questo sotto `ore_non_recuperate` (debiti da recuperare) e `ore_perse` (ore perse non recuperabili).

### 1.7 Buono pasto

Il buono pasto è maturato quando il **netto lavorato** nella giornata raggiunge la soglia configurata:

| Parametro | Default | Configurabile |
|---|---|---|
| `mealVoucherThresholdMins` | 380 min (6h 20m) | Sì, da profilo |

Per le giornate **smart working** il buono è automaticamente maturato (si assume che il dipendente abbia lavorato `stdMins`).

---

## 2. Implementazione in Chigio Time

### 2.1 Configurazione utente (`UserProfile`)

I parametri contrattuali vivono nel documento Firestore `users/{uid}`:

| Campo | Tipo | Significato |
|---|---|---|
| `standardDailyMins` | `int` | minuti contratto/giorno (456 o 432) |
| `mealVoucherThresholdMins` | `int` | soglia buono pasto (default 380) |
| `monthlyArt9Hours` | `int` | cap mensile permessi brevi Art. 9 |
| `monthlyOvertimeHours` | `int` | cap mensile straordinari (SLI+SBO) |
| `monthlySliHours` | `int` | cap SLI specifico (default 0 = no cap) |
| `monthlySboHours` | `int` | cap SBO specifico (default 0 = no cap) |

Provider: `userProfileStreamProvider` — stream Firestore realtime.

I valori pre-impostati da onboarding:

```dart
// onboarding_provider.dart
switch (employmentType) {
  case 'Ruolo':
    standardDailyHours = Duration(hours: 7, minutes: 36);  // 456 min
    mealVoucherThreshold = Duration(hours: 6, minutes: 20); // 380 min
    monthlyArt9Hours = 8;
  case 'Comando':
    standardDailyHours = Duration(hours: 7, minutes: 12);   // 432 min
    mealVoucherThreshold = Duration(hours: 6, minutes: 20);
    monthlyArt9Hours = 17;
}
```

---

### 2.2 Timer attivo (`WorkTimer` / `TimerState`)

File: `lib/features/dashboard/presentation/timer_provider.dart`

#### Stato del timer

```dart
class TimerState {
  final WorkState status;           // notStarted | working | paused | completed
  final DateTime? startTime;        // orario entrata effettiva
  final int totalStandardPauseMins; // pause brevi/caffè (PauseType.short)
  final int totalLeavePauseMins;    // permessi brevi Art. 9 (PauseType.leave)
  final int totalLunchPauseMins;    // pausa pranzo (PauseType.lunch)
  final int standardWorkMins;       // da UserProfile.standardDailyMins
  // ...
}
```

#### Uscita prevista (getter `expectedExitTime`)

```dart
int minsToAdd = standardWorkMins
              + totalStandardPauseMins
              + totalLeavePauseMins
              + totalLunchPauseMins;

// Regola 9 ore: se workedSoFar ≥ 540 e lunch < 30 → +30 min automatici
if (totalLunchPauseMins < 30) {
  final workedSoFar = currentTime.difference(startTime!)
      - totalStandardPauseMins - totalLeavePauseMins;
  if (workedSoFar.inMinutes >= 540) minsToAdd += 30;
}

expectedExitTime = startTime! + Duration(minutes: minsToAdd);
```

#### Persistenza cross-device

Il timer si sincronizza su due livelli:

| Livello | Meccanismo | Scope |
|---|---|---|
| **Locale** | `SharedPreferences` | solo dispositivo corrente — sopravvive ai riavvii della stessa sessione giornaliera |
| **Remoto** | Firestore `users/{uid}/activeTimer/state` | cross-device — dispositivo B carica lo stato dal doc Firestore e rimane in sync via `snapshots()` listener |

Priorità di ripristino al boot: SharedPreferences (più veloce) → Firestore (fallback cross-device).

---

### 2.3 Consolidamento del turno (`endTurn` → `DailyTimesheet`)

Quando l'utente preme "Timbra Uscita":

```dart
Future<void> endTurn(DateTime endTime) async {
  final totalElapsedMins = endTime.difference(startTime!).inMinutes;

  // Regola 9 ore (consolidamento)
  int finalLunchMins = totalLunchPauseMins;
  if (finalLunchMins < 30) {
    final workedSoFar = totalElapsedMins
        - totalStandardPauseMins - totalLeavePauseMins;
    if (workedSoFar >= 540) finalLunchMins += 30;
  }

  final netWorkedMins = totalElapsedMins
      - totalStandardPauseMins
      - totalLeavePauseMins
      - finalLunchMins;

  final extraMins = netWorkedMins - standardWorkMins;
  // extraMins > 0 → straordinario / maggior presenza
  // extraMins < 0 → ore perse (deficit)
}
```

Il record `DailyTimesheet` viene scritto su Firestore con `workType = null` (= presenza normale). I campi `sliMins` e `sboMins` sono inizialmente 0; l'utente può redistribuire `extraMins` tra SLI/SBO nel Timesheet screen.

> **Nota**: oggi `endTurn` assegna l'intero `extraMins > 0` a `sboMins` by default.
> La redistribuzione SLI/SBO è delegata all'`_EntrySheet` del Timesheet.

---

### 2.4 Formula completa (riepilogo)

```
totalElapsedMins  = endTime − startTime

finalLunchMins    = totalLunchPauseMins
                  + (30  se workedSoFar ≥ 540 AND totalLunchPauseMins < 30)

netWorkedMins     = totalElapsedMins
                  − standardPauseMins   (pause brevi)
                  − leavePauseMins      (Art. 9 permessi)
                  − finalLunchMins      (pranzo, minimo 0)

extraMins         = netWorkedMins − standardWorkMins

mealEarned        = netWorkedMins ≥ mealVoucherThresholdMins
```

---

### 2.5 Entità `DailyTimesheet`

File: `lib/features/timesheet/domain/daily_timesheet.dart`

```dart
class DailyTimesheet {
  final String dateId;         // 'YYYY-MM-DD' — doc ID Firestore
  final DateTime startTime;
  final DateTime endTime;
  final int standardPauseMins; // pause brevi/caffè
  final int leavePauseMins;    // Art. 9 permessi brevi
  final int lunchPauseMins;    // pausa pranzo effettiva (post-regola 9h)
  final int netWorkedMins;     // netto effettivo
  final int extraMins;         // delta vs standard (neg = deficit, pos = extra)
  final int sliMins;           // parte extra destinata a SLI
  final int sboMins;           // parte extra destinata a SBO
  final String? workType;      // 'presence' | 'remote' | 'holiday' | 'leave'
  final String? note;
}
```

**Invarianti**:
- `sliMins + sboMins ≤ extraMins` (quando `extraMins > 0`)
- `leavePauseMins` non è incluso nel deficit: permessi brevi Art. 9 sono
  un istituto separato con proprio tetto mensile
- `workType = null` → retrocompatibilità (treat as `'presence'`)

---

### 2.6 Totalizzatori portale PA

File: `lib/features/dashboard/domain/totalizzatori.dart`

I dati del portale sono una vista *esterna* (non calcolata da Chigio Time).
Vengono importati via `portaleJson` nel documento Firestore dell'utente.

La sezione **STRAORDINARI** del portale comprende:

| Campo portale | Tipo | Significato |
|---|---|---|
| `maggior_presenza` | `HH:MM` | extra lavoro non formalizzato come straordinario autorizzato |
| `straordinario_autorizzato` | `HH:MM` | monte ore formalmente autorizzato (cap annuale) |
| `straordinari_liquidati` | `HH:MM` | già pagati in busta paga (SLI) |
| `straordinari_liquidabili` | `HH:MM` | approvati ma non ancora liquidati |
| `riposo_comp_maturato` | `HH:MM` | riposo compensativo maturato (da SBO) |
| `riposo_comp_residuo` | `HH:MM` | riposo compensativo non ancora fruito |
| `protrazioni_art9_effettuate` | `HH:MM` | protrazioni Art. 9 effettuate |
| `protrazioni_art9_da_recuperare` | `HH:MM` | protrazioni da recuperare come riposo |

**Relazione con i campi Chigio Time**:

```
DailyTimesheet.extraMins (positivo)
    ├── sboMins  →  contribuisce a Totalizzatori.riposo_comp_maturato
    ├── sliMins  →  contribuisce a Totalizzatori.straordinari_liquidati
    └── residuo  →  può confluire in Totalizzatori.maggior_presenza
                    (dipende dal workflow di approvazione dell'ente)
```

> **Importante**: Chigio Time è uno strumento *personale* di stima.
> I totalizzatori del portale sono l'unica fonte autoritativa per liquidazioni
> e banca ore. Le due basi di dati possono divergere per:
> - Ore non ancora elaborate dal sistema dell'ente
> - Straordinari rifiutati o decurtati dalla dirigenza
> - Aggiornamento batch (non realtime) del portale

---

### 2.7 Alert e soglie

| Alert | Condizione | Livello |
|---|---|---|
| Maggior presenza non liquidata | `maggiorPresenza > 8h` | 🟡 amber |
| Straordinari in sospeso | `autorizzato − liquidabili > 0` | 🟡 amber |
| Ore da recuperare | `oreNonRecuperate > 0` | 🔴 red |
| Ferie anno precedente | `ferieResiduoAP > 0` | 🟡 amber |
| Accumulo ferie alto | `ferieTotali > 30gg` | 🔴 red |

Alert calcolato in `Totalizzatori.activeAlerts` (getter).

---

### 2.8 Tipi di giornata e impatto su presenza/contatori

| `workType` | `netWorkedMins` | `extraMins` | Buono | Status pubblicato |
|---|---|---|---|---|
| `presence` | calcolato da timer | `net − std` | se `net ≥ threshold` | `working` → `paused` → `completed` |
| `remote` | `= standardDailyMins` | `0` | ✅ sempre | `remote` |
| `holiday` | `0` | `−stdMins` | ❌ | `holiday` |
| `leave` | `0` | `−stdMins` | ❌ | `leave` |

> Lo status pubblicato su `users/{uid}.currentStatus` permette ai colleghi
> di vedere chi è in ufficio, in smart working o assente (visualizzazione
> nel social screen + condizionamento dell'icona ☕).

---

## 3. Flussi utente

### Turno normale (presenza)

```
startTurn(t0)
  → status = working
  → SharedPreferences + Firestore activeTimer

[startPause(PauseType.lunch, t1) → endPause(t2)]   // pranzo
[startPause(PauseType.short, t3) → endPause(t4)]    // caffè
[startPause(PauseType.leave, t5) → endPause(t6)]    // permesso breve Art. 9

endTurn(tn)
  → calcola netWorkedMins, extraMins
  → DailyTimesheet.set(merge: true) su Firestore
  → clearTimerState() locale + Firestore
  → currentStatus = 'completed'
```

### Smart working (one-tap)

```
saveRemoteWorkDay(stdMins)
  → DailyTimesheet{workType: 'remote', netWorkedMins: stdMins}
  → batch: timesheets/{today} + users/{uid}.currentStatus = 'remote'
```

### Inserimento manuale retroattivo

```
_EntrySheet (Timesheet screen)
  → scegli data, tipo, orari
  → saveDailyTimesheet(entry)
  → se dateId == oggi AND workType != presence:
      batch: timesheets/{dateId} + users/{uid}.currentStatus = workType
```

---

## 4. Gap noti e TODO

| # | Gap | Impatto | Priorità |
|---|---|---|---|
| G-01 | `endTurn` assegna tutto `extraMins` a SBO; nessun flusso guidato per scelta SLI/SBO al momento della timbratura | L'utente deve correggere manualmente dal timesheet | Media |
| G-02 | `protrazioniArt9` non calcolate localmente — solo visibili dal portale | Non è possibile un riepilogo locale completo | Bassa |
| G-03 | Totalizzatori portale sono inseriti/modificati manualmente in `portaleJson`; nessuna integrazione HTTP diretta | Dato può essere stale | Media |
| G-04 | Confronto consumi permessi app/portale solo informativo, senza reconciliation automatica | Divergenze da verificare manualmente | Media |
| G-05 | `maggiorPresenza` nel portale non viene riconciliata con `extraMins` Chigio Time | Divergenza numerica tra le due fonti | Bassa |
| G-06 | Nessun cap applicativo su SBO/SLI mensili durante `endTurn` — il cap è solo visualizzato nel widget contatori | Sovra-accumulazione silente | Media |

---

## 5. File chiave

| File | Responsabilità |
|---|---|
| `lib/features/dashboard/presentation/timer_provider.dart` | `WorkTimer`, `TimerState`, logica calcolo netto e uscita prevista |
| `lib/features/timesheet/domain/daily_timesheet.dart` | `DailyTimesheet`, `WorkType`, `toMap`, `fromMap` |
| `lib/features/timesheet/data/timesheet_repository.dart` | salvataggio Firestore + pubblicazione `currentStatus` |
| `lib/features/dashboard/domain/totalizzatori.dart` | `Totalizzatori`, `TotAlert`, logica alert |
| `lib/features/dashboard/presentation/totalizzatori_provider.dart` | provider portale (legge `portaleJson` da Firestore) |
| `lib/features/profile/data/profile_repository.dart` | `userProfileStreamProvider`, `updateCurrentStatus` |
| `lib/shared/widgets/monthly_summary_card.dart` | widget blu contatori Art.9 / SLI / SBO / OP |

---

_Creato: 2026-05-27 — documento iniziale completo_
