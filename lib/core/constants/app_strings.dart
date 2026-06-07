// Centralised UI strings for Chigio Time.
//
// Convention:
//   • Fixed strings   → static const String foo = '…';
//   • Template strings (contain variables) → static String foo(T arg) => '…$arg…';
//   • Emoji-only markers are kept alongside their label.
//
// Import: `import 'package:chigio_time/core/constants/app_strings.dart';`
// Usage:  Text(AppStrings.clockIn)   /   Text(AppStrings.erroreAccesso(e))

abstract final class AppStrings {
  // ── App identity ──────────────────────────────────────────────────────────
  static const appName = 'Chigio Time';
  static const appTagline = 'Time tracking per dipendenti pubblici';
  static const chigioMotto = 'Amministrativamente lento, by design.';
  static const appOrg = 'Presidenza del Consiglio dei Ministri';
  static const appOrgShort = 'PCM';
  static const appUsoInterno =
      'Presidenza del Consiglio dei Ministri · uso interno';
  static const appVersion = 'v2026.06.07';
  // Firebase Hosting site URL (independent from the immutable project ID
  // `chigio-time-pcm` — see docs/CHANGELOG.md 2026-06-07 hosting entry).
  static const webBaseUrl = 'https://chigiotime.web.app';

  // ── Navigation ────────────────────────────────────────────────────────────
  static const navHome = 'Home';
  static const navTimesheet = 'Timesheet';
  static const navSocial = 'Social';
  static const navProfile = 'Profilo';

  // ── Common actions ────────────────────────────────────────────────────────
  static const save = 'Salva';
  static const cancel = 'Annulla';
  static const add = 'Aggiungi';
  static const delete = 'Elimina';
  static const remove = 'Rimuovi';
  static const close = 'Chiudi';
  static const ok = 'OK';
  static const create = 'Crea';
  static const edit = 'Modifica';
  static const confirm = 'Conferma';
  static const retry = 'Riprova';
  static const back = 'Indietro';
  static const comingSoon = 'Prossimamente';
  static const loading = 'Caricamento…';
  static const saved = 'Salvata ✓';

  // ── Common errors / states ────────────────────────────────────────────────
  static const errorPrefix = 'Errore';
  static const userNotAuthenticated = 'Utente non autenticato';
  static const errorLoading = 'Errore nel caricamento';
  static const errorNoData = 'Nessun dato trovato.';
  static String errorGeneric(Object e) => 'Errore: $e';
  static String errorSave(Object e) => 'Errore salvataggio: $e';
  static String errorGoogleSignIn(Object e) => 'Errore accesso Google: $e';
  static const emailNotAvailable =
      'Accesso email non ancora disponibile. Usa Google.';

  // ── Dashboard CTAs ────────────────────────────────────────────────────────
  static const clockIn = 'Timbra Entrata';
  static const clockOut = 'Timbra Uscita';
  static const resume = '▶  Riprendi';
  static const newDay = 'Nuova giornata';
  static const swShort = 'SW';
  static const endShift = 'Fine turno';

  // ── Timer / shift states ──────────────────────────────────────────────────
  static const statusNotStarted = 'Non ancora iniziato';
  static const statusWorking = 'In ufficio';
  static const statusPaused = 'In pausa';
  static const statusRemote = 'Da remoto';
  static const statusCompleted = '✓ Completato';
  static const statusLive = 'LIVE';
  static const statusInPausa = 'IN PAUSA';
  static const statusDoneUpper = '✓ COMPLETATO';

  // ── Work types ────────────────────────────────────────────────────────────
  static const wtPresence = 'Presenza';
  static const wtRemote = 'Smart Working';
  static const wtRemoteShort = 'Smart W.';
  static const wtLeave = 'Permesso';
  static const wtHoliday = 'Ferie';
  static const remoteRegistered =
      '🏠 Giornata da remoto registrata · buono pasto ✓';

