# Articoli CCNL rilevanti per l'app

> Fonti: [`ccnl-pcm-2016-2018.md`](./ccnl-pcm-2016-2018.md) e
> [`ccnl-pcm-2019-2021.md`](./ccnl-pcm-2019-2021.md).
> Per la mappa degli articoli sostituiti vedi
> [`confronto-2016-2018-2019-2021.md`](./confronto-2016-2018-2019-2021.md).
> Questo file traduce il contratto in backlog di prodotto per gestione
> personale; non e' consulenza legale.

## Lettura rapida

Il CCNL PCM 2019-2021 aggiorna la base 2016-2018 in modo selettivo. Per
permessi, visite, malattia, gravi patologie, congedi riservati, diritto allo
studio, formazione e welfare usare i nuovi riferimenti 2019-2021; per gli
istituti non sostituiti resta valida la mappa della base precedente, se
compatibile.

Gia' sviluppato o ben avviato:

- orario giornaliero standard, timbratura entrata/uscita, uscita prevista e riepilogo mensile;
- pause, pausa pranzo minima e maturazione buono pasto;
- straordinario/maggior presenza con campi `extraMins`, `sliMins`, `sboMins`;
- banca ore come saldo da totalizzatori e uso intra-giornaliero BOE (`bancaOreMins`, `boeSlot`);
- ferie e permessi come tipi giornata generici;
- festivita' nazionali nel timesheet, con calendario italiano;
- totalizzatori portale per ferie, festivita' soppresse, banca ore, permessi, visite specialistiche e debiti.

Coperture parziali importanti:

- le assenze sono ancora troppo generiche: `WorkType.leave` non distingue permesso breve, motivi personali, visita specialistica, 104, lutto, matrimonio, studio, malattia, infortunio o congedi;
- manca un registro personale delle assenze con causale, durata, note e residui stimati;
- i contatori portale sono editabili e visualizzati, ma non sono ancora confrontati automaticamente con i consumi personali;
- per il dettaglio funzionale dei permessi mancanti vedi [`permessi-assenze-congedi.md`](./permessi-assenze-congedi.md).

Mancanze piu' rilevanti per sviluppo:

- assenze per malattia e periodo di comporto;
- visite, terapie, prestazioni specialistiche ed esami diagnostici con plafond e documentazione;
- permessi retribuiti e permessi orari per motivi personali/familiari;
- legge 104 e altri permessi/congedi di legge;
- studio, formazione personale, age management, genitorialita' e inclusione disabilita';
- preferenze di disconnessione/notifiche fuori orario, collegate al lavoro agile come contesto;
- turnazioni, reperibilita', lavoro notturno/festivo e maggiorazioni;
- ferie maturate/residue con regole annuali, prima assunzione, cinque/sei giorni e festivita' soppresse;
- congedi parentali, aspettative, studio/formazione e istituti sensibili.

## Aggiornamento CCNL 2019-2021

Questa tabella prevale sulla numerazione 2016-2018 quando l'articolo nuovo
dichiara di sostituire e disapplicare quello precedente.

| CCNL 2019-2021 | Base sostituita | Stato app | Adeguamento prodotto |
|---|---:|---|---|
| Art. 13 Reperibilita' | Art. 19 | Mancante | Evento personale `onCall`, chiamata, eventuale recupero/straordinario, riposo se festivo. Da fare dopo il registro assenze. |
| Art. 14 Attivita' non in turno | Art. 20 | Mancante | Giornata non lavorativa lavorata, classificazione festivo/riposo e scelta compenso/riposo come annotazione personale. |
| Art. 15 Permessi retribuiti | Art. 30 | Mancante | Causali `paidExamCompetition`, `bereavement`, `marriage`, con contatori evento/anno e note personali. |
| Art. 16 Permessi orari motivi personali/familiari | Art. 31 | Parziale | Collegare `permMotiviPersonaliResiduo` a consumi personali; durata minima 1h, giornata convenzionale e warning informativi. |
| Art. 17 Visite, terapie, prestazioni specialistiche, esami | Art. 34 | Parziale | Tipo dedicato `specialistVisit`, residuo annuo, tempi di percorrenza inclusi, flag documentazione e possibile imputazione a malattia. |
| Art. 18 Malattia | Art. 36 | Mancante | `sickness` multi-giorno, stima comporto su triennio mobile, giorni calendario e override manuale. |
| Art. 19 Gravi patologie e terapie salvavita | Art. 37 | Mancante | `seriousPathologyTherapy`, esclusione dal comporto come flag personale e privacy alta. |
| Art. 20 Congedi donne vittime di violenza | Art. 33 | Mancante | `sensitiveLeave` con label neutra, export oscurabile e nessun dettaglio obbligatorio. |
| Art. 21 Age management, genitorialita', disabilita' | Nuovo focus | Mancante | Note private profilo per esigenze ricorrenti, accomodamenti, flessibilita' e genitorialita'. |
| Art. 22 Conoscenze e saperi | Nuovo focus | Mancante | Registro leggero di formazione/upskilling se utile al profilo personale. |
| Art. 23 Diritto allo studio | Art. 45 | Mancante | `studyPermit`, contatore 150h annue e 160h per disabilita' grave L. 104/1992. |
| Art. 24 Formazione | Art. 50 | Mancante | Storico formazione personale, corsi obbligatori/facoltativi, certificazioni e corsi non programmati come nota. |
| Art. 25 Welfare integrativo | Art. 79 | Fuori core | Eventuale scheda promemoria personale; non serve nel timesheet. |
| Art. 7 Diritto alla disconnessione come materia integrativa | Art. 7 | Parziale indiretto | L'app ha notifiche uscita; aggiungere `quietHours` per silenziare notifiche non urgenti fuori orario. |

