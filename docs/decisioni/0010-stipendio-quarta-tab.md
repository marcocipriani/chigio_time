# ADR-0010 — Pagina Stipendio come 4ª tab + sub-collezione `salaryPayments`

- **Data:** 2026-06-15
- **Autore/i:** Claude Code (su richiesta di Marco)
- **Stato:** Accepted
- **Contesto correlato:** [`features/stipendio.md`](../features/stipendio.md), [`entities/salary-payment.md`](../entities/salary-payment.md), [`architecture/navigation.md`](../architecture/navigation.md), `lib/features/salary/`

## Contesto

Serve una pagina dedicata al tracciamento degli accrediti stipendiali (quando
arriva il prossimo, lordo/netto, storico per tipologia, note, notifica del
giorno). Due decisioni non ovvie:

1. **Dove collocarla in navigazione.** L'app ha 3 sezioni principali in
   `StatefulShellRoute.indexedStack` (Home/Timesheet/Social) — un vincolo
   architetturale documentato. Le pagine secondarie (`/stats`, `/chigio`,
   `/profile`) sono push sopra la shell.
2. **Come modellare i dati.** Lista di pagamenti per-utente.

## Opzioni considerate

**Navigazione**
- A. **Push route `/salary`** (come `/stats`): non tocca la nav a 3 tab, link da
  Profilo/Dashboard. Meno visibile.
- B. **4ª `StatefulShellBranch` + 4ª voce nella pill**: rende lo Stipendio una
  sezione di primo livello, ma allarga la pill e cambia l'architettura "3
  sezioni".

**Dati**
- C. Array sul doc profilo — gonfia il doc (leggibile dai colleghi, ADR-0008).
- D. **Sub-collezione `users/{uid}/salaryPayments/{id}`** owner-only.

## Decisione

**Opzione B + D.** Lo Stipendio diventa la **4ª tab** (scelta di prodotto di
Marco: è una pagina "completa" di primo livello). La pill mobile passa da 3 a 4
voci: larghezza tab ridotta `88→76 px` e padding laterale `20→12 px` per
restare entro i telefoni stretti (~360 px). Anche l'header-pill desktop e la
chiave nav (`_navViewKeys`) includono `salary`. I dati vivono in
`users/{uid}/salaryPayments/{id}`, owner-only, Firestore-only (nessun mirror
Drift, come `capPeriods`/`sau_monthly`).

La notifica "Stipendio in arrivo" **non** introduce un nuovo trigger: riusa lo
scheduler `hourlyNotifications` esistente (push diretto alle 08:00 del
`paydayDay`), come S2/P2.

## Conseguenze

- **Positive:** Stipendio è una sezione di primo livello, sempre raggiungibile;
  i dati sono isolati e non gonfiano il doc profilo; nessun nuovo meccanismo di
  notifica da mantenere.
- **Negative / debiti tecnici:** la pill a 4 voci è più stretta — accettabile su
  390–430 px (mobile-first), verificata fino a ~360 px. Se servisse una 5ª
  sezione servirà ripensare la nav (overflow/scroll o "more"). La nav resta
  comunque nascondibile per-voce via `hiddenNavViews`.

## Note

Modello in `salary_payment.dart` (`SalaryPayment`, `SalaryPaymentType`). Repo:
`salaryPaymentsStream`, `addPayment`, `updatePayment`, `deletePayment`. Regola
Firestore: `match /users/{uid}/salaryPayments/{id}` owner-only. Cloud Function:
blocco `notifyPayday` in `hourlyNotifications`.