  // ── Timesheet ─────────────────────────────────────────────────────────────
  static const viewDay = 'Giorno';
  static const viewList = 'Lista';
  static const viewWeek = 'Settimana';
  static const viewMonth = 'Mese';
  static const saveDay = 'Salva giornata';
  static const dayType = 'Tipo giornata:';
  static const noteLabel = 'Nota attività';
  static const notePlaceholder = 'Descrivi le attività svolte oggi…';
  static const timePlaceholder = 'HH:MM';
  static const weeklyReport = 'Report settimanale';
  static const reminderIn = 'Promemoria timbratura entrata';
  static const reminderOut = 'Promemoria timbratura uscita';
  static const lunchPause = 'Pausa pranzo';
  static const quickExit = 'Uscita rapida';
  static const lateExit = 'Uscita tardiva';
  static const dayRecord = 'Record gg';
  static const currentValue = 'Valore attuale';
  static const restoreDefault = 'Ripristina default';
  static const suppressedHolidays = 'FESTIVITÀ SOPPRESSE';

  // ── Timesheet detail stats ─────────────────────────────────────────────
  static const entrata = 'Entrata';
  static const lavorato = 'Lavorato';
  static const uscita = 'Uscita';
  static const giorno = 'Giorno:';
  static const aggiungiGiornata = 'Aggiungi giornata';
  static const modificaGiornata = 'Modifica giornata';
  static const eliminaGiornata = 'Elimina giornata';
  static const eliminaGiornataConferma =
      'Eliminare la giornata inserita? L\'operazione non può essere annullata.';
  static const giornataEliminata = 'Giornata eliminata';
  static String straordinarioDetail(String time) => 'Straordinario: $time';
  static const ottimoLavoro = 'Ottimo lavoro oggi! 🎉';
  static const oggi = 'Oggi';
  static String oggiData(String dateLabel) => 'Oggi · $dateLabel';
  static const weekend = 'Weekend';
  static String settimanaLabel(String weekNumber) => 'Sett. $weekNumber';

  // ── Causale assenza (entry sheet) ─────────────────────────────────────────
  static const causale = 'Causale';
  static const unitaLabel = 'Unità';
  static const unitaOre = 'Ore';
  static const unitaGiorni = 'Giorni';
  static const unitaPeriodo = 'Periodo';
  static const durataLabel = 'Durata';
  static const giorniPrefix = 'Giorni: ';
  static const periodoDal = 'Dal';
  static const periodoAl = 'Al';
  static const assenzaRiservata = 'Assenza riservata';
  static const assenzaRiservataHint =
      'Nascondi causale nelle viste social ed export rapidi';
  static const documentazionePresente = 'Documentazione presente';
  static const notaPrivataHint = 'Nota privata (facoltativa)';

  // ── Abandoned / missing clock-out ─────────────────────────────────────
  static const abandonedBadge = '⚠ INCOMPLETO';
  static const abandonedTitle = 'Uscita non timbrata';
  static const abandonedBody =
      'Il turno è ancora aperto. Timbra l\'uscita per salvare la giornata, oppure ignora.';
  static const registerExit = 'Registra uscita';
  static const dismissDay = 'Ignora giornata';

  // ── Stats / totalizzatori ─────────────────────────────────────────────────
  static const totalHours = 'Ore tot.';
  static const overtime = 'Straord.';
  static const mealVouchers = 'Buoni';
  static const art9Label = 'Art.9';
  static const sliLabel = 'SLI';
  static const sboLabel = 'SBO';
  static const deficitLabel = 'Ore perse';
  static const bankHours = 'Banca Ore';
  static const bankHoursUpper = 'BANCA ORE';
  static const totalizatori = 'TOTALIZZATORI PORTALE';
  static const overtimeUpper = 'STRAORDINARIO';
  static const alerts = 'AVVISI';
  static const mealEarned = 'Buono maturato';
  static const mealEarnedFull = '🍽️ Buono ✓';
  static const entitledMax = 'Spettante (massimo)';
  static const hoursWorked = 'ore lavorate';
  static const portaleData = 'Dati portale PA';

  // ── Dashboard widgets / settings ─────────────────────────────────────────
  static const customise = 'Personalizza';
  static const visibleVoices = 'Voci visibili';
  static const progressBars = 'Mostra barre di avanzamento';
  static const widgetCounters = 'Widget contatori';

