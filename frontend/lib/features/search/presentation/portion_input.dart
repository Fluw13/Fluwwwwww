import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

const double minPortion = 1;
const double maxPortion = 2000;

/// The amount eaten, typed by the user: Fluw never guesses portions (CLAUDE.md).
/// Returns null to [onChanged] while the text is not a valid amount.
class PortionInput extends StatelessWidget {
  const PortionInput({required this.controller, required this.unit, required this.errorText, super.key});

  final TextEditingController controller;
  final QuantityUnit unit;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // The iPhone number pad has no Done key, and the add bar pinned under the page sits behind the keyboard.
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: 'Khẩu phần bạn ăn',
        suffixText: quantityUnitLabel(unit),
        errorText: errorText,
        helperText: 'Nhập số ${quantityUnitLabel(unit)} thực tế, ví dụ 150.',
      ),
    );
  }
}

/// The portion in [unit], or null with the reason shown under the field.
(double?, String?) parsePortion(String text, QuantityUnit unit) {
  final value = parseDecimal(text);
  if (value == null || value < minPortion || value > maxPortion) {
    return (null, 'Nhập từ ${formatDecimal(minPortion)} đến ${formatWhole(maxPortion)} ${quantityUnitLabel(unit)}.');
  }
  return (value, null);
}
