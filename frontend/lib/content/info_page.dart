/// A static text page (terms, privacy, data sources…) shown in the app.
class InfoPage {
  const InfoPage({required this.title, required this.sections, this.notice});

  final String title;

  /// Shown first, highlighted, e.g. that the text is a summary or not final yet.
  final String? notice;
  final List<InfoSection> sections;
}

class InfoSection {
  const InfoSection({required this.heading, required this.paragraphs});

  final String heading;
  final List<String> paragraphs;
}
