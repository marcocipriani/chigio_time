import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/core/constants/app_constants.dart';

void main() {
  group('AppConstants.forcedLunchMins — regola 9 ore 3-zone', () {
    test('zona 1: < 9h, nessuna pausa forzata', () {
      expect(AppConstants.forcedLunchMins(471), 0); // 7h51 (Mer)
      expect(AppConstants.forcedLunchMins(539), 0);
    });

    test('zona 2: 9h–9h30, pausa proporzionale', () {
      expect(AppConstants.forcedLunchMins(540), 0);
      expect(AppConstants.forcedLunchMins(555), 15);
      expect(AppConstants.forcedLunchMins(569), 29);
    });

    test('zona 3: >= 9h30, pausa piena 30min', () {
      expect(AppConstants.forcedLunchMins(570), 30);
      expect(AppConstants.forcedLunchMins(486), 0); // 8h06 (Ven/Lun)
    });

    test('non scende mai sotto la pausa gia\' presa', () {
      expect(AppConstants.forcedLunchMins(400, alreadyTakenMins: 45), 45);
      expect(AppConstants.forcedLunchMins(600, alreadyTakenMins: 45), 45);
    });
  });
}
