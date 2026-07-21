import 'dart:convert';
import 'dart:io';

import 'package:chigio_time/core/data/pcm_catalog.dart';
import 'package:chigio_time/shared/widgets/pcm_assignment_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PcmCatalog catalog;

  setUpAll(() {
    catalog = PcmCatalog.fromMap(
      jsonDecode(File('assets/data/pcm_catalog.json').readAsStringSync())
          as Map<String, Object?>,
    );
  });

  testWidgets('structure selection recommends but does not select a site', (
    tester,
  ) async {
    var structure = '';
    var siteId = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PcmAssignmentForm(
              structures: catalog.structures,
              structureName: structure,
              siteId: siteId,
              onStructureSelected: (value) {
                setState(() {
                  structure = value;
                  siteId = '';
                });
              },
              onSiteSelected: (site) {
                setState(() => siteId = site.id);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Dipartimento/Struttura'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('pcm-structure-field')),
      'antidroga',
    );
    await tester.pump();
    await tester.tap(find.text('Dipartimento per le politiche antidroga'));
    await tester.pumpAndSettle();

    expect(structure, 'Dipartimento per le politiche antidroga');
    expect(siteId, isEmpty);
    expect(find.text('Seleziona sede'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pcm-site-dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Sede consigliata'), findsWidgets);
    expect(find.textContaining('Via dei Laterani, 34'), findsWidgets);
  });
}
