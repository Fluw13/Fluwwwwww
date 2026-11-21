import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/privacy/presentation/privacy_policy_text.dart';

/// PRIVACY.md rebuilt from the text the app shows.
String _markdownFromApp() {
  String block(PolicyBlock block) => switch (block) {
    PolicyParagraph(:final text) => text,
    PolicyBullets(:final items) => [for (final item in items) '- $item'].join('\n'),
    PolicyDataFlows(:final rows) => [
      '| ${PolicyDataFlows.whenHeader} | ${PolicyDataFlows.whatHeader} | ${PolicyDataFlows.whereHeader} |',
      '|---|---|---|',
      for (final row in rows) '| ${row.when} | ${row.what} | ${row.where} |',
    ].join('\n'),
  };
  final parts = [
    '# ${PrivacyPolicy.title}',
    PrivacyPolicy.version,
    '${PrivacyPolicy.intro} ${PrivacyPolicy.contactLabel}: ${PrivacyPolicy.issuesUrl}',
    for (final section in PrivacyPolicy.sections) ...['## ${section.title}', ...section.blocks.map(block)],
  ];
  return '${parts.join('\n\n')}\n';
}

void main() {
  test('chữ trong app trùng từng chữ với PRIVACY.md ở gốc repo (cả hai chiều)', () {
    expect(_markdownFromApp(), File('../PRIVACY.md').readAsStringSync());
  });

  test('địa chỉ công khai là PRIVACY.md trên nhánh main của cùng repo với trang liên hệ', () {
    expect(PrivacyPolicy.issuesUrl, 'https://github.com/Fluw13/Fluwwwwww/issues');
    expect(PrivacyPolicy.publicUrl, 'https://github.com/Fluw13/Fluwwwwww/blob/main/PRIVACY.md');
  });
}
