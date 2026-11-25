import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';

/// Where the data sources, how the targets are worked out, every license (packages, fonts, data) and the privacy
/// policy can be read.
class AboutCard extends StatelessWidget {
  const AboutCard({required this.onOpenPrivacy, required this.onOpenMethodology, super.key});

  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenMethodology;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Về Fluw',
      icon: Icons.info_outline,
      children: [
        Text(
          'Dữ liệu dinh dưỡng từ Open Food Facts (ODbL) và USDA FoodData Central (CC0).',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Fluw không phải thiết bị y tế; không chẩn đoán, điều trị hay phòng bệnh. Số liệu chỉ là ước tính.',
          style: theme.textTheme.bodyMedium,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onOpenMethodology,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Cách Fluw tính'),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PrivacyPolicyButton(onPressed: onOpenPrivacy),
        ),
        const Align(alignment: AlignmentDirectional.centerStart, child: LicensesButton()),
      ],
    );
  }
}

class LicensesButton extends StatelessWidget {
  const LicensesButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      // Full screen above the tabs, like the other pages opened from a tab.
      onPressed: () => showLicensePage(context: context, applicationName: 'Fluw', useRootNavigator: true),
      icon: const Icon(Icons.description_outlined),
      label: const Text('Nguồn dữ liệu và giấy phép'),
    );
  }
}

class PrivacyPolicyButton extends StatelessWidget {
  const PrivacyPolicyButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.privacy_tip_outlined),
      label: const Text('Quyền riêng tư và điều khoản'),
    );
  }
}
