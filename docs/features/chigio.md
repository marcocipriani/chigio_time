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
| `lib/core/services/chigio_phrase_engine.dart` | Selezione contestuale della frase, seed temporale, sostituzioni `{n}` e genere |
| `lib/core/constants/chigio_quotes.dart` | Libreria dedicata delle quote, etichette brevi e alias asset |
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
| Ora del giorno | mattina 5–13, pomeriggio 13–18, sera 18–5 |
| `firstName` | nome utente dal profilo |

Le frasi ruotano ogni **5 minuti** (seed = `hour × 12 + minute ÷ 5`). Il placeholder `{n}` viene sostituito con `firstName`.

### Regole editoriali header

- Frasi pensate per massimo **2 righe** nell'header mobile.
- Testo breve, niente spiegazioni funzionali o istruzioni operative.
- Etichette da tenere molto corte: una o due parole.
- Evitare doppioni: se due frasi hanno lo stesso ritmo o la stessa battuta, tenerne una sola.

### Bank di frasi per contesto

| Contesto | Pool | Uso |
|---|---|---|
| Dashboard – mattina, non iniziato | `ChigioQuotes.morningNotStarted` | Prima timbratura |
| Dashboard – lavorando | `morningWorking` · `afternoonWorking` · `eveningWorking` | Turno attivo per fascia oraria |
| Dashboard – in pausa | `paused` | Pausa in corso |
| Dashboard – completato | `completed` | Turno chiuso |
| Dashboard – abbandonato | `abandoned` | Turno rimasto aperto |
| Timesheet | `timesheet` | Storico cartellino |
| Social | `social` | Colleghi e inviti caffè |
| Profilo | `profile` | Profilo e impostazioni personali |
| Statistiche | `stats` | Riepiloghi e grafici |

### API

```dart
final data = ChigioPhraseEngine.resolve(
  page: ChigioPage.dashboard,
  firstName: 'Marco',
  shiftState: ChigioShiftState.working,
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
- frase italic contestuale (`maxPhrase` audit: 58 caratteri con "Alessandro");
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

Chigio parla in prima persona, in italiano, con tono **caloroso e ironico** ma mai sarcastico. Si rivolge sempre all'utente per nome. Fa riferimento alla sua natura di tartaruga.

**✅ DO:** "Dai Marco, anche le tartarughe arrivano puntuali! ⏰"
**❌ DON'T:** "Promemoria: timbrare entro le 09:00."

---

## Routing

| Path | Accesso |
|---|---|
| `/chigio` | Profilo → "Chigio 🐢" |

_Ultima revisione: 2026-06-07 — quote spostate in `ChigioQuotes`, frasi accorciate per header, duplicati rimossi, doc allineata al tap-cambia-frase._
