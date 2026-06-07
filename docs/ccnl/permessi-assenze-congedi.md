# Permessi, assenze e congedi - modello personale

> Fonti: [`ccnl-pcm-2016-2018.md`](./ccnl-pcm-2016-2018.md) e
> [`ccnl-pcm-2019-2021.md`](./ccnl-pcm-2019-2021.md).
> Per gli articoli sostituiti dal nuovo contratto vedi
> [`confronto-2016-2018-2019-2021.md`](./confronto-2016-2018-2019-2021.md).
> Questo documento traduce gli istituti in una specifica prodotto per
> `chigio_time`.

## Perimetro

`chigio_time` e' un'app di gestione personale. Non sostituisce il portale PA,
non invia richieste, non gestisce autorizzazioni e non decide validita'
giuridiche. Il suo compito e':

- aiutare l'utente a registrare correttamente il tipo di assenza;
- mostrare residui personali e consumi stimati;
- produrre export leggibili per controllo personale;
- mantenere note minime e, se previsto in futuro, allegati locali o privati;
- segnalare incoerenze contabili, senza bloccare l'utente.

Fuori perimetro:

- stati `requested`, `approved`, `rejected`;
- workflow dirigente/ufficio personale;
- protocollazione, invio certificati o validazione ufficiale;
- scadenze amministrative vincolanti calcolate dall'app.

## Stato attuale

| Area | Stato app | Limite |
|---|---|---|
| Tipo giornata | `WorkType.presence`, `remote`, `leave`, `holiday` | `leave` copre troppi casi diversi. |
| Pause/permessi intra-giornata | `PauseType.leave`, `leavePauseMins` | Non distingue causale e plafond. |
| Ferie | `WorkType.holiday` + totalizzatori portale | Non c'e' maturazione personale. |
| Visite specialistiche | Residuo in `Totalizzatori.visitaSpecialisticaResiduo` | Non esiste un tipo giornata/ora dedicato. |
| Motivi personali/familiari | Residuo in `Totalizzatori.permMotiviPersonaliResiduo` | Non esiste fruizione oraria dedicata. |
| Malattia | Assente | Nessun periodo di assenza multi-giorno. |
| Congedi/aspettative | Assenti | Nessuna tassonomia. |

## Riferimenti aggiornati

| Istituto | Riferimento da usare | Nota per l'app |
|---|---|---|
| Permessi retribuiti | Art. 15 CCNL 2019-2021 | Sostituisce Art. 30 base. |
| Permessi orari motivi personali/familiari | Art. 16 CCNL 2019-2021 | Sostituisce Art. 31 base. |
| Visite, terapie, prestazioni specialistiche, esami | Art. 17 CCNL 2019-2021 | Sostituisce Art. 34 base; plafond 18h annue. |
| Malattia | Art. 18 CCNL 2019-2021 | Sostituisce Art. 36 base. |
| Gravi patologie e terapie salvavita | Art. 19 CCNL 2019-2021 | Sostituisce Art. 37 base. |
| Congedi donne vittime di violenza | Art. 20 CCNL 2019-2021 | Sostituisce Art. 33 base. |
| Age management, genitorialita', disabilita' | Art. 21 CCNL 2019-2021 | Nuovo focus da tradurre in note private/profilo. |
| Conoscenze e saperi | Art. 22 CCNL 2019-2021 | Nuovo focus su formazione digitale/upskilling. |
| Diritto allo studio | Art. 23 CCNL 2019-2021 | Sostituisce Art. 45 base; 150h/160h. |
| Formazione | Art. 24 CCNL 2019-2021 | Sostituisce Art. 50 base. |
| Welfare integrativo | Art. 25 CCNL 2019-2021 | Sostituisce Art. 79 base; fuori core timesheet. |
| Permessi brevi | Art. 35 base 2016-2018 | Non sostituito dal nuovo CCNL. |
| Permessi/congedi di legge | Art. 32 base 2016-2018 | Non sostituito; L. 104 e altre norme restano catalogo separato. |
| Infortuni, aspettative, congedi genitori, unioni civili | Art. 38-44, 46-48 base 2016-2018 | Non sostituiti direttamente, restano in backlog personale. |

