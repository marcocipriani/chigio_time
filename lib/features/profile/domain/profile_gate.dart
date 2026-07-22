enum ProfileGateStatus {
  resolving,
  completeCached,
  completeServer,
  incompleteServer,
  failure,
}

class ProfileGateResult {
  final ProfileGateStatus status;
  final bool hasUsableProfile;
  final Object? error;

  const ProfileGateResult({
    required this.status,
    required this.hasUsableProfile,
    this.error,
  });

  bool get requiresOnboarding => status == ProfileGateStatus.incompleteServer;

  bool get allowsHome => hasUsableProfile && !requiresOnboarding;
}

/// Single source of truth for "is this user's onboarding complete?".
///
/// The explicit flag is preferred. The legacy fallback accepts the two fields
/// written only by onboarding, while photo-only documents remain incomplete.
bool profileDocIsComplete(Map<String, dynamic>? data) {
  if (data == null) return false;
  if (data['hasCompletedOnboarding'] == true) return true;
  return (data['name'] as String? ?? '').trim().isNotEmpty &&
      (data['employmentType'] as String? ?? '').trim().isNotEmpty;
}

ProfileGateResult reduceProfileGateSnapshot({
  required ProfileGateResult previous,
  required Map<String, dynamic>? data,
  required bool isFromCache,
}) {
  if (profileDocIsComplete(data)) {
    return ProfileGateResult(
      status: isFromCache
          ? ProfileGateStatus.completeCached
          : ProfileGateStatus.completeServer,
      hasUsableProfile: true,
    );
  }
  if (isFromCache) {
    return ProfileGateResult(
      status: ProfileGateStatus.resolving,
      hasUsableProfile: previous.hasUsableProfile,
    );
  }
  return const ProfileGateResult(
    status: ProfileGateStatus.incompleteServer,
    hasUsableProfile: false,
  );
}

ProfileGateResult reduceProfileGateError({
  required ProfileGateResult previous,
  required Object error,
}) => ProfileGateResult(
  status: ProfileGateStatus.failure,
  hasUsableProfile: previous.hasUsableProfile,
  error: error,
);
