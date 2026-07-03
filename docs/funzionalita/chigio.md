# Feature: Chigio — la tartaruga mascotte 🐢

## Chi è Chigio?

Chigio è la **tartaruga mascotte** di Chigio Time. Lenta per natura, ma precisa e affidabile come il cronometro che sorregge. Compare nell'app in due contesti:

1. **Header globale** — avatar tondeggiante (42px), label breve e frase contestuale. Al tap sull'area Chigio cambia frase immediatamente.
2. **Schermata `/chigio`** — galleria interattiva degli avatar, accessibile da Profilo → Chigio.

---

## File coinvolti

| Path | Ruolo |
|---|---|
| `lib/shared/widgets/glass_header.dart` | Area Chigio in header: avatar animato, label, frase contestuale e tap per nuova frase |
| `lib/core/services/chigio_phrase_engine.dart` | `ChigioContext`, selezione contestuale della frase, seed temporale, sostituzioni e priorità dei pool |
| `lib/core/constants/chigio_quotes.dart` | Libreria dedicata delle quote, etichette brevi e alias asset |
| `test/core/services/chigio_phrase_engine_test.dart` | Audit automatico su genere, ora, Dipartimento, sede, milestone turno e budget header |
| `lib/features/chigio/presentation/chigio_screen.dart` | Galleria interattiva avatar |
| `lib/core/constants/app_strings.dart` | `chigioImages`, `chigioLabels`, `chigioVisit`, `chigioSubtitle` |
| `assets/images/chigio-*.png` + `app_icon.png` | Asset immagini |

---

## Frasi contestuali

Le quote vivono in `ChigioQuotes`, mentre `ChigioPhraseEngine` sceglie quale mostrare in base a:

| Parametro | Valori |
|---|---|
| `ChigioPage` | `dashboard`, `timesheet`, `social`, `profile`, `stats`, `other` |
| `ChigioShiftState` | `notStarted`, `working`, `paused`, `completed`, `abandoned` |
| Ora del giorno | mattina 05:00–12:59, pomeriggio 13:00–17:59, sera/notte 18:00–04:59 |
| `firstName` | nome utente dal profilo |
| `gender` | `M`, `F`, `A` (`ə`), `N` (forma neutra naturale) |
| `department` | Dipartimento/ufficio dal profilo, compattato prima di entrare nelle frasi |
| `site` | sede PCM dal profilo, compattata prima di entrare nelle frasi |
| `dayType` | `presence`, `remote`, `leave`, `holiday`, `unknown` |
| `workedMins` / `remainingMins` | minuti netti lavorati e minuti stimati all'uscita, se il timer è attivo |
| `standardWorkMins` / `mealVoucherThresholdMins` | soglie personali da profilo/timer |
| `weekday` | derivato da `now`, usato per lunedì/venerdì |

Le frasi ruotano ogni **5 minuti** (seed = `hour × 12 + minute ÷ 5`). Il tap
sull'area Chigio incrementa il seed e forza la frase successiva.

Placeholder disponibili:

- `{n}` nome;
- `{dep}` Dipartimento compatto;
- `{site}` sede compatta;
- `{remaining}` minuti rimanenti formattati;
- `{worked}` minuti lavorati formattati;
- `{weekday}` giorno della settimana.

Sulle pagine principali, ogni quarto seed può usare una frase dedicata al
Dipartimento se il profilo lo contiene. In dashboard queste frasi non
sovrascrivono gli stati `paused`, `completed` o `abandoned`, perché lì conta di
più il contesto del turno. Il nome viene accorciato prima della sostituzione:
esempi `Dipartimento per la trasformazione digitale` → `Trasformazione
digitale`, `Ufficio del bilancio e per il riscontro...` → `Bilancio e
riscontro`, `Struttura di missione PNRR` → `PNRR`.

### Regole editoriali header

- Frasi pensate per massimo **2 righe** nell'header mobile.
- Testo breve, niente spiegazioni funzionali o istruzioni operative.
- Etichette da tenere molto corte: una o due parole.
- Evitare doppioni: se due frasi hanno lo stesso ritmo o la stessa battuta, tenerne una sola.
- I marker di genere supportano quattro alternative: `{M|F|A|N}`. La forma
  `N` deve essere leggibile in italiano, non un residuo tipo `o/a`.
- Il test automatico verifica che non restino marker `{...}`, che la label non
  superi 17 caratteri e che la frase generata resti entro il budget header.

### Bank di frasi per contesto

| Contesto | Pool | Uso |
|---|---|---|
| Dashboard – mattina, non iniziato | `ChigioQuotes.morningNotStarted` | Prima timbratura |
| Dashboard – lavorando | `morningWorking` · `afternoonWorking` · `eveningWorking` | Turno attivo per fascia oraria |
| Dashboard/Profile/etc. con Dipartimento | `departmentMorning` · `departmentAfternoon` · `departmentEvening` | Frase istituzionale breve con `{dep}` |
| Sede PCM | `siteMorning` · `siteAfternoon` · `siteEvening` | Frase breve con `{site}` |
| Milestone turno | `mealVoucher` · `finalHour` · `exitSoon` · `overtime` | Buono pasto, ultima ora, uscita vicina, straordinario |
| Tipo giornata | `remoteDay` · `leaveDay` · `holidayDay` | Smart working, assenza/permesso, ferie |
| Giorno settimana | `monday` · `friday` | Tono speciale per inizio/fine settimana |
| Motivazionali | `motivational` | Frasi firma non legate a una pagina specifica |
| Dashboard – in pausa | `paused` | Pausa in corso |
| Dashboard – completato | `completed` | Turno chiuso |
| Dashboard – abbandonato | `abandoned` | Turno rimasto aperto |
| Timesheet | `timesheet` | Storico cartellino |
| Social | `social` | Colleghi e inviti caffè |
| Profilo | `profile` | Profilo e impostazioni personali |
| Statistiche | `stats` | Riepiloghi e grafici |

