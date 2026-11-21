import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/note_entry.dart';

/// How many recent foods the search screen offers.
const int recentFoodsLimit = 8;

/// Foods already in the diary, so they can be logged again without a search; `app/` provides the real one.
abstract interface class RecentFoodsReader {
  /// The newest entry of each different food, newest first, at most [limit]. Emits again when the diary changes.
  Stream<List<NoteEntry>> watchRecentFoods({required int limit});
}

final recentFoodsReaderProvider = Provider<RecentFoodsReader>(
  (ref) => throw UnimplementedError('recentFoodsReaderProvider phải được nối trong app/app_overrides.dart'),
);

final recentFoodsProvider = StreamProvider.autoDispose<List<NoteEntry>>(
  (ref) => ref.watch(recentFoodsReaderProvider).watchRecentFoods(limit: recentFoodsLimit),
);
