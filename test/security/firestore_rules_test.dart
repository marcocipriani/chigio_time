import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Test "contratto" sulle security rules: non esegue l'emulatore (non c'è il
/// pacchetto rules-unit-testing in questo progetto), ma blocca regressioni
/// pericolose verificando che le condizioni chiave restino presenti.
void main() {
  final rules = File('firestore.rules').readAsStringSync();
  final notificationBackend = [
    'functions/index.js',
    'functions/notification_logic.js',
    'functions/notification_runtime.js',
  ].map((path) => File(path).readAsStringSync()).join('\n');

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
      expect(rules.contains('concat([request.auth.uid])'), isTrue);
      expect(
        rules.contains(
          'request.resource.data.memberUids.hasAll(resource.data.memberUids)',
        ),
        isTrue,
      );
    });

    test('notifiche cross-user con whitelist dei campi', () {
      expect(rules.contains('hasOnly(['), isTrue);
    });

    test('notifiche cross-user: solo i type social, no spoof di sistema', () {
      // Un mittente non deve poter creare notifiche di sistema (es.
      // exit_reminder) nella casella altrui: solo i type social sono ammessi.
      expect(rules.contains("data.type == 'colleague_added'"), isTrue);
      expect(rules.contains("data.type == 'coffee_invite'"), isTrue);
      expect(rules.contains("data.type == 'coffee_accepted'"), isTrue);
      expect(rules.contains("data.type == 'exit_reminder'"), isFalse);
    });

    test('scrittura profilo solo al proprietario', () {
      expect(rules.contains('request.auth.uid == userId'), isTrue);
    });

    test('profilo non cancellabile dal client', () {
      final usersBlock = rules.substring(
        rules.indexOf('match /users/{userId}'),
        rules.indexOf('match /private/{docId}'),
      );

      expect(usersBlock.contains('allow delete: if false;'), isTrue);
    });

    test('administration iniziale limitata a PCM e poi immutabile', () {
      expect(
        rules.contains('function profileAdministrationIsValidOnCreate()'),
        isTrue,
      );
      expect(
        rules.contains('function profileAdministrationIsValidOnUpdate()'),
        isTrue,
      );
      expect(
        rules.contains("request.resource.data.get('administration', null)"),
        isTrue,
      );
      expect(
        rules.contains("resource.data.get('administration', null)"),
        isTrue,
      );
      expect(rules.contains("'Presidenza del Consiglio dei Ministri'"), isTrue);
      expect(rules.contains('newAdministration == oldAdministration'), isTrue);
    });

    test('nessuna regola world-readable (request.auth != null da sola)', () {
      // Una `allow read: if request.auth != null;` aprirebbe i dati a chiunque
      // sia loggato: non deve esistere.
      expect(rules.contains('request.auth != null;'), isFalse);
    });

    test('A3: notifiche cross-user solo dalla stessa amministrazione', () {
      // Il create cross-user deve verificare che mittente e destinatario
      // condividano l'amministrazione (anti spam/push cross-amministrazione).
      expect(
        rules.contains(
          ".data.get('administration', null) == myAdministration()",
        ),
        isTrue,
      );
    });

    test('notifiche cross-user validano schema comune e type-specific', () {
      expect(
        rules.contains('function crossUserNotificationCommonIsValid()'),
        isTrue,
      );
      expect(rules.contains('request.resource.data.fromUid is string'), isTrue);
      expect(
        rules.contains('request.resource.data.sentAt is timestamp'),
        isTrue,
      );
      expect(rules.contains('request.resource.data.read == false'), isTrue);
      expect(
        rules.contains("request.resource.data.status == 'pending'"),
        isTrue,
      );
      expect(rules.contains("request.resource.data.status == 'info'"), isTrue);
      expect(
        rules.contains(
          "request.resource.data.responseType in [\n"
          "             'accepted', 'maybe', 'declined', 'arriving'\n"
          '           ]',
        ),
        isTrue,
      );
      expect(rules.contains('request.resource.data.etaMinutes is int'), isTrue);
      expect(rules.contains('request.resource.data.etaMinutes >= 1'), isTrue);
      expect(rules.contains('request.resource.data.etaMinutes <= 60'), isTrue);
      expect(rules.contains('scheduledAt.size() <= 20'), isTrue);
      expect(rules.contains('message.size() <= 280'), isTrue);
    });

    test('anti-spam: i ban legacy attivi restano onorati', () {
      expect(rules.contains('function hasActiveLegacyAbuseBan()'), isTrue);
      expect(rules.contains('abuseBans/\$(request.auth.uid)'), isTrue);
      expect(rules.contains(".data.get('until', null) is timestamp"), isTrue);
      expect(rules.contains(".data.get('until', null) > request.time"), isTrue);
      expect(rules.contains('.data.until'), isFalse);
      expect(rules.contains('&& !hasActiveLegacyAbuseBan()'), isTrue);
    });

    test('anti-spam: nessun writer backend o match client crea nuovi ban', () {
      expect(notificationBackend.contains('abuseBans'), isFalse);
      expect(rules.contains('match /abuseBans/{uid}'), isFalse);
    });

    test('anti-spam: campi testuali notifiche con tetto di dimensione', () {
      expect(rules.contains('fromName.size() <= 60'), isTrue);
      expect(rules.contains('message.size() <= 280'), isTrue);
    });
  });

  group('storage.rules — contratto di sicurezza (A2)', () {
    final storageRules = File('storage.rules').readAsStringSync();

    test('file presente e versionato nel repo', () {
      expect(storageRules.trim(), isNotEmpty);
    });

    test('scrittura foto profilo vincolata al proprio uid', () {
      expect(
        storageRules.contains("fileName == request.auth.uid + '.jpg'"),
        isTrue,
      );
    });

    test('limite dimensione e content-type immagine', () {
      expect(storageRules.contains('request.resource.size'), isTrue);
      expect(storageRules.contains("contentType.matches('image/.*')"), isTrue);
    });

    test('default deny sul resto del bucket', () {
      expect(storageRules.contains('allow read, write: if false;'), isTrue);
    });
  });
}
