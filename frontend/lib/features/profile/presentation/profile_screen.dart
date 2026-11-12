import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/presentation/profile_overview.dart';
import 'package:fluw/features/profile/presentation/profile_setup_prompt.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.onEditProfile, super.key});

  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(storedProfileProvider)) {
      AsyncData(value: LoadedProfile(:final profile)) => ProfileOverview(
        profile: profile,
        today: ref.watch(todayProvider),
        onEdit: onEditProfile,
      ),
      AsyncData(value: NoProfile()) => ProfileSetupPrompt.empty(onSetUp: onEditProfile),
      AsyncData(value: UnreadableProfile()) => ProfileSetupPrompt.unreadable(onSetUp: onEditProfile),
      AsyncError() => ProfileSetupPrompt.loadFailed(onSetUp: onEditProfile),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
