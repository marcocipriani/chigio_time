# Chigio — Identità Visiva e Prompt Generativi

> Documento di riferimento per il design system del personaggio Chigio.
> Contiene l'analisi dello stile visivo, i token di design e i **prompt
> pronti all'uso** per generare o rigenerare ogni asset con un modello
> image-generation (DALL·E 3, Midjourney, Stable Diffusion, ecc.).

---

## 1. Stile visivo del personaggio

### Tecnica
- **3D CGI clay-render** — qualità Pixar/Blender, effetto giocattolo morbido
- Illuminazione studio soft, ombre diffuse leggere (no ombre dure)
- Sfondo **bianco puro** o **trasparente** (PNG con alpha)
- Niente texture complesse: superfici lisce, colori piatti con gradiente leggero

### Proporzioni corpo
- Corporatura **tozza e arrotondata**, testa grande rispetto al busto
- **Bipede**, in piedi o seduto (mai a quattro zampe, è un personaggio)
- Arti corti, palmati, con artigli brunastri/sabbia nella punta
- Testa retrattile ma non retratta — sempre ben visibile

### Palette cromatica

| Parte | Colore approssimato | Note |
|---|---|---|
| Corpo (dorso, testa, arti) | `#70CDE8` — sky blue chiaro | La tinta dominante |
| Plastron (ventre) | `#E8D9B0` — crema/sabbia | Zona centrale del busto |
| Guscio | `#4AA8C8` — blue-verde | Leggermente più scuro del corpo |
| Artigli | `#C8A878` — sabbia tan | Punte di mani e piedi |
| Occhi (iride) | `#1A1A2E` — nero quasi puro | Cerchio grande, espressivo |
| Riflesso occhio | `#FFFFFF` — bianco | Punto luce in alto a destra |
| Bocca (interno) | `#E85050` — rosso caldo | Solo quando la bocca è aperta |
| Corpetto/giubbino | `#2B5FA6` — blu PCM | Colore istituzionale PCM `#0055A5` |
| Testo "ChigioTime" | `#FFFFFF` — bianco | Sul petto sinistro |
| Icona orologio logo | `#FFFFFF` — bianco | Sopra il testo, stilizzata |

### Corpetto istituzionale
Chigio indossa **sempre** un corpetto blu corto (`#2B5FA6`) che ricorda un
gilè da ufficio. Sul petto sinistro è ricamato (o stampato) il logo
**ChigioTime**: un'icona orologio stilizzata in bianco + la scritta "ChigioTime"
in font sans-serif bianco, leggibile ma piccola.

### Espressioni principali

| Espressione | Occhi | Bocca | Uso tipico |
|---|---|---|---|
| Sorriso aperto | Normali | Aperta, denti visibili | Saluto, eccitazione |
| Sorriso chiuso | Normali | Arco morbido chiuso | Approvazione, serenità |
| Concentrato | Leggermente socchiusi | Neutra | Calcolo, analisi |
| Assonnato | Semi-chiusi | Semiaperta/rilassata | Sera, stanchezza |
| Sorpreso/pensoso | Spalancati | Neutra o a "o" | Dubbio, attesa |
| Festoso | Normali o brillanti | Aperta larga | Celebrazioni |

---

## 2. Asset esistenti — schede e prompt

### Regola base per tutti i prompt

I prompt seguenti condividono questo **blocco fisso**, da copiare all'inizio
di ogni generazione:

```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright, cream/tan (#E8D9B0) belly, slightly darker
blue-green shell on back, small tan-tipped claws, large expressive black eyes
with white specular highlight, wearing a short royal-blue (#2B5FA6)
institutional vest with a small white clock icon and "ChigioTime" white text
on the left chest. Soft studio lighting, gentle shadow, clean white background,
no other characters, 1:1 square crop.
```

Ogni immagine aggiunge poi la **pose specifica** descritta nelle sezioni
seguenti.

---

### 2.1 `chigio-ciao.png` — Saluto

**Emozione:** benvenuto, energia mattutina, primo contatto  
**Usata in:** dashboard mattina (notStarted), social, profilo, pool `morningNotStarted`

