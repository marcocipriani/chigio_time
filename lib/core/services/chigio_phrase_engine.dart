import '../constants/chigio_quotes.dart';

/// The page the user is currently on.
enum ChigioPage { dashboard, timesheet, social, profile, stats, other }

/// Timer status context for dashboard.
enum ChigioShiftState { notStarted, working, paused, completed, abandoned }

enum ChigioDayType { presence, remote, leave, holiday, unknown }

enum _ChigioDayPart { morning, afternoon, evening }

/// A resolved phrase + avatar for the current context.
class ChigioData {
  final String phrase; // personalized phrase (already substituted)
  final String image; // asset path for Chigio avatar
  final String label;

  const ChigioData({
    required this.phrase,
    required this.image,
    required this.label,
  });
}

class ChigioContext {
  final ChigioPage page;
  final String firstName;
  final ChigioShiftState shiftState;
  final String gender;
  final String department;
  final String site;
  final ChigioDayType dayType;
  final int? workedMins;
  final int? remainingMins;
  final int? standardWorkMins;
  final int? mealVoucherThresholdMins;
  final bool mealVoucherJustEarned;
  final bool isPayDay;
  final int? seed;
  final DateTime? now;

  const ChigioContext({
    required this.page,
    required this.firstName,
    this.shiftState = ChigioShiftState.notStarted,
    this.gender = 'A',
    this.department = '',
    this.site = '',
    this.dayType = ChigioDayType.unknown,
    this.workedMins,
    this.remainingMins,
    this.standardWorkMins,
    this.mealVoucherThresholdMins,
    this.mealVoucherJustEarned = false,
    this.isPayDay = false,
    this.seed,
    this.now,
  });
}

abstract final class ChigioPhraseEngine {
  /// Returns a contextual phrase for Chigio to display.
  ///
  /// [gender] values: 'M' (maschile), 'F' (femminile), 'A' (altrə, default).
  /// [department] is the user's department name from Firestore; empty = generic phrases.
  /// [isPayDay] when true and on dashboard, injects the 23rd-of-month pay day pool.
  /// [now] is injectable only to make time-of-day selection testable.
  static ChigioData resolve({
    required ChigioPage page,
    required String firstName,
    ChigioShiftState shiftState = ChigioShiftState.notStarted,
    String gender = 'A',
    String department = '',
    bool isPayDay = false,
    int? seed,
    DateTime? now,
  }) {
    return resolveContext(
      ChigioContext(
        page: page,
        firstName: firstName,
        shiftState: shiftState,
        gender: gender,
        department: department,
        isPayDay: isPayDay,
        seed: seed,
        now: now,
      ),
    );
  }

  static ChigioData resolveContext(ChigioContext context) {
    final currentTime = context.now ?? DateTime.now();
    final effectiveSeed =
        context.seed ?? (currentTime.hour * 12 + currentTime.minute ~/ 5);
    final dayPart = _dayPartForHour(currentTime.hour);
    final compactDepartment = _compactDepartment(context.department);
    final compactSite = _compactSite(context.site);

    if (context.mealVoucherJustEarned) {
      return _buildQuote(
        _pick(ChigioQuotes.mealVoucher, effectiveSeed),
        context,
        compactDepartment,
        compactSite,
        currentTime,
      );
    }

    if (context.isPayDay && context.page == ChigioPage.dashboard) {
      return _buildQuote(
        _pick(ChigioQuotes.payday, effectiveSeed),
        context,
        compactDepartment,
        compactSite,
        currentTime,
      );
    }

    final quotePool = _selectContextualPool(
      context,
      compactDepartment: compactDepartment,
      compactSite: compactSite,
      seed: effectiveSeed,
      dayPart: dayPart,
    );

    return _buildQuote(
      _pick(quotePool, effectiveSeed),
      context,
      compactDepartment,
      compactSite,
      currentTime,
    );
  }

  static ChigioQuote _pick(List<ChigioQuote> pool, int seed) {
    return pool[seed % pool.length];
  }

  static ChigioData _buildQuote(
    ChigioQuote quote,
    ChigioContext context,
    String department,
    String site,
    DateTime currentTime,
  ) {
    final (raw, image, label) = quote;
    var phrase = raw
        .replaceAll('{n}', context.firstName)
        .replaceAll('{dep}', department.isNotEmpty ? department : 'ufficio')
        .replaceAll('{site}', site.isNotEmpty ? site : 'sede')
        .replaceAll('{remaining}', _formatMinutes(context.remainingMins))
        .replaceAll('{worked}', _formatMinutes(context.workedMins))
        .replaceAll('{weekday}', _weekdayName(currentTime.weekday));
    phrase = _applyGender(phrase, context.gender);
    final resolvedLabel = _applyGender(label, context.gender);
    return ChigioData(phrase: phrase, image: image, label: resolvedLabel);
  }

