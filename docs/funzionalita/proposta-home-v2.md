# Proposta — Home v2 ("Ciao, Marco!")

> **Stato: solo proposta.** Nessun codice cambiato. Riferimento visivo:
> [`design/how-i-want-home-look-like.png`](../../design/how-i-want-home-look-like.png)
> (+ moodboard in [`design/chigio-moodboard.png`](../../design/chigio-moodboard.png)).
> Data: 2026-07-03.

---

## 1. Com'è oggi la Home (dashboard)

Struttura attuale ([`dashboard_screen.dart`](../../lib/features/dashboard/presentation/dashboard_screen.dart)):

```
GlassHeader (saluto compatto + frase Chigio + avatar)
ListView
├── heroCard          ← anello cronometro turno + timbratura + badge stato
├── noteSection       ← nota giornaliera (se presente)
└── statsSection      ← totalizzatori, maggior presenza, colleghi preferiti,
                        route planner, GPS prompt, grafici…
```

Osservazioni:

- Il saluto è piccolo e "di servizio"; Chigio compare solo come frase testuale
  nel `GlassHeader` — la mascotte (asset PNG) non è mai in scena nella Home.
- Il colpo d'occhio iniziale è il cronometro: ottimo nei giorni lavorativi
  attivi, ma la pagina non comunica *"come sta andando la giornata"* in una
  riga sola.
- Non esiste un riepilogo "obiettivo giornaliero" (ore fatte / ore attese)
  se non dentro l'anello.

## 2. Cosa mostra il mockup

Dal riferimento `how-i-want-home-look-like.png`:

1. **Hero blu a tutta larghezza** (palette blu Chigio, angoli inferiori
   arrotondati) con:
   - hamburger/menu in alto a sinistra (per noi: resta l'avatar/menu attuale);
   - saluto grande su due righe: **"Ciao, Marco!"** + sottotitolo
     motivazionale ("Pronto a conquistare la tua giornata?") — già generabile
     dal `ChigioPhraseEngine`;
   - **mascotte Chigio** (PNG, es. `chigio-ciao.png`) ancorata a destra,
     che "sbuca" dal bordo dell'hero.
2. **Sezione "Oggi"** sotto l'hero, su sfondo chiaro:
   - card **"Obiettivo giornaliero"** con progresso (es. "3/5 attività
     completate" nel mockup → per noi: **ore lavorate / ore attese** del
     turno, stessa fonte dell'anello) e barra di avanzamento blu.

## 3. Proposta di ristrutturazione

```
_HomeHero (nuovo)                       ← sostituisce GlassHeader SOLO in Home
├── saluto grande (greeting + nome)     ← AppStrings.greeting* esistenti
├── sottotitolo frase Chigio            ← ChigioPhraseEngine (già esiste)
├── Image.asset(chigio-* contestuale)   ← stessa logica umore del phrase engine
│     (mattina: ciao · turno attivo: timer · sera: sonno · festa: festeggia)
└── tap sulla mascotte → pagina Chigio  (route esistente /chigio)

_DailyGoalCard (nuovo, prima card della lista "Oggi")
├── "Obiettivo giornaliero"
├── barra progresso: netWorkedMins / standardDailyMins   (dati già derivati)
└── sottotesto: "manca 1h 20m · uscita prevista 17:42"   (già calcolato
      per gli smart-exit scenarios → riuso, zero nuove query)

ListView (invariata sotto)
├── heroCard (anello)      ← resta, subito sotto _DailyGoalCard
├── noteSection
└── statsSection
```

### Scelte deliberate (ponytail)

- **Nessun nuovo dato**: obiettivo giornaliero e uscita prevista riusano i
  calcoli già fatti per anello e barra timbratura. Zero nuovi provider.
- **Nessun background full-screen**: gli asset `chigio-background-*.png`
  restano fuori dal bundle per ora (decisione esplicita 2026-07-03).
- `GlassHeader` resta invariato nelle altre 4 sezioni: l'hero nuovo è solo
  della Home (il nav pill desktop si sovrappone all'hero senza modifiche,
  come oggi si sovrappone al GlassHeader).
- La mascotte è una `Image.asset` statica (niente animazioni/Lottie): gli
  asset attuali sono PNG ~1MB già in bundle.

### Impatto stimato

| Pezzo | Nuovo codice | Rischio |
|---|---|---|
| `_HomeHero` | ~120 righe (gradiente blu + testo + PNG) | Basso |
| `_DailyGoalCard` | ~80 righe (riuso calcoli esistenti) | Basso |
| Ritocco `dashboard_screen` build | ~20 righe | Basso |

Fuori scope per la v2: riordino drag&drop delle card, personalizzazione
sezioni (già coperta da `hiddenNavViews` per i tab), backgrounds.

## 4. Domande aperte per Marco

1. L'hero blu pieno convive col tema scuro attuale (`#0A0C20`)? Proposta:
   gradiente `blue600→blue800` in light, `#12142E→#0A0C20` in dark.
2. La card "Obiettivo giornaliero" deve sparire nei giorni non lavorativi /
   ferie (proposta: sì, si mostra la frase Chigio di ferie al suo posto)?
3. Mascotte contestuale o fissa `chigio-ciao.png`? (proposta: contestuale,
   mappa umore→asset già esistente in `chigio_quotes.dart`).
