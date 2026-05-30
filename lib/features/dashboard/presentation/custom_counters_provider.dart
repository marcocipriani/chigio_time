import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/custom_counter.dart';
import '../../profile/data/profile_repository.dart';

part 'custom_counters_provider.g.dart';

@riverpod
List<CustomCounter> customCounters(Ref ref) {
  final profile = ref.watch(userProfileStreamProvider).asData?.value;
  if (profile == null) return [];
  final raw = profile['customCounters'];
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((e) {
        try {
          return CustomCounter.fromJson(Map<String, dynamic>.from(e));
        } catch (err) {
          debugPrint('[customCounters] Parse error: $err');
          return null;
        }
      })
      .whereType<CustomCounter>()
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
