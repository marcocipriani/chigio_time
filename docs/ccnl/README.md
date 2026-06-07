# CCNL PCM

Sezione di lavoro per trasformare il CCNL PCM in materiale operativo per lo
sviluppo di `chigio_time`.

## File

| File | Scopo |
|---|---|
| [`ccnl-pcm-2016-2018.md`](./ccnl-pcm-2016-2018.md) | Conversione completa in Markdown del PDF locale `CCNL_PCM 16-18.pdf`. |
| [`ccnl-pcm-2019-2021.md`](./ccnl-pcm-2019-2021.md) | Conversione completa in Markdown del PDF locale `2025_10_28_CCNL_C_PCM_2019-2021_Pubblicazione.pdf`. |
| [`confronto-2016-2018-2019-2021.md`](./confronto-2016-2018-2019-2021.md) | Mappa degli articoli sostituiti dal CCNL 2019-2021, istituti confermati dalla base precedente e impatto sull'app. |
| [`articoli-app.md`](./articoli-app.md) | Lettura prodotto degli articoli rilevanti: concetti gia' presenti nell'app, coperture parziali e gap. |
| [`permessi-assenze-congedi.md`](./permessi-assenze-congedi.md) | Specifica permessi/assenze come registro personale: P0 implementata (`absenceKind`, privacy, CSV) e confronto informativo P1 con totalizzatori. |

## Metodo

- Fonte: PDF locali nella root del progetto.
- Conversione: Microsoft MarkItDown `0.1.6`.
- Verifica esterna: PDF ufficiale ARAN del CCNL PCM 2019-2021 pubblicato il
  28 ottobre 2025:
  https://www.aranagenzia.it/wp-content/uploads/2025/10/2025_10_28_CCNL_C_PCM_2019-2021_pubblicazione.pdf
- Analisi manuale: base CCNL 2016-2018 piu' articoli sostituiti dal CCNL
  2019-2021.
- Scopo: backlog e allineamento di dominio per gestione personale, non
  interpretazione legale vincolante.

## Lettura aggiornata

Il CCNL PCM 2019-2021 aggiorna la base precedente in modo selettivo: alcuni
articoli sostituiscono e disapplicano articoli del CCNL 7 ottobre 2022, mentre
le disposizioni non sostituite restano applicabili se compatibili. Per lo
sviluppo dell'app usare prima il file di confronto, poi le specifiche prodotto.

## Aggiornamento

Quando cambia il CCNL o viene aggiunta una feature collegata ad assenze,
orario, ferie o banca ore:

1. convertire il nuovo PDF in `docs/ccnl/` con MarkItDown;
2. aggiornare `confronto-2016-2018-2019-2021.md` o crearne uno nuovo se il
   contratto successivo cambia la mappa;
3. aggiornare `articoli-app.md` e `permessi-assenze-congedi.md`;
4. aggiungere una nota in [`../CHANGELOG.md`](../CHANGELOG.md) e in
   [`../ROADMAP.md`](../ROADMAP.md).

_Ultima revisione: 2026-06-07 - aggiornati P0 assenze e confronto consumi personali._
