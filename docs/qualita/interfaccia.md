# Principi di interfaccia

Queste regole trasformano le decisioni di revisione UI in criteri permanenti.

## Gerarchia e layout

- Ogni schermata ha una sola azione primaria evidente.
- Le informazioni operative precedono configurazione e storico.
- Il contenuto testuale usa larghezze leggibili; desktop non significa
  allargare indefinitamente le card.
- Su mobile, scroll e caricamento sono progressivi: evitare di costruire
  l'intera Home fuori viewport.
- Una funzione condivisa usa lo stesso componente in ogni schermata.

## Stati dell'interfaccia

Loading, empty, error, offline e dati parziali sono stati distinti. Un errore
non deve apparire come una lista vuota. Ogni errore recuperabile espone una
azione concreta; un'operazione in corso impedisce doppi invii.

Il bootstrap Web mostra subito una struttura coerente con la Home Flutter e
la sostituisce senza salto visivo appena l'app è pronta.

## Accessibilità

- Target interattivi almeno 44×44 punti.
- Icone non ovvie hanno tooltip e nome semantico.
- Focus da tastiera visibile; ordine coerente con la lettura.
- Contrasto verificato nei temi chiaro e scuro.
- Animazioni rispettano reduced motion e non sono necessarie per capire lo
  stato.
- Colore e icona non sono l'unico modo di comunicare un'anomalia.

## Feedback e dati

- Salvataggi e import mostrano esito, righe scartate e sovrascritture prima
  della conferma.
- Timer e azioni remote distinguono stato locale, invio e conferma server.
- Skeleton e placeholder preservano la geometria finale.
- CTA degli stati vuoti portano direttamente all'azione che risolve il vuoto.

## Prestazioni

- Limitare i rebuild al dato che cambia: il tick del timer non ricostruisce
  l'intera Home.
- Effetti costosi sul Web sono selettivi e disattivabili.
- Liste lunghe e Home mobile usano builder o sliver.
- Immagini decorative hanno dimensioni e cache coerenti con il punto d'uso.

## Criterio di completamento

Una modifica UI è completa quando copre almeno: happy path, loading, empty,
error, tema scuro, viewport mobile e interazione tastiera dove applicabile.

_Ultima revisione: 2026-07-29._
