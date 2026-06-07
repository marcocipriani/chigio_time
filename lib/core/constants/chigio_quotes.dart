typedef ChigioQuote = (String phrase, String image, String label);

abstract final class ChigioQuotes {
  static const ciao = 'assets/images/chigio-ciao.png';
  static const ok = 'assets/images/chigio-ok.png';
  static const caffe = 'assets/images/chigio-caffe.png';
  static const orologio = 'assets/images/chigio-orologio.png';
  static const calcolatrice = 'assets/images/chigio-calcolatrice.png';
  static const sonno = 'assets/images/chigio-sonno.png';
  static const icon = 'assets/images/app_icon.png';

  static const wow = ok;
  static const love = ciao;
  static const triste = sonno;
  static const scrivania = icon;
  static const telefono = ciao;
  static const martini = caffe;
  static const buonoPasto = calcolatrice;
  static const tartaruga = icon;

  static const List<ChigioQuote> payday = [
    (
      'Buon 23, {n}. Stipendio in arrivo: calma e decoro.',
      buonoPasto,
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
  ];

  static const List<ChigioQuote> morningNotStarted = [
    ('Buongiorno, {n}. La giornata non si timbra da sola.', ciao, 'Ehi!'),
    ('Ciao {n}. Prima il caffè, poi la timbrata.', caffe, 'Caffè?'),
    ('{n}, occhio all\'orologio. Puntuali{o|a}?', orologio, 'Sveglia!'),
    ('La PA può attendere. La timbratura meno, {n}.', telefono, 'Si timbra?'),
    (
      'Il portale ti aspetta, {n}. Io tengo il tempo.',
      scrivania,
      'In bocca al lupo!',
    ),
    ('Festina lente, {n}: timbra in tempo.', orologio, 'Festina lente'),
  ];

  static const List<ChigioQuote> morningWorking = [
    ('Già in pista, {n}. Piano, preciso, puntuale.', wow, 'In marcia!'),
    ('{n}, turno mattutino in ordine.', ok, 'Operativ{o|a}!'),
    ('Mattiniero{o|a} e determinat{o|a}, {n}. Approvato.', love, 'Approvato!'),
    ('{n}, ogni minuto conta. Io li conto tutti.', calcolatrice, 'Minuti!'),
    ('Turno iniziato con slancio, {n}. Bene così.', ciao, 'Bella!'),
    ('Calma istituzionale, precisione digitale.', calcolatrice, 'Precisi!'),
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
    ('Resistenza pomeridiana, {n}. Ore eroiche.', ok, 'Eroic{o|a}!'),
    (
      'Il tempo è relativo. Il buono pasto è assoluto.',
      calcolatrice,
      'Assoluto!',
    ),
  ];

  static const List<ChigioQuote> afternoonNotStarted = [
    ('{n}, quasi pranzo. La timbratura chiede udienza.', telefono, 'Eh?'),
    ('Non giudico, {n}. L\'entrata era stamattina.', triste, 'Mah...'),
    ('Ognuno corre a modo suo, {n}. Ora timbriamo.', tartaruga, 'Con calma!'),
    ('Il turno ti aspetta, {n}. Non è mai troppo tardi.', ciao, 'Dai!'),
    ('L\'orario scorre, {n}. La pratica resta.', orologio, 'Scorre!'),
  ];

  static const List<ChigioQuote> eveningWorking = [
    ('{n}, sei ancora lì? Leggendari{o|a}.', wow, 'Eroe!'),
    ('Bella sera, {n}. Stai per finire?', martini, 'Si chiude?'),
    ('{n}, anche Chigio dorme. Sul serio.', triste, 'Nanna?'),
    ('Quasi fatto, {n}. Ultimo sprint.', ok, 'Ultimo!'),
    ('Ore piccole, {n}. Procedi verso l\'uscita.', orologio, 'Notte!'),
  ];

  static const List<ChigioQuote> eveningNotStarted = [
    ('{n}, è sera. Anche lo SW andrebbe timbrato.', telefono, 'Tutto ok?'),
    ('Smart working segreto, {n}? Non verbalizzo.', tartaruga, 'Segreto?'),
    ('Domani è un altro giorno, {n}.', ciao, 'Domani!'),
  ];

  static const List<ChigioQuote> paused = [
    ('{n}, pausa meritata. Il caffè non aspetta.', caffe, 'Break!'),
    ('Break time, {n}. Timer paziente, caffè no.', martini, 'Pausa!'),
    ('Staccare aiuta, {n}. Parola di Chigio.', love, 'Respira!'),
    ('Firmware biologico in aggiornamento, {n}.', caffe, 'Upgrade!'),
    ('Amministrativamente in pausa, {n}.', martini, 'Pausa PA'),
    ('Nulla osta a un altro caffè, {n}.', caffe, 'Nulla osta'),
    ('Direttiva benessere applicata, {n}.', love, 'Benessere'),
  ];

  static const List<ChigioQuote> completed = [
    ('Fatto, {n}. Oggi hai vint{o|a}. Chigio approva.', wow, 'FATTO!'),
    ('{n}, turno chiuso. Applauso protocollato.', ok, 'Finito!'),
    ('Impeccabile, {n}. Serata libera meritata.', martini, 'Libertà!'),
    ('Cartellino chiuso, {n}. I conti tornano.', calcolatrice, 'Perfetto!'),
    ('Obiettivo raggiunto: buono pasto vidimato.', buonoPasto, 'BP ok'),
    ('Straordinariamente in regola, {n}.', ok, 'In regola'),
    ('Firmato, sigillato, archiviato. A domani.', scrivania, 'A domani'),
    ('Debito orario? Non sotto la mia gestione.', calcolatrice, 'Debito no'),
  ];

  static const List<ChigioQuote> abandoned = [
    ('{n}, ieri il turno è rimasto aperto. Sistemiamo.', triste, 'Ops...'),
    ('Turno incompleto, {n}. Chiudiamolo insieme.', telefono, 'Completiamo'),
    ('Nessun giudizio, {n}. Risolviamo in 10 secondi.', love, 'Tranquill{o|a}'),
    ('{n}, il turno di ieri aspettava ancora.', scrivania, 'Recuperiamo!'),
  ];

  static const List<ChigioQuote> timesheet = [
    ('{n}, ogni giornata racconta una storia.', scrivania, 'Storia!'),
    ('Controlla tutto, {n}. I dettagli contano.', ok, 'Controlla!'),
    ('{n}, il registro parla chiaro.', calcolatrice, 'Registro!'),
    ('Il passato non si cambia, ma si completa, {n}.', telefono, 'Completa!'),
    ('Ordinat{o|a} come sempre, {n}. Precisione apprezzata.', love, 'Ordine!'),
    ('Cartellino in regola, {n}? Zero anomalie.', ok, 'Check!'),
  ];

  static const List<ChigioQuote> social = [
    ('{n}, i colleghi ti vogliono bene. Quasi quanto me.', love, 'Community!'),
    ('Un caffè con i colleghi vale oro, {n}.', caffe, 'Social!'),
    ('{n}, curios{o|a} di chi è in ufficio oggi?', telefono, 'Curiosità!'),
    ('Anche Chigio socializza, {n}. Ci prova.', tartaruga, 'Networking!'),
    ('{n}, invia l\'invito caffè. Nulla osta.', caffe, 'Osa!'),
    ('Colleghi in ufficio, {n}. Almeno uno, forse.', scrivania, 'Conta!'),
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
  ];

  static const List<ChigioQuote> stats = [
    ('{n}, le statistiche non dormono mai. Io sì.', calcolatrice, 'Stats!'),
    ('Guarda quanto hai lavorato, {n}. Impressionante.', wow, 'Wow!'),
    ('{n}, i grafici parlano chiaro.', ok, 'Grafici!'),
    ('Ogni barra è impegno reale, {n}. Chapeau.', love, 'Chapeau!'),
    ('OT, permessi, medie: {n}, archivio vivente.', scrivania, 'Numeri!'),
  ];
}