**Prompt completo:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright, cream/tan belly, royal-blue institutional
vest with white "ChigioTime" logo on left chest, large expressive black eyes
with white highlight, open wide smile showing small white teeth.
RIGHT ARM raised high in a friendly wave gesture, left arm relaxed at side.
Upbeat, welcoming body language. Soft studio lighting, clean white background,
1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 2.2 `chigio-ok.png` — Approvazione

**Emozione:** successo, conferma, tutto a posto  
**Usata in:** turno attivo, turno completato, pool `completed`

**Prompt completo:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright, cream/tan belly, royal-blue institutional
vest with white "ChigioTime" logo on left chest, large expressive black eyes,
calm confident closed-mouth smile.
RIGHT HAND raised making a perfect OK sign (thumb and index finger forming
a circle, other three fingers spread up). Left arm relaxed at side. Confident,
approving posture. Soft studio lighting, clean white background,
1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 2.3 `chigio-orologio.png` — Puntualità

**Emozione:** orario, precisione, attesa della timbratura  
**Usata in:** notStarted, abandoned, pool `morningNotStarted`, `abandoned`

**Prompt completo:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright, cream/tan belly, royal-blue institutional
vest with white "ChigioTime" logo on left chest, large expressive black eyes,
calm neutral expression with slight proud smile.
BOTH HANDS holding up a large antique gold pocket watch with roman numeral
dial, chain dangling, watch face prominently visible to viewer. The turtle
presents the watch as if showing the time. Soft studio lighting, clean white
background, 1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 2.4 `chigio-calcolatrice.png` — Calcolo

**Emozione:** analisi, contabilità, precisione numerica  
**Usata in:** stats, timesheet, pool `timesheet`, `stats`

**Prompt completo:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright, cream/tan belly, royal-blue institutional
vest with white "ChigioTime" logo on left chest, wearing small round vintage
reading glasses perched on the nose, focused analytical expression with
concentrated slightly narrowed eyes and neutral mouth.
BOTH ARMS holding a large vintage beige desktop calculator against the chest,
calculator display showing "432" in orange LED digits. Serious, professional
accountant pose. Soft studio lighting, clean white background,
1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 2.5 `chigio-caffe.png` — Pausa caffè

**Emozione:** pausa, socialità, comfort da ufficio  
**Usata in:** pausa attiva, social, pool `paused`, `social`

**Prompt completo:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright, cream/tan belly, royal-blue institutional
vest with white "ChigioTime" logo on left chest, large expressive happy eyes
slightly squinting with joy, big open smile.
RIGHT HAND holding a white ceramic espresso cup with a small handle, gentle
white steam curling upward above the cup. The turtle looks at the viewer with
a warm, satisfied expression as if enjoying the coffee break. Soft studio
lighting, clean white background, 1:1 square crop, 1024×1024px PNG with
transparent background.
```

---

### 2.6 `chigio-sonno.png` — Stanchezza

**Emozione:** sera, stanchezza, fine giornata  
**Usata in:** sera tardi lavorando, pool `eveningWorking`

**Prompt completo:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle SEATED on a small soft pillow, cream/tan belly, royal-blue
institutional vest with white "ChigioTime" logo on left chest, eyes fully
closed with curved eyelids showing sleepiness, mouth slightly open and relaxed.
HEAD tilted gently to one side, RIGHT HAND supporting the cheek. Above the
head, a soft cartoon thought-bubble cloud containing bold "ZZZ" letters in
dark blue. Cozy, drowsy bedtime atmosphere. Soft warm studio lighting, clean
white background, 1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 2.7 `app_icon.png` — Icona app / firma Chigio

**Emozione:** identità, marchio, firma della mascotte  
**Usata in:** alias semantici senza avatar specifico, icona dell'app

**Nota di stile:** questo asset ha volutamente un look **2D flat vector** diverso
dal 3D degli altri avatar. È il "logo-mascotte" dell'app, non una scena.

**Prompt 3D (per rigenerare in stile coerente con gli altri):**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle, BUST/PORTRAIT view (head and upper torso only, cropped at
waist), cream/tan belly, royal-blue institutional vest with small white clock
icon and "ChigioTime" text on left chest, large round expressive black eyes
with white specular, warm confident closed-mouth smile, looking straight at
the viewer. Centered composition, circular framing suggestion, clean white
background, app icon style, 1:1 square crop, 1024×1024px PNG with
transparent background.
```

