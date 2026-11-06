# Chính sách quyền riêng tư — Fluw

> **BẢN NHÁP.** Cần điền các mục `<...>`, rà soát lại trước khi công bố và đăng tại một URL công khai để khai báo trên Google Play Console. Tài liệu này không phải tư vấn pháp lý.

Cập nhật lần cuối: `<ngày công bố>`

## 1. Fluw là gì

Fluw là ứng dụng tra cứu thông tin thực phẩm bằng mã vạch hoặc tên sản phẩm và hiển thị phân tích dinh dưỡng do trợ lý AI Zero tạo ra.

## 2. Dữ liệu chúng tôi xử lý

| Dữ liệu | Mục đích | Nơi xử lý |
| :--- | :--- | :--- |
| Hình ảnh từ camera | Đọc mã vạch | Chỉ xử lý trên thiết bị. Ứng dụng không gửi hay lưu hình ảnh. |
| Mã vạch hoặc tên sản phẩm bạn nhập | Tra cứu sản phẩm | Máy chủ Fluw, OpenFoodFacts |
| Thông tin sản phẩm (tên, thương hiệu, thành phần, chất gây dị ứng, phụ gia, dinh dưỡng) và bảng Điểm Fluw | Zero (AI) viết phần giải thích điểm, **chỉ khi bạn bấm "Hỏi Zero"** | Máy chủ Fluw, Google Gemini API |
| Địa chỉ IP | Chống lạm dụng (giới hạn số lần tra cứu) | Máy chủ Fluw, chỉ lưu tạm trong bộ nhớ |
| Lịch sử quét và tìm kiếm trong phiên (sản phẩm đã quét, từ khóa đã tìm; tối đa 20 mục mỗi loại) | Cho bạn mở lại nhanh trong lúc đang dùng | Chỉ nằm trong bộ nhớ khi ứng dụng đang mở. Không ghi xuống máy, không gửi đi, mất khi đóng ứng dụng. Bạn có thể xóa trong Tài khoản → Lịch sử. |
| Lựa chọn giao diện (Theo máy / Sáng / Tối) | Giữ giao diện bạn đã chọn cho lần mở sau | Chỉ lưu trên thiết bị của bạn, không gửi đi đâu. Gỡ ứng dụng hoặc xóa dữ liệu ứng dụng sẽ xóa lựa chọn này. |

Fluw **không** yêu cầu tài khoản và **không** thu thập tên, email, số điện thoại, vị trí hay danh bạ. Lịch sử tra cứu không được lưu lại sau khi đóng ứng dụng.

## 3. Bên thứ ba

- **OpenFoodFacts** nhận mã vạch hoặc tên sản phẩm để tra cứu. Xem chính sách của OpenFoodFacts tại https://world.openfoodfacts.org/privacy.
- **Google (Gemini API)** chỉ nhận dữ liệu khi bạn bấm "Hỏi Zero": thông tin sản phẩm và bảng Điểm Fluw, không nhận dữ liệu cá nhân của bạn, để viết phần giải thích. AI không chấm điểm; Điểm Fluw do máy chủ Fluw tính. Việc xử lý tuân theo điều khoản sử dụng Gemini API của Google.
- **Nhà cung cấp hosting** (`<Render>`) vận hành máy chủ và có thể ghi nhật ký kỹ thuật như địa chỉ IP, thời gian truy cập và đường dẫn yêu cầu (đường dẫn có thể chứa mã vạch hoặc từ khóa tra cứu).
- **Bộ nhớ đệm của máy chủ Fluw:** thông tin sản phẩm và phần giải thích của Zero được giữ tạm theo mã vạch, mặc định 24 giờ (`CACHE_TTL_HOURS`); kết quả tìm theo từ khóa mặc định 60 phút (`SEARCH_CACHE_TTL_MINUTES`). Chỉ trong bộ nhớ máy chủ và không gắn với địa chỉ IP hay người dùng.

## 4. Quyền truy cập trên thiết bị

- **Camera:** chỉ dùng khi bạn mở màn hình quét mã vạch.
- **Internet:** dùng để tra cứu sản phẩm.

## 5. Nội dung do AI tạo

Phân tích của Zero do AI tạo, chỉ mang tính tham khảo và có thể chưa chính xác. Nội dung này không phải chẩn đoán hay tư vấn y tế. Dữ liệu sản phẩm do cộng đồng OpenFoodFacts đóng góp và có thể chưa đầy đủ. Hãy luôn kiểm tra nhãn bao bì, đặc biệt nếu bạn bị dị ứng.

## 6. Trẻ em

Fluw không hướng tới trẻ em dưới 13 tuổi và không cố ý thu thập dữ liệu của trẻ em.

## 7. Liên hệ

Mọi câu hỏi về chính sách này, vui lòng liên hệ: `<email liên hệ thật>`
