import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';

/// Overridden in `app/` with limits computed from the stored profile; features only read it.
final personalLimitsProvider = Provider<PersonalLimits>((ref) => PersonalLimits.none);
