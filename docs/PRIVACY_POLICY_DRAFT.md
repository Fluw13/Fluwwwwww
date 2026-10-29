# BẢN NHÁP — cần người có chuyên môn pháp lý xem xét

> Bản nháp chính sách quyền riêng tư của ứng dụng Fluw. Chưa có giá trị pháp lý, chưa được công bố.
> Chỉ mô tả các luồng dữ liệu đã đối chiếu trong code tại nhánh `chore/legal-security-hardening` (29/10/2026). Khi app thay đổi (thêm tài khoản, lịch sử, dữ liệu sức khỏe…) phải cập nhật lại toàn bộ tài liệu này.

---

# Chính sách quyền riêng tư của Fluw

Cập nhật lần cuối: [NGÀY CÔNG BỐ]

## 1. Fluw là gì

Fluw là ứng dụng giúp bạn tra cứu thông tin thực phẩm bằng mã vạch hoặc tên sản phẩm, hiển thị dữ liệu dinh dưỡng từ Open Food Facts và phần phân tích tham khảo do AI (Google Gemini) tạo ra.

## 2. Dữ liệu Fluw xử lý

### 2.1. Camera

- Fluw xin quyền sử dụng camera chỉ để đọc mã vạch trên bao bì sản phẩm.
- Việc nhận diện mã vạch diễn ra trên thiết bị của bạn thông qua thư viện quét mã vạch tích hợp trong app. Fluw không lưu và không gửi hình ảnh từ camera tới máy chủ Fluw. [CẦN XÁC MINH: chính sách dữ liệu của thư viện `mobile_scanner` / Google ML Kit trên Android và iOS.]

### 2.2. Mã vạch hoặc từ khóa tìm kiếm

- Khi bạn quét mã vạch hoặc nhập tên sản phẩm, **chỉ chuỗi mã vạch hoặc từ khóa đó** được gửi tới máy chủ Fluw (lưu trữ trên dịch vụ Render).
- Fluw hiện **không** yêu cầu tạo tài khoản, **không** thu thập họ tên, email, số điện thoại hay vị trí, và **không** lưu lịch sử tra cứu trên thiết bị hoặc trên máy chủ.

### 2.3. Bên thứ ba nhận dữ liệu

| Bên nhận | Dữ liệu gửi đi | Mục đích |
|---|---|---|
| Open Food Facts (openfoodfacts.org) | Mã vạch hoặc từ khóa bạn tra cứu (máy chủ Fluw gửi thay bạn) | Lấy thông tin sản phẩm |
| Google Gemini API | Dữ liệu sản phẩm công khai lấy từ Open Food Facts (tên, thương hiệu, thành phần, chỉ số dinh dưỡng) | Tạo phần phân tích tham khảo |
| Render (nhà cung cấp hosting) | Yêu cầu HTTP tới máy chủ Fluw | Vận hành máy chủ |

Fluw không gửi thông tin nhận dạng cá nhân của bạn tới Google Gemini.

### 2.4. Bộ nhớ đệm trên máy chủ

Để giảm số lần gọi tới Open Food Facts và Google, máy chủ Fluw lưu tạm kết quả tra cứu sản phẩm (dữ liệu sản phẩm và phân tích AI, không kèm thông tin về người tra cứu) trong bộ nhớ tối đa 24 giờ. Bộ nhớ đệm này không được ghi ra file hay cơ sở dữ liệu.

### 2.5. Nhật ký kỹ thuật

Máy chủ Fluw và nhà cung cấp hosting có thể ghi nhật ký kỹ thuật (ví dụ: thời điểm, đường dẫn yêu cầu, địa chỉ IP) phục vụ vận hành, chống lạm dụng (giới hạn số yêu cầu mỗi phút theo địa chỉ IP) và xử lý sự cố. [CẦN XÁC MINH: thời gian lưu nhật ký theo cấu hình Render.]

## 3. Nội dung do AI tạo

Phần "Zero Deep Think" và điểm số là nội dung do AI tạo ra, chỉ mang tính tham khảo, không thay thế tư vấn của bác sĩ hoặc chuyên gia dinh dưỡng. Luôn đọc nhãn sản phẩm, đặc biệt nếu bạn bị dị ứng.

## 4. Quyền của bạn

Vì Fluw hiện không lưu dữ liệu cá nhân gắn với bạn, phần lớn yêu cầu truy cập/xóa dữ liệu không phát sinh. Nếu có câu hỏi, vui lòng liên hệ: [EMAIL LIÊN HỆ].

## 5. Trẻ em

[CẦN QUYẾT ĐỊNH: độ tuổi tối thiểu sử dụng app. Lưu ý điều khoản Gemini API yêu cầu người sử dụng API từ 18 tuổi trở lên.]

## 6. Thay đổi chính sách

Khi Fluw thêm tính năng mới có xử lý dữ liệu cá nhân (ví dụ tài khoản, lịch sử, nhật ký ăn uống, thông tin dị ứng), chính sách này sẽ được cập nhật và bạn sẽ được yêu cầu đồng ý trước khi dữ liệu được thu thập.

## 7. Liên hệ

[TÊN CHỦ DỰ ÁN / ĐƠN VỊ] — [EMAIL LIÊN HỆ]
