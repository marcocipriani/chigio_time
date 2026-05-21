import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/totalizzatori.dart';
import '../../profile/data/profile_repository.dart';

part 'totalizzatori_provider.g.dart';

// Returns parsed portaleJson from the user profile, or null when no data
// has been entered yet. Never returns a zero-filled fixture — null signals
// "no data" so the UI can show an appropriate empty state instead of fake badges.
@riverpod
Totalizzatori? totalizzatori(Ref ref) {
  final profile = ref.watch(userProfileStreamProvider).asData?.value;
  if (profile == null) return null;
  final raw = profile['portaleJson'];
  if (raw is! Map) return null;
  try {
    return Totalizzatori.fromJson(Map<String, dynamic>.from(raw));
  } catch (e) {
    debugPrint('[totalizzatori] Parse error: $e');
    return null;
  }
}
