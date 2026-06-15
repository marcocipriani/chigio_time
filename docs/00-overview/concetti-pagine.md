# Concetti chiave delle pagine principali

> Ultima revisione: 2026-06-07

Ogni pagina di Chigio Time risolve un problema preciso e ben delimitato.
Questa pagina definisce il **perché** di ciascuna sezione, per guidare
decisioni di design e product.

---

## 🏠 Home — "Il cruscotto del turno"

**Problema:** Il dipendente PA deve sapere, a colpo d'occhio, dove è con
il turno giornaliero senza aprire sistemi HR istituzionali lenti o confusi.

**Proposta di valore:**
Il widget di timbratura (entrata / pausa / uscita) è il **cuore
non-rimovibile** della Home. Intorno ad esso l'utente costruisce un
cruscotto personalizzato scegliendo i contatori che ritiene più rilevanti:
banca ore, straordinari, permessi brevi, contatori custom, widget
highlight, etc.

**Principio guida:**
> "Una dashboard è personale come un portafoglio: ognuno ci mette quello
> che usa davvero."

**Funzionalità chiave:**
- Cronometro turno con uscita prevista in tempo reale
- Widget personalizzabili (highlight + contatori Totalizzatore + custom)
- GPS auto-timbratura (opzionale, foreground)
- Exit reminder configurabile
- Sezione Totalizzatori portale PA con contatori custom
- Preferiti colleghi e percorsi rapidi tra sedi PCM

---

## 📋 Timesheet — "Il cartellino digitale"

**Problema:** Il cartellino presenze cartaceo / il portale HR istituzionale
sono rigidi, difficili da consultare e non danno feedback immediato
sull'andamento del mese.

**Proposta di valore:**
Una vista calendario fluida e leggibile che mostra ogni giornata,
segnala anomalie (giornate mancanti, ore insufficienti) e offre
navigazione rapida tra mese corrente e storico. Export PDF e import CSV
per compatibilità con i sistemi istituzionali.

**Principio guida:**
> "Il cartellino perfetto è quello che non devi ricordare di compilare:
> si riempie automaticamente dalle timbrature."

**Funzionalità chiave:**
- 3 viste: lista giornaliera, settimana, mese calendario
- MonthlySummaryCard pinned con totali Art.9 / SLI / SBO / OT
- Alert giornate mancanti o incomplete
- Inserimento retroattivo con form pre-popolato
- Causali assenza personali e privacy export
- Export PDF standard, cartellino PCM ufficiale, import/export CSV con template

---

## 👥 Social — "La rubrica intelligente"

**Problema:** Sapere se un collega è in ufficio, in smart working o in
ferie richiede telefonate, email o sistemi HR inaccessibili. La rubrica
aziendale è statica e non mostra lo stato real-time.

**Proposta di valore:**
Una vista live dei colleghi (presenza, pausa, remoto, uscito) alimentata
dalle timbrature in tempo reale. Permette di organizzarli in gruppi,
contattarli con un tap e invitarli a un caffè.

**Principio guida:**
> "Il collega migliore è quello che sai dove trovare."

**Funzionalità chiave:**
- Lista colleghi con stato real-time (Firestore stream)
- Filtri per sede, dipartimento e stato
- Gruppi personalizzati (accessibili da mobile e desktop)
- Chiamata diretta da interno / numero mobile
- Invito caffè istantaneo o pianificato
- Summary "X in ufficio, Y in SW" in tempo reale

---

## 💶 Stipendio — "Quando arriva e quanto"

**Problema:** Il dipendente PA non ha un posto unico per sapere *quando*
arriva il prossimo accredito e *quanto* sarà. I cedolini stanno su NoiPA, i
buoni pasto a parte, le emissioni straordinarie (arretrati, conguagli) sono
imprevedibili. Nessuna previsione, nessuno storico consultabile a colpo
d'occhio.

**Proposta di valore:**
Una pagina (4ª tab) che mostra il **countdown** al prossimo accredito con una
**stima del netto** (media degli ultimi ordinari), invia una **notifica push
il giorno dell'accredito** e tiene lo **storico** di tutti i pagamenti
ricevuti — per tipologia (ordinaria, straordinaria, buoni pasto, altro), con
lordo, netto e note. L'utente è la fonte: inserimento e modifica manuali.

**Principio guida:**
> "Lo stipendio è una notizia: l'app te la dà prima, non te la fa cercare."

**Funzionalità chiave:**
- Card "Prossimo accredito": data, countdown, stima netto, toggle notifica
- Statistiche anno: netto totale, n° cedolini, media netto
- Storico raggruppato per mese con tipologia colorata e badge "manuale"
- Sheet add/edit: tipo, data, lordo, netto, note
- Notifica push "Stipendio in arrivo" alle 08:00 del giorno-paga (default 23)

---

## 👤 Profilo — "Le mie impostazioni e statistiche"

**Problema:** Ogni dipendente ha un orario contrattuale diverso, soglie
di buono pasto diverse, e vuole vedere statistiche personalizzate, non
aggregati anonimi.

**Proposta di valore:**
Hub di configurazione personale: dati anagrafici (dipartimento, sede,
stanza, interno), parametri contrattuali (orario standard, tipo impiego,
soglia buono pasto), impostazioni GPS, preferenze UI. Statistiche
avanzate in una pagina dedicata.

**Principio guida:**
> "L'app si adatta al dipendente, non il contrario."

**Funzionalità chiave:**
- Tutti i campi editabili inline
- Sede PCM da elenco strutturato, con indirizzo e coordinate
- Preset orari per tipo contratto (Ruolo/Comando)
- GPS auto-timbratura con raggio configurabile
- Statistiche avanzate (`/stats`): OT per giorno settimana, media ore, permessi
- Tema (chiaro / scuro / auto / auto-by-time)
- Lettore CCNL PCM completo con switch nuovo/precedente e indice articoli
- Link a `/chigio` (galleria tartaruga)
