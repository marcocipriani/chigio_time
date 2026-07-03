import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chigio_time/shared/widgets/shell_shortcuts.dart';

// Regressione F4: le scorciatoie devono funzionare anche a focus "vergine"
// (nessun click precedente) e NON devono scattare mentre si scrive in un
// campo di testo.
void main() {
  Widget host({required ValueChanged<int> onSwitch, Widget? body}) {
    return MaterialApp(
      home: ShellShortcuts(
        onSwitchBranch: onSwitch,
        onShowHelp: () {},
        child: Scaffold(body: body ?? const SizedBox()),
      ),
    );
  }

  testWidgets('digit switches branch without any prior focus/click', (
    tester,
  ) async {
    final calls = <int>[];
    await tester.pumpWidget(host(onSwitch: calls.add));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    expect(calls, [1]);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    expect(calls, [1, 1]);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(calls, [1, 1, 0]);
  });

  testWidgets('single-key shortcuts are ignored while typing in a TextField', (
    tester,
  ) async {
    final calls = <int>[];
    await tester.pumpWidget(host(onSwitch: calls.add, body: const TextField()));
    await tester.pump();

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(ShellShortcuts.isTyping, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    expect(calls, isEmpty);
  });
}
