import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : '';
}

Map<String, String> _targetBuildSettings(String project, String targetName) {
  final configurationList = RegExp(
    'Build configuration list for PBXNativeTarget "${RegExp.escape(targetName)}"'
    r' \*/ = \{.*?buildConfigurations = \((.*?)\);',
    dotAll: true,
  ).firstMatch(project);
  expect(configurationList, isNotNull, reason: 'target $targetName not found');

  final configurations = <String, String>{};
  final entries = RegExp(
    r'([A-F0-9]+) /\* (Debug|Profile|Release) \*/',
  ).allMatches(configurationList!.group(1)!);
  for (final entry in entries) {
    final id = entry.group(1)!;
    final name = entry.group(2)!;
    final block = RegExp(
      '$id /\\* $name \\*/ = \\{.*?buildSettings = \\{(.*?)\\n\\t\\t\\t\\};',
      dotAll: true,
    ).firstMatch(project);
    expect(block, isNotNull, reason: '$targetName $name settings not found');
    configurations[name] = block!.group(1)!;
  }
  return configurations;
}

String? _plistString(String plist, String key) => RegExp(
  '<key>${RegExp.escape(key)}</key>\\s*<string>([^<]+)</string>',
).firstMatch(plist)?.group(1);

void main() {
  test('Android crea e seleziona il channel push solo da API 26', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    final activity = _read(
      'android/app/src/main/kotlin/it/marcocipriani/chigio_time/MainActivity.kt',
    );

    expect(
      manifest,
      contains(
        'android:name="com.google.firebase.messaging.'
        'default_notification_channel_id"',
      ),
    );
    expect(manifest, contains('android:value="chigio_notifications"'));
    expect(activity, contains('NotificationChannel('));
    expect(activity, contains('"chigio_notifications"'));
    expect(activity, contains('"Notifiche Chigio Time"'));
    expect(activity, contains('"Promemoria e aggiornamenti di Chigio Time"'));
    expect(activity, contains('NotificationManager.IMPORTANCE_HIGH'));
    expect(
      activity,
      contains('Build.VERSION.SDK_INT >= Build.VERSION_CODES.O'),
    );
    expect(activity, contains('createNotificationChannel(channel)'));
  });

  test('iOS abilita background push e firma Runner in ogni configurazione', () {
    final info = _read('ios/Runner/Info.plist');
    final debugEntitlements = _read('ios/Runner/DebugProfile.entitlements');
    final releaseEntitlements = _read('ios/Runner/Release.entitlements');
    final project = _read('ios/Runner.xcodeproj/project.pbxproj');

    expect(info, contains('<string>location</string>'));
    expect(info, contains('<string>fetch</string>'));
    expect(info, contains('<string>remote-notification</string>'));
    expect(_plistString(debugEntitlements, 'aps-environment'), 'development');
    expect(_plistString(releaseEntitlements, 'aps-environment'), 'production');

    final runner = _targetBuildSettings(project, 'Runner');
    expect(runner.keys, unorderedEquals(['Debug', 'Profile', 'Release']));
    expect(
      runner['Debug'],
      contains('CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements;'),
    );
    expect(
      runner['Profile'],
      contains('CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements;'),
    );
    expect(
      runner['Release'],
      contains('CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements;'),
    );

    final runnerTests = _targetBuildSettings(project, 'RunnerTests');
    expect(
      runnerTests.values,
      everyElement(isNot(contains('CODE_SIGN_ENTITLEMENTS'))),
      reason: 'APS must be attached to the app target, not the test bundle',
    );
  });

  test('macOS abilita APS e rete client in sviluppo e produzione', () {
    final debugEntitlements = _read('macos/Runner/DebugProfile.entitlements');
    final releaseEntitlements = _read('macos/Runner/Release.entitlements');
    final project = _read('macos/Runner.xcodeproj/project.pbxproj');

    expect(
      _plistString(debugEntitlements, 'com.apple.developer.aps-environment'),
      'development',
    );
    expect(
      _plistString(releaseEntitlements, 'com.apple.developer.aps-environment'),
      'production',
    );
    for (final entitlements in [debugEntitlements, releaseEntitlements]) {
      expect(
        entitlements,
        contains('<key>com.apple.security.network.client</key>'),
      );
      expect(
        entitlements,
        matches(
          RegExp(
            r'<key>com\.apple\.security\.network\.client</key>\s*<true\s*/>',
          ),
        ),
      );
    }

    final runner = _targetBuildSettings(project, 'Runner');
    expect(runner.keys, unorderedEquals(['Debug', 'Profile', 'Release']));
    expect(
      runner['Debug'],
      contains('CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements;'),
    );
    expect(
      runner['Profile'],
      contains('CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements;'),
    );
    expect(
      runner['Release'],
      contains('CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements;'),
    );
  });

  test('Web gestisce click allowlisted sul dominio corrente', () {
    final serviceWorker = _read('web/firebase-messaging-sw.js');
    final clickHandler = serviceWorker.indexOf(
      "addEventListener('notificationclick'",
    );
    final firebaseImports = serviceWorker.indexOf('importScripts(');

    expect(clickHandler, greaterThanOrEqualTo(0));
    expect(clickHandler, lessThan(firebaseImports));
    for (final route in [
      '/dashboard',
      '/notifications',
      '/social',
      '/stats',
      '/salary',
    ]) {
      expect(serviceWorker, contains("'$route'"));
    }
    expect(serviceWorker, contains('ALLOWED_NOTIFICATION_ROUTES.has(route)'));
    expect(
      serviceWorker,
      contains('notificationData.FCM_MSG?.data?.route'),
      reason: 'Firebase-generated notification data remains routable',
    );
    expect(serviceWorker, contains('event.stopImmediatePropagation()'));
    expect(serviceWorker, contains('self.location.origin'));
    expect(
      serviceWorker,
      contains('clientUrl.origin !== self.location.origin'),
    );
    expect(serviceWorker, contains('clients.matchAll('));
    expect(serviceWorker, contains('client.navigate(targetUrl.href)'));
    expect(serviceWorker, contains('client.focus()'));
    expect(serviceWorker, contains('clients.openWindow(targetUrl.href)'));
    expect(serviceWorker, contains('messaging.onBackgroundMessage'));
    expect(serviceWorker, isNot(contains('chigio-time-pcm.web.app')));
  });

  test('Web non mostra due volte i payload notification di Firebase', () {
    final result = Process.runSync('node', [
      'test/platform/firebase_messaging_sw_test.js',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
