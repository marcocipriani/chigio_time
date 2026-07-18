import 'package:chigio_time/features/social/domain/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('automatica conserva copy route ed esito', () {
    final n = AppNotification.fromMap('n1', {
      'type': 'weekly_recap',
      'title': 'Recap',
      'body': 'Lavorato 38h00',
      'route': '/stats',
      'pushStatus': 'sent',
      'sentAt': DateTime(2026, 7, 17),
      'status': 'info',
      'read': false,
    });

    expect(n.title, 'Recap');
    expect(n.body, 'Lavorato 38h00');
    expect(n.route, '/stats');
    expect(n.pushStatus, 'sent');
    expect(n.isPending, isFalse);
  });

  test('solo coffee_invite pending mostra azioni', () {
    final invite = AppNotification.fromMap('n2', {
      'type': 'coffee_invite',
      'sentAt': DateTime(2026, 7, 17),
      'status': 'pending',
      'read': false,
    });
    final automatic = AppNotification.fromMap('n3', {
      'type': 'weekly_recap',
      'sentAt': DateTime(2026, 7, 17),
      'status': 'pending',
      'read': false,
    });

    expect(invite.isPending, isTrue);
    expect(automatic.isPending, isFalse);
  });
}
