import 'pcm_locations.dart';

enum PcmDepartmentGroup {
  dipartimentiUffici,
  struttureMissione,
  ufficiPolitici,
}

class PcmDepartment {
  final String name;
  final PcmDepartmentGroup group;
  final String? primarySedeId;

  const PcmDepartment({
    required this.name,
    required this.group,
    this.primarySedeId,
  });
}

const kPcmDepartments = <PcmDepartment>[
  // ── Dipartimenti e Uffici autonomi (ordine alfabetico) ───────────────────
  PcmDepartment(
    name: 'Dipartimento "Casa Italia"',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'casa-italia-ferratella',
  ),
  PcmDepartment(
    name: 'Dipartimento della funzione pubblica',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'dfp-palazzo-vidoni',
  ),
  PcmDepartment(
    name: 'Dipartimento della protezione civile',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'protezione-civile-ulpiano',
  ),
  PcmDepartment(
    name: 'Dipartimento per gli affari europei',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'affari-europei-largo-chigi',
  ),
  PcmDepartment(
    name: 'Dipartimento per gli affari giuridici e legislativi',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'dagl-palazzo-chigi',
  ),
  PcmDepartment(
    name: 'Dipartimento per gli affari regionali e le autonomie',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'daras-stamperia',
  ),
  PcmDepartment(
    name: 'Dipartimento per i rapporti con il Parlamento',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'rapporti-parlamento-largo-chigi',
  ),
  PcmDepartment(
    name: 'Dipartimento per i servizi strumentali',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'servizi-strumentali-mercede-96',
  ),
  PcmDepartment(
    name: 'Dipartimento per il coordinamento amministrativo',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'dica-mercede-9',
  ),
  PcmDepartment(
    name: 'Dipartimento per il personale',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'personale-mercede-96',
  ),
  PcmDepartment(
    name: 'Dipartimento per il programma di Governo',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'programma-governo-mercede-96',
  ),
  PcmDepartment(
    name: 'Dipartimento per il Sud',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'coesione-sud-sicilia',
  ),
  PcmDepartment(
    name: "Dipartimento per l'informazione e l'editoria",
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'die-mercede-9',
  ),
  PcmDepartment(
    name: 'Dipartimento per la programmazione e il coordinamento della politica economica',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'dipe-mercede-9',
  ),
  PcmDepartment(
    name: 'Dipartimento per la trasformazione digitale',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'dtd-brazza',
  ),
  PcmDepartment(
    name: 'Dipartimento per le pari opportunità',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'pari-opportunita-largo-chigi',
  ),
  PcmDepartment(
    name: 'Dipartimento per le politiche contro la droga e le altre dipendenze',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'droga-dipendenze-ferratella',
  ),
  PcmDepartment(
    name: 'Dipartimento per le politiche del mare',
    group: PcmDepartmentGroup.dipartimentiUffici,
  ),
  PcmDepartment(
    name: 'Dipartimento per le politiche della famiglia',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'famiglia-iv-novembre',
  ),
  PcmDepartment(
    name: 'Dipartimento per le politiche di coesione',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'coesione-sud-sicilia',
  ),
  PcmDepartment(
    name: 'Dipartimento per le politiche giovanili e il Servizio civile universale',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'giovani-scu-ferratella',
  ),
  PcmDepartment(
    name: 'Dipartimento per le politiche in favore delle persone con disabilità',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'disabilita-panetteria',
  ),
  PcmDepartment(
    name: 'Dipartimento per le riforme istituzionali',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'riforme-istituzionali-largo-chigi',
  ),
  PcmDepartment(
    name: 'Dipartimento per lo sport',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'sport-sardegna',
  ),
  PcmDepartment(
    name: 'Ufficio del bilancio e per il riscontro di regolarità amministrativo-contabile',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'ubbrac-mercede-96',
  ),
  PcmDepartment(
    name: 'Ufficio del cerimoniale di Stato e per le onorificenze',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'cerimoniale-palazzo-chigi',
  ),
  PcmDepartment(
    name: "Ufficio del controllo interno, la trasparenza e l'integrità",
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'uci-mercede-96',
  ),
  PcmDepartment(
    name: 'Ufficio del Segretario generale',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'segretario-generale-chigi-mercede-96',
  ),
  PcmDepartment(
    name: 'Ufficio di segreteria del Consiglio dei Ministri',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'segreteria-cdm-palazzo-chigi',
  ),
  PcmDepartment(
    name: 'Ufficio di segreteria della Conferenza Stato-città ed autonomie locali',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'conferenza-stato-citta-stamperia',
  ),
  PcmDepartment(
    name: 'Ufficio per le politiche spaziali e aerospaziali',
    group: PcmDepartmentGroup.dipartimentiUffici,
    primarySedeId: 'politiche-spaziali-molise',
  ),

  // ── Strutture di missione (ordine alfabetico) ─────────────────────────────
  PcmDepartment(
    name: 'Struttura di missione per gli anniversari di interesse nazionale',
    group: PcmDepartmentGroup.struttureMissione,
  ),
  PcmDepartment(
    name: 'Struttura di missione per il contrasto della scarsità idrica e per il potenziamento delle infrastrutture idriche',
    group: PcmDepartmentGroup.struttureMissione,
  ),
  PcmDepartment(
    name: 'Struttura di missione per il coordinamento dei processi di ricostruzione e sviluppo dei territori colpiti dal sisma del 6 aprile 2009',
    group: PcmDepartmentGroup.struttureMissione,
  ),
  PcmDepartment(
    name: "Struttura di missione per l'attuazione del Piano Mattei",
    group: PcmDepartmentGroup.struttureMissione,
  ),
  PcmDepartment(
    name: 'Struttura di missione per la semplificazione normativa',
    group: PcmDepartmentGroup.struttureMissione,
  ),
  PcmDepartment(
    name: "Struttura di missione per le procedure d'infrazione alla normativa UE",
    group: PcmDepartmentGroup.struttureMissione,
  ),
  PcmDepartment(
    name: 'Struttura di missione PNRR',
    group: PcmDepartmentGroup.struttureMissione,
    primarySedeId: 'missione-pnrr-largo-chigi',
  ),
  PcmDepartment(
    name: 'Struttura di missione Segreteria tecnica per le politiche in materia di disabilità',
    group: PcmDepartmentGroup.struttureMissione,
    primarySedeId: 'disabilita-panetteria',
  ),
  PcmDepartment(
    name: 'Struttura di missione ZES',
    group: PcmDepartmentGroup.struttureMissione,
  ),
  PcmDepartment(
    name: 'Unità per la semplificazione e la qualità della regolazione',
    group: PcmDepartmentGroup.struttureMissione,
    primarySedeId: 'dfp-palazzo-vidoni',
  ),

  // ── Uffici di diretta collaborazione (ordine alfabetico) ─────────────────
  PcmDepartment(
    name: 'Uffici del Ministro per gli affari europei, il PNRR e le politiche di coesione',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'affari-europei-largo-chigi',
  ),
  PcmDepartment(
    name: 'Uffici del Ministro per gli affari regionali e le autonomie',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'daras-stamperia',
  ),
  PcmDepartment(
    name: 'Uffici del Ministro per i rapporti con il Parlamento',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'rapporti-parlamento-largo-chigi',
  ),
  PcmDepartment(
    name: 'Uffici del Ministro per la famiglia, la natalità e le pari opportunità',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'pari-opportunita-largo-chigi',
  ),
  PcmDepartment(
    name: 'Uffici del Ministro per la Protezione civile e le Politiche del mare',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'protezione-civile-ulpiano',
  ),
  PcmDepartment(
    name: 'Uffici del Ministro per la Pubblica Amministrazione',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'dfp-palazzo-vidoni',
  ),
  PcmDepartment(
    name: 'Uffici del Ministro per le disabilità',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'disabilita-panetteria',
  ),
  PcmDepartment(
    name: 'Uffici del Ministro per le riforme istituzionali e la semplificazione normativa',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'riforme-istituzionali-largo-chigi',
  ),
  PcmDepartment(
    name: 'Uffici del Ministro per lo sport e i giovani',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'sport-sardegna',
  ),
  PcmDepartment(
    name: 'Uffici del Sottosegretario al coordinamento del CIPES',
    group: PcmDepartmentGroup.ufficiPolitici,
  ),
  PcmDepartment(
    name: "Uffici del Sottosegretario all'attuazione del Programma di Governo",
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'programma-governo-mercede-96',
  ),
  PcmDepartment(
    name: "Uffici del Sottosegretario all'informazione e l'editoria",
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'die-mercede-9',
  ),
  PcmDepartment(
    name: "Uffici del Sottosegretario all'innovazione tecnologica e transizione digitale",
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'dtd-brazza',
  ),
  PcmDepartment(
    name: 'Uffici del Sottosegretario alla Sicurezza della Repubblica',
    group: PcmDepartmentGroup.ufficiPolitici,
  ),
  PcmDepartment(
    name: 'Uffici del Sottosegretario per i Rapporti con il Parlamento',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'rapporti-parlamento-largo-chigi',
  ),
  PcmDepartment(
    name: 'Uffici del Sottosegretario per le politiche per il Sud',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'coesione-sud-sicilia',
  ),
  PcmDepartment(
    name: 'Uffici del Vice Presidente del Consiglio',
    group: PcmDepartmentGroup.ufficiPolitici,
  ),
  PcmDepartment(
    name: 'Ufficio del Consigliere diplomatico',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'dagl-palazzo-chigi',
  ),
  PcmDepartment(
    name: 'Ufficio del Consigliere militare',
    group: PcmDepartmentGroup.ufficiPolitici,
  ),
  PcmDepartment(
    name: 'Ufficio del Presidente del Consiglio',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'dagl-palazzo-chigi',
  ),
  PcmDepartment(
    name: 'Ufficio stampa e relazioni con i media',
    group: PcmDepartmentGroup.ufficiPolitici,
    primarySedeId: 'dagl-palazzo-chigi',
  ),
];

String? pcmDepartmentPrimarySedeId(String departmentName) {
  try {
    return kPcmDepartments
        .firstWhere((d) => d.name == departmentName)
        .primarySedeId;
  } catch (_) {
    return null;
  }
}

/// Returns [all] offices with the department's primary sede sorted first.
List<PcmOfficeOption> sortedOfficesForDepartment(
  String? departmentName,
  List<PcmOfficeOption> all,
) {
  if (departmentName == null || departmentName.isEmpty) return all;
  final primaryId = pcmDepartmentPrimarySedeId(departmentName);
  if (primaryId == null) return all;
  return [
    ...all.where((o) => o.id == primaryId),
    ...all.where((o) => o.id != primaryId),
  ];
}
