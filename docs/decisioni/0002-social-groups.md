# ADR-0002 — Gruppi di colleghi: sub-collezione Firestore per-utente

- **Data:** 2026-04-29
- **Autore/i:** Marco Cipriani
- **Stato:** Accepted
- **Contesto correlato:** [`docs/funzionalita/social.md`](../funzionalita/social.md)

## Contesto

La schermata Social permette all'utente di seguire i colleghi della stessa
amministrazione. Con l'aumento dei colleghi, emerge la necessità di
organizzarli in **gruppi nominati** (es. "Team Backend", "Ufficio 3B") per
filtrare rapidamente la visualizzazione. I gruppi sono privati dell'utente
che li crea — non sono strutture condivise.

Il modello dati esistente prevede già una sub-collezione
`users/{uid}/colleagues/{colleagueUid}`. È necessario decidere dove e come
archiviare i gruppi e la loro composizione.

## Opzioni considerate

1. **Campo array su `users/{uid}`** — aggiungere un campo
   `groups: List<{name, memberUids}>` direttamente al documento profilo.
   - Pro: un solo documento da leggere.
   - Contro: documento cresce senza bound (Firestore ha limite 1 MB/doc);
     difficile aggiornare atomicamente un singolo gruppo; impossibile
     usare snapshot listener per-gruppo.

2. **Sub-collezione `users/{uid}/groups/{groupId}`** — un documento per
   gruppo, con campo `memberUids: List<String>`.
   - Pro: scalabile, aggiornamento atomico con `arrayUnion/arrayRemove`,
     listener real-time per-gruppo, query semplice.
   - Contro: un'ulteriore sub-collezione da gestire nelle regole Firestore.

3. **Collezione globale `groups/{groupId}`** — gruppi come entità di primo
   livello, con campo `ownerUid`.
   - Pro: eventuale condivisione gruppi tra utenti in futuro.
   - Contro: introduce complessità di sicurezza (regole `ownerUid == request.auth.uid`),
     query più costose, fuori scope per il caso d'uso corrente.

## Decisione

Adottiamo la **sub-collezione `users/{uid}/groups/{groupId}`** (Opzione 2).

Schema documento:
```
users/{uid}/groups/{groupId}
  ├── name:       String      (max 40 char)
  ├── createdAt:  Timestamp
  └── memberUids: List<String>
```

`memberUids` contiene uid di utenti già presenti in `colleagues/`.
I profili dei membri vengono letti da `users/{memberUid}` (già accessibili
per la feature Social). Nessuna denormalizzazione dei dati del collega nel
gruppo — si evita drift tra profilo reale e copia nel gruppo.

## Conseguenze

- **Positive:**
  - Aggiornamento atomico dei membri con `FieldValue.arrayUnion` /
    `FieldValue.arrayRemove`.
  - Listener real-time sulla collezione `groups/` senza leggere l'intero
    profilo utente.
  - Nessun limite pratico sul numero di gruppi o di membri.
- **Negative / debiti tecnici:**
  - Aggiunta di regole Firestore: `groups/{groupId}` leggibile e scrivibile
    solo da `request.auth.uid == userId` (il proprietario).
  - Se in futuro si vuole condivisione gruppo tra utenti, sarà necessaria
    una migrazione alla struttura globale (Opzione 3).
- **Migrazione:** nessuna — feature nuova, nessun dato preesistente da migrare.

## Note

- `memberUids` non ha un limite esplicito. In pratica è limitato al numero
  di colleghi dell'utente (tipicamente < 100 per il target CCNL settore pubblico).
- La dimensione massima del documento rimane ampiamente sotto il limite Firestore
  (1 MB) anche con 100 uid di 28 char ciascuno.
