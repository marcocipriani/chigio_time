class ColleagueProfile {
  final String uid;
  final String name;
  final String administration;
  final String employmentType;
  final String? phoneNumber;
  final String? dipartimento;
  final String? interno; // internal phone extension
  final String? sede; // office branch / location
  final bool isFavorite;
  final String
  rawStatus; // stored: 'notStarted'|'working'|'paused'|'remote'|'holiday'|'leave'|'completed'
  final String? statusDate; // 'YYYY-MM-DD'
  final bool?
  coffeeAvailable; // true when the colleague has toggled availability
  final String? piano; // floor (piano)
  final String? stanza; // room / office (stanza)
  final String? statusMessage; // daily status text (max 40 chars)

  const ColleagueProfile({
    required this.uid,
    required this.name,
    required this.administration,
    required this.employmentType,
    this.phoneNumber,
    this.dipartimento,
    this.interno,
    this.sede,
    required this.isFavorite,
    required this.rawStatus,
    this.statusDate,
    this.coffeeAvailable,
    this.piano,
    this.stanza,
    this.statusMessage,
  });

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // Status is only valid when statusDate is today; otherwise treat as not started.
  String get effectiveStatus {
    if (statusDate == null || statusDate != _today()) return 'notStarted';
    return rawStatus;
  }

  /// True when the colleague is physically present and available for a coffee break.
  /// Excludes smart-working, holiday, leave, not-started, and completed states.
  bool get canReceiveCoffee =>
      effectiveStatus == 'working' || effectiveStatus == 'paused';

  /// True when the ☕ button should be visible on the colleague card:
  /// - colleague explicitly toggled "disponibile per caffè"
  /// - AND they are physically present (not on remote/holiday/leave)
  bool get showCoffeeButton => (coffeeAvailable == true) && canReceiveCoffee;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
