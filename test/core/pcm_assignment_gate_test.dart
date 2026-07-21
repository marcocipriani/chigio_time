import 'dart:convert';
import 'dart:io';

import 'package:chigio_time/core/constants/app_strings.dart';
import 'package:chigio_time/core/data/pcm_catalog.dart';
import 'package:chigio_time/core/data/pcm_locations_repository.dart';
import 'package:chigio_time/features/profile/data/profile_repository.dart';
import 'package:chigio_time/shared/widgets/pcm_assignment_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PcmCatalog catalog;

  setUpAll(() {
    catalog = PcmCatalog.fromMap(
      jsonDecode(File('assets/data/pcm_catalog.json').readAsStringSync())
          as Map<String, Object?>,
    );
  });

  test('requires assignment for PCM profile with missing fields', () {
    expect(
      needsPcmAssignment({'administration': AppStrings.appOrg}, catalog),
      isTrue,
    );
  });

  test('accepts an exact canonical structure and site', () {
    expect(
      needsPcmAssignment({
        'administration': AppStrings.appOrg,
        'dipartimento': 'Dipartimento per le politiche antidroga',
        'sede': 'Via dei Laterani, 34',
        'sedeId': 'via-dei-laterani-34',
        'sedeAddress': 'Via dei Laterani, 34 · 00184 Roma',
        'sedeLat': 41.8838734,
        'sedeLng': 12.5029923,
      }, catalog),
      isFalse,
    );
  });

  test('requires assignment for legacy site ids and unknown structures', () {
    expect(
      needsPcmAssignment({
        'administration': AppStrings.appOrg,
        'dipartimento': 'Struttura non più presente',
        'sedeId': 'legacy-office-id',
      }, catalog),
      isTrue,
    );
  });

  test('does not gate organizations outside PCM', () {
    expect(
      needsPcmAssignment(const {
        'administration': 'Altra amministrazione',
      }, catalog),
      isFalse,
    );
  });

  test('app mounts the PCM assignment gate below the Navigator', () {
    final appSource = File('lib/app/app.dart').readAsStringSync();
    final routerSource = File(
      'lib/app/routes/app_router.dart',
    ).readAsStringSync();

    expect(appSource, isNot(contains('PcmAssignmentGate(')));
    expect(routerSource, contains('PcmAssignmentGate(child: child)'));
  });

  testWidgets('gate selectors open from a route context', (tester) async {
    final profile = <String, dynamic>{
      'administration': AppStrings.appOrg,
      'dipartimento': '',
      'sedeId': '',
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileStreamProvider.overrideWith(
            (ref) => Stream.value(profile),
          ),
          pcmCatalogProvider.overrideWith((ref) async => catalog),
        ],
        child: MaterialApp(
          home: PcmAssignmentGate(
            child: const Scaffold(body: Text('Dashboard')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.pcmAssignmentRequiredTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('pcm-structure-field')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(catalog.structures.first.structureName), findsOneWidget);
  });
}
