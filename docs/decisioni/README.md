# Decisioni architetturali

Le ADR spiegano perché il sistema è costruito in un certo modo. Sono ordinate
cronologicamente e non vengono riscritte per nascondere l'evoluzione: quando
una scelta cambia, una nuova ADR sostituisce la precedente.

## Come leggere una ADR

1. **Contesto** — problema e vincoli al momento della decisione.
2. **Opzioni** — alternative realmente considerate.
3. **Decisione** — scelta normativa.
4. **Conseguenze** — vantaggi, costi, migrazioni e rischi.

Stati ammessi: `Proposed`, `Accepted`, `Rejected`, `Deprecated`,
`Superseded by ADR-NNNN`.

## Indice

| # | Decisione | Stato |
|---|---|---|
| [0001](./0001-stack-iniziale.md) | Flutter, Riverpod, Firebase e Drift | Accepted |
| [0002](./0002-social-groups.md) | Gruppi per utente in Firestore | Accepted |
| [0003](./0003-pdf-csv-packages.md) | Export PDF e import CSV | Accepted |
| [0004](./0004-gps-geofencing.md) | Geofencing foreground | Accepted |
| [0005](./0005-drift-wasm.md) | Drift Web tramite WASM | Accepted |
| [0006](./0006-share-plus-file-export.md) | Condivisione degli export | Accepted |
| [0007](./0007-banca-ore-esonero.md) | Banca ore come esonero | Accepted |
| [0008](./0008-firestore-read-scoping.md) | Letture Firestore limitate all'amministrazione | Accepted |
| [0009](./0009-cap-periods-storicizzati.md) | Cap di inquadramento effective-dated | Accepted |
| [0010](./0010-stipendio-quarta-tab.md) | Stipendio nella navigazione primaria | Accepted |
| [0011](./0011-pomodoro-progetti.md) | Progetti e Pomodoro condivisi | Accepted |
| [0012](./0012-notifiche-firebase-inbox-first.md) | Notifiche inbox-first e multi-device | Accepted |
| [0013](./0013-catalogo-pcm-firestore-con-fallback-offline.md) | Catalogo PCM remoto con fallback offline | Accepted |
| [0014](./0014-bootstrap-web-cache-first.md) | Bootstrap Web e gate profilo cache-first | Accepted |
| [0015](./0015-logging-e-failure-tipizzate.md) | Logging centralizzato e failure tipizzate | Accepted |
| [0016](./0016-segmenti-giornalieri.md) | Segmenti di lavoro e permesso nel cartellino | Accepted |
| [0017](./0017-sincronizzazione-timer-offline.md) | Sincronizzazione offline del timer | Accepted |
| [0018](./0018-permessi-orari-nella-giornata.md) | Permessi orari dentro la giornata | Proposed |

## Quando crearne una

Serve una nuova ADR per dipendenze strutturali, schema incompatibile,
meccanismi cross-feature, confini di sicurezza o scelte che un futuro
manutentore potrebbe ragionevolmente rimettere in discussione. Correzioni
locali e implementazioni ovvie restano nella scheda della funzionalità.

Usare [il template](./0000-template.md) e aggiornare questo indice.

_Ultima revisione: 2026-07-29._
