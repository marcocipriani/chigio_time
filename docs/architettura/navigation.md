# Navigazione

Il router è definito in
[`lib/app/routes/app_router.dart`](../../lib/app/routes/app_router.dart) ed è
esposto da Riverpod. La shell usa `StatefulShellRoute.indexedStack` per
preservare stato e posizione delle cinque sezioni principali.

## Route

| Route | Tipo | Scopo |
|---|---|---|
| `/login` | root | autenticazione |
| `/onboarding` | root | profilo iniziale |
| `/dashboard` | tab 1 | Home |
| `/timesheet` | tab 2 | Cartellino |
| `/projects` | tab 3 | Progetti |
| `/social` | tab 4 | Colleghi |
| `/salary` | tab 5 | Stipendio |
| `/profile` | push root | Profilo |
| `/profile/edit` | push root | Modifica profilo |
| `/notifications` | push root | Inbox |
| `/chigio` | push root | Galleria Chigio |
| `/stats` | push root | Statistiche |
| `/sau` | push root | Andamento SAU |

```mermaid
flowchart TB
    R[GoRouter] --> L[/login]
    R --> O[/onboarding]
    R --> X[Route secondarie]
    R --> S{StatefulShellRoute}
    S --> H[/dashboard]
    S --> T[/timesheet]
    S --> P[/projects]
    S --> C[/social]
    S --> A[/salary]
```

## Guard di autenticazione e profilo

`resolveAppRedirect` è una funzione pura coperta da test. Le regole sono:

1. Utente non autenticato → `/login`.
2. Utente autenticato con profilo cache o server completo → route richiesta.
3. Cache incompleta, loading o errore → nessun redirect a onboarding.
4. Solo un profilo server incompleto o assente → `/onboarding`.
5. Utente completo su `/login` o `/onboarding` → `/dashboard`.

Il marker locale `hasProfile_<uid>` è solo positivo: accelera la Home ma non
può provare che il profilo sia incompleto.

Vedi [ADR-0014](../decisioni/0014-bootstrap-web-cache-first.md).

## Gate PCM

`PcmAssignmentGate` è montato sotto il `Navigator` delle route autenticate. I
selettori usano l’`Overlay` della route: spostare il gate sopra il Navigator
provoca errori runtime nei popup.

Login e onboarding restano fuori dal gate. Il gate appare soltanto a profili
PCM con struttura o sede non canoniche.

## Shell e adattamento

`MainShellScreen` combina:

- `AppBackground`;
- contenuto della branch corrente;
- `FloatingNav` mobile/web;
- navigazione adattata al layout desktop.

Le voci possono essere nascoste tramite `hiddenNavViews`, ma la branch e la
route restano stabili. Le scorciatoie desktop `1–5`, `T`, `O`, `Esc` e `?`
sono gestite dalla shell.

Su Web mobile la floating nav evita `BackdropFilter` durante lo scroll; native
e layout desktop mantengono il trattamento glass.

## Invarianti

- Non ricreare il router a ogni emissione auth/profilo.
- Non dedurre onboarding da errori o cache miss.
- I popup PCM devono avere un `Navigator`/`Overlay` sotto il proprio context.
- L’ordine delle branch deve restare allineato a nav, shortcut e
  `hiddenNavViews`.

_Ultima revisione: 2026-07-29._
