import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/totalizzatori.dart';
import '../../profile/data/profile_repository.dart';

part 'totalizzatori_provider.g.dart';

// Returns parsed portale data (private/portale, fallback legacy portaleJson),
// or null when no data has been entered yet. Never returns a zero-filled
// fixture — null signals "no data" so the UI can show an empty state.
@riverpod
Totalizzatori? totalizzatori(Ref ref) {
  final raw = ref.watch(portaleRawProvider);
  if (raw == null) return null;
  try {
    return Totalizzatori.fromJson(raw);
  } catch (e) {
    debugPrint('[totalizzatori] Parse error: $e');
    return null;
  }
}
