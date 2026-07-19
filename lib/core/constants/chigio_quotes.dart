typedef ChigioQuote = (String phrase, String image, String label);

abstract final class ChigioQuotes {
  static const ciao = 'assets/images/chigio-ciao.png';
  static const ok = 'assets/images/chigio-ok.png';
  static const caffe = 'assets/images/chigio-caffe.png';
  static const orologio = 'assets/images/chigio-orologio.png';
  static const calcolatrice = 'assets/images/chigio-calcolatrice.png';
  static const sonno = 'assets/images/chigio-sonno.png';
  static const icon = 'assets/images/app_icon.png';
  // Nuove espressioni (luglio 2026)
  static const base = 'assets/images/chigio.png';
  static const festeggia = 'assets/images/chigio-festeggia.png';
  static const lista = 'assets/images/chigio-lista.png';
  static const avviso = 'assets/images/chigio-avviso.png';
  static const timer = 'assets/images/chigio-timer.png';
  static const corre = 'assets/images/chigio-corre.png';
  static const okCammina = 'assets/images/chigio-ok-cammina.png';
  static const bavaglino = 'assets/images/chigio-bavaglino.png';

  static const wow = festeggia;
  static const love = ciao;
  static const triste = sonno;
  static const scrivania = lista;
  static const telefono = avviso;
  static const martini = caffe;
  static const buonoPasto = bavaglino;
  static const tartaruga = base;

  static const List<ChigioQuote> payday = [
    (
      'Buon 23, {n}. Stipendio in arrivo: calma e decoro.',
      calcolatrice,
      'Payday!',
    ),
    ('{n}, oggi è il 23. Festeggia con moderazione.', love, '23!'),
    (
      'Finalmente il 23, {n}. Risparmia il 10%. Forse.',
      calcolatrice,
      'Busta paga!',
    ),
    ('Il 23 illumina il mese, {n}. Procediamo.', wow, '23 sveglia!'),
    (
      '{n}, paga e poi pedalate. Con calma istituzionale.',
      tartaruga,
      'Stipendio!',
    ),
    ('Il 23 è qui, {n}. Chigio fa i conti piano.', calcolatrice, 'Conti ok'),
    ('Busta paga avvistata. Mantieni il contegno, {n}.', ok, 'Avvistata'),
  ];

  static const List<ChigioQuote> departmentMorning = [
    ('Buongiorno da {dep}, {n}. Si procede.', scrivania, 'Il tuo Dip.'),
    ('{dep}: si parte, {n}. Con metodo.', ciao, 'Si parte'),
    ('Da {dep}, calma e precisione.', calcolatrice, 'Assetto'),
    ('{dep}: passo lento, firma certa.', tartaruga, 'Firma certa'),
  ];

  static const List<ChigioQuote> departmentAfternoon = [
    ('Da {dep}, pomeriggio in tenuta.', ok, 'In tenuta'),
    ('{dep}: pratica viva, {n}.', scrivania, 'Pratica viva'),
    ('{dep}: il caffè coordina, Chigio misura.', caffe, 'Coordinati'),
    ('{dep}: Chigio presidia il tempo.', orologio, 'Presidio'),
  ];

  static const List<ChigioQuote> departmentEvening = [
    ('Da {dep}, chiusura con decoro.', ok, 'Chiusura'),
    ('{dep}: ultimi minuti, {n}.', orologio, 'Quasi'),
    ('{dep}: domani si riparte.', tartaruga, 'Domani'),
    ('{dep}: luci basse, conti chiari.', calcolatrice, 'Conti chiari'),
  ];

  static const List<ChigioQuote> siteMorning = [
    ('{site} si sveglia piano, {n}. Chigio è già lì.', ciao, 'Sede viva'),
    ('Da {site}, rotta chiara e guscio saldo.', tartaruga, 'Rotta'),
    ('{site}: minuti allineati, passo gentile.', orologio, 'Allineati'),
  ];

  static const List<ChigioQuote> siteAfternoon = [
    ('{site} regge il pomeriggio, {n}. Anche tu.', ok, 'Tiene'),
    ('Da {site}, Chigio misura senza clamore.', calcolatrice, 'Misura'),
    ('{site}: caffè, metodo e un po\' di gloria.', caffe, 'Gloria'),
  ];

