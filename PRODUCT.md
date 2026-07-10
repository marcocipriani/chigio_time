# Product

## Register

product

## Users

Marco (lead dev, dipendente PA presso PCM) e una cerchia ristretta di
colleghi fidati. Utenti esperti, uso quotidiano ripetuto: timbrano,
controllano ore/uscita prevista/buono pasto piu' volte al giorno, spesso
da mobile in movimento o da web desktop in ufficio. Nessun onboarding di
massa previsto.

## Product Purpose

Time tracking personale per dipendenti pubblici (CCNL PA/PCM): timbrature,
pause, regola 9 ore, straordinari, buoni pasto, banca ore, Articolo 9,
timesheet mensile con 3 viste, vista social dello stato colleghi.
Successo = a colpo d'occhio: quante ore oggi, quando posso uscire, buono
maturato, straordinario mensile.

## Brand Personality

Giocoso-professionale. Base seria e affidabile (i numeri sono soldi e ore
vere), personalita' portata da: mascotte Chigio (tartaruga), aurora
animata, caffe' ai colleghi, glass style di derivazione iOS/Apple
(profondita', motion curato, densita' bassa). Il delight resta
protagonista ma non degrada la leggibilita' dei dati.

## Anti-references

- Gestionale PA anni 2000: portali ministeriali grigi, tabelle dense,
  form burocratici.
- SaaS dashboard generica: card identiche, big-number+label, gradienti
  viola, template admin.
- App consumer infantile: il giocoso non scade nel giocattolo.
- Material Design stock: non deve sembrare una demo Flutter senza
  identita'.

## Design Principles

1. **Risposta in un colpo d'occhio** — ogni schermata risponde alla
   domanda del momento (quanto ho lavorato? quando esco?) senza scavare.
2. **I dati prima del vetro** — glass, aurora e mascotte non competono
   mai con la leggibilita' di ore e numeri.
3. **Delight guadagnato** — micro-gioia nei momenti giusti (buono
   maturato, fine turno), non decorazione uniforme ovunque.
4. **Feel Apple, dominio CCNL** — profondita' e motion da iOS, ma
   terminologia esatta del contratto pubblico (Art.9, SLI, SBO, OP).
5. **Performante e' bello** — niente effetto che costi jank; il fluido fa
   parte dell'estetica (lezione BackdropFilter, 2026-07).

## Accessibility & Inclusion

Base ragionevole, nessun audit formale: contrasti leggibili, touch
target adeguati, `disableAnimations`/reduced-motion gia' rispettato
(aurora statica). Utenti noti e senza esigenze specifiche dichiarate.
