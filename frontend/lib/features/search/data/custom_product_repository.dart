import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/features/search/data/custom_product_mapper.dart';
import 'package:fluw/features/search/domain/custom_product.dart';
import 'package:fluw/features/search/domain/vietnamese_text.dart';

/// Another stored product already has the barcode being saved.
final class DuplicateBarcodeException implements Exception {
  const DuplicateBarcodeException(this.existingName);

  final String existingName;
}

final class CustomProductRepository {
  CustomProductRepository(this._database, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;

  static const int searchLimit = 20;

  Future<CustomProduct?> findById(String id) async {
    final row = await (_database.select(
      _database.customProducts,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : customProductFromRow(row);
  }

  /// Finds the product whether the barcode is read with or without leading zeros: a UPC-A label scanned as EAN-13
  /// gets one more 0 in front.
  Future<CustomProduct?> findByBarcode(String code) async =>
      (await _rowsWithBarcode(code)).map(customProductFromRow).nonNulls.firstOrNull;

  Future<List<CustomProductRow>> _rowsWithBarcode(String code) =>
      (_database.select(_database.customProducts)..where((table) => table.barcode.isIn(_barcodeForms(code)))).get();

  /// Every word of [query] must appear in the name or brand, with or without Vietnamese marks; newest first. Reads
  /// every row: a personal list stays small, and SQLite cannot drop Vietnamese marks itself.
  Future<List<CustomProduct>> search(String query) async {
    final words = foldVietnamese(query).split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) {
      return const [];
    }
    final rows = await (_database.select(
      _database.customProducts,
    )..orderBy([(table) => OrderingTerm.desc(table.updatedAtUtcMs)])).get();
    return [
      for (final product in rows.map(customProductFromRow).nonNulls)
        if (_matches(product, words)) product,
    ].take(searchLimit).toList();
  }

  /// Adds the product, or replaces the stored one with the same id. Throws [DuplicateBarcodeException] when another
  /// product already has its barcode, so a scan never has two answers. Rows are checked as stored, so one this version
  /// cannot read still names itself instead of failing on the unique column.
  Future<void> save(CustomProduct product) => _database.transaction(() async {
    if (product.barcode case final code?) {
      final other = (await _rowsWithBarcode(code)).where((row) => row.id != product.id).firstOrNull;
      if (other != null) {
        throw DuplicateBarcodeException(other.name);
      }
    }
    await _database
        .into(_database.customProducts)
        .insertOnConflictUpdate(customProductToRow(product, updatedAt: _clock()));
  });

  /// Foods already logged keep their numbers: the diary copies them.
  Future<void> delete(String id) =>
      (_database.delete(_database.customProducts)..where((table) => table.id.equals(id))).go();

  static bool _matches(CustomProduct product, List<String> words) {
    final text = foldVietnamese('${product.name} ${product.brand ?? ''}');
    return words.every(text.contains);
  }

  static List<String> _barcodeForms(String code) {
    final digits = code.replaceFirst(RegExp('^0+'), '');
    return {
      code,
      for (final length in const [8, 12, 13, 14])
        if (digits.length <= length) digits.padLeft(length, '0'),
    }.toList();
  }
}
