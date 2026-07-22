import 'dart:async';

import 'package:chigio_time/app/bootstrap/app_bootstrap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('uses persistent Firestore cache with the Web multi-tab manager', () {
    final settings = firestoreWebCacheSettings();
    expect(settings.persistenceEnabled, isTrue);
    expect(
      settings.webPersistentTabManager,
      isA<WebPersistentMultipleTabManager>(),
    );
  });

  testWidgets('shows a structural Home skeleton before bootstrap completes', (
    tester,
  ) async {
    final pending = Completer<AppBootstrapData>();
    await tester.pumpWidget(
      ChigioBootstrapApp(
        load: () => pending.future,
        readyBuilder: (_) => const Text('ready'),
      ),
    );

    expect(find.byKey(const Key('bootstrap-home-skeleton')), findsOneWidget);
    expect(find.byKey(const Key('bootstrap-hero-shape')), findsOneWidget);
    expect(find.byKey(const Key('bootstrap-card-shape')), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('ready'), findsNothing);
  });

  testWidgets('replaces the skeleton with the ready app', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChigioBootstrapApp(
        load: () async => AppBootstrapData(
          preferences: prefs,
          themeModeName: 'dark',
          localeCode: 'it',
        ),
        readyBuilder: (_) => const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('ready'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ready'), findsOneWidget);
    expect(find.byKey(const Key('bootstrap-home-skeleton')), findsNothing);
  });

  testWidgets('shows a human error and retries with a new Future', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    Future<AppBootstrapData> load() async {
      attempts++;
      if (attempts == 1) throw StateError('network unavailable');
      return AppBootstrapData(
        preferences: prefs,
        themeModeName: 'system',
        localeCode: 'it',
      );
    }

    await tester.pumpWidget(
      ChigioBootstrapApp(
        load: load,
        readyBuilder: (_) => const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('ready'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Riprova'), findsOneWidget);
    expect(find.textContaining('Connessione assente'), findsOneWidget);

    await tester.tap(find.text('Riprova'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('ready'), findsOneWidget);
  });
}