## Modello consigliato

Mantenere `WorkType` semplice e aggiungere un dettaglio assenza separato.

```dart
class AbsenceKind {
  static const shortLeave = 'short_leave';
  static const personalFamilyHourly = 'personal_family_hourly';
  static const specialistVisit = 'specialist_visit';
  static const sickness = 'sickness';
  static const seriousPathologyTherapy = 'serious_pathology_therapy';
  static const workInjury = 'work_injury';
  static const paidExamCompetition = 'paid_exam_competition';
  static const bereavement = 'bereavement';
  static const marriage = 'marriage';
  static const law104 = 'law_104';
  static const bloodDonation = 'blood_donation';
  static const civicDuty = 'civic_duty';
  static const parentalLeave = 'parental_leave';
  static const childSickness = 'child_sickness';
  static const studyPermit = 'study_permit';
  static const trainingLeave = 'training_leave';
  static const trainingRecord = 'training_record';
  static const unpaidExpectation = 'unpaid_expectation';
  static const sensitiveLeave = 'sensitive_leave';
  static const militaryService = 'military_service';
}
```

Campi suggeriti su `DailyTimesheet` o su sotto-record `absence`:

| Campo | Tipo | Uso personale |
|---|---|---|
| `absenceKind` | `String?` | Causale specifica quando `workType == leave` o giornata non lavorata. |
| `absenceUnit` | `hourly` / `daily` / `period` | Permette ore, giorno intero o assenza multi-giorno. |
| `absenceMins` | `int` | Consumo orario stimato. |
| `absenceDays` | `double` | Consumo giornaliero stimato, anche frazionabile dove serve. |
| `periodStart` / `periodEnd` | `String?` | Range per malattia, congedi, aspettative. |
| `quotaYear` | `int` | Anno di riferimento dei contatori personali. |
| `countsAsSicknessPeriod` | `bool` | Flag personale per comporto malattia. |
| `sensitive` | `bool` | Nasconde label dettagliata in viste social/export rapidi. |
| `personalNote` | `String?` | Nota privata dell'utente. |
| `hasDocumentation` | `bool` | Solo promemoria personale: documento presente/non presente. |

Regola di prodotto: il calcolo deve essere utile anche se i dati portale sono
inseriti manualmente. I contatori app sono "stima personale"; i totalizzatori
portale rimangono il confronto.

Campi profilo facoltativi, non necessariamente su `DailyTimesheet`:

| Campo | Tipo | Uso personale |
|---|---|---|
| `quietHoursStart` / `quietHoursEnd` | `String?` | Preferenza notifiche collegata al diritto alla disconnessione: silenzia promemoria non urgenti fuori orario. |
| `studyPermitAnnualMins` | `int?` | Plafond personale studio, default 150h; 160h se l'utente imposta manualmente la condizione prevista. |
| `personalNeedsNote` | `String?` | Nota privata per flessibilita', genitorialita', disabilita' o accomodamenti. |
| `hideSensitiveAbsences` | `bool` | Oscura categorie sensibili in dashboard, social/export rapidi. |

## Tassonomia CCNL

### Permessi retribuiti giornalieri

| Art. | Kind | Unita' | Plafond utile | UI personale |
|---|---|---|---|---|
| 15 CCNL 2019-2021 | `paid_exam_competition` | Giorni | 8 giorni/anno | Giorno intero con contatore annuo. |
| 15 CCNL 2019-2021 | `bereavement` | Giorni | 3 giorni/evento | Giorno intero, campo evento opzionale. |
| 15 CCNL 2019-2021 | `marriage` | Giorni | 15 giorni consecutivi | Periodo multi-giorno, contatore evento. |

### Permessi orari e visite

