enum QuantityUnit {
  gram('g'),
  milliliter('ml');

  const QuantityUnit(this.symbol);

  /// As printed on labels and in the app. Storage uses its own fixed keys, never this.
  final String symbol;
}
