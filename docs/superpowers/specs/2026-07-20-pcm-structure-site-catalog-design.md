# Catalogo PCM Dipartimento/Struttura e Sede — Design

**Data:** 2026-07-20

**Stato:** approvato per la pianificazione

**Sorgente:** `Appendice A-elenco strutture.pdf`, colonne `STRUTTURA PCM` e
`SEDE`

## Obiettivo

Sostituire gli elenchi PCM oggi divergenti con un catalogo unico di coppie
`Dipartimento/Struttura → Sede`, distribuito da Firestore, disponibile offline
e usato in modo coerente da onboarding, profilo, geofencing e percorsi PCM.

La terminologia utente diventa **Dipartimento/Struttura**. Per compatibilità con
i documenti esistenti, il campo profilo Firestore resta `dipartimento`.

## Decisioni confermate

- Firestore è la fonte canonica runtime.
- Il catalogo vive in un singolo documento versionato.
- Le righe del PDF vengono normalizzate: formattazione e CAP palesemente errati
  sono corretti; il duplicato evidente del DIPE è unificato.
- Il catalogo risultante contiene 50 strutture.
- La sede associata viene ordinata per prima e marcata come consigliata, ma non
  selezionata automaticamente.
- I profili con una struttura assente dal nuovo catalogo vengono azzerati e
  devono effettuare una nuova selezione mirata.
- Il PDF è una sorgente di lavoro locale, non un asset dell'app né un documento
  da pubblicare nel repository.

## Catalogo e normalizzazione

La prima colonna del PDF produce esclusivamente il nome della struttura. La
seconda produce nome breve sede, indirizzo, CAP e città. Coordinate WGS84 e ID
stabili completano i dati necessari a geofencing e route planner.

Normalizzazioni ammesse:

- spaziatura, maiuscole/minuscole e apostrofi coerenti;
- abbreviazioni `L.go` espanse in `Largo`;
- separazione coerente fra numero civico, CAP e città;
- `00178` di Largo Chigi corretto in `00187`, coerentemente con le altre righe;
- le due varianti del nome DIPE fuse in una singola struttura;
- nomi sede noti conservati quando espliciti nel PDF, per esempio
  `Palazzo Chigi` e `Palazzo della Farnesina`.

Non vengono aggiunte strutture non presenti nella prima colonna.

## Documento Firestore

Percorso canonico:

```text
referenceData/pcmCatalog
```

Schema:

```text
version: string                # CalVer del catalogo, es. 2026.07.20
source: string                 # Appendice A - indirizzario strutture PCM
updatedAt: timestamp           # timestamp server dell'ultimo caricamento
structures: list<map>          # esattamente 50 elementi ordinati
  - id: string                 # slug stabile e univoco
    name: string               # prima colonna normalizzata
    sortOrder: int
    siteId: string             # slug stabile della sede
    siteName: string           # nome breve o indirizzo se non esiste un nome
    address: string            # via/piazza e civico
    city: string               # CAP e città
    latitude: number           # WGS84
    longitude: number          # WGS84
```

Il documento resta ampiamente sotto il limite Firestore di 1 MiB e viene letto
con un singolo `get`, senza query o indici dedicati.

## Accesso e pubblicazione

Le Security Rules consentono il `read` del solo documento agli utenti
autenticati e negano ogni scrittura client. Il catalogo non contiene dati
personali.

Uno script amministrativo versionato:

1. legge lo stesso payload JSON usato come fallback bundled;
2. valida schema, conteggio, ID, nomi, coordinate e duplicati;
3. mostra il diff per impostazione predefinita;
4. scrive il documento solo con `--apply`;
5. rilegge Firestore e verifica versione e hash del payload.

Lo script usa Firebase Admin e le credenziali già previste in `scripts/lib_fs.mjs`.

## Repository e fallback offline

Il payload normalizzato vive anche in `assets/data/pcm_catalog.json`. È la
sorgente versionata usata per il primo avvio offline e dallo script di upload.

Il repository applica questa precedenza:

```text
Firestore valido → sincronizza Drift → restituisce catalogo
Firestore non disponibile/malformato → Drift non vuoto
Drift non disponibile/vuoto → asset JSON bundled
```

Il payload remoto viene accettato solo se passa interamente la validazione. Un
documento parziale o con ID duplicati non sostituisce la cache valida.

Quando la versione o il contenuto cambiano, la tabella Drift delle sedi viene
sostituita in transazione. Le righe rimosse dal catalogo non restano nel DB
locale. Nessuna nuova dipendenza è necessaria.

## Modello applicativo

Il modello mantiene una coppia esplicita:

