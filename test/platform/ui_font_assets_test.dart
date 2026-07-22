import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const files = <String>[
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
    'PlusJakartaSans-ExtraBold.ttf',
    'NotoSans-Regular.ttf',
    'NotoSansSymbols-Regular.ttf',
    'NotoSansSymbols2-Regular.ttf',
    'Roboto-Regular.ttf',
  ];

  test('first-frame UI fonts are bundled and non-empty', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/fonts/'));
    for (final name in files) {
      final file = File('assets/fonts/$name');
      expect(file.existsSync(), isTrue, reason: name);
      expect(file.lengthSync(), greaterThan(10000), reason: name);
    }
  });

  test('main no longer awaits fonts before the first runApp', () {
    final main = File('lib/main.dart').readAsStringSync();
    final bootstrap = File(
      'lib/app/bootstrap/app_bootstrap.dart',
    ).readAsStringSync();
    expect(main, isNot(contains('GoogleFonts.pendingFonts')));
    expect(bootstrap, contains('loadBundledUiFonts'));
    expect(bootstrap, contains('unawaited(warmColorEmojiFont())'));
  });
}
