# ADR-0008 — Scoping per-amministrazione delle letture profilo + sub-collezione privata

- **Data:** 2026-06-14
- **Autore/i:** Claude Code (su richiesta di Marco)
- **Stato:** Accepted
- **Contesto correlato:** [`funzionalita/social.md`](../funzionalita/social.md), `firestore.rules`, [`data/social_repository.dart`](../../lib/features/social/data/social_repository.dart)

## Contesto

La regola di lettura su `users/{userId}` era `allow read: if request.auth != null`:
qualunque account autenticato poteva leggere **l'intero documento profilo di
qualunque altro utente**. Il documento contiene sia campi pensati per la
rubrica colleghi (nome, sede, telefono, stato, piano/stanza) sia campi non
necessari ad altri (genere, parametri orario/straordinario, coordinate GPS
della sede). Conseguenza concreta: un singolo account poteva enumerare l'intera
base utenti e fare harvesting dei numeri di telefono, anche fuori dalla propria
amministrazione. La feature social (scoperta colleghi) lavora invece **dentro
la stessa amministrazione** (`getUsersInAdministration` filtra per
`administration`). Firestore non consente di filtrare i campi in lettura: una
regola `read` è tutto-o-niente sul documento.

## Opzioni considerate

1. **Lasciare `read` aperto a tutti gli autenticati** — zero lavoro, ma espone
   tutta la rubrica (telefoni inclusi) a qualunque account, cross-amministrazione.
2. **Spostare i campi sensibili in una sub-collezione privata e tenere `read`
   aperto sul doc pubblico** — corretto sul lungo periodo, ma richiede migrazione
   dati + refactor dei reader/writer; non risolve l'harvesting dei campi rubrica
   (telefono) che restano pubblici per design.
3. **Restringere `read` alla stessa amministrazione** (+ doc proprio sempre
   leggibile) e aggiungere una sub-collezione `private/` owner-only per i dati
   davvero personali futuri. Allinea le regole al modello reale della feature.

## Decisione

Adottiamo l'**opzione 3**. La lettura di `users/{userId}` è permessa solo se il
richiedente è il proprietario **oppure** appartiene alla stessa
`administration` del documento target (verificata via `get()` sul doc del
richiedente). Aggiunta la sub-collezione `users/{uid}/private/{docId}`
leggibile/scrivibile solo dal proprietario, come casa per dati sensibili
(es. coordinate precise, impostazioni) senza esporli alla rubrica.

## Conseguenze

- **Positive:** un account non può più enumerare utenti / telefoni fuori dalla
  propria amministrazione. La rubrica colleghi continua a funzionare (stessa
  amministrazione). Esiste ora un posto owner-only per dati sensibili.
- **Negative / debiti tecnici:** ogni valutazione della regola fa un `get()`
  sul doc del richiedente → letture extra (costo) per ogni doc valutato in una
  query di rubrica. Le amministrazioni sono limitate, quindi accettabile. Un
  collega che cambia amministrazione non sarà più leggibile dai vecchi colleghi
  (fallback UI "Collega"). I campi GPS sede (`sedeLat/sedeLng`) restano nel doc
  pubblico: sono coordinate dell'ufficio (già pubbliche via `sedeAddress`),
  quindi non migrati; se in futuro si salveranno geo personali, vanno in
  `private/`.
- **Migrazione:** nessuna migrazione dati richiesta. Deploy regole:
  `firebase deploy --only firestore:rules`.

## Note

`firestore.rules` aggiornato con la function `myAdministration()` e il match
`private/{docId}`. La logica social (`getUsersInAdministration`,
`watchColleagues`) legge solo doc della stessa amministrazione, quindi resta
compatibile.
