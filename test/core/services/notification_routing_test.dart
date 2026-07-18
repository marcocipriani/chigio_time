import 'package:chigio_time/core/services/notification_routing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route esplicita ammessa e fallback per type', () {
    expect(notificationRoute({'route': '/salary'}), '/salary');
    expect(notificationRoute({'type': 'exit_reminder'}), '/dashboard');
    expect(notificationRoute({'type': 'morning_colleagues'}), '/social');
    expect(notificationRoute({'type': 'weekly_recap'}), '/stats');
    expect(notificationRoute({'type': 'overtime_threshold'}), '/stats');
    expect(notificationRoute({'type': 'payday'}), '/salary');
    expect(notificationRoute({'route': 'https://evil.test'}), '/notifications');
    expect(notificationRoute({'type': 'unknown'}), '/notifications');
  });

  test('FCM supportato solo web Android iOS macOS', () {
    expect(supportsFcm(TargetPlatform.android, isWeb: false), isTrue);
    expect(supportsFcm(TargetPlatform.iOS, isWeb: false), isTrue);
    expect(supportsFcm(TargetPlatform.macOS, isWeb: false), isTrue);
    expect(supportsFcm(TargetPlatform.windows, isWeb: false), isFalse);
    expect(supportsFcm(TargetPlatform.linux, isWeb: false), isFalse);
    expect(supportsFcm(TargetPlatform.linux, isWeb: true), isTrue);
  });

  test('tap non apre una seconda copia della route corrente', () {
    expect(
      notificationTapRoute({
        'type': 'test',
        'route': '/notifications',
      }, currentPath: '/notifications'),
      isNull,
    );
    expect(
      notificationTapRoute({
        'type': 'weekly_recap',
        'route': '/stats',
      }, currentPath: '/notifications'),
      '/stats',
    );
    expect(
      notificationTapRoute({
        'route': 'https://evil.test',
      }, currentPath: '/notifications'),
      isNull,
    );
  });
}