  // Supports both suffix markers (`{o|a}`) and full alternatives:
  // `{pronto|pronta|prontə}` = M/F/A. Solo 3 generi: il Neutro ('N') è stato
  // rimosso il 2026-06-11; eventuali valori legacy 'N' ripiegano su 'A' (schwa).
  static String _applyGender(String phrase, String gender) {
    return phrase.replaceAllMapped(RegExp(r'\{([^{}|]+(?:\|[^{}|]+)+)\}'), (m) {
      final parts = m.group(1)!.split('|');
      final normalizedGender = gender.trim().toUpperCase();
      return switch (normalizedGender) {
        'M' => parts.first,
        'F' => parts.length > 1 ? parts[1] : parts.first,
        // 'A' (altrə) + legacy 'N' + default → schwa (3° alternante).
        _ => parts.length > 2 ? parts[2] : _schwaFallback(parts.first),
      };
    });
  }

  static List<ChigioQuote> _selectContextualPool(
    ChigioContext context, {
    required String compactDepartment,
    required String compactSite,
    required int seed,
    required _ChigioDayPart dayPart,
  }) {
    if (_shouldUseProgressQuote(context)) {
      return _selectProgressPool(context);
    }

    if (_shouldUseDayTypeQuote(context, seed)) {
      return _selectDayTypePool(context.dayType);
    }

    if (_shouldUseMotivationalQuote(context, seed)) {
      return ChigioQuotes.motivational;
    }

    if (_shouldUseSiteQuote(compactSite, seed)) {
      return _selectSitePool(dayPart);
    }

    if (_shouldUseDepartmentQuote(
      page: context.page,
      shiftState: context.shiftState,
      department: compactDepartment,
      seed: seed,
    )) {
      return _selectDepartmentPool(dayPart);
    }

    if (_shouldUseWeekdayQuote(context, seed)) {
      return _selectWeekdayPool(context.now ?? DateTime.now());
    }

    return _selectPool(context.page, context.shiftState, dayPart);
  }

  static bool _shouldUseProgressQuote(ChigioContext context) {
    if (context.page != ChigioPage.dashboard) return false;
    if (context.shiftState != ChigioShiftState.working) return false;

    final remaining = context.remainingMins;
    final worked = context.workedMins;
    final standard = context.standardWorkMins;

    if (remaining != null && remaining <= 60) return true;
    if (worked != null && standard != null && worked >= standard) return true;
    return false;
  }

  static List<ChigioQuote> _selectProgressPool(ChigioContext context) {
    final remaining = context.remainingMins;
    final worked = context.workedMins;
    final standard = context.standardWorkMins;

    if (worked != null && standard != null && worked >= standard) {
      return ChigioQuotes.overtime;
    }
    if (remaining != null && remaining > 0 && remaining <= 15) {
      return ChigioQuotes.exitSoon;
    }
    if (remaining != null && remaining > 15 && remaining <= 60) {
      return ChigioQuotes.finalHour;
    }
    return ChigioQuotes.motivational;
  }

  static bool _shouldUseDayTypeQuote(ChigioContext context, int seed) {
    if (context.dayType == ChigioDayType.unknown ||
        context.dayType == ChigioDayType.presence) {
      return false;
    }
    if (context.shiftState == ChigioShiftState.working ||
        context.shiftState == ChigioShiftState.paused) {
      return false;
    }
    return seed % 3 == 1;
  }

  static List<ChigioQuote> _selectDayTypePool(ChigioDayType dayType) {
    return switch (dayType) {
      ChigioDayType.remote => ChigioQuotes.remoteDay,
      ChigioDayType.leave => ChigioQuotes.leaveDay,
      ChigioDayType.holiday => ChigioQuotes.holidayDay,
      ChigioDayType.presence ||
      ChigioDayType.unknown => ChigioQuotes.motivational,
    };
  }

  static bool _shouldUseMotivationalQuote(ChigioContext context, int seed) {
    if (context.shiftState == ChigioShiftState.abandoned) return false;
    return seed % 7 == 2;
  }

  static bool _shouldUseSiteQuote(String site, int seed) {
    if (site.isEmpty) return false;
    return seed % 5 == 3;
  }

  static bool _shouldUseWeekdayQuote(ChigioContext context, int seed) {
    final currentTime = context.now ?? DateTime.now();
    if (currentTime.weekday != DateTime.monday &&
        currentTime.weekday != DateTime.friday) {
      return false;
    }
    return seed % 6 == 5;
  }

  static String _schwaFallback(String value) {
    if (value.isEmpty) return value;
    if (value.length == 1) return 'ə';
    return '${value.substring(0, value.length - 1)}ə';
  }

