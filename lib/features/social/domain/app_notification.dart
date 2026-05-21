class AppNotification {
  final String id;
  final String type; // 'coffee_invite' | 'coffee_accepted'
  final String fromUid;
  final String fromName;
  final DateTime sentAt;
  final String status; // 'pending' | 'accepted' | 'declined' | 'maybe' | 'info'
  final String?
  responseType; // for coffee_accepted: 'accepted' | 'declined' | 'maybe' | 'arriving'
  final String? message; // optional text from the responder
  final bool read;
  final String? scheduledAt; // 'HH:MM' for scheduled coffee invites
  final int? etaMinutes; // ETA in minutes for 'arriving' responses

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
  });

  bool get isPending => status == 'pending';

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) =>
      AppNotification(
        id: id,
        type: m['type'] as String? ?? 'coffee_invite',
        fromUid: m['fromUid'] as String? ?? '',
        fromName: m['fromName'] as String? ?? 'Collega',
        sentAt: m['sentAt'] as DateTime? ?? DateTime.now(),
        status: m['status'] as String? ?? 'pending',
        responseType: m['responseType'] as String?,
        message: m['message'] as String?,
        read: m['read'] as bool? ?? false,
        scheduledAt: m['scheduledAt'] as String?,
        etaMinutes: m['etaMinutes'] as int?,
      );
}
