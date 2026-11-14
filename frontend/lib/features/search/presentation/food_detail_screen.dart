import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:fluw/features/search/domain/food_assessment.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/presentation/add_to_note_card.dart';
import 'package:fluw/features/search/presentation/attribution_footer.dart';
import 'package:fluw/features/search/presentation/nutrient_table.dart';
import 'package:fluw/features/search/presentation/personal_check_card.dart';
import 'package:fluw/features/search/presentation/portion_input.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({required this.item, super.key});

  final FoodItem item;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  late FoodItem _item = widget.item;
  final TextEditingController _portion = TextEditingController(text: '100');

  /// Search results from Open Food Facts lack allergens and the Vietnamese name; the full product has them.
  late bool _isLoadingFull = _needsFullProduct;
  bool _fullLoadFailed = false;

  bool get _needsFullProduct => widget.item.source == FoodSource.openFoodFacts && widget.item.barcode != null;

  @override
  void initState() {
    super.initState();
    _portion.addListener(() => setState(() {}));
    if (_needsFullProduct) {
      _loadFullProduct();
    }
  }

  @override
  void dispose() {
    _portion.dispose();
    super.dispose();
  }

  Future<void> _loadFullProduct() async {
    setState(() {
      _isLoadingFull = true;
      _fullLoadFailed = false;
    });
    try {
      final full = await ref.read(foodApiProvider).lookUpBarcode(widget.item.barcode!);
      if (mounted) {
        setState(() {
          _item = full ?? _item;
          _isLoadingFull = false;
        });
      }
    } on ApiFailure {
      if (mounted) {
        setState(() {
          _isLoadingFull = false;
          _fullLoadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limits = ref.watch(personalLimitsProvider);
    final unitLabel = quantityUnitLabel(_item.facts.unit);
    final (portionAmount, portionError) = parsePortion(_portion.text, _item.facts.unit);
    final portion = portionAmount == null ? null : _item.facts.forQuantity(portionAmount);
    final imageUrl = _item.imageUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết dinh dưỡng')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Image.network(
                imageUrl.toString(),
                height: 180,
                // Decode at screen width instead of the photo's full size.
                cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
                fit: BoxFit.cover,
                semanticLabel: 'Ảnh sản phẩm',
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(_item.name ?? 'Chưa có tên', style: theme.textTheme.headlineSmall),
          Text(
            [?_item.brand, foodSourceLabel(_item.source), if (_item.barcode case final code?) 'Mã $code'].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (_item.servingSize case final serving?)
            Text(
              'Khẩu phần ghi trên bao bì: $serving',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          if (_fullLoadFailed) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chưa tải được đủ thông tin sản phẩm (dị ứng). Số liệu bên dưới lấy từ kết quả tìm kiếm.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
                TextButton(onPressed: _loadFullProduct, child: const Text('Thử lại')),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PersonalCheckCard(
            allergens: checkAllergens(_item, limits),
            shares: portion == null ? const [] : portionShares(portion, limits),
            limits: limits,
            isLoadingAllergens: _isLoadingFull,
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Chỉ số dinh dưỡng',
            children: [
              PortionInput(controller: _portion, unit: _item.facts.unit, errorText: portionError),
              const SizedBox(height: AppSpacing.md),
              NutrientTable(
                portion: portion,
                per100: _item.facts.per100,
                portionLabel: portionAmount == null ? 'Khẩu phần' : '${formatDecimal(portionAmount)} $unitLabel',
                unitLabel: unitLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AddToNoteCard(item: _item, portion: portionAmount),
          const SizedBox(height: AppSpacing.md),
          AttributionFooter(attribution: _item.attribution),
        ],
      ),
    );
  }
}