  static bool _shouldUseDepartmentQuote({
    required ChigioPage page,
    required ChigioShiftState shiftState,
    required String department,
    required int seed,
  }) {
    if (department.isEmpty) return false;
    if (page == ChigioPage.dashboard) {
      switch (shiftState) {
        case ChigioShiftState.paused:
        case ChigioShiftState.completed:
        case ChigioShiftState.abandoned:
          return false;
        case ChigioShiftState.notStarted:
        case ChigioShiftState.working:
          break;
      }
    }
    return seed % 4 == 0;
  }

  static _ChigioDayPart _dayPartForHour(int hour) {
    if (hour >= 5 && hour < 13) return _ChigioDayPart.morning;
    if (hour >= 13 && hour < 18) return _ChigioDayPart.afternoon;
    return _ChigioDayPart.evening;
  }

  static List<ChigioQuote> _selectDepartmentPool(_ChigioDayPart dayPart) {
    return switch (dayPart) {
      _ChigioDayPart.morning => ChigioQuotes.departmentMorning,
      _ChigioDayPart.afternoon => ChigioQuotes.departmentAfternoon,
      _ChigioDayPart.evening => ChigioQuotes.departmentEvening,
    };
  }

  static List<ChigioQuote> _selectSitePool(_ChigioDayPart dayPart) {
    return switch (dayPart) {
      _ChigioDayPart.morning => ChigioQuotes.siteMorning,
      _ChigioDayPart.afternoon => ChigioQuotes.siteAfternoon,
      _ChigioDayPart.evening => ChigioQuotes.siteEvening,
    };
  }

  static List<ChigioQuote> _selectWeekdayPool(DateTime currentTime) {
    return switch (currentTime.weekday) {
      DateTime.monday => ChigioQuotes.monday,
      DateTime.friday => ChigioQuotes.friday,
      _ => ChigioQuotes.motivational,
    };
  }

  static List<ChigioQuote> _selectPool(
    ChigioPage page,
    ChigioShiftState shiftState,
    _ChigioDayPart dayPart,
  ) {
    switch (page) {
      case ChigioPage.timesheet:
        return ChigioQuotes.timesheet;
      case ChigioPage.social:
        return ChigioQuotes.social;
      case ChigioPage.profile:
        return ChigioQuotes.profile;
      case ChigioPage.stats:
        return ChigioQuotes.stats;
      case ChigioPage.dashboard:
      case ChigioPage.other:
        break;
    }

    switch (shiftState) {
      case ChigioShiftState.paused:
        return ChigioQuotes.paused;
      case ChigioShiftState.completed:
        return ChigioQuotes.completed;
      case ChigioShiftState.abandoned:
        return ChigioQuotes.abandoned;
      case ChigioShiftState.working:
        return switch (dayPart) {
          _ChigioDayPart.morning => ChigioQuotes.morningWorking,
          _ChigioDayPart.afternoon => ChigioQuotes.afternoonWorking,
          _ChigioDayPart.evening => ChigioQuotes.eveningWorking,
        };
      case ChigioShiftState.notStarted:
        return switch (dayPart) {
          _ChigioDayPart.morning => ChigioQuotes.morningNotStarted,
          _ChigioDayPart.afternoon => ChigioQuotes.afternoonNotStarted,
          _ChigioDayPart.evening => ChigioQuotes.eveningNotStarted,
        };
    }
  }

