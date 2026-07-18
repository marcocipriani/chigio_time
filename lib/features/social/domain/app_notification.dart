class AppNotification {
  final String id;
  final String type; // 'coffee_invite' | 'coffee_accepted'
  final String fromUid;
  final String fromName;
  final DateTime sentAt;
  // 'pending' | 'accepted' | 'declined' | 'maybe' | 'arriving' | 'info'
  final String status;
  final String?
  responseType; // for coffee_accepted: 'accepted' | 'declined' | 'maybe' | 'arriving'
  final String? message; // optional text from the responder
  final bool read;
  final String? scheduledAt; // 'HH:MM' for scheduled coffee invites
  final int? etaMinutes; // ETA in minutes for 'arriving' responses
  final String? title;
  final String? body;
  final String? route;
  final String? pushStatus;

  const AppNotification({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.fromName,
    required this.sentAt,
    required this.status,
    this.responseType,
    this.message,
    required this.read,
    this.scheduledAt,
    this.etaMinutes,
    this.title,
    this.body,
    this.route,
    this.pushStatus,
  });

  bool get isPending => type == 'coffee_invite' && status == 'pending';

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) {
    String stringOr(String key, String fallback) {
      final value = m[key];
      return value is String ? value : fallback;
    }

    String? optionalString(String key) {
      final value = m[key];
      return value is String ? value : null;
    }

    final rawEta = m['etaMinutes'];
    final etaMinutes = rawEta is num && rawEta.isFinite ? rawEta.toInt() : null;
    final rawSentAt = m['sentAt'];

    return AppNotification(
      id: id,
      type: stringOr('type', 'unknown'),
      fromUid: stringOr('fromUid', ''),
      fromName: stringOr('fromName', 'Collega'),
      sentAt: rawSentAt is DateTime ? rawSentAt : DateTime.now(),
      status: stringOr('status', 'info'),
      responseType: optionalString('responseType'),
      message: optionalString('message'),
      read: m['read'] is bool ? m['read'] as bool : false,
      scheduledAt: optionalString('scheduledAt'),
      etaMinutes: etaMinutes,
      title: optionalString('title'),
      body: optionalString('body'),
      route: optionalString('route'),
      pushStatus: optionalString('pushStatus'),
    );
  }
}
