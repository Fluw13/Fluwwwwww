import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/database/row_id.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/data/custom_product_repository.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:fluw/features/search/domain/custom_product.dart';
import 'package:fluw/features/search/domain/custom_product_draft.dart';
import 'package:fluw/features/search/domain/nutrient_plausibility.dart';
import 'package:fluw/features/search/presentation/custom_product_labels.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// Opens the form above the tab bar and returns the saved product, or null when the user left without saving.
/// [product] edits a stored one; [barcode] fills in the code that was just scanned.
Future<CustomProduct?> openCustomProductForm(BuildContext context, {CustomProduct? product, String? barcode}) {
  return Navigator.of(context, rootNavigator: true).push<CustomProduct>(
    MaterialPageRoute(
      builder: (_) => CustomProductFormScreen(product: product, barcode: barcode),
    ),
  );
}

class CustomProductFormScreen extends ConsumerStatefulWidget {
  const CustomProductFormScreen({this.product, this.barcode, super.key});

  final CustomProduct? product;
  final String? barcode;

  @override
  ConsumerState<CustomProductFormScreen> createState() => _CustomProductFormScreenState();
}

class _CustomProductFormScreenState extends ConsumerState<CustomProductFormScreen> {
  late final CustomProductDraft _initial = switch (widget.product) {
    final product? => CustomProductDraft.fromProduct(product),
    null => CustomProductDraft(barcode: widget.barcode ?? ''),
  };
  late final TextEditingController _name = TextEditingController(text: _initial.name);
  late final TextEditingController _brand = TextEditingController(text: _initial.brand);
  late final TextEditingController _barcode = TextEditingController(text: _initial.barcode);
  late final TextEditingController _serving = TextEditingController(text: _initial.servingAmount);
  late final TextEditingController _package = TextEditingController(text: _initial.packageAmount);
  late final Map<Nutrient, TextEditingController> _nutrients = {
    for (final nutrient in Nutrient.values) nutrient: TextEditingController(text: _initial.nutrientText(nutrient)),
  };
  late QuantityUnit _unit = _initial.unit;
  late bool _perServing = _initial.labelPerServing;

  InvalidCustomProduct? _issues;
  String? _barcodeTaken;
  bool _saving = false;

  CustomProductDraft get _draft => CustomProductDraft(
    name: _name.text,
    brand: _brand.text,
    barcode: _barcode.text,
    unit: _unit,
    labelPerServing: _perServing,
    servingAmount: _serving.text,
    packageAmount: _package.text,
    nutrients: {for (final MapEntry(:key, :value) in _nutrients.entries) key: value.text},
  );

