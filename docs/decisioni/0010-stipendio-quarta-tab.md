# ADR-0010 — Stipendio nella navigazione primaria

- **Data:** 2026-06-15
- **Owner:** Marco Cipriani
- **Stato:** Accepted
- **Contesto correlato:** [`funzionalita/stipendio.md`](../funzionalita/stipendio.md), [`entita/salary-payment.md`](../entita/salary-payment.md), [`architettura/navigation.md`](../architettura/navigation.md), `lib/features/salary/`

## Contesto

Serve una pagina dedicata al tracciamento degli accrediti stipendiali (quando
arriva il prossimo, lordo/netto, storico per tipologia, note, notifica del
giorno). Due decisioni non ovvie:

1. **Dove collocarla in navigazione.** Al momento della decisione l'app aveva
   tre sezioni principali. Le pagine secondarie erano push sopra la shell.
2. **Come modellare i dati.** Lista di pagamenti per-utente.

## Opzioni considerate

**Navigazione**
- A. **Push route `/salary`** (come `/stats`): non tocca la nav esistente, link da
  Profilo/Dashboard. Meno visibile.
- B. **4ª `StatefulShellBranch` + 4ª voce nella pill**: rende lo Stipendio una
  sezione di primo livello, ma allarga la pill e cambia l'architettura "3
  sezioni".

**Dati**
- C. Array sul doc profilo — gonfia il doc (leggibile dai colleghi, ADR-0008).
- D. **Sub-collezione `users/{uid}/salaryPayments/{id}`** owner-only.

## Decisione

**Opzione B + D.** Lo Stipendio diventa una destinazione di primo livello.
La shell e le sue chiavi includono `salary`. I dati vivono in
`users/{uid}/salaryPayments/{id}`, owner-only, Firestore-only (nessun mirror
Drift, come `capPeriods`/`sau_monthly`).

La notifica "Stipendio in arrivo" usa il contratto inbox-first di ADR-0012.

## Conseguenze

- **Positive:** Stipendio è una sezione di primo livello, sempre raggiungibile;
  i dati sono isolati e non gonfiano il doc profilo; nessun nuovo meccanismo di
  notifica da mantenere.
- **Evoluzione:** l'introduzione di Progetti ha portato la shell a cinque
  destinazioni. La decisione stabile è mantenere Stipendio al primo livello,
  non il numero storico di tab. La visibilità resta configurabile.

## Note

Modello in `salary_payment.dart` (`SalaryPayment`, `SalaryPaymentType`). Repo:
`salaryPaymentsStream`, `addPayment`, `updatePayment`, `deletePayment`. Regola
Firestore: `match /users/{uid}/salaryPayments/{id}` owner-only. Cloud Function:
producer payday e delivery inbox-first descritti in ADR-0012.
