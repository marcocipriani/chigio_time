import 'package:drift/wasm.dart';

// Entry point for the drift web worker.
// Compile to web/drift_worker.dart.js:
//   dart compile js lib/core/database/drift_worker.dart -o web/drift_worker.dart.js
void main() => WasmDatabase.workerMainForOpen();
