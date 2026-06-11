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
  static const appVersion = 'v2026.06.11';
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
  static const view = 'Vedi';
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
  static const editDay = 'Modifica giornata';
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
  static const viewYear = 'Anno';
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

  // ── Day overview (checkpoints) ────────────────────────────────────────────
  static const dayOverviewUpper = 'PANORAMICA GIORNATA';
  static const overtimeFull = 'Straordinario';

  // ── Stats / totalizzatori ─────────────────────────────────────────────────
  static const totalHours = 'Ore tot.';
  static const overtime = 'Straord.';
  static const mealVouchers = 'Buoni';
  static const art9Label = 'Art.9';
  static const sliLabel = 'SLI';
  static const sboLabel = 'SBO';
  static const deficitLabel = 'Deficit';
  static String lunchVirtualBanner(int mins) => "Pausa pranzo virtuale +$mins' inclusa";
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
  static const otAlertThreshold = 'Avviso soglia straordinari';
  static String otAlertMessage(int h, int total) =>
      'Raggiunte $total h di straordinario su soglia di ${h}h — controlla il tetto mensile.';
  static const otAlertDisabled = 'Disabilitato (0 = nessun avviso)';
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
  static const repeatPassword = 'Ripeti password';
  static const confirmPassword = 'Conferma password';
  static const alreadyHaveAccount = 'Hai già un account? ';
  static const googleChipLabel = 'Google';
  static const passwordMismatch = 'Le password non coincidono';
  static const resetPasswordHint = 'Inserisci la tua email per il reset';
  static const resetPasswordSent =
      'Email di reset inviata! Controlla la casella.';
  static const authErrUserNotFound = 'Nessun account trovato con questa email.';
  static const authErrWrongPassword = 'Password errata.';
  static const authErrInvalidEmail = 'Email non valida.';
  static const authErrEmailInUse = 'Email già registrata.';
  static const authErrWeakPassword =
      'Password troppo debole (min 6 caratteri).';
  static const authErrInvalidCredential = 'Credenziali non valide.';
  static String authErrCode(String code) => 'Errore autenticazione: $code';
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
  static const shareInviteLink = 'Condividi il tuo link';
  static const pasteColleagueLink = 'Incolla link o UID collega';
  static const addFromLinkBtn = 'Aggiungi';
  static const inviteLinkCopied = 'Link copiato negli appunti';
  static const inviteLinkInvalidUid = 'Link o UID non valido';
  static const removeColleague = 'Rimuovi collega';
  static const newGroup = 'Nuovo gruppo';
  static const groupName = 'Nome gruppo';
  static const renameGroup = 'Rinomina gruppo';
  static const rename = 'Rinomina';
  static const cellulare = 'Cellulare';
  static const noGroups = 'Nessun gruppo creato';
  static const notifications = 'Notifiche';
  static const noNotifications = 'Nessuna notifica';
  static const notificationsHint = 'Le notifiche dei colleghi appariranno qui';
  static const noColleaguesYet = 'Nessun collega ancora';
  static const searchByName = 'Cerca per nome…';
  static const searchColleagues = 'Cerca collega…';
  static const giorni = 'giorni';
  static const coverableWorkDays = 'giornate BOE coperte';
  static const bancaOreAlert = 'Soglia superata';
  static const statusMessageLabel = 'Stato del giorno';
  static const coffeeHistoryLabel = 'STORICO CAFFÈ';
  static const homeWidgetsVisibility = 'Widget Home';
  static const smartExitStd = 'Giornaliero';
  static const smartExitPlusHour = '+1h OT';
  static const smartExitMensile = 'Pareggio mese';
  static const notifyMorningColleagues = 'Colleghi in ufficio (mattina)';
  static const notifyMorningHour = 'Orario notifica';
  static const notifyWeeklyRecap = 'Recap settimanale';
  static const notifyWeeklyDay = 'Giorno';
  static const notifyWeeklyHour = 'Ora';
  static const weekdayShort = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const doNotDisturbLabel = 'Silenzio notifiche';
  static const silenceFrom = 'Dalle';
  static const silenceTo = 'Alle';
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

  // Employment types (CCNL) — also used as Firestore domain values
  static const etRuolo = 'Ruolo';
  static const etComando = 'Comando';
  static const etAltro = 'Altro';

  static const employmentTypes = [
    etRuolo,
    etComando,
    'Contratto a tempo determinato',
    'Contratto a tempo indeterminato',
    'Collaborazione',
    etAltro,
  ];

  static int stdMinsByType(String type) => switch (type) {
    etComando => 432,
    _ => 456,
  };

  static int mealMinsByType(String type) => 380;

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
  static const csvImportWarnings = 'Avvisi import CSV';

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

  // ── Schedule variant (CCNL PCM) ──────────────────────────────────────────
  static const scheduleVariantTitle = 'Tipo di orario settimanale';
  static const scheduleVariantUniform = '5 giorni uguali';
  static const scheduleVariantUniformDesc = 'Lo stesso numero di ore ogni giorno';
  static const scheduleVariantMixed = '3+2 giorni';
  static const scheduleVariantMixedDesc = '3 giorni brevi + 2 giorni da 9h';
  static const longWorkDaysLabel = 'Scegli i 2 giorni da 9h';
  static const longWorkDaysHint = 'Seleziona esattamente 2 giorni (lun–ven)';
  static const longWorkDaysTooFew = 'Seleziona esattamente 2 giorni lunghi';
  static const scheduleAltroHint =
      'Il tuo contratto non segue il CCNL PCM.\nRegola l\'orario manualmente.';

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

  // ── Profile screen ────────────────────────────────────────────────────────
  static const defaultUserNameProfile = 'Utente';
  static String employmentAtAdministration(
    String employmentType,
    String administration,
  ) => '$employmentType · $administration';
  static String remoteDaysCount(int days) => '$days gg 🏠';
  static const fullNameRequired = 'Il nome non può essere vuoto';
  static const genderForChigio = 'Genere (per Chigio)';
  static const genderMale = '♂ Maschile';
  static const genderFemale = '♀ Femminile';
  static const genderOther = '∅ Altrə';
  static const weeklySchedule = 'Orario settimanale';
  static const uniformSchedule = 'Uniforme';
  static String hoursPerMonth(int h) => '$h h/mese';
  static const sliMonthly = 'SLI mensile';
  static const sboMonthly = 'SBO mensile';
  static const theme = 'Tema';
  static const languagePicker = 'Lingua / Language';
  static const portalData = 'Dati portale PA';
  static const privacy = 'Privacy';
  static const sectionPersonalCard = 'Card personale';
  static const sectionInquadramento = 'Inquadramento e orario';
  static const sectionStatistics = 'Statistiche';
  static const sectionFeatures = 'Funzionalità';
  static const sectionAppOptions = 'Opzioni app';
  static const sectionAppInfo = 'Info app';
  static const editPersonalDetails = 'Modifica dati personali';
  static const personalDetails = 'Dati personali';
  static const sauMonthly = 'SAU mensile';
  static const sauMonthlyDesc = 'Straordinari Autorizzati Ulteriori (SLI + SBO)';
  static const seeAllGraphs = 'Vedi tutti i grafici →';
  static const appInfoFull =
      'Chigio Time è un\'app di time tracking per dipendenti pubblici del CCNL Presidenza del Consiglio dei Ministri.\n\n'
      'Sviluppata da Marco Cipriani.\n\n'
      'Funzionalità: timbratura con cronometro, timesheet mensile, totalizzatori portale PA, cartellino ufficiale PCM, statistiche, colleghi e caffè, GPS auto-timbratura.';
  static const privacyFullTitle = 'Privacy e dati';
  static const appFeaturesGps = 'GPS auto-timbratura';
  static const appFeaturesGpsDesc = 'Timbra automaticamente entrando/uscendo dalla sede';
  static const photoUrlLabel = 'Foto profilo';
  static const downloadMyData = 'Scarica i tuoi dati';
  static const downloadMyDataExporting = 'Esportazione dati in corso…';
  static const downloadMyDataDone = 'Dati pronti. Scegli come condividerli.';
  static String memberSince(int day, String month, int year) =>
      'Timbratonaut 🚀 dal $day $month $year';
  static const administrationField = 'Amministrazione';
  static const pcmStructure = 'Struttura PCM';
  static String officeNameAddress(String name, String address) =>
      '$name - $address';
  static String structuresCount(int n) => '$n strutture';
  static String addressWithDetail(String address, String detail) =>
      '$address - $detail';
  static const loadingPcmOffices = 'Carico le sedi PCM...';
  static const hoursPerDay = 'ore/giorno';
  static const restDay = 'Riposo';
  static const dataSafe = 'Dati al sicuro';
  static const dataSafeBody =
      'Tutti i dati vengono salvati su Firebase con autenticazione sicura e cifrata.';
  static const noDataSharing = 'Nessuna condivisione';
  static const noDataSharingBody =
      'Chigio Time non condivide i tuoi dati con terze parti né li usa per analytics.';
  static const rightToErasure = 'Diritto alla cancellazione';
  static const rightToErasureBody =
      'Puoi richiedere la cancellazione di tutti i tuoi dati contattando il supporto.';
  static const privacyLegalRefs = 'Riferimenti normativi';
  static const privacyLegalRefsBody =
      'Il trattamento dei dati avviene nel rispetto del GDPR (Reg. UE 2016/679) '
      'e del Codice Privacy italiano (D.Lgs. 196/2003 e s.m.i.).';
  static const privacyTech = 'Tecnologie e server';
  static const privacyTechBody =
      'L\'app usa Firebase Firestore, Authentication, Storage e Cloud Messaging '
      '(Google LLC). I dati sono ospitati su server nell\'Unione Europea.';
  static const privacyRights = 'I tuoi diritti GDPR';
  static const privacyRightsBody =
      'Hai diritto di accesso, rettifica, cancellazione e portabilità dei tuoi '
      'dati. Per la portabilità usa "Scarica i tuoi dati" nella sezione Info app.';

  // ── Profile: dati portale PA (totalizzatori form) ─────────────────────────
  static const identificativo = 'IDENTIFICATIVO';
  static const nominativo = 'Nominativo';
  static const matricola = 'Matricola';
  static const periodoHint = 'Periodo (es. Maggio 2026)';
  static const dataAggiornamentoHint = 'Data aggiornamento (DD/MM/YYYY)';
  static const ferieGiorni = 'FERIE (giorni)';
  static const fruitoAnnuo = 'Fruito annuo';
  static const spettanza = 'Spettanza';
  static const residuoAnnoCorrente = 'Residuo anno corrente';
  static const residuoAnnoPrecedente = 'Residuo anno precedente';
  static const festivitaSoppresseGiorni = 'FESTIVITÀ SOPPRESSE (giorni)';
  static const residuo = 'Residuo';
  static const straordinariHHMM = 'STRAORDINARI (HH:MM)';
  static const art9Effettuate = 'Art.9 effettuate';
  static const art9DaRecuperare = 'Art.9 da recuperare';
  static const maggiorPresenza = 'Maggior presenza';
  static const liquidati = 'Liquidati';
  static const autorizzati = 'Autorizzati';
  static const liquidabili = 'Liquidabili';
  static const riposoCompMaturato = 'Riposo comp. maturato';
  static const riposoCompResiduo = 'Riposo comp. residuo';
  static const bancaOreHHMM = 'BANCA ORE (HH:MM)';
  static const totaleFruibile = 'Totale fruibile';
  static const permessiHHMM = 'PERMESSI (HH:MM)';
  static const permessoBreveResiduo = 'Permesso breve residuo';
  static const motiviPersonaliResiduo = 'Motivi personali residuo';
  static const visitaSpecialisticaResiduo = 'Visita specialistica residuo';
  static const oreNonRecuperate = 'Ore non recuperate';
  static const buoniPastoUpper = 'BUONI PASTO';
  static const buoniMensili = 'Buoni mensili';
  static const appInfoBody =
      'Chigio Time — time tracking per dipendenti pubblici PCM.\n\n'
      '• Timbratura con cronometro e ShiftRing\n'
      '• Timesheet mensile con export PDF ufficiale PCM\n'
      '• Totalizzatori portale PA (SLI, SBO, Art.9, banca ore)\n'
      '• GPS auto-timbratura e notifiche di uscita\n'
      '• Colleghi, caffè e gruppi\n'
      '• Statistiche e grafici avanzati\n\n'
      'Sviluppata da Marco Cipriani — uso personale, dati locali '
      'e su Firebase con autenticazione sicura.';

  // ── CCNL reader ───────────────────────────────────────────────────────────
  static const ccnlNew = 'Nuovo';
  static const ccnlNewLabel = 'CCNL PCM 2019-2021';
  static const ccnlNewSigned = 'Sottoscritto il 28 ottobre 2025';
  static const ccnlPrevious = 'Precedente';
  static const ccnlPreviousLabel = 'CCNL PCM 2016-2018';
  static const ccnlPreviousSigned = 'CCNL del 7 ottobre 2022';
  static String articleFallbackTitle(int number) => 'Articolo $number';
  static const hoursPerMonthLower = 'ore/mese';
  static const ccnlPcmTitle = 'CCNL PCM';
  static const ccnlVersionsHint = 'Nuovo 2019-2021 e precedente 2016-2018';
  static const openCcnl = 'Apri CCNL';
  static const indexLabel = 'Indice';
  static const articlesValue = 'articoli';
  static const readContract = 'Leggi il contratto';
  static const loadingContracts = 'Caricamento contratti';
  static const articlesIndex = 'Indice articoli';
  static const ccnlLoadError = 'Impossibile caricare il CCNL.';
  static const noContractAvailable = 'Nessun contratto disponibile.';
  static String articlesCount(int n) => '$n articoli';
  static String articleHeading(int number) => 'Art. $number';

  // ── Theme picker / counters / notifications sheets ───────────────────────
  static const themeLight = 'Chiaro';
  static const themeDark = 'Scuro';
  static const themeSystem = 'Sistema';
  static const themeAutoByTime = 'Auto (18:00)';
  static const art9ExtensionLabel = 'Art.9 — Estensione orario mensile';
  static const sliLiquidatoLabel = 'SLI — Straord. liquidato';
  static const sboBancaOreLabel = 'SBO — Straord. banca ore';
  static const opOrePerseLabel = 'OP — Ore perse';
  static const restoreDefaults = 'Ripristina default';
  static const remindClockIn = 'Promemoria timbratura entrata';
  static const remindClockOut = 'Promemoria timbratura uscita';
  static const weeklyReportLabel = 'Report settimanale';
  static const expectedExitPushNotif = 'Notifica push uscita prevista';
  static const off = 'Off';
  static String minutesShort(int m) => '$m min';

  // ── Download banner / overtime trend ──────────────────────────────────────
  static const androidPlatform = 'Android';
  static String apkVersion(String v) => 'APK $v';
  static const iosPlatform = 'iOS';
  static const overtimeLast6Months = 'STRAORDINARI — ultimi 6 mesi';
  static String hoursMinutesShort(int mins) =>
      '${mins ~/ 60}h${mins % 60 > 0 ? ' ${mins % 60}m' : ''}';
  static const overtimeHoursAxis = 'Straordinario (ore)';
  static String gpsRadiusValue(int meters) => 'Raggio $meters m';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static const confirmActualTimeHelp = 'CONFERMA ORARIO EFFETTIVO';
  static const actualExit = 'Uscita effettiva';
  static const expectedExit = 'Uscita prevista';
  static const remaining = 'Rimanente';
  static const lunchChip = 'Pranzo';
  static const breakChip = 'Pausa';
  static const hoursTable = 'Tabella orari';
  static const opeLabel = 'OPE';
  static const yourCounters = 'I TUOI CONTATORI';
  static String greaterAttendance(String label) => label.toUpperCase();
  static const smartWorkingFull = 'Smart Working';
  static String nineHourThreshold(String hm) => 'Soglia 9h: $hm';
  static const expectedExitStdHeader = 'Uscita std';
  static const nineHourThresholdHeader = 'Soglia 9h';
  static const lunchExtraHeader = "+30' pranzo";
  static const nineHourPlusPauseLegend = "9h + 30' pausa";
  static const coverWithBankHours = 'Copri con Banca Ore';
  static String workedLessThanMinimum(String hm) =>
      'Hai lavorato $hm in meno del minimo.';
  static const deficit = 'Deficit';
  static const fromPreviousYear = 'Da AP (anno prec.)';
  static const fromCurrentYear = 'Da AC (anno corr.)';
  static const deficitCovered = 'Deficit coperto ✓';
  static const partiallyCovered = 'Coperto parzialmente';
  static String residualLostHours(String hm) =>
      'Residuo $hm registrato come ore perse.';
  static const whereToInsertHours = 'Dove inserire le ore';
  static const beforeClockIn = "Prima dell'entrata";
  static const beforeClockInDesc =
      'Ore accreditate retroattivamente prima della timbratura';
  static const onAPause = 'Su una pausa';
  static const reducesLunchOrShortPause = 'Riduce pausa pranzo o pausa breve';
  static const reducesLunchPause = 'Riduce la pausa pranzo';
  static const reducesShortPause = 'Riduce la pausa breve';
  static const afterClockOut = "Dopo l'uscita";
  static const afterClockOutDesc =
      'Completa il turno dopo la timbratura di uscita';
  static const skip = 'Salta';
  static const confirmBoe = 'Conferma BOE';

  // ── Totalizzatori section (banca ore / contatori CCNL) ───────────────────
  static const apShort = 'AP';
  static const acShort = 'AC';
  static const acYearResidualLabel = 'AC — Anno corrente residuo';
  static const apYearResidualLabel = 'AP — Anno passato residuo';
  static const prevPlusCurrentYear = 'Anno prec. + anno corr.';
  static String sboDelta(String hm) => '+$hm SBO';
  static String boeUsedDelta(String hm) => '−$hm BOE usati';
  static const thisMonth = 'questo mese';
  static String periodBullet(String periodo) => '· $periodo';
  static String updatedAt(String fetchedAt) => 'Agg. $fetchedAt';
  static const ferieUpper = 'FERIE';
  static const usedAnnually = 'Fruito annuo';
  static const residualAc = 'Residuo ac';
  static const residualAp = 'Residuo ap';
  static const residualTotal = 'Residue tot.';
  static const overtimePlural = 'STRAORDINARI';
  static const art9DaRecup = 'Art.9 da recup.';
  static const riposoCompMat = 'Riposo comp. mat.';
  static const riposoCompRes = 'Riposo comp. res.';
  static const permessiUpper = 'PERMESSI';
  static const permessoBreveShort = 'Permesso breve';
  static const motiviPersonaliShort = 'Motivi personali';
  static const visitaSpecialistShort = 'Visita specialist.';
  static String appConsumedOf(String used, String total, int year) =>
      'App: $used su $total ($year)';
  static String appConsumedSpecialistOf(
    String used,
    String total,
    int withDocs,
    int count,
    int year,
  ) => 'App: $used su $total · doc. $withDocs/$count ($year)';
  static String sicknessPeriodsLabel(int year) => 'MALATTIA — periodi ($year)';
  static const periodsLabel = 'Periodi';
  static const totalDaysLabel = 'Giorni totali';
  static const debitsUpper = 'DEBITI';
  static const decimalHint = 'es. 10.5';
  static const colorLabel = 'Colore';

  // ── PCM route planner ─────────────────────────────────────────────────────
  static const travelOnFoot = 'A piedi';
  static const travelByBike = 'Bici';
  static const travelByCarShuttle = 'Auto/Navetta';
  static const pcmRoutes = 'Percorsi PCM';
  static const quickRouteEstimate = 'Stima rapida tra sedi';
  static const reverseRoute = 'Inverti percorso';
  static const routeFrom = 'Da';
  static const routeTo = 'A';
  static const mapsLabel = 'Maps';
  static const outsideRomeEstimateNote =
      'Fuori Roma: stima orientativa, verifica sempre il percorso reale.';
  static const localDistanceEstimateNote =
      'Calcolo locale basato sulla distanza tra sedi.';
  static const loadingPcmSites = 'Carico le sedi PCM...';

  // ── Favorite colleagues card ──────────────────────────────────────────────
  static const favoriteColleaguesUpper = 'COLLEGHI PREFERITI';
  static const coffeeSent = 'Caffè inviato!';
  static const sendCoffee = 'Manda un caffè';
  static const aColleague = 'Un collega';
  static String callPhoneNumber(String phone) => 'Chiama $phone';
  static String internalExtension(String interno) => 'Int. $interno';

  // ── Smart exit widget ─────────────────────────────────────────────────────
  static const yourDay = 'La tua giornata';
  static String timeUntilExit(int hours, int minutes) =>
      'Tra ${hours}h ${minutes}m';
  static const youCanLeave = 'Puoi uscire!';
  static const goodMorningEmoji = 'Buona giornata! 👋';
  static const notClockedInYet = 'Non hai ancora timbrato oggi.';
  static const startShift = 'Inizia Turno';
  static const dayEndedSavedSuccess =
      'Giornata terminata e salvata con successo!';

  // ── Onboarding ────────────────────────────────────────────────────────────
  static const next = 'Avanti';
  static const finishEmoji = 'Fine 🎉';
  static const enterNameToContinue = 'Inserisci il tuo nome per continuare!';
  static const administrationRequired = "L'amministrazione è obbligatoria!";
  static const selectYourEmploymentType = 'Seleziona il tuo inquadramento!';
  static const welcomeToChigioTime = 'Benvenuto in Chigio Time!';
  static const onboardingIntro =
      "L'app pensata per gestire il cartellino in tranquillità e goderti il caffè con i colleghi.";
  static const whatsYourName = 'Come ti chiami?';
  static const yourFullName = 'Il tuo nome e cognome';
  static const howShouldChigioCallYou = 'Come preferisci che Chigio ti chiami?';
  static const chigioWillUseRightGender =
      'Chigio userà il genere giusto nelle sue frasi.';
  static const genderOtherShort = 'Altrə';
  static const youCanChangeItLaterFromProfile =
      'Puoi cambiarlo in seguito dal profilo.';
  static const whereDoYouWork = 'Dove lavori?';
  static const administrationHint = 'Amministrazione';
  static const standardSchedule = 'Orario Standard';
  static String differsFromStandard(String employmentType) =>
      "Differisce dallo standard '$employmentType'";
  static const mealVoucherThresholdTitle = 'Soglia Buono Pasto';
  static const usuallyMealThresholdNote =
      'Di solito 6h 20m per i dipendenti pubblici (CCNL)';
  static const overtimeCapTitle = 'Tetto Straordinari';
  static const preferredTheme = 'Tema preferito';
  static const structureAndOfficeOptional = 'Struttura e sede (opzionale)';
  static const sliSboMonthlyOptional = 'SLI / SBO mensile (opzionale)';
  static String sliHoursValue(int hours) => 'SLI: $hours ore';
  static String sboHoursValue(int hours) => 'SBO: $hours ore';
  static const sliSboLegend =
      'SLI = straordinario liquidato in busta  |  SBO = straordinario in banca ore';
  static const noOfficeAvailable = 'Nessuna sede disponibile.';
  static const selectStructure = 'Seleziona struttura';
  static const youCanUpdateItLaterFromProfile =
      'Puoi aggiornarla in seguito dal profilo.';
  // ── Onboarding S-12 ──────────────────────────────────────────────────────
  static const art9StepTitle = 'Articolo 9 — Smart Working';
  static const art9ZeroLabel = '0 ore/mese\n(nessun Art. 9)';
  static const art9MaxLabelRuolo = '8 ore/mese\n(Ruolo — completo)';
  static const art9MaxLabelComando = '17 ore/mese\n(Comando — completo)';
  static const art9AltroHint = 'Inserisci le ore mensili di smart working previste dal tuo contratto.';
  static const sliSboCapStepTitle = 'SLI, SBO e Tetto Straordinari';
  static String sauLabel(int hours) => 'SAU (Tetto): $hours ore/mese';
  static const sliSboCapNote =
      'Il tetto è calcolato automaticamente come SLI + SBO. Puoi modificarli in seguito dal profilo.';
  static const dipartimentoAndSedeTitle = 'Dipartimento e sede (opzionale)';
  static const selectDepartment = 'Seleziona dipartimento';
  static const suggestedSedeLabel = '★ Sede consigliata';

  // ── Social ────────────────────────────────────────────────────────────────
  static const statusExited = 'Uscito';
  static const statusOutOfOffice = 'Non in ufficio';
  static String peopleInOffice(int count) => '$count in ufficio';
  static String pianoValue(String piano) => 'Piano $piano';
  static String stanzaShort(String stanza) => 'St. $stanza';
  static const noResults = 'Nessun risultato.';
  static const addColleaguesHint =
      'Aggiungi i tuoi colleghi della stessa\namministrazione con il tasto +';
  static const sentSublabel = 'inviati';
  static const receivedSublabel = 'ricevuti';
  static const acceptedSublabel = 'accettati';
  static const noGroup = 'Nessun gruppo';
  static String groupCount(int count) =>
      '$count ${count == 1 ? 'gruppo' : 'gruppi'}';
  static const coffeeLabel = 'Caffè';
  static const sendNow = 'Adesso';
  static const sendInviteNow = "Invia l'invito subito";
  static const planLabel = 'Pianifica';
  static const chooseTime = 'Scegli un orario';

  // ── Notifications ─────────────────────────────────────────────────────────
  static String etaMinutesValue(int minutes) => '($minutes min)';
  static String quotedMessage(String message) => '"$message"';
  static const respImThere = 'Ci sono';
  static const respMaybeShort = 'Forse';
  static const respCannot = 'Non posso';

  // ── Stats screen ──────────────────────────────────────────────────────────
  static String daysCount(int days) => '$days gg';
  static String leaveAndHolidayDays(int leaveDays, int holidayDays) =>
      '$leaveDays'
      'P + $holidayDays'
      'F';
  static const advancedStatsUpper = 'STATISTICHE AVANZATE';
  static const attendanceRecord = 'Record presenze';
  static const averageBreak = 'Pausa media';
  static const punctuality = 'Puntualità';
}
