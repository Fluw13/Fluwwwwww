/// One part of the policy. Every text is written exactly as in PRIVACY.md at the repository root, `**bold**` marks
/// included, and a test rebuilds that file from these parts so the app and the public page never drift apart.
sealed class PolicyBlock {
  const PolicyBlock();
}

final class PolicyParagraph extends PolicyBlock {
  const PolicyParagraph(this.text);

  final String text;
}

final class PolicyBullets extends PolicyBlock {
  const PolicyBullets(this.items);

  final List<String> items;
}

/// The table of what leaves the phone, one row per occasion.
final class PolicyDataFlows extends PolicyBlock {
  const PolicyDataFlows(this.rows);

  static const String whenHeader = 'Khi nào';
  static const String whatHeader = 'Gửi gì';
  static const String whereHeader = 'Tới đâu';

  final List<PolicyDataFlow> rows;
}

final class PolicyDataFlow {
  const PolicyDataFlow({required this.when, required this.what, required this.where});

  final String when;
  final String what;
  final String where;
}

final class PolicySection {
  const PolicySection(this.title, this.blocks);

  final String title;
  final List<PolicyBlock> blocks;
}

abstract final class PrivacyPolicy {
  static const String title = 'Chính sách quyền riêng tư và điều khoản sử dụng Fluw';
  static const String version = 'Phiên bản 2, áp dụng từ ngày 28/11/2026.';
  static const String intro =
      'Fluw là ứng dụng tra cứu dinh dưỡng và ghi nhật ký ăn uống. Fluw do một nhà phát triển cá nhân làm '
      '(GitHub: Fluw13).';
  static const String contactLabel = 'Liên hệ, góp ý hoặc yêu cầu về dữ liệu';
  static const String issuesUrl = 'https://github.com/Fluw13/Fluwwwwww/issues';

  /// Where the same text can be read without the app.
  static const String publicUrl = 'https://github.com/Fluw13/Fluwwwwww/blob/main/PRIVACY.md';

