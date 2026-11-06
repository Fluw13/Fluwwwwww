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
- **Danh sách sản phẩm:** dùng `ProductCard`, xem mục 9.
- **Ảnh:** chỉ tải ảnh https từ `*.openfoodfacts.org` (`isTrustedImageUrl`). Ảnh khác hoặc lỗi tải thì hiện ảnh giữ chỗ.
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

## 9. Trang chủ, Tài khoản và lịch sử

- **Trang chủ** (`HomeScreen`, phần con trong `lib/widgets/home/`):
  - `HomeHeader`: chữ Fluw và nút Tài khoản ở góc phải trên.
  - Lời chào, `ProductSearchField` và `RecentSearches` (tối đa 5 từ khóa gần nhất).
  - Chưa quét gì thì hiện `ZeroIntroCard`; đã quét thì hiện `RecentScansSection` (3 sản phẩm mới nhất + "Xem tất cả").
  - `ScanButton` dạng pill ở đáy.
- **Thẻ sản phẩm cho mọi danh sách:** `ProductCard(product: ProductSummary)`.
  - Điểm dùng `ScorePill` (chấm màu + số + chữ), để không chỉ dựa vào màu.
  - Chữ hệ thống trên 130% thì điểm chuyển xuống dưới tên thay vì ép tên.
  - Cả thẻ được trình đọc màn hình đọc là một nút.
- **Lịch sử trong phiên:** `SessionHistory` (`lib/core/history/`), cấp qua `HistoryScope` ở `FluwApp`.
  - Chỉ nằm trong bộ nhớ, không ghi xuống máy, không gửi đi, mất khi đóng app. Tối đa 20 mục mỗi loại; mục trùng được đưa lên đầu.
  - Lịch sử quét: `ProductDetailScreen` thêm sản phẩm khi tải xong, nếu mở từ màn quét hoặc từ lịch sử (`ProductOrigin`). Tải lỗi thì không thêm.
  - Lịch sử tìm kiếm: Home thêm từ khóa khi người dùng tìm.
  - `HistoryScreen(kind:)` cho cả hai loại; nút "Xóa" có hộp thoại xác nhận.
  - Lưu lâu dài cần đăng nhập, chưa làm (xem kế hoạch `feat/auth-ui`).
- **Tài khoản** (`AccountScreen`, phần con trong `lib/widgets/account/`):
  - `AccountHeaderCard`: nút "Đăng nhập · Sắp có" bị khóa. Không dựng luồng đăng nhập giả.
  - `ThemeModeSelector`: Theo máy / Sáng / Tối, đổi ngay và lưu trên máy.
  - Lịch sử (số mục trong phiên), Hỗ trợ, Pháp lý, Giấy phép mã nguồn mở (`showLicensePage`).
- **Email hỗ trợ:** `SupportContact` đọc `--dart-define=SUPPORT_EMAIL=...`. Chưa đặt thì hiện địa chỉ mẫu `hotro@example.com` và ghi rõ là mẫu. Bấm vào thì chép email.
- **Trang pháp lý trong app:** nội dung ở `lib/content/legal_pages.dart`, hiển thị bằng `InfoPageScreen`.
  - Điều khoản sử dụng ghi "đang hoàn thiện".
  - Chính sách quyền riêng tư là bản tóm tắt cách app đang xử lý dữ liệu, chưa phải bản chính thức.
  - Đổi cách xử lý dữ liệu thì phải sửa cả trang này và `docs/PRIVACY_POLICY.md`.

## 10. Kiểm thử

- Chạy trong thư mục `frontend/`: `flutter analyze`, `flutter test`.
- Mỗi phần ở trên có test tương ứng dưới `test/`, cùng cấu trúc thư mục với `lib/`.
