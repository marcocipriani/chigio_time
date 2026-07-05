# Glossario di dominio

Termini ricorrenti in `chigio_time`. Italiano per i concetti di dominio
(allineati al linguaggio del CCNL del settore pubblico), inglese per i
termini tecnici.

| Termine | Definizione |
|---|---|
| **Turno** | Intervallo di tempo lavorato in una giornata: dall'entrata all'uscita, al netto delle pause. |
| **Timbratura** | Evento puntuale di entrata o uscita. Nell'app si crea con TimePicker. |
| **DailyTimesheet** | Record consolidato della giornata, con `dateId` `YYYY-MM-DD`. Vedi [`entita/daily-timesheet.md`](./entita/daily-timesheet.md). |
| **Pausa pranzo (lunch)** | Pausa tipica con regola "minimo 30 minuti". |
| **Pausa breve (short)** | Pausa di durata libera, conta nel `totalStandardPauseMins`. |
| **Permesso (leave)** | Assenza temporanea durante il turno. Oggi e' un tipo generico da specializzare con una tassonomia assenze. |
| **Regola delle 9 ore** | Logica a 3 zone su `effectiveElapsed` (tempo totale − pause standard/leave): zona 1 < 540 min → nessuna pausa forzata; zona 2 540–569 min → pausa pranzo forzata = effectiveElapsed − 540; zona 3 ≥ 570 min (9h 30') → pausa pranzo forzata = 30 min. |
| **Buono pasto** | Maturato quando i minuti netti lavorati raggiungono `_mealMins` (default 380 min, 6h 20m). |
| **Standard daily mins** | Minuti di lavoro standard giornaliero. Default `_stdMins = 456` (7h 36m). Origine: `UserProfile.standardDailyMins`. |
| **Straordinario (extra)** | `netWorkedMins - standardWorkMins` quando positivo. |
| **Articolo 9 (maggior presenza)** | Istituto del CCNL: il dipendente puo' scegliere di protrarre l'orario facendo ore extra subito dopo l'orario standard, entro un cap mensile di 8h (ruolo) o 17h (comando). NON e' un permesso: i permessi brevi sono Art. 35. Vedi [`ccnl/articoli-app.md`](./ccnl/articoli-app.md). |
| **Permessi brevi (Art. 35 CCNL PCM)** | Permessi brevi a recupero: max meta' dell'orario giornaliero e max 38 ore annue, con recupero entro il mese successivo. |
| **Smart working** | Lavoro da remoto. Nel modello legacy `TimesheetEntry.isSmartWorking`. |
| **Ruolo** | Tipologia di impiego con orario standard 7h 36m (default Art. 9 = 8h). |
| **Comando** | Tipologia di impiego con orario standard 7h 12m (default Art. 9 = 17h). |
| **Smart exit** | "Uscita intelligente" prevista, calcolata in `TimerState.expectedExitTime`. |
| **Glass card / glass tile** | Componenti UI con effetto vetrato (blur + trasparenza). Vedono `lib/shared/widgets/glass_*`. |
| **Shell route** | Una `StatefulShellRoute.indexedStack` di `go_router`: contiene piu' branch che condividono la `MainShellScreen`. |
| **Branch** | Singola sezione della shell (dashboard, timesheet, social). |
| **ADR** | *Architecture Decision Record*, vedi [`decisioni/`](./decisioni/README.md). |
