import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/portion_input.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:fluw/features/search/domain/card_nutrition.dart';
import 'package:fluw/features/search/domain/custom_product_item.dart';
import 'package:fluw/features/search/domain/food_assessment.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/serving_size.dart';
import 'package:fluw/features/search/presentation/add_to_note_bar.dart';
import 'package:fluw/features/search/presentation/attribution_footer.dart';
import 'package:fluw/features/search/presentation/custom_product_form_screen.dart';
import 'package:fluw/features/search/presentation/detail_notice.dart';
import 'package:fluw/features/search/presentation/food_detail_header.dart';
import 'package:fluw/features/search/presentation/nutrient_table.dart';
import 'package:fluw/features/search/presentation/pack_size_hint.dart';
import 'package:fluw/features/search/presentation/personal_check_card.dart';
import 'package:fluw/features/search/presentation/portion_chips.dart';
import 'package:fluw/features/search/presentation/portion_energy_card.dart';
import 'package:fluw/features/search/presentation/portion_nutrient_grid.dart';
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

  /// A serving, else the whole pack, else 100 (see [defaultPortion]).
  late String _defaultPortion = _defaultPortionFor(widget.item);
  late final TextEditingController _portion = TextEditingController(text: _defaultPortion);

  static String _defaultPortionFor(FoodItem item) => formatDecimal(defaultPortion(item));

  /// Search results from Open Food Facts lack allergens and the Vietnamese name; the full product has them.
  late bool _isLoadingFull = _needsFullProduct;
  bool _fullLoadFailed = false;

  /// The barcode lookup found nothing: the product left Open Food Facts after its search index was built.
  bool _productGone = false;

  bool get _needsFullProduct => !widget.isFullProduct && hasProductLookup(widget.item);

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
          _productGone = full == null;
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

  Future<void> _editCustomProduct(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final stored = await ref.read(customProductRepositoryProvider).findById(id);
    if (!mounted) {
      return;
    }
    if (stored == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Sản phẩm này không còn trên máy.')));
      return;
    }
    final saved = await openCustomProductForm(context, product: stored);
    if (saved != null && mounted) {
      setState(() => _item = foodItemFromCustomProduct(saved));
      final savedDefault = _defaultPortionFor(_item);
      if (_portion.text == _defaultPortion) {
        _portion.text = savedDefault;
      }
      _defaultPortion = savedDefault;
    }
  }

  Future<void> _deleteCustomProduct(String id) async {
    final name = _item.name ?? 'sản phẩm';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text('Xóa $name?'),
        content: const Text('Sản phẩm bị xóa khỏi máy. Các món đã ghi trong Nhật Ký vẫn giữ nguyên số liệu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Giữ lại')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xóa')),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(customProductRepositoryProvider).delete(id);
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'custom products'));
      messenger.showSnackBar(SnackBar(content: Text('Chưa xóa được $name.')));
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text('Đã xóa $name.')));
    if (mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limits = ref.watch(personalLimitsProvider);
    final customId = customProductIdOf(_item);
    final unit = _item.facts.unit;
    final (portionAmount, portionError) = parsePortion(_portion.text, unit);
    final portion = portionAmount == null ? null : _item.facts.forQuantity(portionAmount);
    final serving = servingPortion(_item);
    final package = packagePortion(_item);
    final allergens = checkAllergens(_item, limits);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết dinh dưỡng'),
        actions: [
          if (customId != null) ...[
            IconButton(
              onPressed: () => _editCustomProduct(customId),
              tooltip: 'Sửa sản phẩm',
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () => _deleteCustomProduct(customId),
              tooltip: 'Xóa sản phẩm',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
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
          FoodDetailHeader(item: _item),
          // The full check sits under the portion; a match is also said up here so it is never below the fold.
          if (allergens case AllergenMatch(:final severe))
            DetailNotice(
              icon: Icons.gpp_maybe_outlined,
              text: 'Có thành phần bạn dị ứng. Xem phần "Đối chiếu hồ sơ của bạn" bên dưới.',
              color: severe.isNotEmpty ? theme.colorScheme.error : theme.colorScheme.tertiary,
            ),
          if (_item.nutrientsSuspect)
            DetailNotice(
              icon: Icons.warning_amber_outlined,
              text: suspectNutrientsNote,
              color: theme.colorScheme.error,
            ),
          if (_productGone) DetailNotice(icon: Icons.history, text: productGoneNote, color: theme.colorScheme.tertiary),
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
          const SizedBox(height: AppSpacing.lg),
          Semantics(header: true, child: Text('Chỉ số dinh dưỡng', style: theme.textTheme.titleLarge)),
          const SizedBox(height: AppSpacing.sm),
          PortionChips(
            unit: unit,
            serving: serving,
            package: package,
            selected: portionAmount,
            onSelected: (amount) => _portion.text = formatDecimal(amount),
          ),
          const SizedBox(height: AppSpacing.md),
          if (serving == null && package == null) ...[
            PackSizeHint(
              text: printedServing(_item.servingSize) == null ? packSizeMissingHint(unit) : servingNotInUnitHint(unit),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          PortionInput(controller: _portion, unit: unit, errorText: portionError),
          const SizedBox(height: AppSpacing.md),
          PortionEnergyCard(portion: portionAmount, unit: unit, kcal: portion?[Nutrient.energyKcal]),
          const SizedBox(height: AppSpacing.md),
          PersonalCheckCard(
            allergens: allergens,
            shares: portion == null ? const [] : portionShares(portion, limits),
            limits: limits,
            portionLabel: portionAmount == null ? null : '${formatDecimal(portionAmount)} ${unit.symbol}',
            isLoadingAllergens: _isLoadingFull,
          ),
          const SizedBox(height: AppSpacing.md),
          PortionNutrientGrid(portion: portion),
          const SizedBox(height: AppSpacing.md),
          NutrientTable(
            facts: _item.facts,
            // USDA's carbohydrate is "by difference" and counts fibre; Open Food Facts follows EU labels without it.
            footnote: _item.source == FoodSource.usda ? 'USDA: carb gồm cả chất xơ.' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AttributionFooter(attribution: _item.attribution),
        ],
      ),
    );
  }
}
