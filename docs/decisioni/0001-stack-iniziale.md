# ADR-0001 — Stack iniziale: Flutter + Riverpod 3 + Firebase + Drift

- **Data:** 2026-04-26 (estratta a posteriori dallo stato del repo)
- **Autore:** Marco Cipriani
- **Stato:** Accepted
- **Contesto correlato:**
  [`../architecture/README.md`](../architecture/README.md),
  [`../architecture/state-management.md`](../architecture/state-management.md),
  [`../architecture/persistence.md`](../architecture/persistence.md)

## Contesto

`chigio_time` e' un'app di time tracking per dipendenti pubblici, da
distribuire su almeno iOS e Android, con sincronizzazione cloud,
prospettiva offline e una UI ricca (anelli, calendari, KPI live). I
vincoli principali:

- single-developer, serve velocita' di iterazione;
- multi-piattaforma (mobile + desktop + web auspicati);
- bisogno di un backend "as-a-service" per non gestire server (auth,
  database, storage, push);
- testabilita' della logica di business (calcolo turno, regola 9h);
- prospettiva offline-first.

## Opzioni considerate

1. **Flutter + Riverpod 3 + Firebase + Drift** — tutto Dart, code-gen
   uniforme, Firebase fornisce auth/firestore/storage/messaging,
   Drift abilita SQLite locale tipato. Curva di apprendimento gestibile.
2. **React Native + Redux Toolkit + Firebase** — ecosistema piu' grande
   ma toolchain JS/TS + native moduli, build matrix piu' complessa.
3. **Native (Kotlin + Swift)** — massima qualita' UX ma raddoppia il
   costo: due codebase per la stessa app personal-use.
4. **Flutter + Bloc + Supabase** — Bloc piu' verboso di Riverpod su
   stato cross-feature; Supabase ottimo SQL ma manca push out-of-the-box.

## Decisione

Adottiamo **Flutter 3 (Dart 3.10+) + Riverpod 3 (code-gen) + Firebase
(Auth/Firestore/Storage/Messaging) + Drift (SQLite locale)**, con
`go_router` come router e `freezed` + `json_serializable` per i modelli.

Riverpod 3 vince su Bloc per la concisione e per il code-gen che si
integra bene con la stessa pipeline `build_runner` di Drift / Freezed.

Firebase vince su Supabase per la copertura "all-in-one" (auth + db +
push + storage) e per il supporto Flutter ufficiale.

Drift e' scelto come ORM SQLite per lo sync offline futuro: tipato,
con `build_runner`, e con generazione di tabelle dichiarative.

## Conseguenze

- **Positive**
  - Codebase singolo per 6 piattaforme.
  - Code-gen unificato: `dart run build_runner build` rigenera Riverpod,
    Freezed, Drift, JSON.
  - Firestore offre out-of-the-box query reattive, ottime per
    `monthlyTimesheetsProvider`.
- **Negative / debiti**
  - Vendor lock-in su Firebase: passare a un altro backend e' costoso
    (script di migrazione + cambio repository layer).
  - Drift e' presente in `pubspec.yaml` ma non ancora usato: rischio di
    "dipendenza fantasma" finche' non viene cablato.
  - Riverpod 3 e' relativamente recente: alcune ricette online
    riferiscono ancora a Riverpod 2.
- **Migrazione**
  - Non applicabile (decisione iniziale).

## Note

- Versioni di riferimento: vedi `pubspec.yaml`.
- Quando Drift verra' cablato, aprire una ADR dedicata (es.
  *ADR-0002 — strategia offline-first con Drift e Firestore listener*).
