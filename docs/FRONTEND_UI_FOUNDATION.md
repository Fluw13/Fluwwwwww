# Nền tảng giao diện Frontend

Tài liệu này mô tả các phần dùng chung của giao diện Flutter: theme sáng/tối, font, chuyển trang, skeleton và trạng thái tải. Các màn hình mới phải dùng những phần này, không tự đặt màu hay tự viết hiệu ứng tải riêng.

## 1. Màu sắc và theme

- Mọi màu lấy từ `FluwPalette` (`lib/core/theme/fluw_palette.dart`) qua `context.palette`. Không hardcode màu trong widget.
  - Ngoại lệ duy nhất: phần giao diện của màn quét luôn tối vì nằm trên hình camera (xem mục 8).
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

## 7. Khung sản phẩm dùng chung (API v1)

- **Một khung cho mọi sản phẩm:** `ProductDetailView(details:)` (`lib/widgets/product/product_detail_view.dart`), nhận `ProductDetails` (sản phẩm + `score`) từ `GET /api/v1/products/:barcode`. Sản phẩm nào cũng dùng file này, chỉ dữ liệu thay đổi.
- **Điểm do backend tính, app chỉ hiển thị:** không tự tính lại, không tự áp ngưỡng 70/40, nhãn mức là `score.total.label` backend gửi. AI (Zero) không có điểm. Quy tắc chi tiết: `docs/SCORING.md`.
- Mỗi phần nằm ở một file riêng:
  - `ScoreSummaryCard`: vòng điểm 160 + nhãn mức (màu + biểu tượng + chữ), điểm thành phần kèm trọng số, phép tính in từ `total.calculation`, phiên bản công thức, nút "Cách Fluw tính điểm". Khi `total.value` là null: không vẽ vòng, ghi "Chưa đủ dữ liệu để tính điểm tổng" và liệt kê `score.missing`.
  - `ProductHeader`: ảnh (cỡ `small`/`display`, chạm để mở `ProductImageScreen`, chỉ ở đó mới tải `full`), tên, thương hiệu · khối lượng · mã vạch.
  - `NutritionGrid` / `NutrientTile` / `NutrientRow`: lưới 2×2 (năng lượng kcal, đạm, béo, carbohydrate) + các dòng kJ, béo bão hòa, đường, chất xơ, muối; trên 100 g hoặc 100 ml theo `nutrition.basis`; thêm một bảng "sau khi pha" khi có.
  - `IngredientsSection`, `TagSection` (dị ứng theo nhãn, "có thể chứa"), `AdditivesSection` (mã E + tên), `ProductInfoSection`, `ProductImagesSection`.
  - `DataSourceFooter`: "Dữ liệu: Open Food Facts · ODbL · ảnh CC BY-SA", ngày cập nhật, nút sao chép link sản phẩm (dùng `Clipboard`).
- Màn `ScoreExplanationScreen`: tổng + công thức, loại sản phẩm, điểm thô → dải → điểm dinh dưỡng, từng chỉ số (`IndicatorRow`, nhiều dòng ngắn để vừa 360 dp), phụ gia, mục thiếu, NOVA (không tính vào điểm), nguồn, lời miễn trừ.
- Tiêu đề các phần dùng `SectionTitle` (`lib/widgets/common/`), được trình đọc màn hình đọc là tiêu đề. Điểm được đọc là "Điểm tổng 74 trên 100, mức Tốt".
- **Thiếu dữ liệu thì ghi rõ, không đoán, không ẩn:**
  - Trường văn bản thiếu: "Chưa có dữ liệu" (`LabeledValue.missing`).
  - Thiếu chỉ số dinh dưỡng: hiện "—" kèm chú thích, trình đọc màn hình đọc "chưa có dữ liệu".
  - Danh sách dị ứng / "có thể chứa" rỗng: vẫn hiện mục với "Chưa có dữ liệu" (danh sách rỗng trên Open Food Facts không có nghĩa là không có chất gây dị ứng).
  - Phụ gia rỗng: chỉ ghi "Không có phụ gia" khi backend kiểm chứng được danh sách thành phần (`additives.status = computed`, `count = 0`).
  - Ẩn hẳn chỉ áp dụng cho mục ảnh khi sản phẩm không có ảnh nào.