| Art. | Kind | Unita' | Plafond utile | UI personale |
|---|---|---|---|---|
| 16 CCNL 2019-2021 | `personal_family_hourly` | Ore o giornata convenzionale | 18 ore/anno; giornata intera = 6 ore convenzionali | Picker durata, residuo annuo, incompatibilita' come warning. |
| 17 CCNL 2019-2021 | `specialist_visit` | Ore o giorno | 18 ore/anno; 6h20 = giornata convenzionale per comporto | Picker durata, include percorso, flag `hasDocumentation`. |
| 35 base 2016-2018 | `short_leave` | Ore | Max meta' orario giornaliero; 38 ore/anno | Usabile anche intra-giornata dal timer. |

### Permessi e congedi di legge

| Art. | Kind | Unita' | Plafond utile | UI personale |
|---|---|---|---|---|
| 32 base 2016-2018 | `law_104` | Giorni/ore | 3 giorni o 18 ore/mese | Contatore mensile, scelta ore/giorni. |
| 32 base 2016-2018 | `blood_donation` | Giorno/ore | Secondo norma specifica | Tipo dedicato senza calcolo automatico rigido. |
| 32 base 2016-2018 | `civicDuty` | Giorni | Secondo evento | Giorno intero, nota evento. |
| 48 base 2016-2018 | trasversale | N/A | N/A | Le relazioni familiari devono includere unione civile/convivenza ove rilevante. |

### Malattia, terapie, infortunio

| Art. | Kind | Unita' | Plafond utile | UI personale |
|---|---|---|---|---|
| 18 CCNL 2019-2021 | `sickness` | Periodo | 18 mesi nel triennio mobile, con eventuale estensione non retribuita | Range date, calcolo giorni calendario, contatore comporto personale. |
| 19 CCNL 2019-2021 | `serious_pathology_therapy` | Giorni/periodo | Esclusione dal comporto per terapia/ricovero/effetti collaterali | Flag esclusione comporto, privacy alta. |
| 38 base 2016-2018 | `work_injury` | Periodo | Fino a guarigione clinica | Separato da malattia ordinaria, non sommato al comporto ordinario. |

Per la malattia l'app deve essere molto prudente: mostrare "stima personale"
e permettere override manuale. Il conteggio ufficiale puo' dipendere da dati
non presenti nell'app.

### Congedi, aspettative, studio e formazione

| Art. | Kind | Unita' | Plafond utile | UI personale |
|---|---|---|---|---|
| 20 CCNL 2019-2021 | `sensitive_leave` | Ore/giorni/periodo | 90 giorni in 3 anni | Label neutra, privacy massima, export oscurabile. |
| 39 base 2016-2018 | `unpaid_expectation` | Periodo | 12 mesi in triennio | Range date, contatore personale. |
| 40 base 2016-2018 | `unpaid_expectation` con motivo `spouse_abroad` | Periodo | Durata situazione | Range date e nota. |
| 41 base 2016-2018 | `unpaid_expectation` con motivo specifico | Periodo | Variabile | Catalogo motivi: cariche, volontariato, dottorato, gravi motivi familiari. |
| 43 base 2016-2018 | `parental_leave` | Ore/giorni/periodo | Secondo normativa genitori | Range o ore; campo figlio opzionale e privato. |
| 43 base 2016-2018 | `child_sickness` | Giorni | Secondo normativa genitori | Range date, separato da malattia dipendente. |
| 44 base 2016-2018 | `sensitive_leave` con motivo `psychophysical_condition` | Ore/giorni | Permessi fino a 2 ore/giorno o misure dedicate | Label neutra e privacy alta. |
| 23 CCNL 2019-2021 | `study_permit` | Ore | 150 ore/anno; 160 ore per personale con disabilita' grave L. 104/1992 | Contatore annuo, corso/esame come nota. |
| 46 base 2016-2018 | `training_leave` | Periodo | Congedo formazione | Range date, nota corso. |
| 24 CCNL 2019-2021 | `training_record` | Ore/giorni o nota | Formazione organizzata dall'amministrazione come servizio; corsi non programmati annotabili | Storico personale corsi, competenze, certificazione finale. |
| 47 base 2016-2018 | `military_service` | Periodo | Durata richiamo | Range date, promemoria rientro manuale. |