  static const List<ChigioQuote> siteEvening = [
    ('{site} abbassa la voce, {n}. Si chiude bene.', sonno, 'Voce bassa'),
    ('Da {site}, ultimi passi con contegno.', orologio, 'Contegno'),
    ('{site}: il guscio sa quando tornare a casa.', tartaruga, 'Casa'),
  ];

  static const List<ChigioQuote> remoteDay = [
    ('Smart working attivo, {n}. Chigio presidia da remoto.', telefono, 'SW'),
    ('Da remoto, ma con il guscio in assetto.', tartaruga, 'Assetto SW'),
    ('Casa o ufficio, {n}: il tempo resta serio.', orologio, 'Tempo serio'),
  ];

  static const List<ChigioQuote> leaveDay = [
    ('Assenza segnata, {n}. Chigio custodisce il tempo.', scrivania, 'Assenza'),
    ('Permesso in registro. Tutto con misura, {n}.', ok, 'Permesso'),
    ('Oggi il ritmo cambia, {n}. Chigio si adatta.', love, 'Si adatta'),
  ];

  static const List<ChigioQuote> holidayDay = [
    ('Ferie registrate, {n}. Il guscio respira.', martini, 'Ferie'),
    ('Oggi il tempo indossa occhiali da sole.', love, 'Respiro'),
    ('Riposo autorizzato, {n}. Chigio parla piano.', sonno, 'Riposo'),
  ];

  static const List<ChigioQuote> mealVoucher = [
    ('Stasera si mangia!', buonoPasto, 'Si mangia!'),
    ('Scorpacciata di insalata', buonoPasto, 'Insalata!'),
    ('Adoro i tarassachi', buonoPasto, 'Tarassachi!'),
  ];

  static const List<ChigioQuote> finalHour = [
    ('Manca {remaining}, {n}. Chigio vede casa.', orologio, 'Casa vicina'),
    ('Ultima ora, {n}. Mantieni il passo elegante.', ok, 'Ultima ora'),
    ('Il traguardo si avvicina senza fare rumore.', tartaruga, 'Traguardo'),
  ];

  static const List<ChigioQuote> exitSoon = [
    ('Ancora {remaining}, {n}. Il guscio sente l\'uscita.', orologio, 'Quasi'),
    ('Ultimi minuti: decoro alto, zaino pronto.', tartaruga, 'Zaino'),
    ('Chigio vede la porta. Tu chiudi bene, {n}.', ok, 'Porta'),
  ];

  static const List<ChigioQuote> overtime = [
    ('Straordinario in corso, {n}. Chigio prende appunti.', scrivania, 'OT'),
    ('Oltre soglia, {n}. Guscio serio, cuore caldo.', love, 'Oltre'),
    ('Il tempo extra pesa. Tu lo stai governando.', calcolatrice, 'Governo'),
  ];

  static const List<ChigioQuote> monday = [
    ('Lunedì parte piano, {n}. Ma parte.', tartaruga, 'Lunedì'),
    ('Primo passo della settimana: già vale qualcosa.', ciao, 'Primo passo'),
    ('Il lunedì fa scena. Chigio fa metodo.', ok, 'Metodo'),
  ];

  static const List<ChigioQuote> friday = [
    ('Venerdì in vista, {n}. Mantieni il contegno.', ok, 'Venerdì'),
    (
      'La settimana rallenta. Chigio conta fino in fondo.',
      calcolatrice,
      'Fino in fondo',
    ),
    ('Ultima curva, {n}. Il guscio sente il weekend.', tartaruga, 'Weekend'),
  ];

  static const List<ChigioQuote> motivational = [
    ('Una riga alla volta, {n}. Anche così si governa il tempo.', ok, 'Avanti'),
    (
      'Non serve correre: serve tornare coi conti chiari.',
      calcolatrice,
      'Chiari',
    ),
    ('Piccoli minuti, grandi saldi. Chigio ci crede.', love, 'Ci crede'),
    ('Il ritmo giusto è quello che resta, {n}.', tartaruga, 'Ritmo'),
    ('Fai ordine nel tempo. Il resto respira meglio.', scrivania, 'Ordine'),
    ('Anche oggi: passo corto, visione lunga.', ciao, 'Visione'),
    ('Il lavoro buono non fa rumore. Si vede nei dettagli.', ok, 'Dettagli'),
    ('Chigio tifa piano, ma tifa forte, {n}.', love, 'Tifo'),
  ];

