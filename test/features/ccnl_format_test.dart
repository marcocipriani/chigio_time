import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/profile/presentation/profile_screen.dart';

void main() {
  group('formatCcnlBody (lettore CCNL leggibile)', () {
    const raw = 'Art. 5\n'
        'Titolo articolo\n'
        '1. Primo comma che continua\n'
        'su una seconda riga.\n'
        '9\n' // numero di pagina
        'CCNL COMPARTO PCM 2019-2021\n' // intestazione corrente
        '2. Secondo comma.\n'
        'a) lettera a.';

    final out = formatCcnlBody(raw);

    test('rimuove intestazione Art./titolo, numeri pagina e header correnti', () {
      expect(out.contains('Art. 5'), isFalse);
      expect(out.contains('Titolo articolo'), isFalse);
      expect(out.contains('CCNL COMPARTO'), isFalse);
      expect(RegExp(r'(^|\n)9(\n|$)').hasMatch(out), isFalse);
    });

    test('ricompone le righe spezzate in capoversi', () {
      expect(out.contains('1. Primo comma che continua su una seconda riga.'),
          isTrue);
      expect(out.contains('2. Secondo comma.'), isTrue);
      expect(out.contains('a) lettera a.'), isTrue);
    });

    test('capoversi separati da riga vuota', () {
      expect(out.contains('\n\n'), isTrue);
    });
  });
}
