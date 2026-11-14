import 'package:flutter_riverpod/misc.dart';
import 'package:fluw/app/personal_limits_from_profile.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';

/// Providers that join features, shared by `main()` and the app tests so both run the same wiring.
List<Override> crossFeatureOverrides() => [
  personalLimitsProvider.overrideWith((ref) {
    final stored = ref.watch(storedProfileProvider).value;
    return stored is LoadedProfile
        ? personalLimitsFromProfile(stored.profile, today: ref.watch(todayProvider))
        : PersonalLimits.none;
  }),
];
