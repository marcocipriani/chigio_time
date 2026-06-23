import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Test "contratto" sulle security rules: non esegue l'emulatore (non c'è il
/// pacchetto rules-unit-testing in questo progetto), ma blocca regressioni
/// pericolose verificando che le condizioni chiave restino presenti.
void main() {
  final rules = File('firestore.rules').readAsStringSync();

  group('firestore.rules — contratto di sicurezza', () {
    test('file presente e non vuoto', () {
      expect(rules.trim(), isNotEmpty);
    });

    test('collezione progetti + pomodori', () {
      expect(rules.contains('match /projects/{projectId}'), isTrue);
      expect(rules.contains('match /pomodoros/{pid}'), isTrue);
    });

    test('pomodori NON leggibili da chiunque (gate membership)', () {
      expect(rules.contains('in project().memberUids'), isTrue);
    });

    test('cancellazione progetto solo al capo (owner)', () {
      expect(
        rules.contains('request.auth.uid == resource.data.ownerUid'),
        isTrue,
      );
    });

    test('notifiche cross-user con whitelist dei campi', () {
      expect(rules.contains('hasOnly(['), isTrue);
    });

    test('scrittura profilo solo al proprietario', () {
      expect(rules.contains('request.auth.uid == userId'), isTrue);
    });

    test('nessuna regola world-readable (request.auth != null da sola)', () {
      // Una `allow read: if request.auth != null;` aprirebbe i dati a chiunque
      // sia loggato: non deve esistere.
      expect(rules.contains('request.auth != null;'), isFalse);
    });
  });
}
