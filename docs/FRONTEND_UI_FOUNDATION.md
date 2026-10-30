# Nền tảng giao diện Frontend

Tài liệu này mô tả các phần dùng chung của giao diện Flutter: theme sáng/tối, font, chuyển trang, skeleton và trạng thái tải. Các màn hình mới phải dùng những phần này, không tự đặt màu hay tự viết hiệu ứng tải riêng.

## 1. Màu sắc và theme

- Mọi màu lấy từ `FluwPalette` (`lib/core/theme/fluw_palette.dart`) qua `context.palette`. Không hardcode màu trong widget.
  - Ngoại lệ duy nhất: thanh tiêu đề màn quét luôn đen trên nền camera.
- Có hai bộ màu, **bố cục giống nhau, chỉ khác màu**:
  - `FluwPalette.light` (hướng A — sáng tối giản);
  - `FluwPalette.dark` (hướng B — Zero, tông tối, vòng điểm phát sáng).
- Màu điểm theo mức (`ScoreLevel`) lấy qua `palette.scoreColors(level)`, gồm `ring`, `text`, `container`. Màu chỉ dùng để thể hiện ý nghĩa của điểm.
- `test/core/theme/fluw_palette_test.dart` kiểm tra độ tương phản ở cả hai bộ màu:
  - chữ ≥ 4.5:1 (WCAG AA);
  - vòng điểm ≥ 3:1.
  - Đổi màu mà test fail nghĩa là màu mới không đạt chuẩn.
- `AppTheme.light()` / `AppTheme.dark()` (`lib/core/theme/app_theme.dart`) dựng `ThemeData` từ palette, gồm: font, AppBar trong suốt, màu icon thanh trạng thái theo chế độ, hiệu ứng chuyển trang.
- Khoảng cách và bo góc dùng `AppSpacing`, `AppRadius`.

## 2. Lựa chọn Sáng / Tối

- 3 lựa chọn: Theo máy (mặc định), Sáng, Tối.
- `ThemeModeController` giữ lựa chọn hiện tại. Widget lấy controller qua `ThemeModeScope.of(context)` và gọi `setMode(...)` để đổi.
- Lựa chọn được lưu trên từng máy bằng `shared_preferences`, qua `SharedPrefsThemeModeStore`, khóa `theme_mode`. Không đồng bộ, không gửi đi đâu.
- Lựa chọn được đọc trước khung hình đầu, nên app không bị nháy sai màu khi mở.
- Nếu bộ nhớ lỗi hoặc không phản hồi trong 2 giây, app theo cài đặt của máy và không kẹt ở màn chờ.
- Màn chọn giao diện nằm trong màn Tài khoản (PR `feat/home-account-ui`).

## 3. Font

- Be Vietnam Pro (giấy phép SIL OFL 1.1), đóng gói trong `assets/fonts/BeVietnamPro/`, gồm các độ đậm 400–800.
- Nội dung giấy phép được đăng ký vào trang giấy phép của Flutter (`lib/core/licenses/font_licenses.dart`).
- Không có file italic. Chữ nghiêng do engine tạo bằng cách nghiêng bản thường.

## 4. Chuyển trang

- `FluwPageTransitionsBuilder` áp dụng cho mọi `MaterialPageRoute` trên Android: mờ dần kết hợp trượt ngắn từ phải.
  - Thời gian: 280 ms khi mở, 220 ms khi quay lại.
  - Trang đích (tiêu đề + trạng thái tải) hiện ngay từ khi bắt đầu chuyển.
- iOS giữ hiệu ứng Cupertino để còn thao tác vuốt quay lại.
- Hiệu ứng này thay cho predictive back của Android. Manifest hiện chưa bật predictive back nên không mất gì.
- Khi người dùng bật giảm chuyển động, trang mới hiện ngay, không có hiệu ứng.

## 5. Trạng thái tải

- `AsyncContent<T>` (`lib/widgets/async/async_content.dart`): truyền vào một `Future` cùng 3 builder (đang tải / dữ liệu / lỗi).
  - Chuyển giữa các trạng thái bằng crossfade 220 ms.
  - Muốn thử lại thì truyền một `Future` mới.
  - Trong lúc crossfade, view cũ không nhận chạm và không được trình đọc màn hình đọc, nên bấm "Thử lại" hai lần chỉ gọi API một lần.
- `LoadingStatusBanner` cho người dùng biết màn nào đang mở và đang tải gì.
  - Ví dụ: "Đang mở chi tiết sản phẩm · Mã …".
  - `slowHint` hiện sau `slowAfter` (mặc định 8 giây), dùng khi máy chủ Render vừa khởi động.
- Thanh tiến trình chạy liên tục bị ẩn khi người dùng bật giảm chuyển động; dòng trạng thái vẫn giữ.

## 6. Skeleton

- Bọc vùng skeleton bằng một `ShimmerScope`. Toàn bộ `SkeletonBox` bên trong dùng chung một animation, nên chỉ tốn một ticker.
- Các dạng có sẵn: `SkeletonBox(width:, height:, radius:)`, `SkeletonBox.circle(size:)`, `SkeletonBox.line(width:)`.
- Skeleton của một màn phải có cùng bố cục với màn thật, để khi dữ liệu về giao diện không bị nhảy.
- Skeleton bị ẩn khỏi trình đọc màn hình. `LoadingStatusBanner` là phần thông báo trạng thái tải.
- Khi bật giảm chuyển động, skeleton đứng yên.
- Skeleton chi tiết sản phẩm được thêm ở PR `feat/product-detail-template`.

## 7. Kiểm thử

- Chạy trong thư mục `frontend/`: `flutter analyze`, `flutter test`.
- Mỗi phần ở trên có test tương ứng dưới `test/`, cùng cấu trúc thư mục với `lib/`.