  // ── Profile fields ────────────────────────────────────────────────────────
  static const fullName = 'Nome completo';
  static const namePlaceholder = 'Il tuo nome e cognome';
  static const administration = 'Ente';
  static const employmentType = 'Inquadramento';
  static const standardHours = 'Orario standard';
  static const mealThreshold = 'Soglia buono pasto';
  static const articleNine = 'Articolo 9';
  static const overtimeCap = 'Tetto straordinari';
  static const phone = 'Telefono';
  static const phonePlaceholder = '+39 …';
  static const dipartimento = 'Dipartimento';
  static const interno = 'Interno';
  static const sede = 'Sede';
  static const piano = 'Piano';
  static const stanzaUfficio = 'Stanza / Ufficio';
  static const appInfo = 'Informazioni app';
  static const downloadApp = 'Scarica l\'app';

  // ── Login ─────────────────────────────────────────────────────────────────
  static const signInGoogle = 'Accedi con Google';
  static const signInEmail = 'Accedi con email e password';
  static const registerEmail = 'Registrati con email';
  static const signInBtn = 'Accedi';
  static const registerPrompt = 'Non hai un account? ';
  static const registerLink = 'Registrati';
  static const forgotPassword = 'Password dimenticata?';
  static const emailLabel = 'Email';
  static const emailPlaceholder = 'mario.rossi@governo.it';
  static const passwordLabel = 'Password';
  static const passwordPlaceholder = '••••••••';
  static const orDivider = 'oppure';
  static const logout = 'Esci dall\'account';

  // ── Social / colleagues ───────────────────────────────────────────────────
  static const colleagues = 'COLLEGHI';
  static const allColleagues = 'TUTTI I COLLEGHI';
  static const favorites = 'PREFERITI';
  static const groups = 'GRUPPI';
  static const presentToday = 'PRESENTI OGGI';
  static const addColleague = 'Aggiungi collega';
  static const addColleagues = 'Aggiungi colleghi';
  static const removeColleague = 'Rimuovi collega';
  static const newGroup = 'Nuovo gruppo';
  static const groupName = 'Nome gruppo';
  static const noGroups = 'Nessun gruppo creato';
  static const notifications = 'Notifiche';
  static const noNotifications = 'Nessuna notifica';
  static const notificationsHint = 'Le notifiche dei colleghi appariranno qui';
  static const noColleaguesYet = 'Nessun collega ancora';
  static const searchByName = 'Cerca per nome…';
  static const allColleaguesSection = 'Tutti i colleghi';
  static const available = 'disponibile';

  // ── Coffee ────────────────────────────────────────────────────────────────
  static const coffeeAvailableToggle = 'Disponibile per caffè';
  static const coffeeVisibleHint = 'Visibile ai tuoi colleghi';
  static const coffeeInvite = 'Invita a un caffè';
  static const arriving = 'Sto arrivando';
  static const etaQuestion = 'In quanti minuti arrivi?';
  static const cannotCome = 'Non posso';
  static const coming = 'Ci sono';

  // ── Notifications / responses ─────────────────────────────────────────────
  static const msgOptional = 'Messaggio opzionale…';
  static const optionalMsg = 'Messaggio opzionale…';

  // ── ETA / time-ago ─────────────────────────────────────────────────────
  static String etaMinutes(int m) => '$m min';
  static const timeAgoNow = 'adesso';
  static String timeAgoMins(int m) => '$m min fa';
  static String timeAgoHours(int h) => '${h}h fa';
  static String timeAgoDays(int d) => '${d}g fa';

  // ── Notification response labels ────────────────────────────────────────
  static const respAccepted = 'Ci sono!';
  static const respDeclined = 'Non può venire';
  static const respMaybe = 'Forse!';
  static const respArriving = 'Sta arrivando';

