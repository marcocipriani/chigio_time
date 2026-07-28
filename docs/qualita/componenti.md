# Catalogo dei componenti

Inventario dei componenti riusabili che definiscono la struttura
dell'interfaccia. I widget privati di una singola schermata non sono un'API.

## Shell e fondazioni

| Componente | Responsabilità | Vincolo |
|---|---|---|
| `MainShellScreen` | shell responsive e cinque rami di navigazione | non ricreare il Navigator durante i rebuild |
| `FloatingNav` | navigazione primaria compatta | destinazioni coerenti con il router |
| `AppBackground` | sfondo di pagina | non ridurre contrasto o leggibilità |
| `GlassCard` / `GlassTile` | superfici condivise | usare i token del tema |
| `GlassBtn` | azione riusabile | target minimo 44×44 e stato disabilitato chiaro |
| `HomeWidgetHeader` | intestazione dei widget Home | titolo, icona e azioni con gerarchia stabile |
| `HomeWidgetEmpty` | stato vuoto con azione | spiegare il passo successivo |

## Home

| Componente | Responsabilità | Dipendenze |
|---|---|---|
| `TimbraturaHero` | entrata, pause, uscita e resoconto | `WorkTimer`, profilo, Chigio |
| `MonthlySummaryCard` | contatori mensili condivisi | timesheet e cap profilo |
| `FavoriteColleaguesCard` | azioni rapide sui preferiti | social |
| `PcmRoutePlannerCard` | percorso verso una sede PCM | catalogo PCM |
| `PomodoroCard` | stato o avvio rapido Pomodoro | progetti |
| `SalaryCard` | prossimo accredito e stima | stipendio |
| `OrariTableCard` | tabella degli orari teorici | profilo orario |

## Cartellino

| Componente | Responsabilità | Nota |
|---|---|---|
| `_ViewSelector` | seleziona Giorno, Lista, Settimana, Mese, Anno | controllo compatto responsive |
| `_EntrySheet` | crea o modifica una giornata | include segmenti, assenze e privacy |
| `_DayDetailCard` | riepilogo e azioni sul giorno | mostra saldo e anomalie |
| `_EmptyDayQuickAdd` | stato vuoto operativo | non confondere vuoto con errore |
| `MonthlySummaryCard` | riepilogo mensile | stessa implementazione della Home |

## Regole di evoluzione

- Estrarre un componente condiviso solo quando esistono almeno due consumatori
  reali o un contratto di design stabile.
- Gli stati loading, empty, error, offline e disabled fanno parte dell'API.
- Evitare copie divergenti: il riepilogo mensile deve restare un solo widget.
- Documentare qui nuovi componenti cross-feature e nei test i comportamenti
  accessibili essenziali.

Vedi [Principi di interfaccia](./interfaccia.md) e
[Layering](../architettura/layering.md).

_Ultima revisione: 2026-07-29._
