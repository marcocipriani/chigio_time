import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('index and Flutter bootstrap keep a structural loader until runApp', () {
    final html = File('web/index.html').readAsStringSync();
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    expect(html, contains('id="app-loader"'));
    expect(html, contains('aria-label="Caricamento della Home"'));
    expect(html, contains('class="loader-hero"'));
    expect(html, contains('class="loader-card"'));
    expect(html, contains('flutter_bootstrap.js'));
    expect(bootstrap, contains('{{flutter_js}}'));
    expect(bootstrap, contains('{{flutter_build_config}}'));
    expect(bootstrap, contains('await appRunner.runApp()'));
    expect(
      bootstrap,
      contains("document.getElementById('app-loader')?.remove()"),
    );
  });
}
