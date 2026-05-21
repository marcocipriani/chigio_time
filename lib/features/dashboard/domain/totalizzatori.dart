enum TotAlertLevel { info, amber, red }

class TotAlert {
  final String message;
  final TotAlertLevel level;
  const TotAlert(this.message, this.level);
}

class Totalizzatori {
  final String? dipendente;
  final String? matricola;
  final String? ente;
  final String? periodo;
  final String? fetchedAt;

  // FERIE (days)
  final double ferieFruitoMese;
  final double ferieFruitoAnnuo;
  final double ferieSpettanza;
  final double ferieResiduoAnnoCorrente;
  final double ferieResiduoAnnoPrecedente;
  final double ferieResidueTotali;

  // FESTIVITÀ SOPPRESSE (days)
  final double festSoppFruitoAnnuo;
  final double festSoppSpettanza;
  final double festSoppResiduo;

  // STRAORDINARI (minutes)
  final int protrazioniArt9Effettuate;
  final int protrazioniArt9DaRecuperare;
  final int maggiorPresenza;
  final int straordinariLiquidati;
  final int straordinarioAutorizzato;
  final int straordinariLiquidabili;
  final int riposoCompMaturato;
  final int riposoCompResiduo;

  // BANCA ORE (minutes)
  final int bancaOreAcResiduo;
  final int bancaOreApResiduo;
  final int totaleBancaOreFruibile;

  // PERMESSI (minutes)
  final int orePerse;
  final int permessoBreveResiduo;
  final int permMotiviPersonaliResiduo;
  final int visitaSpecialisticaResiduo;

  // BUONI PASTO
  final int buoniPastoMensili;

  // DEBITI (minutes)
  final int oreNonRecuperate;

  const Totalizzatori({
    this.dipendente,
    this.matricola,
    this.ente,
    this.periodo,
    this.fetchedAt,
    required this.ferieFruitoMese,
    required this.ferieFruitoAnnuo,
    required this.ferieSpettanza,
    required this.ferieResiduoAnnoCorrente,
    required this.ferieResiduoAnnoPrecedente,
    required this.ferieResidueTotali,
    required this.festSoppFruitoAnnuo,
    required this.festSoppSpettanza,
    required this.festSoppResiduo,
    required this.protrazioniArt9Effettuate,
    required this.protrazioniArt9DaRecuperare,
    required this.maggiorPresenza,
    required this.straordinariLiquidati,
    required this.straordinarioAutorizzato,
    required this.straordinariLiquidabili,
    required this.riposoCompMaturato,
    required this.riposoCompResiduo,
    required this.bancaOreAcResiduo,
    required this.bancaOreApResiduo,
    required this.totaleBancaOreFruibile,
    required this.orePerse,
    required this.permessoBreveResiduo,
    required this.permMotiviPersonaliResiduo,
    required this.visitaSpecialisticaResiduo,
    required this.buoniPastoMensili,
    required this.oreNonRecuperate,
  });

