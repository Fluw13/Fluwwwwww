import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time, as a function so tests can pin it next to `todayProvider`.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
