# ADR-0014 — Bootstrap Web e gate profilo cache-first tipizzato

- **Data:** 2026-07-22
- **Autore/i:** Marco Cipriani, Codex
- **Stato:** Accepted
- **Contesto correlato:** [Authentication](../funzionalita/authentication.md), [Onboarding](../funzionalita/onboarding.md), [Dashboard](../funzionalita/dashboard.md)

## Contesto

Su Chrome e PWA Android un avvio a freddo poteva lasciare la pagina vuota
mentre `main()` attendeva font, Firebase, locale e preferenze. Subito dopo, un
documento profilo assente o incompleto nella sola cache Firestore poteva essere
ridotto a `false` e mostrare per un istante l'onboarding a un utente esistente.
Chrome e PWA possono inoltre aprire due contesti Web sullo stesso dispositivo,
quindi la persistenza Firestore deve supportare più tab senza duplicare una
seconda cache applicativa della Home.

## Opzioni considerate

1. **Gate solo server** — autorevole ma lento e inutilizzabile offline.
2. **Gate booleano cache-first** — rapido, ma perde provenienza e stato
   dell'errore; un miss locale può sembrare un nuovo utente.
3. **Gate cache/server tipizzato** — conserva metadata, profilo utilizzabile ed
   errore, lasciando al solo server l'autorità di richiedere onboarding.

## Decisione

Adottiamo un bootstrap con skeleton DOM e Flutter, font UI locali, cache
Firestore Web persistente multi-tab e gate profilo tipizzato. Una cache completa
può aprire la Home; cache incompleta, loading ed errore non scelgono onboarding.
Solo uno snapshot server incompleto o assente ha quell'autorità.

## Conseguenze

- **Positive:** primo paint immediato; riapertura PWA più stabile; Home rapida e
  disponibile con profilo cache valido; nessun flash onboarding da cache/errori.
- **Negative / debiti tecnici:** un nuovo utente attende la risposta server;
  se IndexedDB non è disponibile Firestore degrada alla memoria e il bootstrap
  prosegue, ma l'offline cold-start perde il vantaggio della cache.
- **Migrazione:** `hasProfile_<uid>` resta un marker positivo; viene scritto
  dopo onboarding o conferma server e rimosso solo da un server incompleto.
  `hasProfileStreamProvider` è sostituito da `profileGateProvider`.

## Note

La persistenza multi-tab usa `WebPersistentMultipleTabManager`. Le decisioni
del router sono isolate in `resolveAppRedirect` e coperte da una truth table.
