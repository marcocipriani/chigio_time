import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/profile/domain/profile_gate.dart';

void main() {
  group('profileDocIsComplete (gate onboarding / sicurezza)', () {
    test('null → false', () {
      expect(profileDocIsComplete(null), isFalse);
    });

    test('flag esplicito → true', () {
      expect(profileDocIsComplete({'hasCompletedOnboarding': true}), isTrue);
    });

    test('name + employmentType (legacy) → true', () {
      expect(
        profileDocIsComplete({'name': 'Mario', 'employmentType': 'Ruolo'}),
        isTrue,
      );
    });

    test('doc solo-photoURL (creato dal login) → false', () {
      // Regressione: NON deve far saltare l'onboarding ai nuovi utenti, ma
      // nemmeno ri-mostrarlo a chi ha già un profilo.
      expect(profileDocIsComplete({'photoURL': 'http://x/y.png'}), isFalse);
    });

    test('solo name senza employmentType → false', () {
      expect(profileDocIsComplete({'name': 'Mario'}), isFalse);
    });
  });
}
