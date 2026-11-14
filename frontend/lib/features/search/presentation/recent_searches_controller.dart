import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/features/search/data/search_providers.dart';

final recentSearchesProvider = NotifierProvider<RecentSearchesController, List<String>>(RecentSearchesController.new);

final class RecentSearchesController extends Notifier<List<String>> {
  @override
  List<String> build() => ref.watch(recentSearchesStorageProvider).read();

  Future<void> add(String query) async => state = await ref.read(recentSearchesStorageProvider).add(query);

  Future<void> remove(String query) async => state = await ref.read(recentSearchesStorageProvider).remove(query);

  Future<void> clear() async {
    await ref.read(recentSearchesStorageProvider).clear();
    state = const [];
  }
}
