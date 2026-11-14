import 'package:shared_preferences/shared_preferences.dart';

/// The last few search words, newest first. Kept in shared preferences: they are not health data and losing them
/// only empties the "Gần đây" row.
final class RecentSearchesStorage {
  const RecentSearchesStorage(this._preferences);

  static const String _key = 'recent_searches';
  static const int maxEntries = 8;

  final SharedPreferences? _preferences;

  List<String> read() => List.unmodifiable(_preferences?.getStringList(_key) ?? const <String>[]);

  /// Moves [query] to the front; the same words in another letter case count as one entry.
  Future<List<String>> add(String query) async {
    final updated = [
      query,
      ...read().where((entry) => entry.toLowerCase() != query.toLowerCase()),
    ].take(maxEntries).toList();
    await _write(updated);
    return List.unmodifiable(updated);
  }

  Future<List<String>> remove(String query) async {
    final updated = read().where((entry) => entry != query).toList();
    await _write(updated);
    return List.unmodifiable(updated);
  }

  Future<void> clear() => _write(const []);

  // A failed write only means the list is not remembered after a restart.
  Future<void> _write(List<String> entries) async {
    try {
      await _preferences?.setStringList(_key, entries);
    } on Exception {
      return;
    }
  }
}
