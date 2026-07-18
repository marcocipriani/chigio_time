import 'dart:async';

import 'package:chigio_time/core/constants/app_strings.dart';
import 'package:chigio_time/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('invio riuscito blocca chiusure e torna al caller stabile', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final completion = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: _Harness(onSendTest: () => completion.future)),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.sendTestNotification));
    await tester.pump();

    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              AppStrings.sendTestNotification,
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, AppStrings.save),
          )
          .onPressed,
      isNull,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text(AppStrings.notifications), findsOneWidget);
    expect(find.text('navigated'), findsNothing);

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text(AppStrings.notifications), findsOneWidget);

    await tester.drag(find.byType(BottomSheet), const Offset(0, 900));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.notifications), findsOneWidget);

    completion.complete();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notifications), findsNothing);
    expect(find.text('navigated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('errore invio è inline e viene azzerato al retry riuscito', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final error = StateError('network unavailable');
    final retryCompletion = Completer<void>();
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _Harness(
          onSendTest: () {
            attempts++;
            if (attempts == 1) return Future<void>.error(error);
            return retryCompletion.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.sendTestNotification));
    await tester.pumpAndSettle();

    final inlineError = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(AppStrings.testNotificationError(error)),
    );
    expect(inlineError.hitTestable(), findsOneWidget);
    expect(find.text(AppStrings.notifications), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              AppStrings.sendTestNotification,
            ),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, AppStrings.save),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('navigated'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.sendTestNotification));
    await tester.pump();

    expect(find.text(AppStrings.testNotificationError(error)), findsNothing);
    retryCompletion.complete();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notifications), findsNothing);
    expect(find.text('navigated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe verso il basso chiude la sheet quando idle', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: _Harness(onSendTest: () async {})),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.text(AppStrings.notifications),
      const Offset(0, 900),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notifications), findsNothing);
    expect(find.text('closed'), findsOneWidget);
  });
}

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1400);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

class _Harness extends StatefulWidget {
  final Future<void> Function() onSendTest;

  const _Harness({required this.onSendTest});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  var _state = 'idle';

  Future<void> _open(BuildContext context) async {
    final result = await showNotificationPreferencesSheet(
      context: context,
      profileData: const {},
      onSave: (_) async {},
      onSendTest: widget.onSendTest,
    );
    if (!mounted) return;
    setState(() {
      _state = result == NotificationPreferencesResult.testSent
          ? 'navigated'
          : 'closed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            Text(_state),
            ElevatedButton(
              onPressed: () => _open(context),
              child: const Text('Apri'),
            ),
          ],
        ),
      ),
    );
  }
}
