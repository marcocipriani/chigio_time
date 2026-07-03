# Entità — SalaryPayment

> Un singolo **accredito stipendiale** (cedolino) ricevuto dall'utente.
> Sorgente canonica: `users/{uid}/salaryPayments/{autoId}` (Firestore).
> Definizione Dart: `lib/features/salary/domain/salary_payment.dart`.

---

## Scopo

Rappresenta un accredito sul conto: emissione ordinaria mensile, emissione
straordinaria (arretrati/conguagli), accredito buoni pasto, o altro. È la
base della pagina [Stipendio](../funzionalita/stipendio.md). I dati sono inseriti
**manualmente** dall'utente — non c'è ancora import da NoiPA.

---

## Campi

| Campo Dart | Tipo | Firestore | Note |
|---|---|---|---|
| `id` | String | doc id | Auto-id Firestore. |
| `date` | DateTime (date-only) | `date` string `YYYY-MM-DD` | Data accredito; chiave di ordinamento (desc). |
| `type` | `SalaryPaymentType` | `type` string | `ordinaria`, `straordinaria`, `buoniPasto`, `altro`. Gli id sono stabili. |
| `grossAmount` | double | `grossAmount` num | Lordo da cedolino (€). `0` = non inserito. |
| `netAmount` | double | `netAmount` num | Netto accreditato (€). Obbligatorio `> 0`. |
| `note` | String? | `note` string | Nota libera (omessa se vuota). |
| `manual` | bool | `manual` bool | `true` = inserimento manuale (vs. import futuro). |
| `createdAt` | DateTime? | `createdAt` serverTimestamp | Audit. |

### Getter derivati

- `monthId` → `YYYY-MM` (raggruppamento per mese in lista).
- `dateId` → `YYYY-MM-DD` (serializzazione `date`).
- `year` → anno dell'accredito.

---

## Tipologie (`SalaryPaymentType`)

| Id | Label IT | Colore UI |
|---|---|---|
| `ordinaria` | Emissione ordinaria | blu (`blue400`) |
| `straordinaria` | Emissione straordinaria | ambra (`#F59E0B`) |
| `buoniPasto` | Buoni pasto | verde (`green500`) |
| `altro` | Altro | viola (`#8B5CF6`) |

Solo gli accrediti `ordinaria` con `netAmount > 0` alimentano la **stima del
netto** (media degli ultimi 3) mostrata nella card "Prossimo accredito".

---

## Regole & persistenza

- Firestore: `users/{uid}/salaryPayments/{id}` — **owner only**
  (`firestore.rules`).
- Nessun mirror Drift (Firestore-only, come `capPeriods` e `sau_monthly`);
  l'offline è gestito dalla cache dell'SDK Firestore.

Vedi anche [`../architettura/persistence.md`](../architettura/persistence.md).
