import '../../models/analysis/product_analysis.dart';

/// What to tell the user when Zero could not explain the score, and whether
/// asking again can help.
class AiErrorText {
  const AiErrorText._();

  static String message(AiErrorCode code) {
    return switch (code) {
      AiErrorCode.notConfigured =>
        'Tính năng giải thích bằng AI chưa được bật trên máy chủ.',
      AiErrorCode.unavailable =>
        'Zero tạm thời không phản hồi. Bạn có thể thử lại.',
      AiErrorCode.invalidResponse => 'Zero trả lời không đúng định dạng nên Fluw đã bỏ qua để tránh hiển thị thông tin sai. Bạn có thể thử lại.',
      AiErrorCode.rateLimited =>
        'Dịch vụ AI đang tạm hết lượt. Vui lòng thử lại sau ít phút.',
      AiErrorCode.dailyLimit => 'Fluw đã dùng hết lượt giải thích bằng AI của hôm nay. Vui lòng quay lại vào ngày mai.',
      AiErrorCode.unknown =>
        'Zero chưa giải thích được lúc này. Bạn có thể thử lại.',
    };
  }

  /// No retry when the server is not set up for AI or today's quota is used.
  static bool canRetry(AiErrorCode code) {
    return switch (code) {
      AiErrorCode.notConfigured || AiErrorCode.dailyLimit => false,
      _ => true,
    };
  }
}
