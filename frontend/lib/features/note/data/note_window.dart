import 'package:fluw/features/note/domain/note_entry.dart';

/// Entries read from storage, plus how many stored rows could not be read, so the screen can say so instead of
/// silently showing a smaller total.
final class NoteWindow {
  const NoteWindow({required this.entries, required this.unreadableCount});

  final List<NoteEntry> entries;
  final int unreadableCount;
}
