import 'package:flutter/material.dart';

/// A section heading, announced as a heading by screen readers.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.3, fontWeight: FontWeight.w700)),
    );
  }
}