**Prompt 2D flat vector (per rigenerare nello stile attuale):**
```
2D flat vector cartoon, app icon style, cute chubby turtle mascot head and
shoulders bust portrait, light sky-blue (#70CDE8) body, cream belly, small
blue institutional vest with white clock icon, large round black eyes with
white dot highlight, small curved smile, clean thick navy-blue outline,
smooth gradients, no texture, circular composition, clean white background,
1024×1024px.
```

---

## 3. Nuovi avatar proposti — prompt

Questi 10 asset non esistono ancora. I prompt sono pronti per la generazione.

---

### 3.1 `chigio-corsa.png` — In ritardo!

**Emozione:** urgenza comica, ritardo mattutino  
**Usata in (proposta):** dashboard mattina tardiva (es. dopo le 09:30 notStarted), pool `morningNotStarted`

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle in a RUNNING POSE, cream/tan belly, royal-blue institutional
vest with white "ChigioTime" logo on left chest, wide surprised eyes, mouth
open in a comic "oh no!" expression.
LEANING FORWARD in an exaggerated sprint, one leg raised mid-stride, RIGHT
HAND clutching a small brown vintage leather briefcase swinging forward, LEFT
ARM pumping back. Small motion blur lines behind the turtle for speed effect.
Energetic, playful panic. Soft studio lighting, clean white background,
1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 3.2 `chigio-spiaggia.png` — Ferie

**Emozione:** vacanza, riposo totale, ferie guadagnate  
**Usata in (proposta):** giornata holiday, pool `holidayDay`

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle SITTING in a small striped beach chair (blue and white stripes),
cream/tan belly, royal-blue institutional vest REPLACED by a colorful Hawaiian
shirt (the vest logo still subtly visible as a badge), large round expressive
eyes squinting in happy relaxation behind small white-framed sunglasses.
RIGHT HAND holding a tropical cocktail glass with a tiny umbrella and straw.
Sandy beige ground suggestion, background hint of warm golden light.
Relaxed, blissful holiday vibe. Soft warm studio lighting, clean white
background, 1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 3.3 `chigio-computer.png` — Smart working

**Emozione:** lavoro da remoto, concentrazione casalinga  
**Usata in (proposta):** dayType remote, pool `remoteDay`

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle SEATED at a small desk, cream/tan belly, royal-blue
institutional vest with white "ChigioTime" logo on left chest, focused
attentive expression with slightly narrowed engaged eyes, small smile.
A compact LAPTOP open on the desk in front of the turtle, screen glowing blue.
HEADPHONES resting around the neck (not on ears), suggesting a video call
ready mode. Both hands resting on the laptop keyboard. Home-office cozy
atmosphere. Soft warm studio lighting, clean white background, 1:1 square
crop, 1024×1024px PNG with transparent background.
```

---

### 3.4 `chigio-champagne.png` — Traguardo raggiunto

**Emozione:** celebrazione, obiettivo mensile, record personale  
**Usata in (proposta):** OT mensile completato, record streak, pool `overtime`

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright in a CELEBRATORY POSE, cream/tan belly,
royal-blue institutional vest with white "ChigioTime" logo on left chest,
huge joyful open-mouth smile, eyes bright and squinting with excitement.
RIGHT HAND raised high holding an elegant champagne flute with golden
bubbling liquid, LEFT HAND on hip in triumph. Small golden confetti pieces
floating around. Festive, victorious energy. Soft studio lighting, clean
white background, 1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 3.5 `chigio-pensiero.png` — Turno incerto

**Emozione:** dubbio, stato non chiaro, turno abbandonato  
**Usata in (proposta):** abandoned, stato ignoto, pool `abandoned`

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle SITTING or standing with a puzzled, thoughtful pose, cream/tan
belly, royal-blue institutional vest with white "ChigioTime" logo on left
chest, wide confused eyes, one eyebrow slightly raised, mouth in a small
uncertain "hmm" expression.
RIGHT HAND raised with one finger pointing up pensively (thinking gesture),
head tilted slightly. Above the head, a large cartoon THOUGHT BUBBLE containing
a bold white "?" question mark on a soft cloud. Gentle, curious atmosphere.
Soft studio lighting, clean white background, 1:1 square crop,
1024×1024px PNG with transparent background.
```

