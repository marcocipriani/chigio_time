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

    test('appVersion ha formato vYYYY.MM.DD', () {
      expect(
        RegExp(r'^v\d{4}\.\d{2}\.\d{2}$').hasMatch(AppStrings.appVersion),
        isTrue,
        reason: 'appVersion="${AppStrings.appVersion}"',
      );
    });
  });
}
