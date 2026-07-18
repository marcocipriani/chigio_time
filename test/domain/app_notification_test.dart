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

  test('payload legacy malformato non interrompe il parsing inbox', () {
    final before = DateTime.now();
    final notification = AppNotification.fromMap('legacy', {
      'type': 42,
      'fromUid': false,
      'fromName': <String>['nome'],
      'sentAt': 'ieri',
      'status': <String, Object>{},
      'responseType': 7,
      'message': true,
      'read': 'false',
      'scheduledAt': 900,
      'etaMinutes': 'subito',
      'title': <String, String>{},
      'body': 99,
      'route': false,
      'pushStatus': <String>[],
    });

    expect(notification.type, 'unknown');
    expect(notification.fromUid, '');
    expect(notification.fromName, 'Collega');
    expect(notification.sentAt.isBefore(before), isFalse);
    expect(notification.status, 'info');
    expect(notification.isPending, isFalse);
    expect(notification.responseType, isNull);
    expect(notification.message, isNull);
    expect(notification.read, isFalse);
    expect(notification.scheduledAt, isNull);
    expect(notification.etaMinutes, isNull);
    expect(notification.title, isNull);
    expect(notification.body, isNull);
    expect(notification.route, isNull);
    expect(notification.pushStatus, isNull);
  });
}