  static int _toMins(String v) {
    final p = v.split(':');
    if (p.length != 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  factory Totalizzatori.fromJson(Map<String, dynamic> j) => Totalizzatori(
    dipendente: j['dipendente'] as String?,
    matricola: j['matricola'] as String?,
    ente: j['ente'] as String?,
    periodo: j['periodo'] as String?,
    fetchedAt: j['fetched_at'] as String?,
    ferieFruitoMese: (j['ferie_fruito_mese'] as num? ?? 0).toDouble(),
    ferieFruitoAnnuo: (j['ferie_fruito_annuo'] as num? ?? 0).toDouble(),
    ferieSpettanza: (j['ferie_spettanza'] as num? ?? 0).toDouble(),
    ferieResiduoAnnoCorrente: (j['ferie_residuo_anno_corrente'] as num? ?? 0)
        .toDouble(),
    ferieResiduoAnnoPrecedente:
        (j['ferie_residuo_anno_precedente'] as num? ?? 0).toDouble(),
    ferieResidueTotali: (j['ferie_residue_totali'] as num? ?? 0).toDouble(),
    festSoppFruitoAnnuo: (j['fest_sopp_fruito_annuo'] as num? ?? 0).toDouble(),
    festSoppSpettanza: (j['fest_sopp_spettanza'] as num? ?? 0).toDouble(),
    festSoppResiduo: (j['fest_sopp_residuo'] as num? ?? 0).toDouble(),
    protrazioniArt9Effettuate: _toMins(
      j['protrazioni_art9_effettuate'] as String? ?? '00:00',
    ),
    protrazioniArt9DaRecuperare: _toMins(
      j['protrazioni_art9_da_recuperare'] as String? ?? '00:00',
    ),
    maggiorPresenza: _toMins(j['maggior_presenza'] as String? ?? '00:00'),
    straordinariLiquidati: _toMins(
      j['straordinari_liquidati'] as String? ?? '00:00',
    ),
    straordinarioAutorizzato: _toMins(
      j['straordinario_autorizzato'] as String? ?? '00:00',
    ),
    straordinariLiquidabili: _toMins(
      j['straordinari_liquidabili'] as String? ?? '00:00',
    ),
    riposoCompMaturato: _toMins(
      j['riposo_comp_maturato'] as String? ?? '00:00',
    ),
    riposoCompResiduo: _toMins(j['riposo_comp_residuo'] as String? ?? '00:00'),
    bancaOreAcResiduo: _toMins(j['banca_ore_ac_residuo'] as String? ?? '00:00'),
    bancaOreApResiduo: _toMins(j['banca_ore_ap_residuo'] as String? ?? '00:00'),
    totaleBancaOreFruibile: _toMins(
      j['totale_banca_ore_fruibile'] as String? ?? '00:00',
    ),
    orePerse: _toMins(j['ore_perse'] as String? ?? '00:00'),
    permessoBreveResiduo: _toMins(
      j['permesso_breve_residuo'] as String? ?? '00:00',
    ),
    permMotiviPersonaliResiduo: _toMins(
      j['perm_motivi_personali_residuo'] as String? ?? '00:00',
    ),
    visitaSpecialisticaResiduo: _toMins(
      j['visita_specialistica_residuo'] as String? ?? '00:00',
    ),
    buoniPastoMensili: j['buoni_pasto_mensili'] as int? ?? 0,
    oreNonRecuperate: _toMins(j['ore_non_recuperate'] as String? ?? '00:00'),
  );

  List<TotAlert> get activeAlerts {
    final a = <TotAlert>[];
    if (ferieResiduoAnnoPrecedente > 0) {
      a.add(
        TotAlert(
          'Ferie anno precedente da smaltire (${ferieResiduoAnnoPrecedente.round()} gg)',
          TotAlertLevel.amber,
        ),
      );
    }
    if (ferieResidueTotali > 30) {
      a.add(
        TotAlert(
          'Accumulo ferie elevato (${ferieResidueTotali.round()} gg)',
          TotAlertLevel.red,
        ),
      );
    }
    if (maggiorPresenza > 8 * 60) {
      a.add(TotAlert('Maggior presenza da liquidare', TotAlertLevel.amber));
    }
    if ((straordinarioAutorizzato - straordinariLiquidabili) > 0) {
      a.add(TotAlert('Straordinari in sospeso', TotAlertLevel.amber));
    }
    if (oreNonRecuperate > 0) {
      a.add(TotAlert('Ore da recuperare', TotAlertLevel.red));
    }
    return a;
  }

  // Banca ore "healthy" range: at least 1h available, not exceeding 1 full work day.
  static const int bancaOreMinMins = 60;
  static const int bancaOreMaxMins = 8 * 60; // 1 full work day

  // Permesso breve residuo threshold for a green badge: more than 20h remaining.
  static const int permessoBreveGreenThresholdMins = 20 * 60;

  bool get bancaOreIsGreenBadge =>
      totaleBancaOreFruibile >= bancaOreMinMins &&
      totaleBancaOreFruibile <= bancaOreMaxMins;

  bool get permessoBreveIsGreenBadge =>
      permessoBreveResiduo > permessoBreveGreenThresholdMins;
}
