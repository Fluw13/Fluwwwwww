import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';

/// Asks for today's weight; returns `null` when cancelled.
Future<double?> showRecordWeightDialog(BuildContext context, {required double currentKg}) {
  return showDialog<double>(
    context: context,
    builder: (context) => _RecordWeightDialog(currentKg: currentKg),
  );
}

class _RecordWeightDialog extends StatefulWidget {
  const _RecordWeightDialog({required this.currentKg});

  final double currentKg;

  @override
  State<_RecordWeightDialog> createState() => _RecordWeightDialogState();
}

class _RecordWeightDialogState extends State<_RecordWeightDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: formatDecimal(widget.currentKg, maxFractionDigits: 2),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final weightKg = parseDecimal(_controller.text);
    if (weightKg == null || weightKg < minWeightKg || weightKg > maxWeightKg) {
      setState(() => _error = 'Cân nặng từ ${minWeightKg.round()} đến ${maxWeightKg.round()} kg.');
      return;
    }
    Navigator.of(context).pop(weightKg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // The keyboard opens at once (autofocus); with large text the dialog must scroll instead of overflowing.
      scrollable: true,
      title: const Text('Ghi cân nặng hôm nay'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(labelText: 'Cân nặng', suffixText: 'kg', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
        TextButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}
