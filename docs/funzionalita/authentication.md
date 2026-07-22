# Feature: Authentication

## Scopo

Permettere all'utente di accedere all'app con Google oppure con
email/password, gestire registrazione/reset password e mantenere lo stato di
sessione reattivo per tutta l'app.

## Requisiti coperti

RF-01, RF-02, RF-03, RF-04 — vedi
[`../panoramica/requirements.md`](../panoramica/requirements.md).

## File coinvolti

| Path | Ruolo |
|---|---|
| `lib/app/bootstrap/app_bootstrap.dart` | Monta subito la skeleton Flutter, inizializza Firebase/cache/locale/preferenze e mostra un errore umano con retry se il bootstrap fallisce. |
| `lib/features/authentication/data/auth_repository.dart` | Provider `firebaseAuthProvider`, `authStateChangesProvider`, `authRepositoryProvider`; classe `AuthRepository` con `signInWithGoogle()`, `signInWithEmail()`, `registerWithEmail()`, `sendPasswordReset()`, `signOut()`. |
| `lib/features/authentication/presentation/login_screen.dart` | UI login/registrazione: bottone Google con icona PNG ufficiale, form email, reset password, card centrata con max width 420px. |
| `lib/app/routes/app_router.dart` | Redirect basato su `authStateChanges`. |
| `lib/shared/widgets/pcm_assignment_gate.dart` | Gate post-login per coppie PCM legacy non canoniche. |
| `lib/features/authentication/domain/auth_service.dart` | **Vuoto** (placeholder). |
| `assets/images/google_g_logo.png` | Logo Google usato nel bottone di accesso. |

## UI login

- Il contenitore principale e' vincolato a `maxWidth: 420` sugli schermi
  grandi, quindi non si estende da lato a lato del viewport.
- Il bottone Google usa sfondo bianco, logo `google_g_logo.png` e font
  Roboto, in linea con il branding Google.
- Il motto visualizzato sotto il logo e' `AppStrings.chigioMotto`:
  "Amministrativamente lento, by design."
- Il link "Non hai un account?" resta nel flusso email e porta alla modalità
  registrazione senza nascondere il bottone Google.

## Flusso utente

### Avvio applicazione

Su Web il primo paint non dipende dal download e dall'avvio di Flutter:

1. `web/index.html` mostra una skeleton strutturale della Home;
2. il primo `runApp()` sincrono la sostituisce con la skeleton Flutter;
3. Firebase, cache Firestore persistente multi-tab, locale e preferenze vengono
   inizializzati dietro la skeleton;
4. al completamento viene montata l'app autenticata; un errore di bootstrap
   mostra un messaggio leggibile e il comando `Riprova`.

La skeleton mantiene la stessa geometria tra DOM e Flutter e rispetta la
preferenza di sistema per il movimento ridotto.

```mermaid
sequenceDiagram
    actor U as Utente
    participant LS as LoginScreen
    participant AR as AuthRepository
    participant FBA as FirebaseAuth
    participant GS as GoogleSignIn
    participant R as Router

    U->>LS: tap "Accedi con Google"
    alt Web
        LS->>AR: signInWithGoogle()
        AR->>FBA: signInWithPopup(GoogleAuthProvider)
    else Mobile
        LS->>AR: signInWithGoogle()
        AR->>GS: initialize() + authenticate()
        GS-->>AR: GoogleSignInAccount
        AR->>GS: authorizationClient.authorizeScopes(['email','profile'])
        AR->>FBA: signInWithCredential(...)
    end
    FBA-->>AR: UserCredential
    FBA-->>R: authStateChanges → User
    R->>R: redirect → /onboarding o /dashboard
```

### Email/password

```mermaid
sequenceDiagram
    actor U as Utente
    participant LS as LoginScreen
    participant AR as AuthRepository
    participant FBA as FirebaseAuth
    participant R as Router

    alt Login
        U->>LS: email + password
        LS->>AR: signInWithEmail(email, password)
        AR->>FBA: signInWithEmailAndPassword(...)
    else Registrazione
        U->>LS: email + password + conferma
        LS->>AR: registerWithEmail(email, password)
        AR->>FBA: createUserWithEmailAndPassword(...)
    else Reset password
        U->>LS: email
        LS->>AR: sendPasswordReset(email)
        AR->>FBA: sendPasswordResetEmail(...)
    end
    FBA-->>R: authStateChanges → User
    R->>R: redirect → /onboarding o /dashboard
```

## Logout

`AuthRepository.signOut()`:
- mobile: `googleSignIn.disconnect()` + `FirebaseAuth.signOut()`;
- web: solo `FirebaseAuth.signOut()`.

Dopo il redirect autenticato, l'app valida struttura e sede PCM contro il
catalogo canonico. Il gate è separato dal controllo di completezza profilo:
non ripete il flusso di onboarding e non si applica ad altre amministrazioni.
Il gate è montato nelle route autenticate, sotto il `Navigator`, così i menu
di `Autocomplete` e `DropdownButton` dispongono dell'`Overlay` della route.

## Gap noti

- La `SharedPreferences['hasProfile_<uid>']` **non viene cancellata** al
  logout: se l'utente fa login con un altro account dopo il logout di
  uno con profilo, la prima rotta potrebbe essere errata fino al primo
  refresh. Va aggiunto un cleanup esplicito (issue futura).
- Errori loggati con `debugPrint(...)`: serve un logger strutturato.
- Esiste `lib/features/authentication/domain/auth_service.dart` vuoto:
  o si materializza un `AuthService` che incapsula le regole di
  business, o si rimuove.

_Ultima revisione: 2026-07-22 — bootstrap Web/Flutter con skeleton strutturale e retry._
