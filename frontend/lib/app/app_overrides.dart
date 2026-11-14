import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fluw/app/personal_limits_from_profile.dart';
import 'package:fluw/core/diary/food_logger.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/note/data/note_food_logger.dart';
import 'package:fluw/features/note/data/note_providers.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';

/// Providers that join features, shared by `main()` and the app tests so both run the same wiring.
List<Override> crossFeatureOverrides() => [
  foodLoggerProvider.overrideWith((ref) => NoteFoodLogger(ref.watch(noteRepositoryProvider))),
  personalLimitsProvider.overrideWith(
    (ref) => switch (ref.watch(storedProfileProvider)) {
      AsyncData(value: LoadedProfile(:final profile)) => personalLimitsFromProfile(
        profile,
        today: ref.watch(todayProvider),
      ),
      AsyncData(value: NoProfile()) => PersonalLimits.none,
      // A broken profile must never look like "no allergies": the UI says it could not be read.
      AsyncData(value: UnreadableProfile()) || AsyncError() => const PersonalLimits.empty(ProfileStatus.unreadable),
      _ => const PersonalLimits.empty(ProfileStatus.loading),
    },
  ),
];