### API

```dart
final data = ChigioPhraseEngine.resolveContext(
  ChigioContext(
    page: ChigioPage.dashboard,
    firstName: 'Marco',
    shiftState: ChigioShiftState.working,
    gender: 'M',
    department: 'Dipartimento per la trasformazione digitale',
    site: 'Palazzo Chigi',
    workedMins: 390,
    remainingMins: 66,
    standardWorkMins: 456,
    mealVoucherThresholdMins: 380,
  ),
);
// data.phrase  → frase personalizzata, pronta da mostrare
// data.image   → path asset avatar (es. 'assets/images/chigio-ok.png')
// data.label   → etichetta breve (es. 'Bravo!')
```

---

## GlassHeader — area Chigio

`_ChigioAvatar` — avatar 42×42px con **pulse animation** (scale 0.96↔1.04, 1.6s ease-in-out, `repeat(reverse: true)`).

La parte sinistra dell'header è composta da:

- avatar contestuale;
- label chip breve (`maxLabel` audit: 17 caratteri con nome lungo);
- frase italic contestuale (`maxPhrase` audit automatico: 76 caratteri con
  "Alessandro" e Dipartimento lungo);
- tap sull'area → incrementa il seed locale e cambia frase.

`chigioPage` si passa come parametro a `GlassHeader`:
```dart
GlassHeader(chigioPage: ChigioPage.timesheet)
```

Pagine cablate: `dashboard`, `timesheet`, `social`, `profile`, `stats`. Altre pagine: default `ChigioPage.other` → usa il pool dashboard coerente con stato e fascia oraria.

---

## Avatar esistenti (6 + app icon)

| File | Emozione | Usata in |
|---|---|---|
| `chigio-ciao.png` | Saluto, benvenuto | Mattina, profilo, social |
| `chigio-ok.png` | Approvazione, successo | Working, completed |
| `chigio-orologio.png` | Puntualità, orario | Not started, abandoned |
| `chigio-calcolatrice.png` | Calcolo, analisi | Stats, timesheet |
| `chigio-caffe.png` | Pausa, socialità | Pause, social |
| `chigio-sonno.png` | Stanchezza, sera tardi | Evening working |
| `app_icon.png` | Firma Chigio | Alias semantici senza asset dedicato |

---

## Proposte nuovi avatar 🎨

| File proposto | Pose/situazione | Contesto d'uso |
|---|---|---|
| `chigio-corsa.png` | Tartaruga che "corre" con valigia | Dashboard – mattina tardiva, entrata in ritardo |
| `chigio-spiaggia.png` | In spiaggia con ombrellone e cocktail | Ferie registrate, giornata holiday |
| `chigio-computer.png` | Davanti a laptop con cuffie | Smart working / remoto |
| `chigio-champagne.png` | Flute di champagne | Turno completato con record, traguardo mensile |
| `chigio-pensiero.png` | Fumetto "?" sulla testa | Turno abbandonato, stato incerto |
| `chigio-lente.png` | Lente d'ingrandimento | Statistiche avanzate, audit timesheet |
| `chigio-ombrello.png` | Ombrello aperto sotto la pioggia | Permesso / Art. 9 registrato |
| `chigio-sole.png` | Testa fuori dal guscio, sole pieno | Primo accesso del giorno, buon umore |
| `chigio-trofeo.png` | Regge un trofeo dorato | Obiettivo mensile raggiunto |
| `chigio-banca.png` | Sacchetto di monete | Banca ore positiva |

**Stile:** palette coerente con blu PCM `#0055A5` e verde tartaruga. PNG 512×512, sfondo trasparente.

---

## Schermata `/chigio` — galleria

`chigio_screen.dart` — swipe orizzontale o tap per ciclare tra gli avatar disponibili.

- **Bounce**: `TweenSequence` scale 1.0→1.14→0.92→1.0 in 320ms.
- **Transizione**: `AnimatedSwitcher` fade+scale.
- **Dot indicator**: pill 18px (attivo) / 6px (inattivo).

---

## Tono di voce

Chigio parla in prima persona, in italiano, con tono **caloroso e ironico** ma
mai sarcastico. Si rivolge spesso all'utente per nome e fa emergere una
personalità riconoscibile: calma istituzionale, precisione gentile, affetto da
scrivania e orgoglio di guscio.

Le frasi più riuscite devono sembrare piccole firme di Chigio, non messaggi di
sistema. Esempi di direzione:

- “Lento per natura, puntuale per missione.”
- “Guscio stabile, rotta chiara.”
- “Chigio misura. Tu fai succedere le cose.”
- “Il cartellino parla piano, ma dice tutto.”

**✅ DO:** "Dai Marco, anche le tartarughe arrivano puntuali! ⏰"
**❌ DON'T:** "Promemoria: timbrare entro le 09:00."

---

## Routing

| Path | Accesso |
|---|---|
| `/chigio` | Profilo → "Chigio 🐢" |

---

## Design system e prompt generativi

Per l'analisi completa dell'identità visiva del personaggio, la palette
cromatica, le specifiche tecniche degli asset e i **prompt pronti per generare
ogni immagine** (7 esistenti + 10 proposte), vedi:

[`chigio-visual-identity.md`](./chigio-visual-identity.md)

---

_Ultima revisione: 2026-06-09 — aggiunto link alla pagina identità visiva con prompt generativi._