  static const List<ChigioQuote> morningNotStarted = [
    ('Buongiorno, {n}. La giornata non si timbra da sola.', ciao, 'Ehi!'),
    ('Ciao {n}. Prima il caffè, poi la timbrata.', caffe, 'Caffè?'),
    ('Ti vedo {pronto|pronta|prontə}, {n}: timbriamo?', orologio, 'Sveglia!'),
    ('La PA può attendere. La timbratura meno, {n}.', telefono, 'Si timbra?'),
    (
      'Il portale ti aspetta, {n}. Io tengo il tempo.',
      scrivania,
      'In bocca al lupo!',
    ),
    ('Festina lente, {n}: timbra in tempo.', orologio, 'Festina lente'),
    ('Il guscio è pronto, {n}. Mancano solo i minuti.', tartaruga, 'Pronti'),
    ('Chigio è lento, non distratto. Buongiorno, {n}.', ciao, 'A fuoco'),
    ('Lento per natura, puntuale per missione, {n}.', orologio, 'Missione'),
  ];

  static const List<ChigioQuote> morningWorking = [
    ('Già in pista, {n}. Piano, preciso, puntuale.', wow, 'In marcia!'),
    ('{n}, turno mattutino in ordine.', ok, 'Operatività'),
    ('Ti vedo {pronto|pronta|prontə}, {n}. Approvato.', love, 'Approvato!'),
    ('{n}, ogni minuto conta. Io li conto tutti.', calcolatrice, 'Minuti!'),
    ('Turno iniziato con slancio, {n}. Bene così.', ciao, 'Bella!'),
    ('Calma istituzionale, precisione digitale.', calcolatrice, 'Precisi!'),
    ('Guscio stabile, rotta chiara, {n}.', tartaruga, 'Rotta chiara'),
    ('Chigio misura, {n}. Tu fai succedere le cose.', calcolatrice, 'Succede'),
    ('Protocollo avviato: giornata in carreggiata.', ok, 'Avviato'),
  ];

  static const List<ChigioQuote> afternoonWorking = [
    ('Metà strada fatta, {n}. Resistenza amministrativa.', ok, 'A metà!'),
    (
      'Pomeriggio nobile, {n}. O così dice la circolare.',
      tartaruga,
      'Pomeriggio!',
    ),
    ('L\'uscita si avvicina, {n}. Mantieni il decoro.', orologio, 'Quasi!'),
    ('{n}, pausa caffè autorizzata. Rientro previsto.', caffe, 'Pausa!'),
    ('Ti vedo ancora in piedi, {n}. Rispetto assoluto.', love, 'Tenace!'),
    ('{n}, gli straordinari li archivio io. Tu respira.', martini, 'Exit?'),
    ('Resistenza pomeridiana, {n}. Ore eroiche.', ok, 'Ore eroiche'),
    (
      'Il tempo è relativo. Il buono pasto è assoluto.',
      calcolatrice,
      'Assoluto!',
    ),
    ('Il pomeriggio pesa, {n}. Il guscio regge.', tartaruga, 'Si regge'),
    ('Minuto dopo minuto, {n}. Chigio non molla.', ok, 'Non molla'),
    ('Calma, {n}: anche le code hanno un protocollo.', telefono, 'Protocollo'),
  ];

  static const List<ChigioQuote> afternoonNotStarted = [
    ('{n}, quasi pranzo. La timbratura chiede udienza.', telefono, 'Eh?'),
    ('Non giudico, {n}. L\'entrata era stamattina.', triste, 'Mah...'),
    ('Ognuno corre a modo suo, {n}. Ora timbriamo.', tartaruga, 'Con calma!'),
    ('Il turno ti aspetta, {n}. Non è mai troppo tardi.', ciao, 'Dai!'),
    ('L\'orario scorre, {n}. La pratica resta.', orologio, 'Scorre!'),
    (
      'Entrata tardiva, {n}. Chigio verbalizza con tatto.',
      scrivania,
      'Con tatto',
    ),
    ('Il tempo ha bussato, {n}. Io ho aperto piano.', orologio, 'Bussato'),
  ];

