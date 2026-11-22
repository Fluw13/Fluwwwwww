import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/presentation/profile_overview.dart';
import 'package:fluw/features/profile/presentation/profile_setup_prompt.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    required this.onEditProfile,
    required this.onOpenPrivacy,
    required this.onOpenMethodology,
    required this.onEraseAllData,
    super.key,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenMethodology;

  /// Asks for confirmation, then erases everything Fluw keeps on the phone.
  final VoidCallback onEraseAllData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(storedProfileProvider)) {
      AsyncData(value: LoadedProfile(:final profile)) => ProfileOverview(
        profile: profile,
        today: ref.watch(todayProvider),
        onEdit: onEditProfile,
        onOpenPrivacy: onOpenPrivacy,
        onOpenMethodology: onOpenMethodology,
        onEraseAllData: onEraseAllData,
      ),
      AsyncData(value: NoProfile()) => ProfileSetupPrompt.empty(onPressed: onEditProfile, onOpenPrivacy: onOpenPrivacy),
      AsyncData(value: UnreadableProfile()) => ProfileSetupPrompt.unreadable(
        onPressed: onEditProfile,
        onOpenPrivacy: onOpenPrivacy,
      ),
      AsyncError() => ProfileSetupPrompt.loadFailed(
        onPressed: () => ref.invalidate(storedProfileProvider),
        onOpenPrivacy: onOpenPrivacy,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