  static const List<PolicySection> sections = [
    PolicySection('1. Fluw dành cho ai', [
      PolicyBullets([
        'Người từ **18 tuổi** trở lên, ở Việt Nam.',
        'Fluw **không phải thiết bị y tế** và không chẩn đoán, điều trị, chữa khỏi hay phòng ngừa bệnh nào. Mọi con số '
            'chỉ là ước tính tham khảo. Hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng trước khi thay đổi chế độ ăn, nhất '
            'là khi bạn có bệnh nền, đang mang thai, cho con bú, có bệnh thận hoặc đang điều trị rối loạn ăn uống.',
      ]),
    ]),
    PolicySection('2. Dữ liệu chỉ lưu trên điện thoại của bạn', [
      PolicyBullets([
        'Hồ sơ: tên gọi (nếu nhập), ngày sinh, giới tính, chiều cao, cân nặng, mục tiêu, mức vận động, hình thức tập, '
            'có mang thai hoặc cho con bú, bệnh nền, dị ứng, chế độ ăn và thói quen.',
        'Nhật ký ăn uống, lịch sử cân nặng, sản phẩm bạn tự nhập từ nhãn, giờ nhắc, lịch sử tìm kiếm gần đây, các lựa '
            'chọn đồng ý của bạn.',
      ]),
      PolicyParagraph(
        'Đây là dữ liệu sức khỏe, thuộc nhóm dữ liệu cá nhân nhạy cảm. Fluw chỉ dùng chúng trên máy để tính chỉ tiêu, '
        'gợi ý, cảnh báo và nhắc nhở. **Fluw không gửi chúng lên máy chủ và không ai khác nhận được chúng.** Fluw chỉ '
        'lưu khi bạn đồng ý ở lần lưu hồ sơ đầu tiên.',
      ),
      PolicyParagraph(
        'Nếu bạn bật sao lưu của Android (Google) hoặc iCloud, hệ điều hành có thể sao lưu dữ liệu của app vào tài '
        'khoản của chính bạn; việc này do bạn và Google/Apple quản lý.',
      ),
    ]),
    PolicySection('3. Dữ liệu rời khỏi điện thoại', [
      PolicyDataFlows([
        PolicyDataFlow(
          when: 'Bạn tìm món hoặc quét mã vạch',
          what: 'Từ khóa hoặc mã vạch, địa chỉ IP',
          where:
              'Máy chủ Fluw (Render, Hoa Kỳ). Máy chủ gửi tiếp từ khóa/mã vạch (không kèm IP của bạn) tới Open Food '
              'Facts (Pháp) và USDA FoodData Central (Hoa Kỳ).',
        ),
        PolicyDataFlow(
          when: 'Mở app hoặc quay lại app',
          what: 'Một yêu cầu kiểm tra máy chủ, không kèm dữ liệu',
          where: 'Máy chủ Fluw',
        ),
        PolicyDataFlow(
          when: 'Xem ảnh sản phẩm',
          what: 'Địa chỉ IP (như khi mở một trang web)',
          where: 'Open Food Facts',
        ),
        PolicyDataFlow(
          when: 'Bạn dùng nhận diện món qua ảnh (chỉ khi đồng ý)',
          what: 'Ảnh món ăn đã xóa thông tin vị trí và thời gian chụp, địa chỉ IP',
          where: 'Máy chủ Fluw, rồi Google Gemini (Hoa Kỳ)',
        ),
        PolicyDataFlow(
          when: 'Quét mã vạch trên Android',
          what: 'Thông tin thiết bị và hiệu năng của bộ đọc mã (không có hình camera)',
          where: 'Google (ML Kit)',
        ),
      ]),
      PolicyBullets([
        'Máy chủ Fluw **không lưu ảnh** và không gắn từ khóa với người dùng. Kết quả tra cứu được giữ tạm trong bộ nhớ '
            'máy chủ tối đa 24 giờ để trả lời nhanh hơn.',
        'Render (nhà cung cấp máy chủ) ghi nhật ký truy cập gồm địa chỉ IP, thời gian và đường dẫn yêu cầu (có thể gồm '
            'từ khóa tìm kiếm hoặc mã vạch). Fluw chỉ xem nhật ký này để xử lý sự cố.',
        'Nhận diện ảnh dùng gói miễn phí của Google Gemini: Google có thể lưu ảnh, cho người xem lại và dùng để cải '
            'thiện sản phẩm của họ. Đừng chụp người, giấy tờ hay thông tin cá nhân. Rút lại đồng ý không xóa được '
            'những ảnh đã gửi trước đó khỏi Google.',
        'Fluw không bán dữ liệu, không quảng cáo, không dùng công cụ theo dõi hay phân tích hành vi.',
      ]),
    ]),
    PolicySection('4. Cơ sở xử lý', [
      PolicyBullets([
        'Sự đồng ý của bạn: lưu dữ liệu sức khỏe trên máy, gửi ảnh để nhận diện.',
        'Thực hiện yêu cầu của bạn: tra cứu thực phẩm và mã vạch.',
      ]),
    ]),
    PolicySection('5. Quyền của bạn', [
      PolicyBullets([
        'Xem và sửa hồ sơ trong tab Hồ Sơ; xóa từng món trong Nhật Ký.',
        'Xóa toàn bộ dữ liệu trên máy: Hồ Sơ → "Xóa toàn bộ dữ liệu trên máy", hoặc gỡ app.',
        'Rút lại đồng ý gửi ảnh: trong màn Quét Món, chế độ Ảnh món ăn.',
        'Rút lại đồng ý lưu dữ liệu sức khỏe: xóa toàn bộ dữ liệu như trên.',
        'Hỏi, góp ý hoặc khiếu nại: $issuesUrl (đừng đăng thông tin sức khỏe của bạn ở đó, vì trang này công khai).',
      ]),
    ]),
    PolicySection('6. Bảo mật', [
      PolicyBullets([
        'Mọi kết nối tới máy chủ dùng HTTPS.',
        'Dữ liệu trên máy nằm trong vùng riêng của app, các app khác không đọc được.',
      ]),
    ]),
    PolicySection('7. Nguồn dữ liệu và giấy phép', [
      PolicyBullets([
        'Open Food Facts (giấy phép ODbL, ảnh CC BY-SA), © các cộng tác viên Open Food Facts.',
        'USDA FoodData Central (phạm vi công cộng, CC0).',
        'Tên món do AI (Google Gemini) gợi ý có thể sai; số liệu dinh dưỡng luôn lấy từ Open Food Facts hoặc USDA, '
            'không lấy từ AI.',
        'Danh sách đầy đủ giấy phép: trong app, Hồ Sơ → Về Fluw.',
      ]),
    ]),
    PolicySection('8. Điều khoản sử dụng', [
      PolicyBullets([
        'Fluw được cung cấp miễn phí, "như hiện có", để tham khảo. Dữ liệu từ nguồn mở có thể thiếu hoặc sai; luôn '
            'đọc nhãn trên bao bì, nhất là khi bạn bị dị ứng.',
        'Không dùng Fluw thay cho chẩn đoán, điều trị hay chỉ định của bác sĩ.',
        'Không dùng máy chủ Fluw cho mục đích khác ngoài app (ví dụ gọi tự động hàng loạt).',
      ]),
    ]),
    PolicySection('9. Thay đổi chính sách', [
      PolicyParagraph('Khi chính sách thay đổi, phiên bản và ngày áp dụng ở đầu trang sẽ đổi, và app sẽ báo cho bạn.'),
    ]),
  ];
}
