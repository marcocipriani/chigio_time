# ADR-0004 — GPS Geofencing per Auto-Timbratura

- **Data:** 2026-05-30
- **Autore/i:** Marco Cipriani
- **Stato:** Accepted
- **Contesto correlato:** [`docs/funzionalita/dashboard.md`](../funzionalita/dashboard.md), [`docs/entita/user-profile.md`](../entita/user-profile.md)

## Contesto

L'utente deve timbrare entrata/uscita manualmente ogni giorno. Dimentica spesso la timbratura, soprattutto l'uscita (problema già gestito dall'auto-abbandono alle 21:00). L'auto-timbratura basata su posizione GPS è una funzionalità standard nei sistemi PA moderni. Il requisito è rilevare quando l'utente entra nel perimetro dell'ufficio e proporre automaticamente la timbratura di entrata, senza tracking in background (troppo intrusivo, richiede permessi speciali).

## Opzioni considerate

1. **Geofencing nativo** (`geofencer_flutter`, `geofencing_api`) — notifiche push in background anche quando l'app è chiusa. Pro: funziona sempre. Contro: richiede `ACCESS_BACKGROUND_LOCATION` su Android (Play Store scrutiny aumentata) e `NSLocationAlwaysUsageDescription` su iOS; privacy invasiva; complessa da implementare correttamente.

2. **Geolocator foreground + check on app resume** — usa `geolocator` per ottenere posizione quando l'app è in foreground (wake on resume). Pro: permesso `WhenInUse` sufficiente; package già maturo e mantenuto; no background. Contro: funziona solo se l'utente apre l'app.

3. **Nessun GPS** — reminder manuale via notifica push schedulata. Contro: non automatico, meno valore.

## Decisione

Adottiamo **opzione 2**: `geolocator ^13` con check foreground su apertura app. Viene mostrato un prompt card nella dashboard se: GPS auto-timbratura attivato nel profilo + posizione ufficio impostata + ora tra 06:00–11:00 + turno non ancora iniziato. L'utente decide se timbrare; non è mai automatico senza conferma.

## Conseguenze

- **Positive:** permesso `WhenInUse` sufficiente; nessun tracking persistente; rispetta la privacy; funziona senza background services; configurazione semplice (bottone "Usa posizione attuale").
- **Negative / debiti tecnici:** richiede che l'utente apra l'app per triggerare il check. Il raggio di default (150m) può non essere sufficiente in uffici con GPS scarso (palazzo con segnale attenuato).
- **Migrazione:** nessuna migrazione Firestore incompatibile. Nuovi campi `officeLat`, `officeLng`, `officeRadiusM`, `gpsAutoClockIn` aggiunti a `users/{uid}` con `merge: true`.

## Note

- `geolocator` è il package GPS più usato nell'ecosistema Flutter; ~3M pub.dev download/mese.
- Haversine formula implementata in `GeofencingService._haversineM` per calcolo distanza senza dipendenze aggiuntive.
- Se in futuro si vuole geofencing in background: sostituire con `geofencing_api` o `background_fetch`; attuale `GeofencingService` è un wrapper sostituibile.
