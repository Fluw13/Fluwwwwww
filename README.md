# Fluw

Ứng dụng di động giúp bạn tra cứu dinh dưỡng của thực phẩm, ghi lại những gì đã ăn trong ngày và biết mình cần nạp bao nhiêu calo, protein theo chiều cao, cân nặng và mục tiêu. Trợ lý AI của app tên là **Zero**.

> Dự án đang ở mốc **M0 (khung dự án)**. Các màn hình đã có điều hướng nhưng nội dung ghi "Đang xây dựng".

## Tính năng

| Tính năng | Mô tả | Trạng thái |
|---|---|---|
| Tra cứu | Tìm calo, protein (đạm), đường, chất béo của đồ đóng gói, trái cây, đồ tươi, món nấu chín, bánh kẹo | Chưa làm |
| Quét | Quét mã vạch sản phẩm, hoặc chụp ảnh để nhận diện thực phẩm tươi (cà chua, hành...) | Chưa làm |
| Thông tin sản phẩm | Tên, ảnh, nhà cung cấp, đánh giá, các chỉ số dinh dưỡng | Chưa làm |
| Nhật ký | Thêm món vào nhật ký, xếp theo ngày và 4 khung giờ, có tổng theo buổi và theo ngày | Chưa làm |
| Hồ sơ sức khỏe | Chiều cao, cân nặng, tuổi, giới tính, mức vận động, dị ứng, bệnh, cân nặng mục tiêu, sở thích | Chưa làm |
| Gợi ý | Lượng calo và protein nên nạp; sản phẩm nên/không nên dùng; nhắc khi ăn chưa đủ | Chưa làm |
| Lịch sử tra cứu | Xem lại những gì đã tìm hoặc quét | Chưa làm |

**Khung giờ trong Nhật ký:** Sáng 06:00–12:00 · Chiều 12:01–18:00 · Tối 18:01–24:00 · Đêm 00:01–05:59.

## App tính nhu cầu thế nào

**Năng lượng cơ bản (BMR, công thức Mifflin–St Jeor)**
- Nam: `BMR = 10 × cân nặng(kg) + 6,25 × chiều cao(cm) − 5 × tuổi + 5`
- Nữ: `BMR = 10 × cân nặng(kg) + 6,25 × chiều cao(cm) − 5 × tuổi − 161`

**Tổng năng lượng tiêu hao trong ngày:** `TDEE = BMR × hệ số vận động`

| Mức vận động | Hệ số |
|---|---|
| Ít vận động | 1,2 |
| Hoạt động nhẹ | 1,375 |
| Hoạt động vừa | 1,55 |
| Hoạt động nhiều | 1,725 |
| Hoạt động rất cao | 1,9 |

**Protein:** `cân nặng(kg) × P`. P = 0,8 g/kg với người trưởng thành, 0,85 g/kg với tuổi 14–18; người tập luyện thường xuyên có thể cần cao hơn.

Mọi con số chỉ là **ước tính tham khảo**, không thay thế tư vấn của bác sĩ hay chuyên gia dinh dưỡng. Người dưới 18 tuổi không dùng trực tiếp công thức của người lớn.

## Quyền riêng tư

- Hồ sơ sức khỏe, nhật ký ăn uống và lịch sử tra cứu **chỉ lưu trên điện thoại**. App không có đăng nhập.
- Ảnh chụp để nhận diện được gửi lên máy chủ Fluw rồi tới Google Gemini để nhận ra tên thực phẩm; không lưu lại.
- Dữ liệu sản phẩm từ [Open Food Facts](https://world.openfoodfacts.org) (giấy phép ODbL).

## Kiến trúc

```
Điện thoại (Flutter)
  ├─ Hồ sơ, nhật ký, lịch sử: SQLite trên máy
  ├─ Công thức BMR / TDEE / protein: tính trên máy
  └─ Tra cứu, quét, nhận diện ảnh ──► Backend Fluw (Node.js, Render)
                                         ├─ Open Food Facts (đồ đóng gói, mã vạch)
                                         ├─ Nguồn dữ liệu đồ tươi (đang chọn)
                                         └─ Google Gemini (nhận diện ảnh)
```

```
frontend/   app Flutter (Android, iOS)
  lib/app/        ghép app: router, thanh điều hướng
  lib/core/       theme, widget dùng chung
  lib/features/   mỗi tính năng một thư mục: data / domain / presentation
backend/    API Node.js + Express
  src/            app, routes, controllers, services, middlewares
  tests/
```

## Chạy trên máy

Yêu cầu: Flutter 3.47.9, Node.js 22.

```bash
cd backend
npm install
npm test
npm run dev
```

```bash
cd frontend
flutter pub get
flutter test
flutter run
```

## Cài APK lên điện thoại Android

1. Vào tab **Actions** của repo trên GitHub, chọn lần chạy **CI** mới nhất có dấu xanh.
2. Ở mục **Artifacts**, tải **fluw-apk** (file .zip) và giải nén ra `app-release.apk`.
3. Chép file vào điện thoại, mở và cho phép "Cài ứng dụng không rõ nguồn gốc" khi được hỏi.

Bản APK hiện ký bằng khóa debug: cài thử được ngay, nhưng chưa đưa lên Google Play được.

## Lộ trình

| Mốc | Nội dung |
|---|---|
| **M0** | Khung dự án, CI build APK *(đang làm)* |
| M1 | API tra cứu, mã vạch, nhận diện ảnh; deploy Render |
| M2 | Hồ sơ sức khỏe và công thức tính nhu cầu |
| M3 | Tìm kiếm, thông tin sản phẩm, lịch sử |
| M4 | Nhật ký theo ngày và khung giờ |
| M5 | Quét mã vạch và nhận diện ảnh |
| M6 | Gợi ý, nhắc nhở, sở thích |

## Bản cũ

Phiên bản trước (tra cứu thực phẩm và chấm điểm FNS) đã được gỡ ở mốc M0. Toàn bộ mã nguồn cũ vẫn xem được tại commit `df79e6b`.