## Stato implementativo sintetico

| Modulo | Copertura reale | Gap rispetto al CCNL aggiornato |
|---|---|---|
| `DailyTimesheet` | Presenza/remoto/permesso/ferie, minuti pausa, lavoro netto, extra, SLI/SBO, BOE, **`absenceKind`/`absenceUnit`/`absenceMins`/`absenceDays`/`periodStart`/`periodEnd`/`quotaYear`/`sensitive`/`personalNote`/`hasDocumentation`/`countsAsSicknessPeriod`** (P0 fondazione, vedi `AbsenceKind`). | Tassonomia presente in scrittura/UI/CSV; manca backfill euristico sulle entries storiche pre-P0 (vedi backlog "Backfill assenze storiche"). |
| `Totalizzatori` | Ferie, banca ore, permesso breve, motivi personali, visite, ore non recuperate. **`AbsenceConsumption`/`personalAbsenceConsumptionProvider`** (P1): confronto "App: Xh su plafond" per `short_leave`/`personal_family_hourly`/`specialist_visit` (38h/18h/18h annui) e periodi `sickness` multi-giorno raggruppati, mostrati in `TotalizzatoriSection`. | Confronto solo informativo lato app (no sync bidirezionale); mancano `paid_exam_competition`/`bereavement`/`marriage`/`law_104`/`parental_leave`/`child_sickness`/`study_permit` (P2) e istituti sensibili P3. |
| `Profile` | Orario standard, soglia buono pasto, limiti mensili, sede/dipartimento, notifiche uscita. | Mancano quiet hours, preferenze private per studio/disabilita'/genitorialita'. |
| `Timer` | Pause, permesso breve generico, notifica uscita, BOE. | Non distingue causali CCNL orarie diverse da `PauseType.leave`. |
| `Timesheet export/import` | CSV semplice/dettagliato e import con colonne `assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a`, oscuramento causale/periodo/nota per `sensitive` su entrambi i CSV, PDF con tipo giornata e note. | Manca oscuramento sensibile nell'export PDF; manca confronto consumi/totalizzatori. |

## Mappa per articolo

La sezione seguente conserva la base 2016-2018 per gli istituti dell'orario,
ferie, permessi brevi, aspettative e congedi non sostituiti direttamente dal
CCNL 2019-2021.

### Capo II - Istituti dell'orario di lavoro

| Art. | Concetto per l'app | Stato | Evidenza attuale | Gap principale |
|---|---|---|---|---|
| 17 Orario di lavoro | 38 ore settimanali, media 48 ore incl. straordinario, articolazione su 5/6 giorni, riposo 11 ore, assenze intera giornata non in ore. | Parziale | `standardDailyMins`, orario settimanale, timer e monthly summary. | Validare monte ore settimanale/periodale, riposo 11 ore, media 48 ore su 6 mesi e regola sulle assenze intere. |
| 18 Turnazioni | Rotazione ciclica, turni notturni/festivi, limiti, indennita', esoneri per situazioni personali. | Mancante | Nessun calendario turni. | Modello `ShiftSchedule`, classificazione notturno/festivo e regole di esclusione. |
| 19 Reperibilita' | Periodi max 12 ore, chiamata entro 60 minuti, compenso/recupero, limiti mensili, riposo se festivo. | Sostituito | Vedi Art. 13 CCNL 2019-2021. | Modello reperibilita', chiamata in servizio e conversione in straordinario/riposo. |
| 20 Attivita' non in turno | Prestazioni su riposo settimanale, festivo infrasettimanale, feriale non lavorativo, maggiorazioni. | Sostituito | Vedi Art. 14 CCNL 2019-2021. | Gestire giornate non lavorative lavorate e scelta compenso/riposo. |
| 21 Orario multiperiodale | Calendari plurisettimanali/annuali con settimane sopra/sotto 38 ore. | Mancante | Totali mensili semplici. | Motore calendario multi-periodo e verifica media. |
| 22 Pausa | Pausa minima 30 minuti oltre 6 ore continuative, eccezioni per continuita' servizio, pause piu' ampie per casi specifici. | Parziale | `PauseType.lunch`, `lunchPauseMins`, regola pausa in timer. | Soglia oltre 6 ore, eccezioni servizio continuo e pause personalizzate per casi Art. 25. |
| 23 Rilevazione orario e ritardi | Controlli automatici, trasferte tra sede e luogo prestazione come lavoro, recupero ritardi entro mese successivo. | Parziale | Time picker, GPS prompt, timesheet. | Registro personale ritardi/recuperi e conteggio percorrenze di servizio come orario lavorato. |
| 24 Straordinario e riposi compensativi | Straordinario, maggiorazioni 15/30/50%, riposo compensativo. | Parziale | `extraMins`, `sliMins`, `sboMins`, `BancaOreTile`, `MonthlySummaryCard`. | Causale personale, notturno/festivo e confronto con totalizzatori. |

