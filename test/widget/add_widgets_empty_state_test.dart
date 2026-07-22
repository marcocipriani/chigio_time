import 'dart:io';

import 'package:chigio_time/features/dashboard/widgets/add_widgets_empty_state.dart';
import 'package:chigio_time/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows approved Chigio copy and invokes the add action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AddWidgetsEmptyState(onAdd: () => taps++),
          ),
        ),
      ),
    );

    expect(find.text('Costruisci la tua Home'), findsOneWidget);
    expect(
      find.text(
        'Scegli i widget che ti servono ogni giorno. '
        'Puoi cambiarli quando vuoi.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aggiungi widget'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Chigio invita ad aggiungere un widget'),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(GlassBtn)).width, greaterThan(350));

    await tester.tap(find.text('Aggiungi widget'));
    expect(taps, 1);
  });

  test('approved mascot asset is optimized and transparent-source sized', () {
    final asset = File('assets/images/chigio-aggiungi-widget.png');
    expect(asset.existsSync(), isTrue);
    expect(asset.lengthSync(), lessThan(350 * 1024));
  });
}
