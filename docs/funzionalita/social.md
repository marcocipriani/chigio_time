# Feature: Social

## Scopo

Colleghi di lavoro in tempo reale: lista personalizzabile (per stessa
amministrazione), stato presenza, telefono visibile, inviti caffè con
notifica in-app.

## Stato

🟢 **Completamente implementato con dati reali Firestore, inclusi gruppi di colleghi.**

---

## Flusso principale

1. L'utente si **collega** ai colleghi della stessa amministrazione tramite il
   pulsante **"+"** / "Collegati con" (ricerca per nome, lista filtrata per
   admin, esclusi i profili privati).
2. Ogni collega mostra: avatar con **anello colorato per stato** (B5), nome,
   **interno/sede** (riga con icona ☎️), **piano/stanza** (riga con icona 📍),
   badge stato, pulsante 📞 (se `interno` o `phoneNumber` impostati), pulsante
   ☕, stella preferiti.
3. **Preferiti** appaiono in cima alla lista.
4. **Filtri** per sede, dipartimento e stato restringono la lista in modo cumulativo.
5. **Pull-to-refresh** aggiorna i profili dei colleghi da Firestore.

### Collegamenti reciproci (F1)

Politica "amichevole" auto-accettata: quando A si collega a B il legame è
**reciproco** e immediato (entrambi tra i "Collegati"), B riceve una notifica
`colleague_added`, **non** esiste richiesta/conferma né rimozione. Poiché le
rules vietano di scrivere nei `colleagues` altrui, `addColleague` scrive solo
lato A + notifica; il client di B riconcilia via
`reconcileIncomingConnections` (in `initState` di `SocialScreen`).

### Profilo privato (F2)

`users/{uid}.isPrivate == true` (toggle in Profilo › Impostazioni): il profilo
non compare in ricerca e non è aggiungibile (filtro client-side). Un
utente privato **vede** ancora gli altri ma **non può aggiungere** (FAB "+"
nascosto). Default pubblico.

### Anello stato avatar (B5)

`_SocialAvatar.ringColor` colora il bordo in base a `effectiveStatus`:
🟢 verde = in sede, 🔵 blu = smart, 🟡 giallo = pausa, ⚫ **nero** = uscito +
assenza (uniti). La spiegazione testuale è nel profilo collega
(`statusExplanation`).

---

## Stato colleghi

Lo stato è pubblicato su `users/{uid}.currentStatus` + `statusDate`
ogni volta che il timer cambia stato:

| `currentStatus` | Descrizione | Badge |
|---|---|---|
| `working` | Turno attivo, in ufficio | 🏢 In ufficio (verde) |
| `paused` | In pausa (caffè/permesso) | ☕ In pausa (arancione) |
| `remote` | Smart working | 🏠 Da remoto (blu) |
| `completed` | Turno completato oggi | 🌙 Uscito (nero) |
| `notStarted` | Fuori orario o data stale | — Non in ufficio (nero) |

Se `statusDate ≠ oggi` lo stato viene trattato come `notStarted`.

## Filtri colleghi

`_ColleagueFilterBar` mostra chip scroll orizzontali generati dai dati reali
dei colleghi:

- sede;
- dipartimento;
- stato corrente.

I filtri sono cumulativi e si disattivano con un secondo tap sul chip
selezionato.

---

## Invito caffè ☕

1. Utente A tocca ☕ sul collega B (icona visibile su **tutti** i colleghi).
2. Viene scritto un documento in `users/{B}/notifications/{id}` con
   `type: 'coffee_invite'`, `fromUid`, `fromName`, `status: 'pending'`.
3. B vede il punto rosso sul campanello nell'header.
4. B apre la schermata **Notifiche** e risponde con una delle 3 icone:
   - ✅ **Ci sono** → `responseType: 'accepted'`
   - 🤔 **Forse** → `responseType: 'maybe'`
   - ❌ **Non posso** → `responseType: 'declined'`
   Può allegare un messaggio testuale opzionale (max 160 caratteri).
5. Il documento originale viene aggiornato con `status: accepted|maybe|declined`.
6. **Back-notification (sempre)**: viene scritto un documento in `users/{A}/notifications/{id}` con
   `type: 'coffee_accepted'`, `fromUid` = B, `responseType`, `message?`, `status: 'info'`.
   A vede il tipo di risposta + eventuale messaggio di B.

---

## Chiamata diretta collega

Se `ColleagueProfile.phoneNumber` o `ColleagueProfile.interno` è valorizzato, su `_ColleagueCard` appare un pulsante 📞 verde. Al tap viene lanciato `launchUrl(Uri(scheme: 'tel', path: tel))` via `url_launcher`. Priorità: `phoneNumber` > `interno`.

> Nota: `interno` è un numero SIP/VOIP corto (es. 1234). Su mobile apre il dialer con il numero digitato; l'utente completa la chiamata manualmente se necessario.

## Schema Firestore

```
users/{uid}
  ├── currentStatus: String   ('notStarted'|'working'|'paused'|'remote'|'completed')
  ├── statusDate:    String   ('YYYY-MM-DD')
  ├── phoneNumber:   String?  (opzionale, editabile da profilo)
  ├── interno:       String?  (numero interno SIP, editabile da profilo)
  ├── dipartimento:  String?  (struttura PCM)
  ├── sede:          String?  (opzionale, editabile da profilo)
  ├── sedeId:        String?  (id sede PCM)
  ├── piano:         String?  (opzionale, editabile da profilo)
  ├── stanza:        String?  (opzionale, editabile da profilo)
  │
  ├── colleagues/{colleagueUid}
  │     ├── isFavorite: bool
  │     └── addedAt:    Timestamp
  │
  ├── groups/{groupId}
  │     ├── name:       String       (max 40 char)
  │     ├── createdAt:  Timestamp
  │     └── memberUids: List<String> (uid già in colleagues/)
  │
  └── notifications/{notifId}
        ├── type:         String    ('coffee_invite'|'coffee_accepted')
        ├── fromUid:      String
        ├── fromName:     String
        ├── sentAt:       Timestamp
        ├── status:       String    ('pending'|'accepted'|'maybe'|'declined'|'info')
        ├── responseType: String?   (solo per coffee_accepted: 'accepted'|'maybe'|'declined')
        ├── message:      String?   (messaggio opzionale del rispondente)
        └── read:         bool
```