```text
PcmStructureSite
  id
  structureName
  siteId
  siteName
  address
  city
  latitude
  longitude
  sortOrder
```

Le vecchie liste separate `kPcmDepartments` e `pcmOfficeSeeds` cessano di essere
fonti indipendenti. Onboarding e profilo leggono entrambe dal provider del
catalogo.

## Esperienza utente

### Onboarding

- Etichetta: `Dipartimento/Struttura`.
- Ricerca sulle 50 strutture canoniche.
- Dopo la selezione, il menu Sede mostra la sede associata in cima con la
  dicitura `Sede consigliata` e una stella.
- La sede non viene selezionata automaticamente.
- Il salvataggio continua a scrivere `dipartimento`, `sede`, `sedeId`,
  `sedeAddress`, `sedeLat` e `sedeLng`.

### Profilo

- Lo stesso catalogo e lo stesso ordinamento dell'onboarding sono riutilizzati.
- Cambiare struttura non sovrascrive la sede corrente finché l'utente non ne
  sceglie una.
- Se la sede corrente non appartiene alla nuova struttura, viene mostrato un
  avviso e il salvataggio della nuova struttura richiede una nuova sede.

### Profili da riallineare

La migrazione amministrativa conserva i profili il cui `dipartimento` coincide
con una struttura canonica. Per gli altri azzera:

```text
dipartimento, sede, sedeId, sedeAddress, sedeLat, sedeLng
```

I quattro campi testuali vengono impostati a stringa vuota; `sedeLat` e
`sedeLng` vengono rimossi dal documento, così non cambiano tipo.

Al primo accesso successivo, un gate mirato e non dismissibile chiede soltanto
`Dipartimento/Struttura` e `Sede`; non ripete l'intero onboarding. In assenza di
catalogo remoto usa cache o fallback bundled. Il gate salva i sei campi e poi
restituisce l'utente alla schermata richiesta.

## Sede consigliata

La raccomandazione non usa più una mappa separata. Data una struttura, cerca la
coppia con `structureName` identico e porta la sua `siteId` in cima alle sedi
uniche aggregate dal catalogo.

Se non esiste una corrispondenza esatta, nessuna sede viene marcata. Non si usa
matching fuzzy in UI: evita suggerimenti errati su nomi simili.

## Migrazione produzione

La migrazione profili è separata dall'upload catalogo ed è idempotente:

1. dry-run con conteggio di profili validi, da azzerare e già vuoti;
2. elenco UID e valori coinvolti senza stampare altri dati personali;
3. `--apply` in batch Firestore;
4. rilettura e verifica dei soli campi interessati;
5. report finale versionato senza dati personali.

Non modifica timesheet, notifiche, totalizzatori o altri dati utente.

## Errori e telemetria

- Gli errori Firestore non vengono mostrati come catalogo vuoto.
- L'app usa automaticamente l'ultima cache valida o il bundled.
- Se anche il bundled è invalido, mostra un messaggio umano con `Riprova` e non
  permette di salvare una coppia incompleta.
- Log tecnici indicano origine usata (`remote`, `cache`, `bundled`) e versione,
  senza dati del profilo.

## Test e verifica

- parser del payload: schema, conteggio, duplicati, coordinate e versioni;
- esattamente 50 strutture e una sede consigliata deterministica per ciascuna;
- precedenza remote/cache/bundled e rifiuto atomico del remoto malformato;
- sostituzione Drift senza righe obsolete;
- onboarding e profilo usano la stessa sorgente e non auto-selezionano la sede;
- gate mostrato solo per profili PCM senza struttura/sede valida;
- migrazione dry-run/apply idempotente;
- contratto rules: read autenticato, read anonimo e write client negati;
- `flutter analyze`, `flutter test`, test Functions/rules, build Web release;
- dopo il deploy: documento remoto, versione/hash, caricamento app e smoke di
  selezione struttura/sede.

## Documentazione da aggiornare

- nuova ADR per catalogo Firestore canonico con fallback offline;
- `docs/entita/dipartimenti-pcm.md`;
- `docs/entita/sedi-pcm.md`;
- `docs/entita/user-profile.md`;
- `docs/entita/onboarding-state.md`;
- `docs/funzionalita/authentication.md` e `profile.md`;
- `docs/architettura/persistence.md`;
- `docs/CHANGELOG.md`.

## Fuori scope

- pannello amministrativo per modificare il catalogo dall'app;
- matching fuzzy o geocodifica eseguita sul dispositivo;
- rinomina del campo profilo Firestore `dipartimento`;
- pubblicazione del PDF sorgente.
