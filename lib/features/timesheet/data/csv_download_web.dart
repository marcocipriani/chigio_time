// Web-only file, loaded via conditional import (dart.library.html) from
// csv_export_service.dart. dart:html is the right API here; migrating to
// package:web/dart:js_interop would add a direct dependency (ADR-gated).
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data' show Uint8List;

// Forza il download diretto del browser (anziché il Web Share Sheet, che su
// alcuni browser/OS non offre "Salva file" e si limita a condividere il link).
void triggerBrowserDownload(Uint8List bytes, String filename, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