  static String _compactDepartment(String department) {
    final clean = department.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return '';

    final lower = clean.toLowerCase();
    const aliases = <({String needle, String label})>[
      (needle: 'funzione pubblica', label: 'Funzione pubblica'),
      (needle: 'casa italia', label: 'Casa Italia'),
      (needle: 'droga', label: 'Antidroga'),
      (needle: 'dipendenze', label: 'Antidroga'),
      (needle: 'politiche giovanili', label: 'Giovani e SCU'),
      (needle: 'servizio civile', label: 'Giovani e SCU'),
      (needle: 'trasformazione digitale', label: 'Trasformazione digitale'),
      (needle: 'affari europei', label: 'Affari europei'),
      (needle: 'pari opportun', label: 'Pari opportunità'),
      (needle: 'riforme istituzionali', label: 'Riforme istituzionali'),
      (needle: 'rapporti con il parlamento', label: 'Rapporti Parlamento'),
      (needle: 'pnrr', label: 'PNRR'),
      (needle: 'coordinamento amministrativo', label: 'Coord. amministrativo'),
      (needle: 'informazione', label: 'Informazione editoria'),
      (needle: 'editoria', label: 'Informazione editoria'),
      (needle: 'programma di governo', label: 'Programma Governo'),
      (needle: 'programmazione', label: 'Politica economica'),
      (needle: 'politica economica', label: 'Politica economica'),
      (needle: 'personale', label: 'Personale'),
      (needle: 'servizi strumentali', label: 'Servizi strumentali'),
      (needle: 'bilancio', label: 'Bilancio e riscontro'),
      (needle: 'controllo interno', label: 'Controllo interno'),
      (needle: 'affari giuridici', label: 'Affari legislativi'),
      (needle: 'legislativi', label: 'Affari legislativi'),
      (needle: 'cerimoniale', label: 'Cerimoniale'),
      (needle: 'consiglio dei ministri', label: 'Segreteria CdM'),
      (needle: 'segretario generale', label: 'Segretario generale'),
      (needle: 'disabilit', label: 'Disabilità'),
      (needle: 'scuola nazionale', label: 'SNA'),
      (needle: 'affari regionali', label: 'Affari regionali'),
      (needle: 'conferenza stato', label: 'Conferenza Stato-città'),
      (needle: 'politiche della famiglia', label: 'Famiglia'),
      (needle: 'spaziali', label: 'Politiche spaziali'),
      (needle: 'sport', label: 'Sport'),
      (needle: 'coesione', label: 'Coesione e Sud'),
      (needle: 'zes', label: 'ZES'),
      (needle: 'protezione civile', label: 'Protezione civile'),
    ];

    for (final alias in aliases) {
      if (lower.contains(alias.needle)) return alias.label;
    }

    final withoutPrefix = clean
        .replaceFirst(
          RegExp(
            r'^(Dipartimento|Ufficio|Struttura di missione)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r"^(per|della|del|degli|delle|di|l'|gli|le|i)\s+",
            caseSensitive: false,
          ),
          '',
        );
    return _truncateDepartment(withoutPrefix);
  }

  static String _truncateDepartment(String value) {
    const maxLength = 24;
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= maxLength) return clean;

    final words = clean.split(' ');
    var result = '';
    for (final word in words) {
      final candidate = result.isEmpty ? word : '$result $word';
      if (candidate.length > maxLength) break;
      result = candidate;
    }
    if (result.isEmpty) return '${clean.substring(0, maxLength - 1)}…';
    return result;
  }

  static String _compactSite(String site) {
    final clean = site.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return '';

    final lower = clean.toLowerCase();
    const aliases = <({String needle, String label})>[
      (needle: 'palazzo chigi / via della mercede, 96', label: 'Chigi/Mercede'),
      (needle: 'palazzo chigi', label: 'Palazzo Chigi'),
      (needle: 'mercede, 96', label: 'Mercede 96'),
      (needle: 'mercede 96', label: 'Mercede 96'),
      (needle: 'mercede, 9', label: 'Mercede 9'),
      (needle: 'mercede 9', label: 'Mercede 9'),
      (needle: 'ferratella', label: 'Ferratella'),
      (needle: 'largo pietro di brazz', label: 'Largo Brazzà'),
      (needle: 'largo brazz', label: 'Largo Brazzà'),
      (needle: 'largo chigi', label: 'Largo Chigi'),
      (needle: 'panetteria', label: 'Panetteria'),
      (needle: 'robinant', label: 'Robilant'),
      (needle: 'caserta', label: 'Caserta'),
      (needle: 'stamperia', label: 'Stamperia'),
      (needle: 'iv novembre', label: 'IV Novembre'),
      (needle: 'molise', label: 'Molise'),
      (needle: 'sardegna', label: 'Sardegna'),
      (needle: 'sicilia', label: 'Sicilia'),
      (needle: 'ulpiano', label: 'Ulpiano'),
      (needle: 'vitorchiano', label: 'Vitorchiano'),
    ];

    for (final alias in aliases) {
      if (lower.contains(alias.needle)) return alias.label;
    }

    final withoutPrefix = clean.replaceFirst(
      RegExp(r'^(Via|Viale|Largo|Piazza)\s+', caseSensitive: false),
      '',
    );
    return _truncateSite(withoutPrefix);
  }

  static String _truncateSite(String value) {
    const maxLength = 18;
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= maxLength) return clean;

    final words = clean.split(' ');
    var result = '';
    for (final word in words) {
      final candidate = result.isEmpty ? word : '$result $word';
      if (candidate.length > maxLength) break;
      result = candidate;
    }
    if (result.isEmpty) return '${clean.substring(0, maxLength - 1)}…';
    return result;
  }

  static String _formatMinutes(int? mins) {
    if (mins == null) return 'pochi minuti';
    final absolute = mins.abs();
    if (absolute < 60) return '$absolute min';
    final hours = absolute ~/ 60;
    final minutes = absolute % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}';
  }

  static String _weekdayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'lunedì',
      DateTime.tuesday => 'martedì',
      DateTime.wednesday => 'mercoledì',
      DateTime.thursday => 'giovedì',
      DateTime.friday => 'venerdì',
      DateTime.saturday => 'sabato',
      DateTime.sunday => 'domenica',
      _ => 'oggi',
    };
  }
}
