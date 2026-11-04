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
- Các dạng có sẵn: `SkeletonBox(width:, height:, radius:)`, `SkeletonBox.circle(size:)`, `SkeletonBox.text(width:, fontSize:, lineHeight:)`.
  - `SkeletonBox.text` cao đúng bằng một dòng chữ cùng cỡ và tự to lên theo cỡ chữ hệ thống.
- **Skeleton khớp với màn thật nhờ cách dựng, không nhờ đo tay:**
  - `ProductDetailView` và `ProductDetailSkeleton` cùng dựng trên `ProductDetailLayout` (lề, khoảng cách giữa các phần, footer).
  - Mỗi phần có thêm hàm dựng `.loading()` (`ScoreSummaryCard.loading()`, `ProductHeader.loading()`, `NutritionGrid.loading()`, `ZeroAnalysisCard.loading()`), dùng chung khung, padding và tiêu đề với bản thật, chỉ thay chữ và số bằng `SkeletonBox`.
  - Kích thước dùng chung nằm trong `ProductDetailMetrics`.
  - Test `product_detail_skeleton_test.dart` so vị trí từng phần giữa skeleton và màn thật.
- Skeleton bị ẩn khỏi trình đọc màn hình. `LoadingStatusBanner` là phần thông báo trạng thái tải.
  - Ở màn chi tiết, banner nằm ở đáy màn hình, đè lên skeleton, nên khi dữ liệu về nội dung không bị đẩy lên.
- Khi bật giảm chuyển động, skeleton đứng yên.

## 7. Khung sản phẩm dùng chung

- **Một khung cho mọi sản phẩm:** `ProductDetailView(product:)` (`lib/widgets/product/product_detail_view.dart`). Sản phẩm nào cũng dùng file này, chỉ dữ liệu thay đổi.
- Mỗi phần nằm ở một file riêng:
  - `ScoreSummaryCard`: vòng điểm 160 ở giữa, nhãn mức, "Do AI tạo".
  - `ProductHeader`: ảnh, tên, thương hiệu · mã vạch.
  - `NutritionGrid` / `NutrientTile`: lưới 2×2, trên 100 g. Số không bị cắt; chữ to thì xuống dòng và cả hàng cao bằng nhau.
  - `ZeroAnalysisCard`: ẩn hẳn khi AI không viết gì.
  - `TagSection`: dị ứng theo nhãn, AI gợi ý, lựa chọn thay thế.
  - `DataSourceFooter`
- Tiêu đề các phần dùng `SectionTitle` (`lib/widgets/common/`), được trình đọc màn hình đọc là tiêu đề.
- **Phần không có dữ liệu thì ẩn đi:**
  - Không có AI: thay thẻ điểm bằng `AiUnavailableCard`, ẩn mọi nội dung do AI tạo.
  - Thiếu chỉ số dinh dưỡng: hiện "—" kèm chú thích.
  - Danh sách rỗng: ẩn cả mục, kể cả tiêu đề.
- **Lỗi tải:** `ErrorRetryView` cuộn được khi chữ to hoặc màn thấp; thông báo lỗi được đọc ngay khi hiện.
- **Định dạng số:** kiểu Việt Nam, xem `NutrientFormat`: "9,8 g", "1.250,3 g", "2.000 kcal". Số âm (dữ liệu lỗi) hiện là 0.
- **Danh sách sản phẩm** (thẻ sản phẩm, lịch sử quét) thuộc PR màn chính, chưa có trong khung này.
- **Ảnh:** chỉ tải ảnh https từ `*.openfoodfacts.org` (`isTrustedImageUrl`). Ảnh khác hoặc lỗi tải thì hiện ảnh giữ chỗ.
- **Kiểm tra bố cục:** test chạy ở màn 320 px và cỡ chữ 200%, không được tràn.

## 8. Kiểm thử

- Chạy trong thư mục `frontend/`: `flutter analyze`, `flutter test`.
- Mỗi phần ở trên có test tương ứng dưới `test/`, cùng cấu trúc thư mục với `lib/`.
