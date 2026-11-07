import '../models/fns_result.dart';

/// Every user-facing text about the Fluw Nutrition Score. Wording stays neutral: it describes the
/// nutrition profile and the data, never accuses a product or claims health or safety effects.
class FnsCopy {
  const FnsCopy._();

  static const String name = 'Fluw Nutrition Score';
  static const String breakdownTitle = 'Cách Fluw tính điểm';
  static const String breakdownIntro =
      'Các chất có dấu (+) làm tăng tổng điểm; rau củ quả, chất đạm, chất xơ (−) làm giảm. '
      'Tổng càng thấp thì Fluw Nutrition Score càng cao.';
  static const String outOfScopeTitle = 'Fluw chưa chấm điểm nhóm sản phẩm này';
  static const String missingDataTitle = 'Chưa đủ dữ liệu để chấm điểm';
  static const String unknownPoints = 'Chưa rõ';
  static const String notCounted = 'Không tính';

  static const Map<String, String> _categories = {
    'C1': 'Đồ uống (không phải sữa)',
    'C1D': 'Sữa và đồ uống từ sữa',
    'C2': 'Thực phẩm đóng gói',
    'C2D': 'Thực phẩm từ sữa',
    'C3': 'Dầu ăn và chất phết từ dầu',
    'C3D': 'Phô mai',
  };

  static const Map<String, String> _components = {
    'energy': 'Năng lượng',
    'saturated_fat': 'Chất béo bão hòa',
    'total_sugars': 'Đường tổng',
    'sodium': 'Natri',
    'fvnl': 'Rau, củ, quả, hạt, đậu',
    'protein': 'Chất đạm',
    'fiber': 'Chất xơ',
  };

  static const Map<String, String> _fields = {
    'energy_kj': 'năng lượng',
    'saturated_fat_g': 'chất béo bão hòa',
    'total_sugars_g': 'đường tổng',
    'sodium_mg': 'natri',
    'protein_g': 'chất đạm',
    'fiber_g': 'chất xơ',
    'fvnl.percent': 'tỷ lệ rau, củ, quả, hạt, đậu',
    'fvnl.concentrated': 'dạng cô đặc của rau củ quả',
  };

  static const Map<String, String> _reasons = {
    'OUT_OF_SCOPE': 'Phiên bản hiện tại không chấm đồ uống có cồn, thực phẩm cho trẻ nhỏ, thực phẩm bổ sung, nước lọc và các loại bột hoặc siro pha.',
    'CATEGORY_UNRESOLVED': 'Chưa xác định được nhóm sản phẩm để so sánh.',
    'BASIS_MISMATCH': 'Chưa rõ số liệu dinh dưỡng được ghi trên 100 g hay 100 ml.',
    'VALUE_INVALID': 'Một số số liệu dinh dưỡng có giá trị không hợp lệ.',
    'BASELINE_NUTRIENT_MISSING': 'Thiếu số liệu dinh dưỡng bắt buộc.',
    'RATING_AMBIGUOUS': 'Dữ liệu còn thiếu có thể làm thay đổi mức điểm, nên Fluw chưa đưa ra con số.',
  };

  static const String _fallbackReason = 'Máy chủ chưa trả kết quả chấm điểm cho sản phẩm này.';

  static const Map<String, String> _limitations = {
    'SOURCE_UNVERIFIED': 'Dữ liệu cộng đồng (Open Food Facts), chưa được đối chiếu với nhãn sản phẩm.',
    'FVNL_ESTIMATED': 'Tỷ lệ rau, củ, quả, hạt, đậu được ước tính từ danh sách thành phần.',
    'RULES_NEEDS_REVIEW': 'Phương pháp chấm điểm đang được đối chiếu, kết quả có thể thay đổi.',
    'MODIFIER_DATA_MISSING': 'Một số số liệu còn thiếu nhưng không làm thay đổi mức điểm.',
    'VALUE_CENSORED': 'Một số giá trị trên nhãn chỉ ghi dạng "dưới x".',
  };

  static String? categoryLabel(String? category) => _categories[category];

  static String componentLabel(String component) => _components[component] ?? component;

  static String statusLabel(FnsStatus status) {
    switch (status) {
      case FnsStatus.verified:
        return 'Đã xác minh';
      case FnsStatus.provisional:
        return 'Tạm tính';
      case FnsStatus.notScored:
        return 'Chưa chấm';
    }
  }

  static String disclaimer(String? basis) {
    final String amount = basis == 'per_100ml' ? '100 ml' : '100 g';
    return 'Điểm hồ sơ dinh dưỡng tính trên $amount, dùng để so sánh với sản phẩm cùng nhóm. '
        'Không phải chẩn đoán hay chứng nhận an toàn.';
  }

  static bool isOutOfScope(FnsResult fns) => fns.reasonCodes.contains('OUT_OF_SCOPE');

  static String notScoredTitle(FnsResult fns) => isOutOfScope(fns) ? outOfScopeTitle : missingDataTitle;

  static String notScoredReason(FnsResult fns) {
    for (final String code in fns.reasonCodes) {
      final String? reason = _reasons[code];
      if (reason != null) return reason;
    }
    return _fallbackReason;
  }

  static String? missingFieldsText(List<String> fields) {
    if (fields.isEmpty) return null;
    return 'Còn thiếu: ${fields.map((field) => _fields[field] ?? field).join(', ')}.';
  }

  static List<String> limitationNotes(FnsResult fns) {
    return [for (final String code in fns.limitations) ?_limitations[code]];
  }
}
