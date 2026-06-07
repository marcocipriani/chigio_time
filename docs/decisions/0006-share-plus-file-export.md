# ADR-0006 — share_plus per l'export di file CSV

**Data:** 2026-06-06  
**Stato:** Accettato

## Contesto

La funzionalità di export CSV del timesheet richiede di offrire all'utente uno o più file `.csv` da salvare o condividere. Su iOS e Android il meccanismo nativo è la **share sheet** (UIActivityViewController / Android Sharesheet): permette di salvare su Files, inviare via email, aprire in Numbers/Excel, ecc.

Il progetto già usa `printing` per condividere PDF (`Printing.sharePdf`), ma quella API è esclusiva del pacchetto `pdf`/`printing` e non può essere riusata per file arbitrari.

## Opzioni considerate

1. **`share_plus`** — pacchetto ufficiale FlutterCommunity, supporta iOS/Android/macOS/Windows/Linux/Web. API v10: `Share.shareXFiles(List<XFile>, {String? subject})`. Usa XFile di `cross_file` (già transitivo via `image_picker`).
2. **`platform_channels` custom** — scrittura di una share sheet nativa: eccessiva complessità per questo scopo.
3. **Solo clipboard** — copiare il CSV negli appunti: non funziona per file binari, scarsa UX per dati di mesi interi.
4. **`url_launcher` + data: URI** — funziona su web, non adatto per file su mobile (aprirebbe il browser).

## Decisione

Aggiungere **`share_plus: ^10.1.0`**. Il flusso è:

1. Generare il CSV in memoria (StringBuffer).
2. Scrivere in un file temporaneo via `path_provider` (`getTemporaryDirectory()`).
3. Passare gli `XFile` a `Share.shareXFiles([...], subject: '...')`.

Su Web: `XFile.fromData(Uint8List bytes)` invece di file temporaneo (no filesystem access). `share_plus` usa il Web Share API se disponibile.

## Conseguenze

- Aggiunta dipendenza `share_plus: ^10.1.0`.
- Nessuna configurazione aggiuntiva richiesta su iOS/Android (permessi non necessari per directory temporanea + share sheet).
- Il file temporaneo viene scritto in `getTemporaryDirectory()` — la directory viene gestita dall'OS e svuotata automaticamente.
