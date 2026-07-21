# Entità: Sedi PCM

> Payload versionato: `assets/data/pcm_catalog.json`
> Modello: `lib/core/data/pcm_catalog.dart`
> Aggiornato: 2026-07-21

## Definizione

Le sedi non hanno più seed autonomi. `PcmSiteOption` è una vista deduplicata
delle coppie `PcmStructureSite`, raggruppata per `siteId`.

Il catalogo contiene 12 sedi fisiche:

| ID | Sede / indirizzo |
|---|---|
| `palazzo-chigi` | Palazzo Chigi — Piazza Colonna, 370 · 00187 Roma |
| `via-dell-impresa-90` | Via dell'Impresa, 90 · 00187 Roma |
| `largo-chigi-19` | Largo Chigi, 19 · 00187 Roma |
| `via-della-stamperia-8` | Via della Stamperia, 8 · 00187 Roma |
| `corso-vittorio-emanuele-ii-116` | Corso Vittorio Emanuele II, 116 · 00186 Roma |
| `via-della-ferratella-in-laterano-51` | Via della Ferratella in Laterano, 51 · 00184 Roma |
| `via-dei-laterani-34` | Via dei Laterani, 34 · 00184 Roma |
| `via-della-mercede-9` | Via della Mercede, 9 · 00187 Roma |
| `via-della-mercede-96` | Via della Mercede, 96 · 00187 Roma |
| `piazza-sant-apollonia-14` | Piazza di Sant'Apollonia, 14 · 00153 Roma |
| `palazzo-della-farnesina` | Palazzo della Farnesina — Piazzale della Farnesina, 1 · 00135 Roma |
| `via-di-villa-ruffo-6` | Via di Villa Ruffo, 6 · 00196 Roma |

## Sede consigliata

`recommendedSiteIdForStructure` usa solo il match esatto del nome struttura.
`sortedSitesForStructure` restituisce la sede associata in cima con
`isRecommended: true`, seguita dalle altre sedi nell'ordine del catalogo.
L'ordinamento non equivale a una selezione: UI e provider non devono
precompilare il campo sede.

## Etichette e coordinate

`pcmSiteLabel` evita la ripetizione quando il nome breve coincide con
l'indirizzo. CAP e coordinate WGS84 sono dati obbligatori e vengono validati
prima che il payload sia accettato.

## File correlati

- [`dipartimenti-pcm.md`](./dipartimenti-pcm.md)
- `assets/data/pcm_catalog.json`
- `lib/core/data/pcm_catalog.dart`
