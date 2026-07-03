import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/app/theme/color_schemes.dart';
import 'package:chigio_time/features/social/presentation/social_screen.dart';

void main() {
  group('statusRingColor (B5 — anello stato avatar)', () {
    test('mappa stati → colori', () {
      expect(statusRingColor('working'), AppColors.green600);
      expect(statusRingColor('remote'), AppColors.blue600);
      expect(statusRingColor('paused'), AppColors.orange500);
      // uscito + assenza uniti in nero
      expect(statusRingColor('completed'), AppColors.neutral900);
      expect(statusRingColor('notStarted'), AppColors.neutral900);
      // sconosciuto → grigio neutro
      expect(statusRingColor('boh'), AppColors.neutral400);
    });
  });

  group('statusExplanation', () {
    test('testo non vuoto per ogni stato', () {
      for (final s in [
        'working',
        'remote',
        'paused',
        'completed',
        'notStarted',
        'x',
      ]) {
        expect(statusExplanation(s).trim(), isNotEmpty);
      }
    });
  });
}
