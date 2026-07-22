import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/shared/widgets/floating_nav.dart';

void main() {
  group('FloatingNav (UI)', () {
    testWidgets('mostra le 5 voci', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FloatingNav(currentIndex: 0, onTap: _noop)),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Progetti'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Stipendio'), findsOneWidget);
    });

    testWidgets('tap su una voce invoca onTap con l\'indice giusto', (
      tester,
    ) async {
      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingNav(currentIndex: 0, onTap: (i) => tapped = i),
          ),
        ),
      );
      await tester.tap(find.text('Progetti'));
      await tester.pump();
      expect(
        tapped,
        2,
      ); // Home(0) Cartellino(1) Progetti(2) Social(3) Stipendio(4)
    });

    testWidgets('can render the Web-mobile pill without BackdropFilter', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingNav(
              currentIndex: 0,
              onTap: _noop,
              useBackdropFilter: false,
            ),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('retains blur when explicitly enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingNav(
              currentIndex: 0,
              onTap: _noop,
              useBackdropFilter: true,
            ),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });
}

void _noop(int _) {}
