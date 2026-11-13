import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/data/weight_log_repository.dart';
import 'package:fluw/features/profile/domain/weight_entry.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(appDatabaseProvider)),
);

final storedProfileProvider = StreamProvider<StoredProfile>((ref) => ref.watch(profileRepositoryProvider).watch());

final weightLogRepositoryProvider = Provider<WeightLogRepository>(
  (ref) => WeightLogRepository(ref.watch(appDatabaseProvider)),
);

/// Oldest first.
final weightLogProvider = StreamProvider<List<WeightEntry>>((ref) => ref.watch(weightLogRepositoryProvider).watch());