---

### 3.6 `chigio-lente.png` — Analisi e statistiche

**Emozione:** ispezione, analisi avanzata, audit  
**Usata in (proposta):** stats screen, timesheet audit, pool `stats`

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright in an INVESTIGATOR POSE, cream/tan belly,
royal-blue institutional vest with white "ChigioTime" logo on left chest,
wearing small round golden-framed reading glasses, squinting one eye
(left eye closed) with the other peering through the lens, determined
concentrated expression.
RIGHT HAND holding a large round MAGNIFYING GLASS up to one eye, the glass
rim golden/brass colored. Slightly hunched forward as if examining something
closely. Detective/auditor energy. Soft studio lighting, clean white background,
1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 3.7 `chigio-ombrello.png` — Permesso / assenza

**Emozione:** giornata di permesso, assenza programmata, pausa istituzionale  
**Usata in (proposta):** dayType leave, pool `leaveDay`

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright, cream/tan belly, royal-blue institutional
vest with white "ChigioTime" logo on left chest, calm peaceful expression
with a gentle closed-mouth smile, eyes slightly droopy and relaxed.
RIGHT HAND holding a large open UMBRELLA above the head (classic dome umbrella,
deep blue color matching the vest), a few small stylized RAIN DROPS falling
around but not touching the turtle. The turtle looks unbothered and cozy
under the umbrella. Soft studio lighting, clean white background,
1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 3.8 `chigio-sole.png` — Primo accesso / buon umore

**Emozione:** energia del mattino, giornata iniziata con il piede giusto  
**Usata in (proposta):** primo accesso del giorno, lunedì solare, pool `monday`

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle with HEAD AND NECK STRETCHED UP AND OUT of the shell,
cream/tan belly, royal-blue institutional vest with white "ChigioTime"
logo on left chest, very wide enthusiastic open smile, eyes bright and
extra large with sparkling highlights.
The turtle stretches tall and proud. Behind and slightly above the turtle,
a warm golden SUN with soft cartoon rays radiating outward (not cartoon
spikes, but soft light beams). The overall feel is dawn, optimism, and
fresh energy. Soft warm golden studio lighting, clean white background,
1:1 square crop, 1024×1024px PNG with transparent background.
```

---

### 3.9 `chigio-trofeo.png` — Obiettivo mensile

**Emozione:** risultato mensile, superamento target, orgoglio  
**Usata in (proposta):** obiettivo ore mensile raggiunto, pool `overtime` avanzato

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing in a CHAMPION POSE, cream/tan belly, royal-blue
institutional vest with white "ChigioTime" logo on left chest, huge proud
open-mouth smile, eyes gleaming with pride.
BOTH HANDS raised high holding a shiny golden TROPHY CUP above the head,
the trophy has a classic two-handle cup shape with a small star on top.
The turtle's whole body radiates triumph — slight backward lean, chest out.
A few small golden star sparkles around the trophy. Heroic, celebratory
energy. Soft studio lighting, clean white background, 1:1 square crop,
1024×1024px PNG with transparent background.
```

---

### 3.10 `chigio-banca.png` — Banca ore

**Emozione:** risparmio, accumulo, banca ore positiva  
**Usata in (proposta):** banca ore positiva, BOE accumulato, pool generale

