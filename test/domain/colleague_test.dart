import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/social/domain/colleague.dart';

ColleagueProfile _c({required String rawStatus, String? statusDate}) =>
    ColleagueProfile(
      uid: 'u1',
      name: 'Mario Rossi',
      administration: 'PCM',
      employmentType: 'Ruolo',
      isFavorite: false,
      rawStatus: rawStatus,
      statusDate: statusDate,
    );

void main() {
  group('ColleagueProfile', () {
    String today() {
      final d = DateTime.now();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    test('effectiveStatus valido solo se statusDate è oggi', () {
      expect(_c(rawStatus: 'working', statusDate: today()).effectiveStatus,
          'working');
      // data vecchia → trattato come notStarted
      expect(_c(rawStatus: 'working', statusDate: '2020-01-01').effectiveStatus,
          'notStarted');
      expect(_c(rawStatus: 'working').effectiveStatus, 'notStarted');
    });

    test('canReceiveCoffee solo se working/paused oggi', () {
      expect(_c(rawStatus: 'working', statusDate: today()).canReceiveCoffee,
          isTrue);
      expect(_c(rawStatus: 'paused', statusDate: today()).canReceiveCoffee,
          isTrue);
      expect(_c(rawStatus: 'remote', statusDate: today()).canReceiveCoffee,
          isFalse);
      expect(_c(rawStatus: 'completed', statusDate: today()).canReceiveCoffee,
          isFalse);
    });

    test('initials da nome e cognome', () {
      expect(_c(rawStatus: 'working').initials, 'MR');
      final single = ColleagueProfile(
        uid: 'u2',
        name: 'Anna',
        administration: 'PCM',
        employmentType: 'Ruolo',
        isFavorite: false,
        rawStatus: 'working',
      );
      expect(single.initials, 'A');
    });
  });
}
