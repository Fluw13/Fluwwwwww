import 'dart:math';

final Random _random = Random.secure();

/// A row id unique enough for one device: the time keeps ids ordered, the random part keeps two rows made in the same
/// microsecond apart.
String newRowId({DateTime? now}) {
  final time = (now ?? DateTime.now()).toUtc().microsecondsSinceEpoch.toRadixString(36);
  final randomPart = List.generate(6, (_) => _random.nextInt(36).toRadixString(36)).join();
  return '$time-$randomPart';
}