  // ── Notification invite titles ──────────────────────────────────────────
  static String notifArrivingEta(String name, Object eta) =>
      '$name sta arrivando tra $eta min 🚶';
  static String notifDeclined(String name) =>
      '$name non può prendere il caffè ❌';
  static String notifMaybe(String name) =>
      '$name risponde forse al tuo invito caffè 🤔';
  static String notifAccepted(String name) =>
      '$name ha accettato il tuo caffè ✅';
  static String notifCoffeeScheduled(String name, String time) =>
      '$name ti ha invitato a un caffè alle $time ☕';
  static String notifCoffeeInvite(String name) =>
      '$name ti ha invitato a prendere un caffè ☕';

  // ── Totalizzatori ──────────────────────────────────────────────────────
  static String bankHoursDetail(String ac, String ap) => 'AC $ac · AP $ap';

  // ── Custom counters ───────────────────────────────────────────────────────
  static const customCounters = 'Contatori personalizzati';
  static const addCounter = 'Aggiungi contatore';
  static const counterLabel = 'Nome';
  static const counterValue = 'Valore';
  static const counterUnit = 'Unità (es. gg, h, %)';
  static const importDefaults = 'Importa predefiniti PCM';
  static const importDefaultsBody =
      'Importa i contatori standard per PCM. I contatori esistenti con lo stesso ID verranno aggiornati.';
  static const importDefaultsDone = 'Predefiniti PCM importati ✓';
  static String deleteCounterConfirm(String label) => 'Eliminare "$label"?';
  static const noCustomCounters =
      'Nessun contatore ancora.\nAggiungine uno o importa i predefiniti PCM.';

  // ── Profile dialogs ────────────────────────────────────────────────────
  static const phoneNumber = 'Numero di telefono';

  // ── Dialogs ───────────────────────────────────────────────────────────────
  static String removeColleagueConfirm(String firstName) =>
      'Rimuovere $firstName dalla lista?';
  static String deleteGroupConfirm(String groupName) => 'Elimina "$groupName"?';
  static const deleteGroupBody = 'Il gruppo verrà eliminato definitivamente.';
  static String coffeeGroupSent(String groupName) =>
      '☕ Inviti caffè inviati al gruppo "$groupName"!';

