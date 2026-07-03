# Strutture PCM — Lista dipartimenti e uffici

> Fonte: DPCM 1 ottobre 2012 e decreti successivi.  
> Ordinamento: alfabetico per nome, raggruppato per categoria.  
> Usare questa lista come unica sorgente per dropdown onboarding/profilo e seed Dart (`kPcmDepartments`).

---

## 1. Dipartimenti e Uffici autonomi

- Dipartimento "Casa Italia"
- Dipartimento della funzione pubblica
- Dipartimento della protezione civile
- Dipartimento per gli affari europei
- Dipartimento per gli affari giuridici e legislativi
- Dipartimento per gli affari regionali e le autonomie
- Dipartimento per i rapporti con il Parlamento
- Dipartimento per i servizi strumentali
- Dipartimento per il coordinamento amministrativo
- Dipartimento per il personale
- Dipartimento per il programma di Governo
- Dipartimento per il Sud
- Dipartimento per l'informazione e l'editoria
- Dipartimento per la programmazione e il coordinamento della politica economica
- Dipartimento per la trasformazione digitale
- Dipartimento per le pari opportunità
- Dipartimento per le politiche contro la droga e le altre dipendenze
- Dipartimento per le politiche del mare
- Dipartimento per le politiche della famiglia
- Dipartimento per le politiche di coesione
- Dipartimento per le politiche giovanili e il Servizio civile universale
- Dipartimento per le politiche in favore delle persone con disabilità
- Dipartimento per le riforme istituzionali
- Dipartimento per lo sport
- Ufficio del bilancio e per il riscontro di regolarità amministrativo-contabile
- Ufficio del cerimoniale di Stato e per le onorificenze
- Ufficio del controllo interno, la trasparenza e l'integrità
- Ufficio del Segretario generale
- Ufficio di segreteria del Consiglio dei Ministri
- Ufficio di segreteria della Conferenza Stato-città ed autonomie locali
- Ufficio per le politiche spaziali e aerospaziali

---

## 2. Strutture di missione

- Struttura di missione per gli anniversari di interesse nazionale
- Struttura di missione per il contrasto della scarsità idrica e per il potenziamento delle infrastrutture idriche
- Struttura di missione per il coordinamento dei processi di ricostruzione e sviluppo dei territori colpiti dal sisma del 6 aprile 2009
- Struttura di missione per l'attuazione del Piano Mattei
- Struttura di missione per la semplificazione normativa
- Struttura di missione per le procedure d'infrazione alla normativa UE
- Struttura di missione PNRR
- Struttura di missione Segreteria tecnica per le politiche in materia di disabilità
- Struttura di missione ZES
- Unità per la semplificazione e la qualità della regolazione

---

## 3. Uffici di diretta collaborazione (uffici politici)

> Strutture di supporto diretto alle autorità politiche. Decadono con il Governo.  
> Elenco per ruolo istituzionale, senza nome del titolare corrente.

- Uffici del Ministro per gli affari europei, il PNRR e le politiche di coesione
- Uffici del Ministro per gli affari regionali e le autonomie
- Uffici del Ministro per i rapporti con il Parlamento
- Uffici del Ministro per la famiglia, la natalità e le pari opportunità
- Uffici del Ministro per la Protezione civile e le Politiche del mare
- Uffici del Ministro per la Pubblica Amministrazione
- Uffici del Ministro per le disabilità
- Uffici del Ministro per le riforme istituzionali e la semplificazione normativa
- Uffici del Ministro per lo sport e i giovani
- Uffici del Sottosegretario al coordinamento del CIPES
- Uffici del Sottosegretario all'attuazione del Programma di Governo
- Uffici del Sottosegretario all'informazione e l'editoria
- Uffici del Sottosegretario all'innovazione tecnologica e transizione digitale
- Uffici del Sottosegretario alla Sicurezza della Repubblica
- Uffici del Sottosegretario per i Rapporti con il Parlamento
- Uffici del Sottosegretario per le politiche per il Sud
- Uffici del Vice Presidente del Consiglio
- Ufficio del Consigliere diplomatico
- Ufficio del Consigliere militare
- Ufficio del Presidente del Consiglio
- Ufficio stampa e relazioni con i media

---

## Gruppi per il dropdown app

| Gruppo | Valore `departmentGroup` in Dart |
|---|---|
| Dipartimenti e Uffici autonomi | `DeptGroup.dipartimentiUffici` |
| Strutture di missione | `DeptGroup.struttureMissione` |
| Uffici di diretta collaborazione | `DeptGroup.ufficiPolitici` |

La costante Dart `kPcmDepartments` (da implementare in `lib/core/constants/pcm_departments.dart`) deve rispecchiare questa lista nell'ordine indicato.
