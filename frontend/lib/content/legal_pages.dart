import 'info_page.dart';

/// In-app texts for the Account screen. The full terms and privacy policy are
/// still drafts awaiting legal review, so the app shows a status or a factual
/// summary instead of presenting a draft as final.
class LegalPages {
  const LegalPages._();

  static const InfoPage terms = InfoPage(
    title: 'Điều khoản sử dụng',
    notice: 'Điều khoản sử dụng đang được hoàn thiện và sẽ được công bố trước khi Fluw phát hành chính thức.',
    sections: [
      InfoSection(
        heading: 'Trong lúc chờ bản chính thức',
        paragraphs: [
          'Fluw là công cụ tra cứu thông tin thực phẩm và hiện không yêu cầu tài khoản.',
          'Thông tin sản phẩm và phân tích của Zero chỉ để tham khảo. Hãy luôn đọc nhãn trên bao bì, '
              'đặc biệt khi bạn bị dị ứng hoặc đang theo chế độ ăn đặc biệt.',
        ],
      ),
    ],
  );

  static const InfoPage privacy = InfoPage(
    title: 'Chính sách quyền riêng tư',
    notice: 'Đây là bản tóm tắt cách Fluw đang xử lý dữ liệu. Bản chính sách đầy đủ đang được hoàn thiện.',
    sections: [
      InfoSection(
        heading: 'Fluw không cần tài khoản',
        paragraphs: [
          'Fluw không thu thập tên, email, số điện thoại, vị trí hay danh bạ của bạn.',
        ],
      ),
      InfoSection(
        heading: 'Camera',
        paragraphs: [
          'Camera chỉ bật khi bạn mở màn quét. Hình ảnh được xử lý ngay trên điện thoại để đọc mã vạch, '
              'không được gửi đi hay lưu lại.',
        ],
      ),
      InfoSection(
        heading: 'Khi bạn tra cứu',
        paragraphs: [
          'Mã vạch hoặc tên sản phẩm bạn nhập được gửi tới máy chủ Fluw và Open Food Facts để tìm sản phẩm.',
          'Thông tin của sản phẩm (không phải thông tin của bạn) được gửi tới Google Gemini để Zero phân tích.',
          'Máy chủ Fluw dùng địa chỉ IP trong thời gian ngắn để giới hạn số lần tra cứu, chống lạm dụng.',
          'Máy chủ giữ tạm kết quả tra cứu theo mã vạch hoặc từ khóa (mặc định 24 giờ, không gắn với bạn) '
              'để trả lời nhanh hơn.',
          'Nhà cung cấp hosting của máy chủ có thể ghi nhật ký kỹ thuật như địa chỉ IP, thời gian truy cập '
              'và đường dẫn yêu cầu (có thể chứa mã vạch hoặc từ khóa bạn tra).',
        ],
      ),
      InfoSection(
        heading: 'Lịch sử và cài đặt',
        paragraphs: [
          'Lịch sử quét và tìm kiếm chỉ nằm trong bộ nhớ khi ứng dụng đang mở. '
              'Lịch sử không được ghi xuống máy, không gửi đi đâu, và mất khi bạn đóng ứng dụng.',
          'Lựa chọn giao diện Sáng / Tối được lưu trên điện thoại của bạn để lần sau mở lại vẫn giữ nguyên.',
        ],
      ),
    ],
  );

  static const InfoPage dataSources = InfoPage(
    title: 'Nguồn dữ liệu và giấy phép',
    sections: [
      InfoSection(
        heading: 'Thông tin sản phẩm',
        paragraphs: [
          'Dữ liệu sản phẩm và dinh dưỡng lấy từ Open Food Facts (openfoodfacts.org), '
              'cung cấp theo giấy phép Open Database License (ODbL).',
          'Dữ liệu do cộng đồng đóng góp nên có thể thiếu hoặc chưa chính xác. Fluw ghi rõ khi thiếu, '
              'ví dụ chỉ số dinh dưỡng chưa có được ghi "—".',
        ],
      ),
      InfoSection(
        heading: 'Ảnh sản phẩm',
        paragraphs: [
          'Ảnh sản phẩm do cộng tác viên Open Food Facts chụp, theo giấy phép Creative Commons BY-SA.',
        ],
      ),
      InfoSection(
        heading: 'Phân tích',
        paragraphs: [
          'Điểm và phần phân tích do Zero tạo ra bằng Google Gemini, dựa trên dữ liệu sản phẩm ở trên.',
        ],
      ),
      InfoSection(
        heading: 'Phông chữ và thư viện',
        paragraphs: [
          'Giao diện dùng phông Be Vietnam Pro (SIL Open Font License). '
              'Danh sách đầy đủ có trong mục "Giấy phép mã nguồn mở".',
        ],
      ),
    ],
  );

  static const InfoPage aiDisclaimer = InfoPage(
    title: 'Về phân tích của Zero',
    sections: [
      InfoSection(
        heading: 'Zero là gì',
        paragraphs: [
          'Zero là trợ lý AI của Fluw. Zero đọc thông tin dinh dưỡng của sản phẩm, chấm điểm từ 0 đến 100 '
              'và giải thích ngắn gọn.',
        ],
      ),
      InfoSection(
        heading: 'Giới hạn',
        paragraphs: [
          'Nội dung do AI tạo, chỉ mang tính tham khảo và có thể sai.',
          'Đây không phải chẩn đoán hay tư vấn y tế. Nếu bạn có vấn đề sức khỏe, hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng.',
          'Phần "Có thể chứa thêm" là gợi ý của AI, không thay cho danh sách chất gây dị ứng in trên bao bì.',
        ],
      ),
      InfoSection(
        heading: 'Khi Zero không phân tích được',
        paragraphs: [
          'Nếu dịch vụ AI tạm thời không trả lời, Fluw vẫn hiện thông tin sản phẩm và dinh dưỡng, '
              'kèm lý do chưa có điểm.',
        ],
      ),
    ],
  );
}
