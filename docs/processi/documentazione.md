# Manutenzione della documentazione

La documentazione è parte della modifica, non un'attività successiva.

## Fonte unica

- `docs/navigation.json` definisce il menu del portale.
- Le pagine Markdown contengono la conoscenza.
- `docs/index.html` renderizza il manifest; non mantiene un secondo elenco.
- Le ADR conservano le motivazioni, il changelog registra i cambiamenti e
  l'archivio contiene solo snapshot ancora utili.

## Per ogni modifica

1. Aggiornare la scheda feature o entità coinvolta.
2. Aggiornare persistenza o sicurezza se cambia un contratto dati.
3. Creare una ADR solo per una decisione non ovvia.
4. Aggiungere una voce a `docs/CHANGELOG.md`.
5. Aggiornare `docs/navigation.json` per nuove pagine.
6. Eseguire:

```bash
node scripts/check_docs.mjs
```

Il controllo valida link relativi, pagine del manifest, duplicati e riferimenti
a documentazione operativa rimossa.

## Stile

Scrivere per chi non conosce il repository: scopo prima dei file, termini
definiti nel glossario, stato corrente distinto dalla storia, comandi
copiabili e limiti dichiarati.

_Ultima revisione: 2026-07-29._
