import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/ai_unavailable_card.dart';

void main() {
  test('AiUnavailableCard có lý do riêng cho từng mã lỗi AI', () {
    expect(AiUnavailableCard.reasonFor('AI_RATE_LIMITED'), contains('hết lượt'));
    expect(AiUnavailableCard.reasonFor('AI_NOT_CONFIGURED'), contains('chưa được bật'));
    expect(AiUnavailableCard.reasonFor('AI_INVALID_RESPONSE'), contains('không hợp lệ'));
    expect(AiUnavailableCard.reasonFor(null), contains('tạm thời không phản hồi'));
  });
}
