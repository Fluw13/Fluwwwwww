import 'package:flutter/material.dart';

import '../core/format/date_format.dart';
import '../core/format/score_format.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../models/product/product.dart';
import '../models/product/product_details.dart';
import '../models/product/product_tags.dart';
import '../models/score/additives_score.dart';
import '../models/score/fluw_score.dart';
import '../models/score/nutrition_score.dart';
import '../models/score/score_indicator.dart';
import '../widgets/common/info_chip.dart';
import '../widgets/score/explanation_card.dart';
import '../widgets/score/indicator_row.dart';
import '../widgets/score/missing_data_list.dart';
import '../widgets/score/score_components.dart';
import '../widgets/score/score_level_style.dart';

/// "Cách Fluw tính điểm": every number of the score as sent by the backend,
/// from each nutrient to the total, with the rule behind it.
class ScoreExplanationScreen extends StatelessWidget {
  const ScoreExplanationScreen({super.key, required this.details});

  static const String defaultDisclaimer =
      'Điểm Fluw là thông tin tham khảo, tính từ dữ liệu cộng đồng Open Food Facts theo công thức công khai, '
      'không phải chẩn đoán hay tư vấn y tế.';

  final ProductDetails details;

  @override
  Widget build(BuildContext context) {
    final FluwScore score = details.score;
    final Product product = details.product;
    const SizedBox gap = SizedBox(height: AppSpacing.lg);

    return Scaffold(
      appBar: AppBar(title: const Text('Cách Fluw tính điểm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalCard(score: score),
              gap,
              _NutritionCard(nutrition: score.nutrition),
              gap,
              _AdditivesCard(
                additives: score.additives,
                list: product.additives,
              ),
              if (score.missing.isNotEmpty) ...[
                gap,
                _MissingCard(score: score),
              ],
              gap,
              _NovaCard(novaGroup: product.novaGroup),
              gap,
              _SourceCard(product: product, version: score.version),
              gap,
              ExplanationText(
                score.disclaimer ?? defaultDisclaimer,
                secondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.score});

  final FluwScore score;

  @override
  Widget build(BuildContext context) {
    final ScoreTotal total = score.total;
    final int? value = total.value;
    final String? label = total.label;
    final String? calculation = ScoreFormat.calculation(score);
    final double? nutritionWeight = score.nutritionWeight;
    final double? additivesWeight = score.additivesWeight;
    final ScoreLevelStyle style = ScoreLevelStyle.of(context, total.level);

    return ExplanationCard(
      title: 'Điểm Fluw',
      children: [
        if (value == null)
          const ExplanationText(
            'Chưa đủ dữ liệu để tính điểm tổng.',
            emphasized: true,
          )
        else
          Semantics(
            label: label == null
                ? 'Điểm tổng $value trên 100'
                : 'Điểm tổng $value trên 100, mức $label',
            excludeSemantics: true,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  ScoreFormat.outOf100(value),
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (label != null)
                  InfoChip(
                    label: label,
                    icon: style.icon,
                    foreground: style.colors.text,
                    background: style.colors.container,
                    emphasized: true,
                  ),
              ],
            ),
          ),
        if (nutritionWeight != null && additivesWeight != null)
          ExplanationText(
            'Điểm Fluw = Điểm dinh dưỡng × ${ScoreFormat.weightPercent(nutritionWeight)} '
            '+ Điểm phụ gia × ${ScoreFormat.weightPercent(additivesWeight)}, làm tròn đến số nguyên. '
            'Chỉ có điểm tổng khi có đủ cả hai điểm thành phần.',
            secondary: true,
          ),
        if (calculation != null)
          ExplanationText('Phép tính: $calculation', emphasized: true),
        const SizedBox(height: AppSpacing.sm),
        ScoreComponents(score: score, textAlign: TextAlign.start),
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.nutrition});

  final NutritionScore nutrition;

  String? get _statusText => switch (nutrition.status) {
    NutritionStatus.computed => switch (nutrition.basis) {
      NutritionScoreBasis.asSold => 'Tính trên sản phẩm như khi bán.',
      NutritionScoreBasis.prepared => 'Tính trên sản phẩm sau khi pha.',
      null => null,
    },
    NutritionStatus.missingData => 'Chưa đủ dữ liệu để tính điểm dinh dưỡng.',
    NutritionStatus.needsPreparedData => 'Sản phẩm cần pha trước khi dùng nhưng chưa có số liệu dinh dưỡng sau khi pha, nên chưa tính điểm.',
    NutritionStatus.notApplicable =>
      'Cách tính điểm dinh dưỡng không áp dụng cho loại sản phẩm này.',
    null => 'Chưa rõ trạng thái điểm dinh dưỡng.',
  };

  @override
  Widget build(BuildContext context) {
    final int? value = nutrition.value;
    final String? status = _statusText;
    final List<ScoreIndicator> negatives = [
      for (final ScoreIndicator indicator in nutrition.indicators)
        if (indicator.effect != IndicatorEffect.positive) indicator,
    ];
    final List<ScoreIndicator> positives = [
      for (final ScoreIndicator indicator in nutrition.indicators)
        if (indicator.effect == IndicatorEffect.positive) indicator,
    ];

    return ExplanationCard(
      title: value == null
          ? 'Điểm dinh dưỡng'
          : 'Điểm dinh dưỡng: ${ScoreFormat.outOf100(value)}',
      children: [
        ExplanationText(
          'Loại sản phẩm: ${nutrition.productTypeLabel ?? 'Chưa xác định'}',
        ),
        if (status != null) ExplanationText(status),
        ..._path(),
        if (nutrition.indicators.isNotEmpty)
          const ExplanationText(
            'Điểm thô tính theo thuật toán công khai Nutri-Score (cập nhật 2022–2023), '
            'trên 100 g hoặc 100 ml, rồi quy đổi sang thang 0–100 theo công thức của Fluw.',
            secondary: true,
          ),
        if (negatives.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const ExplanationText('Chỉ số tính điểm trừ', emphasized: true),
          for (final ScoreIndicator indicator in negatives)
            IndicatorRow(indicator: indicator),
        ],
        if (positives.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const ExplanationText('Chỉ số tính điểm cộng', emphasized: true),
          for (final ScoreIndicator indicator in positives)
            IndicatorRow(indicator: indicator),
        ],
        if (nutrition.missing.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          MissingDataList(
            labels: [for (final item in nutrition.missing) item.label],
          ),
        ],
      ],
    );
  }

  /// Raw points → band → nutrition score, only with the numbers the backend sent.
  List<Widget> _path() {
    final int? value = nutrition.value;
    final int? points = nutrition.points;
    final NutritionBand? band = nutrition.band;

    if (nutrition.productType == 'water' && value != null && band == null) {
      return [
        ExplanationText(
          'Nước luôn được ${ScoreFormat.outOf100(value)} điểm dinh dưỡng, không tính theo chỉ số.',
        ),
      ];
    }
    if (points == null) return const [];

    final int? negative = nutrition.negativePoints;
    final int? positive = nutrition.positivePoints;
    final String? rawRange = band == null
        ? null
        : ScoreFormat.pointsInterval(band.pointsMin, band.pointsMax);
    final String? scoreRange = band == null
        ? null
        : ScoreFormat.scoreInterval(band.scoreMin, band.scoreMax);

    return [
      if (negative != null && positive != null)
        ExplanationText(
          'Điểm trừ $negative − điểm cộng $positive = điểm thô $points.',
        )
      else
        ExplanationText('Điểm thô: $points.'),
      if (rawRange != null && scoreRange != null)
        ExplanationText(
          'Điểm thô thuộc dải $rawRange, ứng với điểm dinh dưỡng $scoreRange.',
        ),
      if (value != null)
        ExplanationText(
          '→ Điểm dinh dưỡng ${ScoreFormat.outOf100(value)}.',
          emphasized: true,
        ),
    ];
  }
}

class _AdditivesCard extends StatelessWidget {
  const _AdditivesCard({required this.additives, required this.list});

  final AdditivesScore additives;
  final List<ProductAdditive> list;

  @override
  Widget build(BuildContext context) {
    final int? value = additives.value;
    final int? count = additives.count;
    final AdditivesBand? band = additives.band;
    final String? interval = band == null
        ? null
        : ScoreFormat.additivesInterval(band);
    final int? bandScore = band?.score;

    final String? status = switch (additives.status) {
      AdditivesStatus.computed => null,
      AdditivesStatus.missingIngredients =>
        'Chưa có danh sách thành phần nên chưa tính được điểm phụ gia.',
      AdditivesStatus.ingredientsNotRecognized => 'Hơn một nửa thành phần chưa được nhận diện nên chưa tính được điểm phụ gia.',
      null => 'Chưa rõ trạng thái điểm phụ gia.',
    };

    return ExplanationCard(
      title: value == null
          ? 'Điểm phụ gia'
          : 'Điểm phụ gia: ${ScoreFormat.outOf100(value)}',
      children: [
        if (status != null) ExplanationText(status),
        if (count != null) ExplanationText('Số phụ gia khác nhau: $count.'),
        if (interval != null && bandScore != null)
          ExplanationText('Mốc điểm: $interval → $bandScore điểm.'),
        const ExplanationText(
          'Điểm phụ gia chỉ phản ánh mức độ sử dụng phụ gia, không đánh giá độ an toàn của từng chất.',
          secondary: true,
        ),
        if (list.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          for (final ProductAdditive additive in list)
            ExplanationText(
              '${additive.code} · ${additive.name ?? 'Chưa có tên'}',
            ),
        ],
      ],
    );
  }
}

class _MissingCard extends StatelessWidget {
  const _MissingCard({required this.score});

  final FluwScore score;

  @override
  Widget build(BuildContext context) {
    return ExplanationCard(
      title: 'Còn thiếu dữ liệu',
      children: [
        MissingDataList(
          labels: [for (final item in score.missing) item.label],
          title: 'Open Food Facts chưa có:',
        ),
        const ExplanationText(
          'Fluw không đoán phần dữ liệu thiếu. Bạn có thể bổ sung sản phẩm trên Open Food Facts '
          '(link ở cuối trang chi tiết sản phẩm).',
          secondary: true,
        ),
      ],
    );
  }
}

class _NovaCard extends StatelessWidget {
  const _NovaCard({required this.novaGroup});

  final int? novaGroup;

  @override
  Widget build(BuildContext context) {
    final int? group = novaGroup;
    return ExplanationCard(
      title: 'Nhóm chế biến NOVA',
      children: [
        ExplanationText(
          group == null ? 'Chưa có dữ liệu.' : 'Nhóm $group trên thang 1–4.',
        ),
        const ExplanationText(
          'Chỉ để tham khảo, không tính vào điểm.',
          secondary: true,
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.product, required this.version});

  final Product product;
  final String? version;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final DateTime? lastModified = product.source.lastModified;
    return ExplanationCard(
      title: 'Nguồn dữ liệu',
      children: [
        ExplanationText(
          'Open Food Facts · ${product.source.license ?? 'ODbL'} · ảnh ${product.source.imagesLicense ?? 'CC BY-SA'}',
        ),
        ExplanationText(
          'Cập nhật trên Open Food Facts: '
          '${lastModified == null ? 'Chưa có dữ liệu' : formatVietnameseDate(lastModified)}',
        ),
        ExplanationText('Phiên bản công thức: ${version ?? 'Chưa có dữ liệu'}'),
        Text(
          'Điểm do máy chủ Fluw tính theo công thức công khai; ứng dụng chỉ hiển thị, không tính lại.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}
