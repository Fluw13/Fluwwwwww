import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/portion_limits.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';

/// The amount eaten, typed by the user: Fluw never guesses portions (CLAUDE.md). Read it with [parsePortion].
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
        suffixText: unit.symbol,
        errorText: errorText,
        helperText: 'Nhập số ${unit.symbol} thực tế, ví dụ 150.',
      ),
    );
  }
}

/// The portion in [unit], or null with the reason shown under the field. The range is written "1–2000", not
/// "2,000", which Vietnamese readers take for 2.
(double?, String?) parsePortion(String text, QuantityUnit unit) {
  final value = parseDecimal(text);
  if (value == null || !isValidPortion(value)) {
    return (
      null,
      'Khẩu phần phải trong khoảng ${formatDecimal(minPortion)}–${formatDecimal(maxPortion)} ${unit.symbol}.',
    );
  }
  return (value, null);
}
