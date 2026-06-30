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

    test('collaboratore può toccare memberUids solo col proprio uid', () {
      // Un collaboratore non-owner non deve poter espellere altri membri né
      // aggiungerne di arbitrari: join/leave sono vincolati al proprio uid.
      expect(
        rules.contains('concat([request.auth.uid])'),
        isTrue,
      );
      expect(
        rules.contains(
            'request.resource.data.memberUids.hasAll(resource.data.memberUids)'),
        isTrue,
      );
    });

    test('notifiche cross-user con whitelist dei campi', () {
      expect(rules.contains('hasOnly(['), isTrue);
    });

    test('notifiche cross-user: solo i type social, no spoof di sistema', () {
      // Un mittente non deve poter creare notifiche di sistema (es.
      // exit_reminder) nella casella altrui: solo i type social sono ammessi.
      expect(rules.contains("'colleague_added', 'coffee_invite', 'coffee_accepted'"), isTrue);
      expect(rules.contains('request.resource.data.type in ['), isTrue);
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