  // ── Months ────────────────────────────────────────────────────────────────
  static const months = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];
  static const monthsShort = [
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic',
  ];
  static const weekdaysFull = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];
  static const weekdaysShort = [
    'Lun',
    'Mar',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom',
  ];
  static const weekdayLetters = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  // ── Greetings ─────────────────────────────────────────────────────────────
  static const greetingMorning = 'Buongiorno';
  static const greetingAfternoon = 'Buon pomeriggio';
  static const greetingEvening = 'Buona sera';
  static String greetingWithName(String g, String name) => '$g, $name 👋';

  // ── Chigio mascot ─────────────────────────────────────────────────────────
  static const chigio = 'Chigio';
  static const chigioSubtitle = 'La tartaruga di Chigio Time';
  static const tapToChange = 'Tocca per cambiare';
  static const chigioVisit = 'Vai da Chigio →';
  static String chigioCounter(int i, int total) => '$i/$total';

  static const chigioImages = [
    'assets/images/chigio-ciao.png',
    'assets/images/chigio-ok.png',
    'assets/images/chigio-orologio.png',
    'assets/images/chigio-calcolatrice.png',
    'assets/images/chigio-caffe.png',
    'assets/images/chigio-sonno.png',
    'assets/images/app_icon.png',
  ];
  static const chigioLabels = [
    'Ciao! 👋',
    'Ottimo lavoro! ✅',
    'È ora di timbrare! ⏰',
    'Sto calcolando... 🔢',
    'Pausa caffè! ☕',
    'Sono stanco... 😴',
    'Sono io, Chigio! 🐢',
  ];

  // ── Administrations list (Ente picker) ───────────────────────────────────
  // Presidenza del Consiglio dei Ministri short reference
  static const presidenzaPCM = 'Presidenza del Consiglio dei Ministri';

  static const administrations = [
    'Presidenza del Consiglio dei Ministri',
    'Ministero dell\'Economia e delle Finanze',
    'Ministero dell\'Interno',
    'Ministero della Giustizia',
    'Ministero degli Affari Esteri e della Cooperazione Internazionale',
    'Ministero dell\'Istruzione e del Merito',
    'Ministero dell\'Università e della Ricerca',
    'Ministero della Salute',
    'Ministero delle Infrastrutture e dei Trasporti',
    'Ministero dell\'Ambiente e della Sicurezza Energetica',
    'Ministero dell\'Agricoltura, della Sovranità Alimentare e delle Foreste',
    'Ministero delle Imprese e del Made in Italy',
    'Ministero del Lavoro e delle Politiche Sociali',
    'Ministero della Difesa',
    'Ministero della Cultura',
    'Ministero dello Sport e dei Giovani',
    'Ministero per la Pubblica Amministrazione',
    'Agenzia delle Entrate',
    'Agenzia delle Dogane e dei Monopoli',
    'INPS',
    'INAIL',
    'Corte dei Conti',
    'Consiglio di Stato',
    'Avvocatura dello Stato',
    'Ragioneria Generale dello Stato',
    'Altro ente pubblico',
  ];

  // Employment types (CCNL)
  static const employmentTypes = [
    'Ruolo',
    'Comando',
    'Contratto a tempo determinato',
    'Contratto a tempo indeterminato',
    'Collaborazione',
    'Altro',
  ];

  static int stdMinsByType(String type) => switch (type) {
    'Comando' => 432,
    _ => 456,
  };

  static int mealMinsByType(String type) => switch (type) {
    'Comando' => 360,
    _ => 380,
  };

  // ── Advanced stats screen ────────────────────────────────────────────────
  static const advancedStats = 'Statistiche avanzate';
  static const statsAvgDaily = 'Media ore giornaliere';
  static const statsHoursPerDay = 'Ore/giorno (media)';
  static const statsOtByWeekday = 'Straordinari per giorno';
  static const statsLast3Months = 'ultimi 3 mesi';
  static const statsLeaveVacation = 'Permessi e ferie';
  static const statsAvgEntry = 'Orario medio entrata';
  static const statsLink = 'Statistiche avanzate →';

  // ── Exit reminder ─────────────────────────────────────────────────────────
  static const exitReminderTitle = 'Uscita tra poco';
  static String exitReminderBody(int mins) =>
      'Mancano $mins min all\'uscita prevista.';

  // ── GPS geofencing ────────────────────────────────────────────────────────
  static const gpsAutoClockIn = 'Auto-timbratura GPS';
  static const gpsAutoClockInHint = 'Timbra entrata quando arrivi in ufficio';
  static const gpsOfficeLocation = 'Posizione ufficio';
  static const gpsSetFromHere = 'Usa posizione attuale';
  static const gpsLocationNotSet = 'Posizione non impostata';
  static const gpsRadius = 'Raggio (metri)';
  static const gpsPermissionDenied = 'Permesso posizione negato';
  static const gpsServiceDisabled = 'GPS disabilitato sul dispositivo';
  static String gpsLocationSaved(double lat, double lng) =>
      '📍 ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  static const gpsAutoClockInDialog = 'Sei in ufficio?';
  static const gpsAutoClockInBody =
      'Sei nelle vicinanze dell\'ufficio. Vuoi timbrare l\'entrata?';

  // ── Import / export sheet (timesheet) ────────────────────────────────────
  static const noEntriesToExport = 'Nessuna giornata da esportare';
  static const defaultUserName = 'Utente';
  static const selectExportRange = 'Seleziona periodo da esportare';
  static const exportAction = 'Esporta';
  static const preparingCsv = 'Preparazione CSV…';
  static const noEntriesInRange = 'Nessuna giornata nel periodo selezionato';
  static const importAnyway = 'Importa comunque';
  static String importedCount(int n) => 'Importate $n giornate ✓';
  static const exportSheetTitle = 'Esporta dati';
  static const exportSheetSubtitle =
      'Scegli il formato per esportare il timesheet del mese.';
  static const exportPdfTitle = 'Esporta PDF';
  static const exportPdfSubtitle = 'Riepilogo del mese pronto per la stampa';
  static const exportCsvTitle = 'Esporta CSV';
  static const exportCsvSubtitle = 'Dati grezzi del mese in formato tabellare';
  static const importSheetTitle = 'Importa dati';
  static const importSheetSubtitle =
      'Importa giornate da CSV o scarica il template preformattato.';
  static const importCsvTitle = 'Importa CSV';
  static const importCsvSubtitle = 'Seleziona un file .csv con i tuoi dati';
  static const downloadTemplateTitle = 'Scarica template';
  static const downloadTemplateSubtitle = 'File CSV preformattato da compilare';
  static const importTooltip = 'Importa / Template';
  static const exportTooltip = 'Esporta / Strumenti';

  // ── CSV import/export ─────────────────────────────────────────────────────
  static const downloadCsvTemplate = 'Scarica template CSV';
  static const csvTemplateTitle = 'Template CSV';
  static const csvTemplateCopied = 'Template copiato negli appunti ✓';
  static const csvTemplateContent =
      'data;tipo;entrata;uscita;nota\n'
      '2026-01-13;presenza;09:00;17:36;\n'
      '2026-01-14;smart_working;;;\n'
      '2026-01-15;ferie;;;\n'
      '2026-01-16;permesso;09:00;13:30;Visita medica\n';

  // ── Orario standard presets ───────────────────────────────────────────────
  static const orarioPreset736 = '7:36';
  static const orarioPreset640 = '6:40';
  static const orarioPreset712 = '7:12';
  static const orarioPreset612 = '6:12';
  static const orarioPresetTitle = 'Orario standard';

  // ── Highlight widget (dashboard/profile) ─────────────────────────────────
  static const highlightWidget = 'Widget in evidenza';
  static const highlightWidgetNone = 'Nessuno';
  static const highlightBankHours = 'Banca ore';
  static const highlightOvertime = 'Straordinari mese';
  static const highlightMealCount = 'Buoni pasto';

  // ── Nav views visibility (profilo) ───────────────────────────────────────
  static const navViewsVisibility = 'Schede di navigazione';
  static const navViewsVisibilityHint =
      'Scegli quali schede mostrare nel menu di navigazione';
  static const navViewHome = 'Home';
  static const navViewTimesheet = 'Cartellino';
  static const navViewSocial = 'Social';
  static const navViewsAtLeastOne = 'Deve restare visibile almeno una scheda';

  // ── Colleghi actions ──────────────────────────────────────────────────────
  static const callColleague = 'Chiama';
  static const noOtherUsers = 'Nessun altro utente nella tua amministrazione.';
  static String coffeeToastSent(String name) => 'Invito caffè inviato a $name!';
  static String inOfficeCount(int n) => '$n in ufficio';

  // ── Install page ─────────────────────────────────────────────────────────
  static const installAndroid = 'Scarica APK Android';
  static const installIosTitle = 'iOS — Prossimamente';
  static const installIosBody =
      'La versione iOS di Chigio Time è in preparazione.';
  static const installIosWeb =
      'Nel frattempo puoi usare la versione web su Safari:';
  static const installHow = 'Come installare';

  // ── Export PDF (timesheet mensile) ───────────────────────────────────────
  static String pdfTitle(String monthName, int year) =>
      'Timesheet $monthName $year';
  static const pdfSummaryPresenze = 'Giorni presenza';
  static const pdfSummaryOreLavorate = 'Ore lavorate';
  static const pdfSummaryStraordinario = 'Straordinario';
  static const pdfSummaryBuoniPasto = 'Buoni pasto';
  static const pdfColGiorno = 'Giorno';
  static const pdfColTipo = 'Tipo';
  static const pdfColEntrata = 'Entrata';
  static const pdfColUscita = 'Uscita';
  static const pdfColNetto = 'Netto';
  static const pdfColOt = 'OT';
  static const pdfColBuono = 'Buono';
  static const pdfColNota = 'Nota';
  static const pdfTypeRemote = 'SW';
  static const pdfTypeLeave = 'Perm.';
  static const pdfTypeHoliday = 'Ferie';
  static const pdfTypePresence = 'Pres.';
}
