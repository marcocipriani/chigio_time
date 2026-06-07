# ADR-0003 — Export PDF e Import CSV: pacchetti `pdf`, `printing`, `file_picker`

## Contesto

Richiesta utente: export del timesheet mensile in PDF e import da file CSV.

## Opzioni considerate

| Pacchetto | Alternativa | Motivo scelta |
|---|---|---|
| `pdf ^3.11` | `syncfusion_flutter_pdf` (licenza commerciale) | MIT, no licenza |
| `printing ^5.13` | share_plus | `printing` gestisce anteprima nativa iOS/Android/web + condivisione |
| `file_picker ^8.1` | `image_picker` (solo immagini) | Supporta tutti i tipi di file inclusi `.csv` e `.txt` |

## Decisione

Aggiunta delle tre dipendenze. Nota: `printing` non supporta ancora Swift Package Manager su macOS (warning non bloccante — la build macOS funziona via CocoaPods).

## Conseguenze

- `file_picker` su Android richiede `READ_EXTERNAL_STORAGE` o Storage Access Framework (SAF, default da Android 11+).
- La generazione PDF avviene interamente in Dart (nessuna dipendenza nativa aggiuntiva).
- Il parsing CSV è gestito direttamente in Dart senza pacchetti aggiuntivi (formato semplice).

_Data: 2026-05-28_
