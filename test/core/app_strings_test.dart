import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/core/constants/app_strings.dart';

void main() {
  group('AppStrings — invarianti leggibilità/coerenza', () {
    test('3 generi distinti M/F/A (schwa), nessuno vuoto', () {
      final genders = {
        AppStrings.genderMale,
        AppStrings.genderFemale,
        AppStrings.genderOther,
      };
      expect(genders.length, 3); // tutti distinti
      for (final g in genders) {
        expect(g.trim(), isNotEmpty);
      }
      // 'Altrə' usa lo schwa
      expect(AppStrings.genderOther.contains('ə'), isTrue);
    });

    test('etichette navbar (5 voci) non vuote', () {
      for (final s in [
        AppStrings.navHome,
        AppStrings.navTimesheet,
        AppStrings.navProjects,
        AppStrings.navSocial,
        AppStrings.navSalary,
      ]) {
        expect(s.trim(), isNotEmpty);
      }
    });

    test('appVersion include data e build number allineati al pubspec', () {
      final visibleMatch = RegExp(
        r'^v(\d{4})\.(\d{2})\.(\d{2})\+(\d+)$',
      ).firstMatch(AppStrings.appVersion);
      final pubspecMatch = RegExp(
        r'^version:\s*(\d{4})\.(\d{1,2})\.(\d{1,2})\+(\d+)$',
        multiLine: true,
      ).firstMatch(File('pubspec.yaml').readAsStringSync());

      expect(
        visibleMatch,
        isNotNull,
        reason: 'appVersion="${AppStrings.appVersion}"',
      );
      expect(pubspecMatch, isNotNull);
      expect(
        [for (var i = 1; i <= 4; i++) int.parse(visibleMatch!.group(i)!)],
        [for (var i = 1; i <= 4; i++) int.parse(pubspecMatch!.group(i)!)],
      );
    });

    test('etichetta download APK non dichiara la versione Web', () {
      expect(
        AppStrings.latestApkVersion,
        isNot(contains(AppStrings.appVersion)),
      );
    });
  });
}
