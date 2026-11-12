import 'package:fluw/features/profile/domain/health_profile.dart';

/// What the device holds. [UnreadableProfile] is kept apart from [NoProfile] so the UI can tell the user their saved
/// profile could not be read, instead of silently showing an empty setup form.
sealed class StoredProfile {
  const StoredProfile();
}

final class NoProfile extends StoredProfile {
  const NoProfile();
}

final class UnreadableProfile extends StoredProfile {
  const UnreadableProfile();
}

final class LoadedProfile extends StoredProfile {
  const LoadedProfile(this.profile);

  final HealthProfile profile;
}
