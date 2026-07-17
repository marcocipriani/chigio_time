# Design: notifiche push affidabili e multi-device

Data: 2026-07-17 · Stato: approvato in brainstorming

## Obiettivo

Rendere le notifiche affidabili anche ad applicazione chiusa su Android, iOS,
macOS e Web, senza errori sulle piattaforme non supportate. Il sistema deve:

- consegnare la stessa notifica a tutte le installazioni attive dell'utente;
- mantenere sempre l'evento nell'inbox Firestore;
- rispettare il periodo Non disturbare;
- aprire la sezione corretta dell'app;
- rendere osservabile l'esito della consegna;
- eliminare controlli UI non collegati a comportamenti reali.

Windows e Linux non ricevono push: l'inizializzazione FCM viene saltata senza
bloccare il resto dell'app.

## 1. Architettura: inbox prima, push dopo

Tutti gli eventi, sociali e automatici, creano un documento in:

```text
users/{uid}/notifications/{notificationId}
```

Una sola Cloud Function `onNotificationCreated` traduce il documento in un
messaggio FCM. In questo modo inbox, DND, routing, logging e pulizia token hanno
un unico punto di verita'. Le notifiche automatiche non inviano piu' FCM
direttamente.

Campi comuni:

```text
type, title, body, route, sentAt, read
pushStatus, pushedAt, pushError
```

`pushStatus` vale `sent`, `suppressed`, `no-token` o `failed`. Le notifiche di
prova ignorano DND; tutte le altre push vengono soppresse durante la fascia di
silenzio, ma restano nell'inbox.

## 2. Registrazione multi-device

Il documento privato esistente `users/{uid}/private/fcm` contiene una mappa di
installazioni:

```text
installations.{installationId} = {
  token,
  platform,
  updatedAt
}
```

`installationId` e' un UUID locale persistente, non sensibile. Il client:

1. richiede il permesso solo sulle piattaforme FCM supportate;
2. registra o aggiorna la propria installazione;
3. aggiorna la voce al refresh del token;
4. rimuove la voce e cancella il token locale prima del logout.

La Function legge temporaneamente anche il vecchio campo singolo `token`, per
una migrazione compatibile. I token rifiutati definitivamente da FCM vengono
rimossi dalla sola installazione interessata.

## 3. Eventi automatici

### Promemoria uscita

Lo stato timer remoto salva `reminderAt`, calcolato da uscita prevista meno la
soglia configurata. Pausa, ripresa, cambio soglia e fine turno aggiornano o
rimuovono il campo.

Una Function schedulata ogni minuto cerca i reminder scaduti, li reclama in
transazione e crea una notifica inbox deterministica. Il ticker Flutter non
invia piu' la notifica: puo' mostrare solo lo stato aggiornato dell'interfaccia.
Questo evita duplicati e funziona ad app chiusa.

### Recap e promemoria periodici

La Function periodica viene allineata al minuto `0` e crea documenti inbox per:

- colleghi presenti al mattino;
- recap della settimana corrente, da lunedi' al momento dell'invio;
- giorno dello stipendio.

Gli ID deterministici impediscono doppi invii per giorno, settimana o mese.

### Soglia straordinario

Una Function sulle modifiche ai timesheet ricalcola lo straordinario positivo
del mese. Al primo superamento della soglia crea una notifica deterministica;
non la ripete nello stesso mese.

## 4. Preferenze

Restano solo preferenze con comportamento reale:

- minuti di anticipo uscita;
- Non disturbare e fascia oraria;
- colleghi presenti al mattino e orario;
- recap settimanale, giorno e orario;
- soglia straordinario mensile;
- giorno stipendio.

Vengono rimossi i toggle legacy `notifyClockIn`, `notifyClockOut` e
`notifyWeekly`: sono inattivi o duplicati. Non viene introdotto un promemoria
entrata.

La schermata espone inoltre "Invia notifica di prova", che crea un evento
inbox `test` e mostra l'esito registrato dalla Function.

## 5. Routing e piattaforme

Il payload FCM contiene `type` e una `route` appartenente a una allowlist:

| Evento | Destinazione |
|---|---|
| uscita | Dashboard |
| colleghi, inviti, risposte | Social / Notifiche |
| recap, soglia straordinario | Statistiche |
| stipendio | Stipendio |
| test | Notifiche |

Il client usa la stessa risoluzione per app terminata, background e tap in
foreground. Route sconosciute ricadono su `/notifications`.

Configurazione piattaforme:

- Android: channel `chigio_notifications` creato nativamente e dichiarato come
  default FCM;
- iOS: capability APS e background mode `remote-notification`;
- macOS: entitlement APS e accesso rete client;
- Web: service worker sul dominio corrente e `fcm_options.link` coerente con
  la route;
- Windows/Linux: FCM non inizializzato.

L'upload della chiave APNs in Firebase Console resta un prerequisito operativo
da verificare con una build firmata su dispositivo reale.

## 6. Errori e osservabilita'

Le Function non mascherano piu' gli errori di invio. Registrano log strutturati
con `uid`, `notificationId`, tipo ed esito, senza token completo. Un errore di
una installazione non impedisce l'invio alle altre.

Il documento inbox conserva l'ultimo esito push. Gli errori transitori restano
visibili; i token non registrati o invalidi vengono rimossi.

## 7. Test e rilascio

Sviluppo test-first:

- Node: DND, intervalli notturni, recap settimanale, routing/copy, deduplica e
  classificazione errori token;
- Dart: piattaforme supportate, allowlist route e stato timer/reminder;
- configurazione: channel Android, entitlement Apple, service worker Web;
- regressione: `flutter analyze`, `flutter test`, test Functions e controllo
  sintassi;
- verifica live: deploy Functions/Rules/Web, creazione notifica di prova,
  log Function e ricezione su almeno un dispositivo/browser autorizzato.

Codice, ADR, wiki delle feature/entita' e `docs/CHANGELOG.md` vengono aggiornati
nello stesso insieme di commit. Nessuna nuova dipendenza Flutter.

## Decisioni chiave

| Domanda | Scelta |
|---|---|
| Piattaforme | Android, iOS, macOS, Web; fallback sicuro Windows/Linux |
| Multi-device | Si', una voce per installazione |
| Architettura | Firebase-only, inbox Firestore come sorgente |
| Reminder uscita | Server-side ogni minuto |
| Non disturbare | Blocca tutte le push non critiche, non l'inbox |
| Toggle legacy | Rimossi |
| Promemoria entrata | Fuori scope |
| Dipendenze Flutter | Nessuna nuova |