**Prompt:**
```
3D CGI clay render, Pixar-quality toy mascot, chubby light sky-blue (#70CDE8)
bipedal turtle standing upright with a SATISFIED PLEASED expression, cream/tan
belly, royal-blue institutional vest with white "ChigioTime" logo on left
chest, content closed-mouth smile, eyes relaxed and happy.
BOTH HANDS holding a large round COIN SACK (fabric money bag, dark blue or
brown with gold drawstring) against the chest, the sack plump and full.
A few gold coins floating or spilling nearby. The turtle has a self-satisfied
"I've been saving up" energy — calm pride, not greed. Soft studio lighting,
clean white background, 1:1 square crop, 1024×1024px PNG with transparent
background.
```

---

## 4. Tabella riepilogativa asset

| File | Stato | Emozione chiave | Contesto d'uso principale |
|---|---|---|---|
| `chigio-ciao.png` | ✅ Esiste | Saluto | Mattina, social, profilo |
| `chigio-ok.png` | ✅ Esiste | Approvazione | Working, completed |
| `chigio-orologio.png` | ✅ Esiste | Puntualità | notStarted, abandoned |
| `chigio-calcolatrice.png` | ✅ Esiste | Calcolo | Stats, timesheet |
| `chigio-caffe.png` | ✅ Esiste | Pausa caffè | Paused, social |
| `chigio-sonno.png` | ✅ Esiste | Stanchezza | Evening working |
| `app_icon.png` | ✅ Esiste | Firma/Logo | Icona app, alias |
| `chigio-corsa.png` | 🔲 Da generare | Urgenza/ritardo | Mattina tardiva notStarted |
| `chigio-spiaggia.png` | 🔲 Da generare | Vacanza | Holiday day |
| `chigio-computer.png` | 🔲 Da generare | Smart working | Remote day |
| `chigio-champagne.png` | 🔲 Da generare | Celebrazione | Traguardo, OT record |
| `chigio-pensiero.png` | 🔲 Da generare | Dubbio | Abandoned, incerto |
| `chigio-lente.png` | 🔲 Da generare | Analisi | Stats, audit |
| `chigio-ombrello.png` | 🔲 Da generare | Permesso | Leave day |
| `chigio-sole.png` | 🔲 Da generare | Energia mattina | Primo accesso, lunedì |
| `chigio-trofeo.png` | 🔲 Da generare | Traguardo mensile | Target raggiunto |
| `chigio-banca.png` | 🔲 Da generare | Banca ore | BOE positivo |

---

## 5. Note tecniche per i nuovi asset

- **Dimensione:** 512×512 px minimo, preferibile 1024×1024 px
- **Formato:** PNG-32 con **sfondo trasparente** (alpha channel)
- **Denominazione file:** `chigio-<nome>.png` in `assets/images/`
- **Dichiarazione pubspec:** già coperta da `assets/images/` bulk
- **Dichiarazione AppStrings:** aggiungere path in `chigioImages` e label in `chigioLabels`
- **Quote:** aggiungere alias in `ChigioQuotes` (es. `static const corsa = 'assets/images/chigio-corsa.png'`)
- **Engine:** associare il nuovo asset ai pool contestuali appropriati in `chigio_phrase_engine.dart`

---

## 6. Consistenza visiva — checklist per ogni nuovo asset

- [ ] Colore corpo: `#70CDE8` (sky blue)
- [ ] Plastron crema `#E8D9B0` visibile se il busto è frontale
- [ ] Corpetto blu `#2B5FA6` con logo "ChigioTime" sul petto sinistro
- [ ] Occhi grandi, rotondi, scuri con punto luce bianco
- [ ] Sfondo bianco puro o trasparente
- [ ] Stile 3D clay render coerente con gli esistenti (no 2D, no pixel art, no realismo fotografico)
- [ ] Nessun altro personaggio nell'immagine
- [ ] Crop 1:1 quadrato
- [ ] File PNG < 500 KB se possibile (comprimere con pngquant)

---

_Ultima revisione: 2026-06-09 — prima stesura completa identità visiva, prompt per 17 asset (7 esistenti + 10 proposti)._
