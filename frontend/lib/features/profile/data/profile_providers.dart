import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(appDatabaseProvider)),
);

final storedProfileProvider = StreamProvider<StoredProfile>((ref) => ref.watch(profileRepositoryProvider).watch());
