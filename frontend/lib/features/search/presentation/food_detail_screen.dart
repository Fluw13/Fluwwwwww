import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/portion_input.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:fluw/features/search/domain/food_assessment.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/serving_size.dart';
import 'package:fluw/features/search/presentation/add_to_note_bar.dart';
import 'package:fluw/features/search/presentation/attribution_footer.dart';
import 'package:fluw/features/search/presentation/nutrient_table.dart';
import 'package:fluw/features/search/presentation/personal_check_card.dart';
import 'package:fluw/features/search/presentation/portion_chips.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({required this.item, this.isFullProduct = false, super.key});

  final FoodItem item;

  /// True when [item] already came from the barcode lookup, which has the allergens and the Vietnamese name.
  final bool isFullProduct;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  late FoodItem _item = widget.item;

  /// The pack's serving when it has one in the unit of the numbers, otherwise 100.
  late String _defaultPortion = _defaultPortionFor(widget.item);
  late final TextEditingController _portion = TextEditingController(text: _defaultPortion);

  static String _defaultPortionFor(FoodItem item) =>
      formatDecimal(servingAmount(item.servingSize, item.facts.unit) ?? 100);

  /// Search results from Open Food Facts lack allergens and the Vietnamese name; the full product has them.
  late bool _isLoadingFull = _needsFullProduct;
  bool _fullLoadFailed = false;

  bool get _needsFullProduct =>
      !widget.isFullProduct && widget.item.source == FoodSource.openFoodFacts && widget.item.barcode != null;

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
        // The full product may bring the pack's serving; a portion the user already typed is kept.
        final fullDefault = _defaultPortionFor(_item);
        if (_portion.text == _defaultPortion && fullDefault != _defaultPortion) {
          _defaultPortion = fullDefault;
          _portion.text = fullDefault;
        }
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
    final unitLabel = _item.facts.unit.symbol;
    final (portionAmount, portionError) = parsePortion(_portion.text, _item.facts.unit);
    final portion = portionAmount == null ? null : _item.facts.forQuantity(portionAmount);
    final imageUrl = _item.imageUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết dinh dưỡng')),
      bottomNavigationBar: AddToNoteBar(
        name: _item.name,
        sourceFoodId: _item.id,
        facts: _item.facts,
        portion: portionAmount,
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
            hasPortion: portionAmount != null,
            isLoadingAllergens: _isLoadingFull,
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Chỉ số dinh dưỡng',
            children: [
              PortionChips(
                unit: _item.facts.unit,
                serving: servingAmount(_item.servingSize, _item.facts.unit),
                selected: portionAmount,
                onSelected: (amount) => _portion.text = formatDecimal(amount),
              ),
              const SizedBox(height: AppSpacing.md),
              PortionInput(controller: _portion, unit: _item.facts.unit, errorText: portionError),
              const SizedBox(height: AppSpacing.md),
              NutrientTable(
                portion: portion,
                per100: _item.facts.per100,
                portionLabel: portionAmount == null ? 'Khẩu phần' : '${formatDecimal(portionAmount)} $unitLabel',
                unitLabel: unitLabel,
              ),
              // USDA's carbohydrate is "by difference" and counts fibre; Open Food Facts follows EU labels without it.
              if (_item.source == FoodSource.usda) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'USDA: carb gồm cả chất xơ.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AttributionFooter(attribution: _item.attribution),
        ],
      ),
    );
  }
}