### Capo III - Conciliazione vita-lavoro

| Art. | Concetto per l'app | Stato | Evidenza attuale | Gap principale |
|---|---|---|---|---|
| 25 Orario flessibile | Fasce flessibili entrata/uscita, debito da recuperare nel mese successivo, priorita' per situazioni personali. | Parziale | Entrata/uscita scelte dall'utente e orario personalizzato. | Fasce configurabili, debito mensile e note personali sul regime flessibile. |
| 26 Banca delle ore | Conto individuale, ore straordinario/supplementare, fruizione a ore/giornate. | Parziale avanzato | `Totalizzatori`, `bancaOreMins`, `boeSlot`, `sboMins`, `BancaOreTile`. | Confronto personale tra saldo portale, SBO maturato e BOE consumato. |

### Capo IV - Ferie e festivita'

| Art. | Concetto per l'app | Stato | Evidenza attuale | Gap principale |
|---|---|---|---|---|
| 27 Ferie e festivita' soppresse | 26/28/30/32 giorni, 4 riposi L. 937/77, maturazione pro-rata, divieto ferie a ore, carry-over e monetizzazione. | Parziale | `WorkType.holiday`, totalizzatori ferie/festivita' soppresse. | Maturazione personale, residui AP/AC e controllo fruizione a ore. |
| 28 Festivita' | Domeniche, festivita' civili, Santo Patrono della localita', riposo settimanale, riposo sabbatico. | Parziale | `ItalianHolidays` con festivita' nazionali. | Verificare Santo Patrono della sede: oggi il codice include 21/04 "Natale di Roma", mentre per Roma il patrono civile e' normalmente il 29/06. Mancano turnisti e riposo sabbatico. |
| 29 Ferie e riposi solidali | Cessione volontaria di ferie/riposi a colleghi per assistenza figli minori con cure costanti. | Mancante | Nessun tracciamento. | Registro personale di giorni ceduti/ricevuti, se l'utente vuole annotarli. |

### Capo V - Permessi, assenze e congedi