### Profilo, disconnessione e welfare

| Art. | Concetto | UI personale |
|---|---|---|
| 7 CCNL 2019-2021 | Diritto alla disconnessione come materia di contrattazione integrativa | Preferenze `quietHours`, applicate a notifiche non urgenti. |
| 21 CCNL 2019-2021 | Age management, genitorialita', inclusione disabilita' | Note profilo private e filtri di privacy; nessun workflow. |
| 22 CCNL 2019-2021 | Conoscenze e saperi | Storico formazione digitale/upskilling se utile all'utente. |
| 25 CCNL 2019-2021 | Welfare integrativo | Eventuale sezione promemoria, fuori dal timesheet e dai calcoli presenze. |

## Priorita' prodotto

### P0 - Fondazione completata

- `DailyTimesheet` include `absenceKind`, `absenceUnit`, `absenceMins`,
  `absenceDays`, `periodStart`, `periodEnd`, `quotaYear`, `sensitive`,
  `personalNote`, `hasDocumentation`, `countsAsSicknessPeriod`.
- `_EntrySheet` mostra categorie raggruppate: Permessi orari,
  Malattia/salute, Ferie, Congedi, Studio/formazione, Altro.
- CSV import/export usa colonne `assenza_tipo`, `assenza_min`,
  `assenza_giorni`, `periodo_da`, `periodo_a`; l'export dettagliato include
  `riservata`.
- I riferimenti UI/documentazione usano i nuovi articoli CCNL 2019-2021 per
  gli istituti sostituiti, senza cambiare lo scope personale dell'app.

### P1 - Permessi piu' usati

- Confronto informativo gia' presente per `short_leave`,
  `personal_family_hourly`, `specialist_visit` e periodi `sickness`.
- Prossimo passo: backfill storico e rafforzamento calcolo comporto/residui.

### P2 - Giornate e famiglia

- `paid_exam_competition`, `bereavement`, `marriage`.
- `law_104`, `parental_leave`, `child_sickness`.
- Report mensile che separa ferie, permessi, malattia, visite e congedi.
- `study_permit` con 150h/160h e `training_record` per corsi personali.
- Preferenze `quietHours` per silenziare notifiche fuori orario.

### P3 - Istituti sensibili o rari

- `serious_pathology_therapy`, `work_injury`, `sensitive_leave`.
- `training_leave`, `unpaid_expectation`, `military_service`.
- Modalita' privacy: label neutra in dashboard/social/export veloce.

## Regole UI

- Il selettore tipo assenza deve usare label comprensibili, non solo riferimenti
  normativi.
- Le categorie sensibili devono poter apparire come "Assenza riservata".
- Le note non devono essere mostrate nelle viste social.
- I residui devono essere modificabili manualmente dall'utente.
- Se un contatore supera il plafond, mostrare warning informativo, non blocco.
- Export PDF/CSV deve poter includere o oscurare il dettaglio sensibile.

## Integrazione con totalizzatori

| Totalizzatore esistente | Collegamento futuro |
|---|---|
| `permessoBreveResiduo` | Confronto con consumo `short_leave`. |
| `permMotiviPersonaliResiduo` | Confronto con consumo `personal_family_hourly`. |
| `visitaSpecialisticaResiduo` | Confronto con consumo `specialist_visit`. |
| `ferieResidueTotali` | Confronto con `WorkType.holiday`. |
| `oreNonRecuperate` | Alert personale su deficit non coperto. |

Il portale resta sorgente di confronto, non di verita' assoluta dentro l'app.

_Ultima revisione: 2026-06-07 - aggiornata con P0 assenze completata e confronto consumi personali P1._
