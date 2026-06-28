import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Contract test on Cloud Storage rules. Like the Firestore counterpart it does
/// not run the emulator; it blocks dangerous regressions by asserting the key
/// guards stay present in `storage.rules`.
void main() {
  final file = File('storage.rules');

  group('storage.rules — contratto di sicurezza', () {
    test('file presente e non vuoto', () {
      expect(file.existsSync(), isTrue,
          reason: 'storage.rules deve esistere ed essere deployato');
      expect(file.readAsStringSync().trim(), isNotEmpty);
    });

    test('scrittura foto profilo solo al proprietario (<uid>.jpg)', () {
      final rules = file.readAsStringSync();
      expect(rules.contains('profile_photos/{fileName}'), isTrue);
      expect(
        rules.contains("fileName == request.auth.uid + '.jpg'"),
        isTrue,
      );
    });

    test('default-deny su ogni altro path', () {
      final rules = file.readAsStringSync();
      expect(rules.contains('match /{allPaths=**}'), isTrue);
      expect(rules.contains('allow read, write: if false;'), isTrue);
    });

    test('nessun bucket world-writable (allow write: if true)', () {
      final rules = file.readAsStringSync().replaceAll(' ', '');
      expect(rules.contains('allowwrite:iftrue'), isFalse);
      expect(rules.contains('allowread,write:iftrue'), isFalse);
    });
  });
}
