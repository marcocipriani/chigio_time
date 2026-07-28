# Deploy Firebase

Usare deploy limitati alla risorsa modificata. Prima di scrivere stato remoto,
verificare il progetto attivo con `firebase use` e il diff locale.

## Comandi

```bash
# Compilazione delle rules senza pubblicazione
firebase deploy --only firestore:rules --dry-run

# Risorse singole
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
firebase deploy --only functions

# Contratto notifiche: distribuire insieme
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Hosting è descritto in [Release Web](./web-release.md).

## Criteri

- Rules, query e indici sono una singola modifica logica.
- I producer di notifiche devono essere idempotenti.
- Il deploy verde non sostituisce uno smoke autenticato.
- Errori live e rollback vanno annotati nel changelog.
- Service account e token restano fuori dal repository e dai log.

_Ultima revisione: 2026-07-29._
