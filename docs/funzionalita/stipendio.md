# Feature — Stipendio

> Pagina dedicata al tracciamento degli accrediti stipendiali: **quando**
> arriva il prossimo accredito, **quanto** (lordo da cedolino + netto), e lo
> **storico** dei pagamenti ricevuti con tipologia e note. È la **4ª tab**
> della bottom-nav (vedi [ADR-0010](../decisioni/0010-stipendio-quarta-tab.md)).

---

## Obiettivo

Il dipendente PA non ha un posto unico dove tenere traccia dei propri
accrediti: cedolini sparsi su NoiPA, buoni pasto a parte, emissioni
straordinarie (arretrati, conguagli) impreviste. Questa pagina dà:

- un **countdown** al prossimo accredito (giorno-paga, default 23, PCM);
- una **stima del netto** dalla media degli ultimi accrediti ordinari;
- una **notifica push** il giorno dell'accredito (opt-in);
- uno **storico** completo, raggruppato per mese, con tipologia colorata,
  importi lordo/netto e note;
- inserimento **manuale** di qualunque accredito (l'utente è la fonte dati).

---

## File coinvolti

| Layer | File | Ruolo |
|---|---|---|
| domain | `lib/features/salary/domain/salary_payment.dart` | Modello `SalaryPayment` + enum `SalaryPaymentType` (`ordinaria`/`straordinaria`/`buoniPasto`/`altro`). Vedi [entità](../entita/salary-payment.md). |
| data | `lib/features/salary/data/salary_repository.dart` | `SalaryRepository` (CRUD Firestore-only) + provider `salaryRepositoryProvider`, `salaryPaymentsStreamProvider`. |
| presentation | `lib/features/salary/presentation/salary_screen.dart` | `SalaryScreen`: hero "Prossimo accredito", strip statistiche anno, lista raggruppata per mese, FAB + sheet di add/edit. Calcoli derivati in `_SalaryStats`. |
| routing | `lib/app/routes/app_router.dart` | 4ª `StatefulShellBranch` → `/salary`. |
| nav | `lib/shared/widgets/floating_nav.dart`, `main_shell_screen.dart` | 4ª voce nella pill (mobile) e nell'header pill (desktop); chiave nav `salary`. |
| notifiche | `lib/features/profile/presentation/profile_screen.dart` (`_NotificationSheet`) | Toggle "Stipendio in arrivo" + stepper giorno accredito (1–28). |
| backend | `functions/index.js` (`hourlyNotifications`) | Push FCM alle 08:00 del giorno-paga quando `notifyPayday == true`. |
| rules | `firestore.rules` | `users/{uid}/salaryPayments/{id}` owner-only. |
| strings | `lib/core/constants/app_strings.dart` | Blocco `salary*` + `navSalary` + `notifPayday*`. |

---

## Modello dati

`users/{uid}/salaryPayments/{autoId}`:

| Campo | Tipo | Note |
|---|---|---|
| `date` | string `YYYY-MM-DD` | Data accredito; sort key (desc). |
| `type` | string | `ordinaria` \| `straordinaria` \| `buoniPasto` \| `altro`. |
| `grossAmount` | num | Lordo da cedolino (€). `0` se non inserito. |
| `netAmount` | num | Netto accreditato (€). Obbligatorio (> 0). |
| `note` | string? | Nota libera dell'utente. |
| `manual` | bool | `true` = inserito a mano (vs. import futuro). |
| `createdAt` | serverTimestamp | Audit. |

Campi profilo correlati su `users/{uid}`:
`notifyPayday` (bool), `paydayDay` (int, default 23).

---

## Calcoli derivati (`_SalaryStats`)

- **Prossimo accredito** = prima occorrenza di `paydayDay` ≥ oggi (questo mese
  o il prossimo). `paydayDay` è clampato a 1–28 per evitare mesi corti.
- **Stima netto** = media del `netAmount` degli ultimi 3 accrediti di tipo
  `ordinaria`. `null` (mostra `—`) se non c'è storico ordinario.
- **Netto anno / Cedolini / Media netto** = somma, conteggio e media del netto
  per l'anno corrente.

---

## Flusso utente

1. Apre la tab **Stipendio** → vede countdown + stima netto.
2. Tocca **🔔 Avvisami** → scrive `notifyPayday` sul profilo. Il giorno e
   l'ora (08:00) e il giorno del mese si regolano in **Profilo › Notifiche**.
3. Tocca **+ Aggiungi** (FAB o header) → sheet: tipo, data, lordo, netto, note.
4. Salva → `salaryRepository.addPayment` → comparsa in lista in tempo reale.
5. Tocca una riga → stesso sheet in modalità modifica (con **Elimina**).

---

## Notifica "Stipendio in arrivo"

Riusa lo scheduler esistente `hourlyNotifications` (Cloud Function, ogni 60
min, TZ Europe/Rome) — stesso pattern di S2 (colleghi mattina) e P2 (recap
settimanale). Alle **08:00** del giorno `paydayDay` invia un push FCM diretto
(nessun documento inbox), titolo `💶 Stipendio in arrivo`.

> Quando si tocca questo flusso mantenere allineati: client (toggle profilo),
> `functions/index.js`, e — se in futuro si scrivesse un doc inbox —
> `firestore.rules` + `_buildNotification`.

---

## Stato

✅ Implementata (2026-06-15). Firestore-only (nessun mirror Drift, come
`capPeriods`/`sau_monthly`).

## Gap noti / evoluzioni

Vedi backlog in [`../ROADMAP.md`](../ROADMAP.md): stima netto da lordo
(aliquote IRPEF/addizionali), tredicesima, confronto cedolini, allegato PDF
del cedolino, grafico andamento netto, riconciliazione buoni pasto col
timesheet, export.