---

## File coinvolti

| Path | Ruolo |
|---|---|
| `lib/features/social/domain/colleague.dart` | Modello `ColleagueProfile` |
| `lib/features/social/domain/app_notification.dart` | Modello `AppNotification` |
| `lib/features/social/data/social_repository.dart` | Repository Firestore + provider manuali |
| `lib/features/social/presentation/social_screen.dart` | Schermata principale |
| `lib/features/social/presentation/notifications_screen.dart` | Inbox notifiche |
| `lib/shared/widgets/glass_header.dart` | Campanello → `/notifications` con badge unread |
| `lib/features/profile/data/profile_repository.dart` | `updatePhoneNumber`, `updateCurrentStatus` |
| `lib/features/dashboard/presentation/timer_provider.dart` | Pubblica `currentStatus` su ogni transizione |
| `firestore.rules` | Regole sicurezza aggiornate |

---

## Regole Firestore richieste

Vedi `firestore.rules` nella root. Modifiche rispetto al default:
- `users/{userId}` → `allow read` per qualsiasi utente autenticato.
- `users/{userId}/notifications/{notifId}` → `allow create` per qualsiasi
  utente autenticato (per ricevere inviti dai colleghi).

---

## Gruppi di colleghi

Implementati in v0.5. Vedi [ADR-0002](../decisioni/0002-social-groups.md) per la motivazione della scelta schema.

**Flusso**:
1. **Crea gruppo**: tap `+` nel pannello gruppi → `AlertDialog` → `SocialRepository.createGroup(name)`.
2. **Aggiungi membro**: `SocialRepository.addMemberToGroup(groupId, colleagueUid)`.
3. **Rimuovi membro**: `removeMemberFromGroup(groupId, colleagueUid)`.
4. **Elimina gruppo**: long-press → confirm dialog → `deleteGroup(groupId)`.

**Layout desktop**: pannello sinistro gruppi (240 px) + pannello destro lista colleghi.
**Layout mobile**: i gruppi sono gestiti da `_GroupsMobileSheet`, accessibile dalla schermata Social.

> **Bug noto / fix applicato** — I dialog `AlertDialog` usano il `BuildContext` del builder della dialog (`dialogCtx`) per chiamare `Navigator.pop()`, non il contesto esterno del widget. L'uso del contesto esterno in un'app GoRouter causa `pop` dello stack GoRouter invece della dialog, con `AssertionError: currentConfiguration.isNotEmpty`.

---

## Provider

| Provider | Tipo | Scopo |
|---|---|---|
| `socialRepositoryProvider` | `Provider` | DI del repository |
| `colleaguesStreamProvider` | `StreamProvider.autoDispose` | lista colleghi in RT |
| `groupsStreamProvider` | `StreamProvider.autoDispose` | lista gruppi in RT |
| `notificationsStreamProvider` | `StreamProvider.autoDispose` | notifiche in RT |
| `hasUnreadProvider` | `Provider` | `true` se ci sono notifiche non lette |

_Ultima revisione: 2026-06-07 — aggiunti filtri sede/dipartimento/stato e gruppi mobile._

---

## Proposte evoluzione funzionalità caffè ☕

### 1. Stato "disponibile per caffè" (toggle)
Aggiungere un toggle rapido nella dashboard o nell'header che pubblica `coffeeAvailable: true/false` su Firestore. I colleghi vedono un badge verde ☕ solo per chi ha il toggle attivo. Riduce le risposte "Non posso" automatiche perché l'invito arriva solo a chi è davvero libero.

### 2. Caffè pianificato (con orario)
Invece di un invito istantaneo, aggiungere l'opzione "pianifica caffè alle [orario]" (time picker). I colleghi invitati ricevono la notifica all'orario scelto. Utile per pausare dopo una riunione o a un orario fisso.

### 3. Invito caffè di gruppo
Nella sezione **Gruppi**, aggiungere un pulsante ☕ che invia l'invito a tutti i membri del gruppo in un unico tap. `SocialRepository.sendGroupCoffee(groupId)` iterera sui `memberUids` creando una notifica per ciascuno.

### 4. Storia e statistiche caffè
Aggiungere una scheda nel profilo o nella sezione Social con:
- Caffè inviati/ricevuti nel mese corrente
- Chi ha risposto di più (collega con più ✅)
- Streak di caffè condivisi

Richiede aggiungere `coffeeStats` come sub-collezione o campo aggregato.

### 5. Risposta "in arrivo ☕" con ETA
Quarta risposta opzionale "Sto arrivando" con un selettore di minuti (5/10/15). Back-notify al mittente con l'ETA. Migliora il coordinamento senza scambi di messaggi extra.

### 6. Promemoria caffè ricorrente
Impostazione in Profilo > Notifiche: "Ricordami di invitare qualcuno al caffè ogni giorno alle HH:MM". Implementato come scheduled notification locale (già in pubspec: `flutter_local_notifications`) che apre la schermata Social. Nessuna infrastruttura server richiesta.
