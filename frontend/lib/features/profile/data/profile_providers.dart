import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(appDatabaseProvider)),
);

/// `null` until the user has set up a profile.
final profileProvider = StreamProvider<HealthProfile?>((ref) => ref.watch(profileRepositoryProvider).watch());
