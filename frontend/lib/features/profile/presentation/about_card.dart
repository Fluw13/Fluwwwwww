import 'package:flutter/material.dart';
import 'package:fluw/core/widgets/section_card.dart';

/// Where the data sources and every license (packages, fonts, data) can be read, as their licenses require.
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Về Fluw',
      children: [
        Text(
          'Dữ liệu dinh dưỡng từ Open Food Facts (ODbL) và USDA FoodData Central (CC0). '
          'Số liệu là ước tính, không thay thế tư vấn y tế.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
      onPressed: () => showLicensePage(context: context, applicationName: 'Fluw'),
      icon: const Icon(Icons.description_outlined),
      label: const Text('Nguồn dữ liệu và giấy phép'),
    );
  }
}