| Art. | Concetto per l'app | Stato | Evidenza attuale | Gap principale |
|---|---|---|---|---|
| 30 Permessi retribuiti | Concorsi/esami 8 giorni anno, lutto 3 giorni evento, matrimonio 15 giorni. | Sostituito | Vedi Art. 15 CCNL 2019-2021. | Tipi permesso giornalieri con plafond, evento e nota personale. |
| 31 Permessi orari motivi personali/familiari | 18 ore anno, minimo 1 ora, incompatibilita' con altri permessi orari/riposi, giornata convenzionale 6 ore. | Sostituito/parziale | Vedi Art. 16 CCNL 2019-2021; residuo in `Totalizzatori.permMotiviPersonaliResiduo`. | Fruizione oraria reale, regole di compatibilita' e conversione giornata. |
| 32 Permessi e congedi di legge | Legge 104 3 giorni/18 ore mese, donatori, giudice popolare e altri istituti. | Mancante | Nessuna tassonomia. | Plafond mensili/annuali e note personali. |
| 33 Congedi donne vittime di violenza | Congedo max 90 giorni in 3 anni, orario/giornaliero, privacy, part-time/trasferimento. | Sostituito | Vedi Art. 20 CCNL 2019-2021. | Categoria riservata con label neutra e dati minimi. |
| 34 Visite, terapie, prestazioni specialistiche, esami | Permessi annui incluse percorrenze, anche giornaliero, assimilazione malattia per comporto, attestazioni. | Sostituito/parziale | Vedi Art. 17 CCNL 2019-2021; residuo `visitaSpecialisticaResiduo`, template CSV con nota visita medica. | Tipo assenza dedicato, campo documentazione presente, conversione 6h20 e interazione con malattia. |
| 35 Permessi brevi | Max meta' orario giornaliero e 38 ore annue, recupero entro mese successivo. | Parziale | `PauseType.leave`, `leavePauseMins`, contatori "Art.9". | Plafond personale 38h e collegamento con deficit/recuperi. |
| 36 Assenze per malattia | Conservazione posto 18 mesi in triennio, eventuali altri 18, fasce economiche, comunicazione, reperibilita', certificati. | Sostituito | Vedi Art. 18 CCNL 2019-2021. | Modello malattia, periodo di comporto stimato, giorni calendario, domicilio/note e alert soglie. |
| 37 Gravi patologie e terapie salvavita | Esclusione dal comporto per ricoveri/day hospital/terapie/effetti collaterali, piena retribuzione, certificazioni. | Sostituito | Vedi Art. 19 CCNL 2019-2021. | Sottotipo malattia protetto con esclusione comporto e calendario terapie. |
| 38 Infortuni e causa di servizio | Conservazione fino a guarigione clinica, piena retribuzione, non cumulabilita' con comporto malattia. | Mancante | Nessun sottotipo. | Tipo assenza separato da malattia e logica comporto dedicata. |
| 39 Aspettative | Aspettativa non retribuita per esigenze personali/familiari, 12 mesi in triennio, frazionabile. | Mancante | Nessun registro personale. | Range date e contatore triennale stimato. |
| 40 Ricongiungimento con coniuge all'estero | Aspettativa senza assegni per coniuge in servizio all'estero. | Mancante | Nessun registro personale. | Sottotipo aspettativa con motivo. |
| 41 Altre aspettative di legge | Cariche elettive, cooperazione, volontariato, dottorato/borse, gravi motivi familiari. | Mancante | Nessun registro personale. | Catalogo motivi e range date. |
| 42 Norme comuni aspettative | Intervalli minimi di servizio attivo, rientro, risoluzione se mancato rientro. | Mancante | Nessun registro personale. | Note informative, senza enforcement amministrativo. |
| 43 Congedi dei genitori | Maternita'/paternita', congedo parentale, malattia figlio, fruizione oraria. | Mancante | Nessun registro personale. | Tipi congedo parentale, range e calcolo giorni/ore. |
| 44 Condizioni psicofisiche particolari | Progetti terapeutici, permessi fino a 2 ore, riduzione orario, aspettativa familiari. | Mancante | Nessun istituto sensibile. | Modello accomodamenti con dati minimi e privacy forte. |
| 45 Diritto allo studio | 150 ore anno, limite 3% personale, priorita', no obbligo straordinario/festivo. | Sostituito | Vedi Art. 23 CCNL 2019-2021. | Plafond personale 150h/160h e nota corso/esame. |
| 46 Congedi per formazione | Congedi per formazione, anzianita' 5 anni, limite 10%, domanda 30 giorni, possibile differimento. | Mancante | Nessun registro personale. | Range date e nota corso. |
| 47 Servizio militare | Conservazione posto e termini di rientro dopo richiamo. | Mancante | Nessun registro personale. | Tipo assenza raro con range date. |
| 48 Unioni civili | Estensione delle tutele riferite a matrimonio/coniuge alle parti dell'unione civile. | Trasversale mancante | Nessun modello familiare. | Quando si implementano permessi familiari, usare relazioni inclusive e non solo "coniuge". |

## Backlog consigliato

1. Completare il backfill storico delle entries `leave`/`holiday` con la nuova tassonomia `absenceKind` gia' presente nel modello e nella UI.
2. Rafforzare malattia come periodo multi-giorno usando Art. 18 e 19 CCNL 2019-2021: comporto stimato, giorni calendario, gravi patologie e alert soglie.
3. Rendere ferie/festivita' un motore personale: maturazione, spettanza, residui AP/AC, festivita' soppresse e blocco informativo sulla fruizione a ore.
4. Estendere il confronto consumi personali/totalizzatori a ferie, banca ore e ulteriori causali oltre permessi brevi, motivi personali/familiari e visite specialistiche.
5. Aggiungere studio/formazione e profilo personale evoluto: Art. 21, 22, 23 e 24 CCNL 2019-2021.
6. Aggiungere calendari avanzati solo dopo il motore assenze: turnazioni, reperibilita', multiperiodale, notturno/festivo e maggiorazioni.
7. Usare [`permessi-assenze-congedi.md`](./permessi-assenze-congedi.md) come specifica per le prossime storie.

_Ultima revisione: 2026-06-07 - integrato aggiornamento CCNL PCM 2019-2021, P0 assenze e confronto consumi personali._