  static const List<ChigioQuote> eveningWorking = [
    (
      'Sei ancora lì, {n}? {Leggendario|Leggendaria|Leggendariə}.',
      wow,
      'Eroe!',
    ),
    ('Bella sera, {n}. Stai per finire?', martini, 'Si chiude?'),
    ('{n}, anche Chigio dorme. Sul serio.', triste, 'Nanna?'),
    ('Quasi fatto, {n}. Ultimo sprint.', ok, 'Ultimo!'),
    ('Ore piccole, {n}. Procedi verso l\'uscita.', orologio, 'Notte!'),
    ('Chigio abbassa le luci, {n}. Tu chiudi il cerchio.', martini, 'Cerchio'),
    ('La sera approva il rientro, {n}. Io pure.', ok, 'Rientro'),
    ('Ultimi passi, {n}. Il guscio sa la strada.', tartaruga, 'Ultimi'),
  ];

  static const List<ChigioQuote> eveningNotStarted = [
    ('{n}, è tardi. Anche lo SW andrebbe timbrato.', telefono, 'Tutto ok?'),
    ('Smart working segreto, {n}? Non verbalizzo.', tartaruga, 'Segreto?'),
    ('Domani è un altro giorno, {n}.', ciao, 'Domani!'),
    ('Il giorno sfuma, {n}. Chigio resta diplomatico.', sonno, 'Diplomazia'),
    ('Archiviamo la notte, {n}. Senza rumore.', scrivania, 'Archivio'),
  ];

  static const List<ChigioQuote> paused = [
    ('{n}, pausa meritata. Il caffè non aspetta.', caffe, 'Break!'),
    ('Break time, {n}. Timer paziente, caffè no.', martini, 'Pausa!'),
    ('Staccare aiuta, {n}. Parola di Chigio.', love, 'Respira!'),
    ('Firmware biologico in aggiornamento, {n}.', caffe, 'Upgrade!'),
    ('Amministrativamente in pausa, {n}.', martini, 'Pausa PA'),
    ('Nulla osta a un altro caffè, {n}.', caffe, 'Nulla osta'),
    ('Direttiva benessere applicata, {n}.', love, 'Benessere'),
    ('Pausa in corso, {n}. Il guscio ricarica.', caffe, 'Ricarica'),
    ('Silenzio operativo, {n}. Caffè in audizione.', martini, 'Audizione'),
    ('Chigio sospende il tempo. Solo un attimo, {n}.', orologio, 'Sospeso'),
  ];

  static const List<ChigioQuote> completed = [
    ('Fatto, {n}. Oggi hai vinto. Chigio approva.', wow, 'FATTO!'),
    ('{n}, turno chiuso. Applauso protocollato.', ok, 'Finito!'),
    ('Impeccabile, {n}. Serata libera meritata.', martini, 'Libertà!'),
    ('Cartellino chiuso, {n}. I conti tornano.', calcolatrice, 'Perfetto!'),
    ('Obiettivo raggiunto: buono pasto vidimato.', buonoPasto, 'BP ok'),
    ('Straordinariamente in regola, {n}.', ok, 'In regola'),
    ('Firmato, sigillato, archiviato. A domani.', scrivania, 'A domani'),
    ('Debito orario? Non sotto la mia gestione.', calcolatrice, 'Debito no'),
    ('Missione compiuta, {n}. Guscio in modalità casa.', tartaruga, 'Casa'),
    ('Chiusura elegante, {n}. Chigio prende nota.', scrivania, 'Elegante'),
    ('Hai finito bene, {n}. Il tempo firma per te.', orologio, 'Firma'),
  ];

  static const List<ChigioQuote> abandoned = [
    ('{n}, ieri il turno è rimasto aperto. Sistemiamo.', triste, 'Ops...'),
    ('Turno incompleto, {n}. Chiudiamolo insieme.', telefono, 'Completiamo'),
    (
      'Nessun giudizio, {n}. Risolviamo in 10 secondi.',
      love,
      '{Tranquillo|Tranquilla|Tranquillə}',
    ),
    ('{n}, il turno di ieri aspettava ancora.', scrivania, 'Recuperiamo!'),
    ('Niente panico, {n}. Chigio scioglie il nodo.', love, 'Niente panico'),
    ('Il tempo è rimasto aperto. Lo chiudiamo con stile.', ok, 'Con stile'),
  ];