- **Lỗi tải:** `ErrorRetryView` cuộn được khi chữ to hoặc màn thấp; thông báo lỗi được đọc ngay khi hiện. Có `Retry-After` thì nút bị khóa và đếm ngược, không tự gửi lại; lỗi không thể thử lại (mã vạch sai, không tìm thấy) thì không có nút. `ApiErrorView` chọn các thứ này từ `FluwApiException`.
- **Định dạng số:** kiểu Việt Nam (`formatVietnameseNumber`, `NutrientFormat`): "3,5 g", "0,01 g", "1.715,4 kJ", "2.000 kcal". Gam tối đa 2 chữ số thập phân và kJ tối đa 1, đúng mức backend làm tròn trước khi so ngưỡng, để giá trị hiển thị không mâu thuẫn với khoảng ngưỡng. Số âm (dữ liệu lỗi) hiện là 0.
- **Ảnh:** chỉ tải ảnh https từ `images.openfoodfacts.org` hoặc `static.openfoodfacts.org` (`isTrustedImageUrl`, đúng contract). Ảnh khác hoặc lỗi tải thì hiện ảnh giữ chỗ.
- **Kiểm tra bố cục:** test chạy ở màn 320 px và cỡ chữ 200%, không được tràn.

## 8. Màn quét mã vạch

- `ScannerScreen` (`lib/screens/scanner_screen.dart`) chỉ ghép các phần trong `lib/widgets/scanner/`:
  - `ScannerViewfinder`: làm tối ngoài khung, 4 góc khung, vạch quét chạy.
  - `ScannerTopBar`: nút Đóng, tiêu đề, nút đèn flash (bật/tắt, tự động trên iOS được coi là đang bật).
  - `ScannerHint`: dòng hướng dẫn trên nền tối, đọc được trên cả hình camera sáng.
  - `ScanDetectedBanner`: báo "Đã nhận mã …, đang mở Chi tiết sản phẩm".
  - `ScannerErrorView`: lỗi camera (chưa cấp quyền, không hỗ trợ…) kèm nút "Thử lại" (ví dụ sau khi bật quyền trong Cài đặt), cuộn được khi chữ to.
  - `ManualEntryButton`: luôn có, để còn đường đi tiếp khi không quét được.
- **Khung quét:** `ScannerViewfinder.windowFor(size)` tính một lần ở màn hình, dùng cho cả phần vẽ lẫn `scanWindow` của camera, nên chỉ mã nằm trong khung mới được đọc.
- **Chỉ nhận mã sản phẩm:** `firstProductBarcode` chỉ lấy GTIN 8, 12, 13 hoặc 14 chữ số; URL, chữ hay mã khác bị bỏ qua.
- **Sau khi nhận mã:**
  - Rung nhẹ, dừng camera, dừng vạch quét, hiện banner.
  - Khóa Đóng, Nhập tay và nút Back cho tới khi màn chi tiết thay thế màn quét (`pushReplacement`), nên không có hai màn chi tiết hoặc quay nhầm về Home giữa chừng.
  - Mã đọc được khi màn quét đang đóng thì bỏ qua. Nếu người dùng bấm Back đúng khung hình nhận mã, app về Home và không mở chi tiết, không bật lại camera.
- **Vòng đời ứng dụng:** vào nền thì tắt camera, quay lại thì bật lại (chỉ khi đã có quyền và chưa nhận mã). `MobileScanner` không tự làm việc này khi màn hình tự giữ controller.
  - Chưa có quyền thì quay lại app không tự hỏi lại (tránh hỏi quyền lặp trên Android); người dùng bấm "Thử lại".
- **Bố cục:** phần dưới (banner + nút nhập tay) cao tối đa 60% màn hình và cuộn được khi chữ rất to. Khung quét thấp lại khi màn thấp (xoay ngang); khi không đủ chỗ, dòng hướng dẫn bị ẩn thay vì đè lên nút.
- **Nhập tay:** đóng màn quét và trả `ScannerExit.manualEntry`; Home đưa con trỏ vào ô tìm kiếm.
- Home chặn bấm nút quét hai lần liên tiếp.
- **Kiểm thử:** `test/helpers/fake_mobile_scanner_platform.dart` thay plugin camera, để test được luồng nhận mã, lỗi quyền camera và vòng đời mà không cần điện thoại. Camera thật, quyền và độ nhạy quét vẫn phải thử trên máy thật.

## 9. Kiểm thử

- Chạy trong thư mục `frontend/`: `flutter analyze`, `flutter test`.
- Mỗi phần ở trên có test tương ứng dưới `test/`, cùng cấu trúc thư mục với `lib/`.
