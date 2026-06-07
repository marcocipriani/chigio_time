import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

// Web WASM support via drift/wasm (ADR-0005).
// Prerequisites (one-time build steps):
//   1. sqlite3.wasm served from package:sqlite3_flutter_libs assets.
//   2. drift_worker.dart.js — compile via:
//        dart compile js lib/core/database/drift_worker.dart -o web/drift_worker.dart.js
//
// Fallback: if WASM init fails, appDatabaseProvider catches and returns null
// so the app degrades to Firestore-only mode silently.
QueryExecutor nativeConnection() => DatabaseConnection.delayed(
  WasmDatabase.open(
    databaseName: 'chigio_time',
    sqlite3Uri: Uri.parse('packages/sqlite3_flutter_libs/assets/sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.dart.js'),
  ).then((result) => result.resolvedExecutor),
);