  static const List<ChigioQuote> timesheet = [
    ('{n}, ogni giornata racconta una storia.', scrivania, 'Storia!'),
    ('Controlla tutto, {n}. I dettagli contano.', ok, 'Controlla!'),
    ('{n}, il registro parla chiaro.', calcolatrice, 'Registro!'),
    ('Il passato non si cambia, ma si completa, {n}.', telefono, 'Completa!'),
    ('Registro ordinato, {n}. Precisione apprezzata.', love, 'Ordine!'),
    ('Cartellino in regola, {n}? Zero anomalie.', ok, 'Check!'),
    (
      'Il cartellino parla piano, {n}. Ma dice tutto.',
      calcolatrice,
      'Dice tutto',
    ),
    ('Giorni, ore, pause: Chigio mette in fila.', scrivania, 'In fila'),
    ('Ogni riga ha un carattere, {n}. Anche questa.', ciao, 'Carattere'),
  ];

  static const List<ChigioQuote> social = [
    ('{n}, i colleghi ti vogliono bene. Quasi quanto me.', love, 'Community!'),
    ('Un caffè con i colleghi vale oro, {n}.', caffe, 'Social!'),
    ('Curiosità: chi è in ufficio oggi, {n}?', telefono, 'Curiosità!'),
    ('Anche Chigio socializza, {n}. Ci prova.', tartaruga, 'Networking!'),
    ('{n}, invia l\'invito caffè. Nulla osta.', caffe, 'Osa!'),
    ('Colleghi in ufficio, {n}. Almeno uno, forse.', scrivania, 'Conta!'),
    ('Caffè condiviso, {n}. La burocrazia sorride.', caffe, 'Sorride'),
    (
      'Chigio rompe il ghiaccio. Lentamente, ma lo rompe.',
      tartaruga,
      'Ghiaccio',
    ),
    ('Una pausa insieme vale doppio, {n}. Quasi triplo.', love, 'Insieme'),
  ];

  static const List<ChigioQuote> profile = [
    (
      '{n}, guarda quant\'hai lavorato. I dati non mentono.',
      calcolatrice,
      'Dati!',
    ),
    ('Aggiorna il profilo, {n}. Con calma.', ok, 'Profilo!'),
    ('Profilo completo: Chigio felice, {n}.', love, 'Completo!'),
    ('{n}, il profilo è una finestra su di te.', ciao, 'Identità!'),
    ('Impostazioni a posto, {n}? Chigio controlla.', scrivania, 'Check!'),
    ('Identità ordinata, {n}. Il guscio ringrazia.', ciao, 'Identità'),
    ('Preferenze salvate, Chigio più sereno.', ok, 'Sereno'),
    ('Qui si decide il tono, {n}. Chigio ascolta.', love, 'Ascolto'),
  ];

  static const List<String> invite = [
    'Il tempo si governa meglio in compagnia.',
    'Chigio è lento, ma conta bene. Portami un collega.',
    'Con più timbrature, i conti tornano più in fretta.',
    'Il guscio ha spazio per un\'altra tartaruga.',
    'Anche i colleghi meritano ordine nei minuti.',
    'Chigio tifa la squadra, non solo il singolo.',
    'Un invito è già un atto di collaborazione istituzionale.',
  ];

  static const List<ChigioQuote> stats = [
    ('{n}, le statistiche non dormono mai. Io sì.', calcolatrice, 'Stats!'),
    ('Guarda quanto hai lavorato, {n}. Impressionante.', wow, 'Wow!'),
    ('{n}, i grafici parlano chiaro.', ok, 'Grafici!'),
    ('Ogni barra è impegno reale, {n}. Chapeau.', love, 'Chapeau!'),
    ('OT, permessi, medie: {n}, archivio vivente.', scrivania, 'Numeri!'),
    ('I numeri hanno memoria, {n}. Chigio pure.', calcolatrice, 'Memoria'),
    ('Grafici composti, anima vivace, {n}.', wow, 'Vivace'),
    ('La media non giudica, {n}. Suggerisce.', ok, 'Suggerisce'),
  ];
}