  @override
  void dispose() {
    for (final controller in [_name, _brand, _barcode, _serving, _package, ..._nutrients.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final result = _draft.build(id: widget.product?.id ?? newRowId());
    switch (result) {
      case InvalidCustomProduct():
        setState(() {
          _issues = result;
          _barcodeTaken = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiểm lại các ô báo đỏ.')));
      case ValidCustomProduct(:final product):
        setState(() => _issues = null);
        if (areNutrientsSuspect(product.facts.per100) && (!await _confirmSuspect() || !mounted)) {
          return;
        }
        await _store(product);
    }
  }

  Future<bool> _confirmSuspect() async {
    final keep = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Số liệu có vẻ chưa khớp'),
        content: const Text(
          'Năng lượng lệch nhiều so với protein, carb và chất béo, hoặc tổng của chúng quá 100 g. Hãy đối chiếu lại '
          'nhãn. Đồ uống có cồn hay kẹo không đường có thể lệch thật.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Kiểm lại')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Vẫn lưu')),
        ],
      ),
    );
    return keep ?? false;
  }

  Future<void> _store(CustomProduct product) async {
    final repository = ref.read(customProductRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await repository.save(product);
      if (mounted) {
        setState(() => _saving = false);
        navigator.pop(product);
      }
    } on DuplicateBarcodeException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _barcodeTaken = 'Mã này đã có trong sản phẩm tự nhập: ${error.existingName}.';
        });
      }
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'custom products'));
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(const SnackBar(content: Text('Chưa lưu được sản phẩm. Hãy thử lại.')));
      }
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Bỏ thông tin đã nhập?'),
        content: const Text('Sản phẩm chưa được lưu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Nhập tiếp')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Bỏ')),
        ],
      ),
    );
    if ((leave ?? false) && mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _fieldError(CustomProductField field) =>
      _issues?.fields[field] == null ? null : customProductIssueText(_issues!.fields[field]!, _unit);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = _unit.symbol;
    return PopScope(
      canPop: !_saving && _draft == _initial,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) {
          _confirmLeave();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.product == null ? 'Nhập từ nhãn' : 'Sửa sản phẩm')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Đang lưu…' : 'Lưu sản phẩm')),
          ),
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Chép số từ bảng dinh dưỡng trên bao bì. Ô để trống là nhãn không ghi. Sản phẩm chỉ lưu trên máy này.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            _Field(
              controller: _name,
              label: 'Tên sản phẩm',
              errorText: _fieldError(CustomProductField.name),
              onChanged: _changed,
            ),
            _Field(
              controller: _brand,
              label: 'Hãng (không bắt buộc)',
              errorText: _fieldError(CustomProductField.brand),
              onChanged: _changed,
            ),
            _Field(
              controller: _barcode,
              label: 'Mã vạch (không bắt buộc)',
              errorText: _barcodeTaken ?? _fieldError(CustomProductField.barcode),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                _barcodeTaken = null;
                _changed();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(header: true, child: Text('Đơn vị trên nhãn', style: theme.textTheme.titleMedium)),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<QuantityUnit>(
              segments: const [
                ButtonSegment(value: QuantityUnit.gram, label: Text('Khối lượng (g)')),
                ButtonSegment(value: QuantityUnit.milliliter, label: Text('Thể tích (ml)')),
              ],
              selected: {_unit},
              onSelectionChanged: (selection) => setState(() => _unit = selection.single),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(header: true, child: Text('Bảng dinh dưỡng ghi theo', style: theme.textTheme.titleMedium)),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text('100 $symbol')),
                const ButtonSegment(value: true, label: Text('1 khẩu phần')),
              ],
              selected: {_perServing},
              onSelectionChanged: (selection) => setState(() => _perServing = selection.single),
            ),
            const SizedBox(height: AppSpacing.md),
            _Field(
              controller: _serving,
              label: _perServing ? '1 khẩu phần ($symbol)' : '1 khẩu phần ($symbol, không bắt buộc)',
              errorText: _fieldError(CustomProductField.servingAmount),
              keyboardType: _decimalKeyboard,
              onChanged: _changed,
            ),
            _Field(
              controller: _package,
              label: 'Cả gói/chai ($symbol, không bắt buộc)',
              errorText: _fieldError(CustomProductField.packageAmount),
              keyboardType: _decimalKeyboard,
              onChanged: _changed,
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              header: true,
              child: Text(
                _perServing ? 'Số liệu trong 1 khẩu phần' : 'Số liệu trong 100 $symbol',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final nutrient in Nutrient.values)
              _Field(
                controller: _nutrients[nutrient]!,
                label: nutrient == Nutrient.energyKcal
                    ? '${nutrientLabel(nutrient)} (${nutrientUnit(nutrient)})'
                    : '${nutrientLabel(nutrient)} (${nutrientUnit(nutrient)}, không bắt buộc)',
                helperText: nutrientFieldHelper(nutrient),
                errorText: _issues?.nutrients[nutrient] == null
                    ? null
                    : customProductIssueText(_issues!.nutrients[nutrient]!, _unit),
                keyboardType: _decimalKeyboard,
                onChanged: _changed,
              ),
          ],
        ),
      ),
    );
  }

  /// Rebuilds so leaving the page asks first once something was typed.
  void _changed([String? _]) => setState(() {});

  static const TextInputType _decimalKeyboard = TextInputType.numberWithOptions(decimal: true);
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        // The pinned save button sits behind the keyboard, and the iPhone number pad has no Done key.
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
          errorText: errorText,
          errorMaxLines: 3,
        ),
      ),
    );
  }
}
