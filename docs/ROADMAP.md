# Roadmap

Stato al 2026-07-29. La versione Web pubblicata è `2026.7.22+22`.
Questa pagina contiene soltanto lavoro futuro o rischi ancora aperti; lo
storico delle consegne è nel [changelog](./CHANGELOG.md).

## Stato corrente

Sono operative:

- autenticazione, onboarding e profilo PCM;
- Home con timer, pause, widget e sincronizzazione multi-device;
- Cartellino a cinque viste, segmenti giornalieri, assenze, CSV e PDF;
- Progetti e Pomodoro;
- Colleghi, gruppi, preferiti e inbox notifiche;
- Stipendio e reminder;
- catalogo PCM remoto con fallback Drift e bundled;
- bootstrap Web cache-first e cache Drift/WASM.

Non esiste uno sprint successivo approvato.

## Decisioni di prodotto aperte

| Tema | Decisione richiesta | Rischio se rinviata |
|---|---|---|
| Membership PCM | invito, allowlist o altra autorità server | un nuovo account può dichiararsi PCM |
| Dati privati | trasformare `isPrivate` in ACL reale o mantenerlo convenzione UI | aspettative di privacy superiori alle rules |
| Offline write | coda esplicita per scritture fallite | azioni locali possono richiedere retry manuale |
| Runtime Functions | migrazione da Node 20 prima della dismissione | build/deploy backend bloccati |
| Notifiche Apple | chiave APNs e smoke su build firmata | infrastruttura verde senza prova di ricezione |

## Backlog candidato

### Cartellino e CCNL

- calcolo personale di malattia/comporto e residui;
- ferie e festività soppresse con maturazione;
- import da terminali esterni;
- promemoria e chiusura cartellino mensile;
- ricerca full-text nel lettore CCNL.

### Home e dati

- import automatico dei totalizzatori dal portale, solo con integrazione
  autorizzata;
- riconciliazione buoni pasto;
- visibilità più esplicita del BOE nelle barre;
- coda sync offline osservabile.

### Progetti e stipendio

- stop/finalizzazione Pomodoro con uscita dal turno;
- trasferimento ownership progetto in UI;
- statistiche focus;
- stima netto fiscale e confronto cedolini;
- allegato cedolino e export storico.

### Piattaforma

- smoke autenticati Web e push;
- test comportamentali delle Firestore Rules con Emulator;
- PWA install/offline feedback;
- telemetria strutturata al posto dei catch silenziosi residui.

## Fuori scopo

| Area | Motivo |
|---|---|
| Workflow autorizzativo PA | l'app è un registro personale |
| Timbratura tornelli o QR | richiede integrazione con sistemi fisici |
| Scraping NoiPA | manca un'API ufficiale e il flusso è fragile |
| Consulenza normativa CCNL | i contenuti sono supporto personale |

Ogni item promosso a lavoro pianificato deve avere criterio di accettazione,
owner e test prima dell'implementazione.

_Ultima revisione: 2026-07-29._
