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
