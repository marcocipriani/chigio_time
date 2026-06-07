import 'dart:typed_data' show Uint8List;

// Stub per piattaforme non-web — mai invocato (vedi _downloadCsv in
// csv_export_service.dart, che instrada su [kIsWeb]).
void triggerBrowserDownload(Uint8List bytes, String filename, String mimeType) {
  throw UnsupportedError('triggerBrowserDownload è disponibile solo su web');
}
