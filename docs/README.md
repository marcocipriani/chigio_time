# Documentazione di Chigio Time

Questa è la fonte canonica per prodotto, architettura, dominio, processi e
decisioni. È organizzata per rispondere prima alla domanda del lettore, non
secondo l’ordine in cui il progetto è stato sviluppato.

## Da dove iniziare

### Uso l’app

1. [Guida utente](./panoramica/guida-utente.md)
2. [Concetti delle schermate](./panoramica/concetti-pagine.md)
3. [Glossario](./glossario.md)

### Devo capire il progetto

1. [Panoramica e confini](./panoramica/README.md)
2. [Requisiti](./panoramica/requirements.md)
3. [Architettura](./architettura/README.md)
4. [Mappa delle feature](./funzionalita/README.md)
5. [Modello di dominio](./entita/README.md)

### Devo sviluppare o fare manutenzione

1. [CONTRIBUTING.md](../CONTRIBUTING.md)
2. [Layering](./architettura/layering.md)
3. [State management](./architettura/state-management.md)
4. [Persistenza](./architettura/persistence.md)
5. [Sicurezza](./architettura/sicurezza.md)
6. [Testing](./processi/testing.md)

### Devo operare o rilasciare

1. [Indice dei processi](./processi/README.md)
2. [Release Web](./processi/web-release.md)
3. [Deploy Firebase](./processi/firebase-deploy.md)
4. [Manutenzione catalogo PCM](./processi/catalogo-pcm.md)

### Devo capire una scelta

Consulta il [registro ADR](./decisioni/README.md). Le ADR descrivono contesto,
alternative, decisione e conseguenze; non sono piani di implementazione.

## Mappa completa

### Prodotto

- [Panoramica](./panoramica/README.md)
- [Guida utente](./panoramica/guida-utente.md)
- [Requisiti](./panoramica/requirements.md)
- [Concetti delle schermate](./panoramica/concetti-pagine.md)
- [Roadmap](./ROADMAP.md)

### Architettura

- [Overview](./architettura/README.md)
- [Layering](./architettura/layering.md)
- [State management](./architettura/state-management.md)
- [Navigazione](./architettura/navigation.md)
- [Persistenza](./architettura/persistence.md)
- [Sicurezza](./architettura/sicurezza.md)

### Dominio

- [Indice delle entità](./entita/README.md)
- [DailyTimesheet](./entita/daily-timesheet.md)
- [TimerState](./entita/timer-state.md)
- [UserProfile](./entita/user-profile.md)
- [OnboardingState](./entita/onboarding-state.md)
- [Catalogo Dipartimenti/Strutture](./entita/dipartimenti-pcm.md)
- [Sedi PCM](./entita/sedi-pcm.md)
- [Project e PomodoroSession](./entita/progetto.md)
- [SalaryPayment](./entita/salary-payment.md)

### Funzionalità

- [Indice delle feature](./funzionalita/README.md)
- [Autenticazione](./funzionalita/authentication.md)
- [Onboarding](./funzionalita/onboarding.md)
- [Dashboard](./funzionalita/dashboard.md)
- [Orario e presenza](./funzionalita/orario-e-presenza.md)
- [Timesheet](./funzionalita/timesheet.md)
- [Social](./funzionalita/social.md)
- [Progetti](./funzionalita/progetti.md)
- [Stipendio](./funzionalita/stipendio.md)
- [Profilo](./funzionalita/profile.md)
- [Chigio](./funzionalita/chigio.md)
- [Identità visiva di Chigio](./funzionalita/chigio-identita-visiva.md)

### Qualità e riferimenti

- [Standard dell’interfaccia](./qualita/interfaccia.md)
- [Inventario componenti](./qualita/componenti.md)
- [CCNL PCM](./ccnl/README.md)
- [Glossario](./glossario.md)
- [Archivio](./archivio/README.md)
- [Changelog](./CHANGELOG.md)

## Regole editoriali

- Ogni pagina deve dichiarare scopo, stato attuale e riferimenti al codice.
- Le decisioni durevoli vanno in una ADR, non in piani temporanei.
- I documenti superati vanno in `archivio/` con un avviso esplicito.
- Le cartelle di strumenti, sessioni o agenti non sono documentazione.
- Una pagina nuova o spostata deve essere registrata in
  [`navigation.json`](./navigation.json).
- `node scripts/check_docs.mjs` deve passare prima del commit.

_Ultima revisione: 2026-07-29 — architettura informativa, navigazione e fonti
canoniche consolidate._
