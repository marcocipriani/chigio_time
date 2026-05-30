import '../constants/chigio_quotes.dart';

/// The page the user is currently on.
enum ChigioPage { dashboard, timesheet, social, profile, stats, other }

/// Timer status context for dashboard.
enum ChigioShiftState { notStarted, working, paused, completed, abandoned }

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

abstract final class ChigioPhraseEngine {
  /// Returns a contextual phrase for Chigio to display.
  ///
  /// [gender] values: 'M' (maschile), 'F' (femminile), 'N' (neutro, default).
  /// [department] is the user's department name from Firestore; empty = generic phrases.
  /// [isPayDay] when true and on dashboard, injects the 23rd-of-month pay day pool.
  static ChigioData resolve({
    required ChigioPage page,
    required String firstName,
    ChigioShiftState shiftState = ChigioShiftState.notStarted,
    String gender = 'N',
    String department = '',
    bool isPayDay = false,
    int? seed,
  }) {
    final now = DateTime.now();
    final effectiveSeed = seed ?? (now.hour * 12 + now.minute ~/ 5);

    if (isPayDay && page == ChigioPage.dashboard) {
      return _buildQuote(
        _pick(ChigioQuotes.payday, effectiveSeed),
        firstName,
        gender,
        department,
      );
    }

    return _buildQuote(
      _pick(_selectPool(page, shiftState, now.hour), effectiveSeed),
      firstName,
      gender,
      department,
    );
  }

  static ChigioQuote _pick(List<ChigioQuote> pool, int seed) {
    return pool[seed % pool.length];
  }

  static ChigioData _buildQuote(
    ChigioQuote quote,
    String firstName,
    String gender,
    String department,
  ) {
    final (raw, image, label) = quote;
    var phrase = raw
        .replaceAll('{n}', firstName)
        .replaceAll('{dep}', department.isNotEmpty ? department : 'ufficio');
    phrase = _applyGender(phrase, gender);
    final resolvedLabel = _applyGender(label, gender);
    return ChigioData(phrase: phrase, image: image, label: resolvedLabel);
  }

  // {o|a} -> 'o' (M) / 'a' (F) / 'ə' (A=altro/schwa) / 'o/a' (N=neutro)
  static String _applyGender(String phrase, String gender) {
    return phrase.replaceAllMapped(
      RegExp(r'\{([^|{}]+)\|([^|{}]+)\}'),
      (m) => switch (gender) {
        'M' => m.group(1)!,
        'F' => m.group(2)!,
        'A' => 'ə',
        _ => '${m.group(1)}/${m.group(2)}',
      },
    );
  }

  static List<ChigioQuote> _selectPool(
    ChigioPage page,
    ChigioShiftState shiftState,
    int hour,
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
        if (hour < 13) return ChigioQuotes.morningWorking;
        if (hour < 18) return ChigioQuotes.afternoonWorking;
        return ChigioQuotes.eveningWorking;
      case ChigioShiftState.notStarted:
        if (hour < 13) return ChigioQuotes.morningNotStarted;
        if (hour < 18) return ChigioQuotes.afternoonNotStarted;
        return ChigioQuotes.eveningNotStarted;
    }
  }
}
