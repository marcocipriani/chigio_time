import 'package:flutter/foundation.dart';

const _allowedNotificationRoutes = {
  '/dashboard',
  '/notifications',
  '/social',
  '/stats',
  '/salary',
};

const _notificationTypeRoutes = {
  'exit_reminder': '/dashboard',
  'morning_colleagues': '/social',
  'coffee_invite': '/notifications',
  'coffee_accepted': '/notifications',
  'colleague_added': '/notifications',
  'weekly_recap': '/stats',
  'overtime_threshold': '/stats',
  'payday': '/salary',
  'test': '/notifications',
};

String notificationRoute(Map<String, dynamic> data) {
  final route = data['route'];
  if (_allowedNotificationRoutes.contains(route)) return route as String;
  return _notificationTypeRoutes[data['type']] ?? '/notifications';
}

bool supportsFcm(TargetPlatform platform, {required bool isWeb}) {
  if (isWeb) return true;
  return switch (platform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => false,
  };
}
