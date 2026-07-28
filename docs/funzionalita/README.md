# Funzionalità

Questa mappa descrive cosa può fare l'utente e dove approfondire ogni flusso.

## Navigazione principale

| Sezione | Cosa offre | Documentazione |
|---|---|---|
| Home | timbratura, pause, riepilogo del giorno e widget | [Dashboard](./dashboard.md), [Orario e presenza](./orario-e-presenza.md) |
| Cartellino | viste Giorno, Lista, Settimana, Mese e Anno; import/export | [Timesheet](./timesheet.md) |
| Progetti | progetti personali o condivisi e Pomodoro | [Progetti](./progetti.md) |
| Colleghi | stati, gruppi, preferiti e inviti caffè | [Social](./social.md) |
| Stipendio | accrediti previsti, storico e stima personale | [Stipendio](./stipendio.md) |

Profilo, notifiche e Chigio sono raggiungibili dalle azioni contestuali e dalle
impostazioni.

## Flussi di ingresso e configurazione

- [Autenticazione](./authentication.md)
- [Onboarding](./onboarding.md)
- [Profilo](./profile.md)

## Funzioni trasversali

| Area | Stato | Nota |
|---|---|---|
| Catalogo PCM | operativa | Firestore → cache Drift valida → JSON bundled |
| Cache cartellino | operativa su tutte le piattaforme | Drift nativo e Web/WASM |
| Assenze personali | operativa, con limiti dichiarati | registro personale, non workflow autorizzativo |
| Notifiche | inbox-first, push multi-dispositivo | DND silenzia il push ma conserva l'inbox |
| Totalizzatori portale | manuale | nessun accesso automatico al portale PCM |
| CCNL | consultazione e classificazione | non è consulenza normativa |

## Identità e componenti

- [Chigio](./chigio.md)
- [Identità visiva](./chigio-identita-visiva.md)
- [Principi di interfaccia](../qualita/interfaccia.md)
- [Catalogo componenti](../qualita/componenti.md)

Per schema dati e decisioni tecniche: [Entità](../entita/README.md) e
[ADR](../decisioni/README.md).

_Ultima revisione: 2026-07-29._
