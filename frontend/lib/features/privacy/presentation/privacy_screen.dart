import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/erase_all_data_button.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/privacy/presentation/privacy_policy_text.dart';

/// The privacy policy and terms of use, the same text as PRIVACY.md, with its public address and the contact page as
/// text the user can select or copy (the app opens no browser).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({required this.onEraseAllData, super.key});

  /// Asks for confirmation, then erases everything Fluw keeps on the phone.
  final VoidCallback onEraseAllData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: const Text('Quyền riêng tư và điều khoản')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(PrivacyPolicy.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(PrivacyPolicy.version, style: muted),
          const SizedBox(height: AppSpacing.sm),
          const Text(PrivacyPolicy.intro),
          const SizedBox(height: AppSpacing.md),
          const SectionCard(
            title: 'Bản công khai và liên hệ',
            children: [
              _Link(label: 'Đọc bản này trên web', url: PrivacyPolicy.publicUrl),
              SizedBox(height: AppSpacing.md),
              _Link(label: PrivacyPolicy.contactLabel, url: PrivacyPolicy.issuesUrl),
            ],
          ),
          for (final section in PrivacyPolicy.sections) ...[
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: section.title,
              children: [
                for (final (index, block) in section.blocks.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.md),
                  _Block(block),
                ],
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Dữ liệu trên máy này',
            accentColor: theme.colorScheme.error,
            children: [
              Text(
                'Xóa hồ sơ, Nhật ký, lịch sử cân, giờ nhắc, lịch sử tìm kiếm và các lựa chọn đồng ý. Fluw hỏi lại '
                'trước khi xóa.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              EraseAllDataButton(onPressed: onEraseAllData),
            ],
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.url});

  final String label;
  final String url;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(const SnackBar(content: Text('Đã sao chép liên kết.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        Row(
          children: [
            Expanded(
              child: SelectableText(url, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
            ),
            IconButton(
              onPressed: () => _copy(context),
              tooltip: 'Sao chép liên kết: $label',
              icon: const Icon(Icons.copy_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.block);

  final PolicyBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium;
    return switch (block) {
      PolicyParagraph(:final text) => _MarkedText(text, style: style),
      PolicyBullets(:final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in items.indexed)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Text('•', style: style)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _MarkedText(item, style: style)),
                ],
              ),
            ),
        ],
      ),
      PolicyDataFlows(:final rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, row) in rows.indexed)
            Container(
              margin: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.when, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  _MarkedText('**${PolicyDataFlows.whatHeader}:** ${row.what}', style: style),
                  _MarkedText('**${PolicyDataFlows.whereHeader}:** ${row.where}', style: style),
                ],
              ),
            ),
        ],
      ),
    };
  }
}

/// Shows text written with PRIVACY.md's `**bold**` marks.
class _MarkedText extends StatelessWidget {
  const _MarkedText(this.text, {required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final (index, part) in parts.indexed)
            if (part.isNotEmpty)
              TextSpan(
                text: part,
                style: index.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
              ),
        ],
      ),
    );
  }
}
