# CLAUDE.md — Sổ tay cho agent làm việc trên Fluw

File này là nơi mọi agent đọc trước khi bắt đầu và ghi lại sau khi làm xong.
Đọc file này thay cho việc quét toàn bộ repo.

---

## 1. Quy tắc làm việc (FLuw đặt ra, bắt buộc)

### Đọc và sửa file
- **Chỉ đọc đúng file và đúng vị trí liên quan đến yêu cầu.** Không đọc cả file khi chỉ cần một hàm, không quét toàn bộ repo mỗi lần sửa hay kiểm tra lỗi.
- **Chỉ sửa đúng chỗ cần sửa.** Phần đang đúng thì giữ nguyên.
- Khi chỗ cần sửa là thứ dùng chung (contract API, widget nhiều màn dùng): được tìm theo **tên hàm hoặc tên biến** để biết nơi nào bị ảnh hưởng, nhưng không đọc trọn các file đó.
- Mỗi file một trách nhiệm. Không thêm comment dư thừa; chỉ comment khi cần giải thích lý do kỹ thuật hoặc một quyết định không hiển nhiên.

### Trước khi sửa
- Báo lỗi tìm được và phương án đề xuất, **chờ FLuw đồng ý rồi mới làm**.
- Khi sửa: nói rõ sai ở đâu, vì sao sai, cách khắc phục, rồi mới đưa code.

### Git (không được tự ý vượt)
- Mỗi tính năng / bug fix / nhóm tài liệu một branch riêng, mở Pull Request để FLuw xem.
- **Không push trực tiếp vào `main`. Không tự merge PR. Không deploy production** khi FLuw chưa cho phép rõ ràng.
- Không ghi đè thay đổi sẵn có của FLuw. Thấy working tree có thay đổi lạ thì kiểm tra trước khi tiếp tục.
- Trước khi push: phải có agent khác review chéo và các lỗi review đã sửa.

### Bảo mật
- Không hardcode API key, token, mật khẩu. Không đưa secret vào code, log, tài liệu, screenshot hay memory.
- Không yêu cầu FLuw gửi secret trong chat.
- Không bịa kết quả test, git hay deployment. Test nào chưa chạy thì ghi rõ là chưa chạy.

### Sau khi làm xong
- **Ghi vào mục 6 của file này:** đã sửa gì, ở file nào, vì sao, test nào đã chạy.
- Không cần viết thêm tài liệu bàn giao trong project; CLAUDE.md là nơi duy nhất.

---

## 2. Dự án (VERIFIED 06/11/2026)

Fluw: ứng dụng tra cứu và đánh giá thực phẩm bằng mã vạch. Trợ lý AI tên **Zero**.

Luồng dữ liệu: Flutter → backend Fluw → Open Food Facts + Gemini → backend xử lý → Flutter hiển thị.

| Thành phần | Thực tế |
|---|---|
| Repository | `https://github.com/Fluw13/Fluwwwwww`, branch chính `main` |
| Trạng thái | `main@e6670b8`, không còn PR nào mở, CI backend và frontend xanh |
| Frontend | Flutter 3.47.8 / Dart 3.13.7, thư mục `frontend/` |
| Backend | Node.js + Express, entry `backend/src/index.js`, thư mục `backend/` |
| Hosting backend | Render: `https://fluw.onrender.com` |
| API chính | `GET /api/product/:query` (mã vạch hoặc từ khóa) |
| Dữ liệu thực phẩm | Open Food Facts (ODbL), ảnh CC BY-SA |
| AI | Google Gemini, chỉ nhận dữ liệu sản phẩm, không nhận định danh người dùng |

Tài liệu chi tiết trong repo:
- `docs/FRONTEND_UI_FOUNDATION.md` — hệ thống giao diện, skeleton, màn quét, trang chủ và Tài khoản. **Đây là nguồn chính thức về frontend.**
- `docs/PRIVACY_POLICY.md` — bản nháp chính sách quyền riêng tư, chưa qua rà soát pháp lý.
- `README.md` — giới thiệu và cách chạy.

---

## 3. Chạy và kiểm thử

```bash
# Frontend
export PATH=/home/claude/sdk/flutter/bin:$PATH
cd frontend
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/product

# Backend
cd backend && npm install && npm test && npm start
```

- `dart format` dùng độ rộng dòng **120** cho code mới.
- Email hỗ trợ: `--dart-define=SUPPORT_EMAIL=...`. Không đặt thì app hiện địa chỉ mẫu và ghi rõ là mẫu.
- **Chưa build được APK** trong môi trường agent: không có Android SDK.

---

## 4. Quyết định đang áp dụng (FLuw đã duyệt)

- Giao diện Sáng và Tối **chỉ khác màu, bố cục giống nhau**, theo bố cục B (vòng điểm lớn ở giữa, có hào quang).
- 3 lựa chọn giao diện: Theo máy / Sáng / Tối, lưu trên từng máy bằng `shared_preferences`.
- Một khung chi tiết dùng cho mọi sản phẩm; một `ProductCard` dùng cho mọi danh sách.
- Skeleton phải khớp vị trí nội dung thật nhờ dùng chung layout, không đo tay.
- Lịch sử khi chưa đăng nhập **chỉ nằm trong bộ nhớ**, tối đa 20 mục mỗi loại, mất khi đóng app.
- Nút Đăng nhập hiện "Sắp có" và bị khóa. **Không dựng luồng đăng nhập giả.**
- Điều khoản trong app ghi "đang hoàn thiện". Quyền riêng tư là bản tóm tắt đã đối chiếu với code, chưa phải bản chính thức.
- Dữ liệu từ Open Food Facts và nội dung do AI tạo phải được phân biệt rõ trên giao diện. Thiếu dữ liệu thì ghi rõ, không hiện số 0 hay số bịa.

---

## 5. Việc còn lại

### Chờ FLuw
1. Thử trên điện thoại thật: camera, quyền camera, độ nhạy quét, đèn flash, chuyển Sáng/Tối và giữ lựa chọn sau khi tắt app.
2. Email hỗ trợ thật.
3. Bản chính thức của Điều khoản và Chính sách quyền riêng tư (cần người có chuyên môn pháp lý).
4. Duyệt kế hoạch v1 (`/api/v1`, B0–B5 và F1, F3–F9). Các phần frontend phụ thuộc v1 chưa làm: danh sách kết quả tìm kiếm, giải thích điểm.
5. Chọn `GEMINI_MODEL`: `gemini-3.5-flash-lite` (500 lượt/ngày) hay giữ `gemini-3.6-flash` (20 lượt/ngày), hoặc bật thanh toán.
6. Cho phép xóa các branch đã merge trên GitHub.

### Chưa làm, cần backend và pháp lý
- `feat/auth-ui`: đăng nhập, đồng bộ lịch sử, xóa tài khoản. Điều kiện: backend auth + database, màn đồng ý, DPIA, cho xóa tài khoản ngay trong app (yêu cầu của Google Play và App Store), lịch sử chỉ lưu mã vạch và từ khóa để giảm rủi ro ODbL.

### Ghi nhận kỹ thuật (không chặn)
- Chuyển `zero_analysis_card.dart`, `tag_section.dart`, `ai_unavailable_card.dart` vào `widgets/product/`.
- Thống nhất độ rộng dòng `dart format` cho toàn repo, làm ở PR riêng.
- `mobile_scanner`: app vào nền đúng lúc camera đang khởi động thì camera có thể vẫn chạy. Hạn chế của thư viện gốc.
- Nếu đổi `CACHE_TTL_HOURS` trên Render thì phải sửa câu "mặc định 24 giờ" trong `frontend/lib/content/legal_pages.dart` và `docs/PRIVACY_POLICY.md`.

---

## 6. Nhật ký công việc

Mục mới nhất ở trên. Mỗi mục ghi: ngày, PR, đã sửa gì ở file nào, vì sao, test đã chạy.

### 06/11/2026 — Thêm CLAUDE.md
- **Thêm:** `CLAUDE.md` (file này).
- **Lý do:** FLuw yêu cầu có một chỗ để mọi agent nắm trạng thái dự án và quy tắc làm việc, thay cho việc quét toàn bộ repo.
- **Test:** không có code thay đổi.

### 05/11/2026 — PR #9 `feat/home-account-ui`: trang chủ, Tài khoản, lịch sử, trang pháp lý
- **Thêm:** `lib/widgets/home/` (6 widget), `lib/widgets/account/` (4 widget), `lib/screens/account_screen.dart`, `history_screen.dart`, `info_page_screen.dart`, `lib/core/history/`, `lib/core/navigation/product_origin.dart`, `lib/core/support/support_contact.dart`, `lib/content/`, `lib/widgets/product/product_card.dart`, `score_pill.dart`, `lib/widgets/common/empty_state.dart`.
- **Sửa:** `home_screen.dart` viết lại theo bố cục B; `main.dart` thêm `HistoryScope`; `product_detail_screen.dart` thêm tham số `origin` và ghi lịch sử quét khi tải xong.
- **Lý do sửa theo review:** trang quyền riêng tư trong app thiếu hai ý so với `docs/PRIVACY_POLICY.md` (nhật ký kỹ thuật của hosting có thể chứa IP và từ khóa tra cứu; máy chủ giữ tạm kết quả tra cứu), và nhiều test vẫn pass dù code sai.
- **Test:** `flutter analyze` sạch, `flutter test` 192/192. Đã kiểm 12 đột biến (gỡ từng guard), lần nào cũng có test fail.

### 05/11/2026 — PR #8 `feat/scanner-ui`: màn quét mã vạch
- **Thêm:** `lib/screens/scanner_screen.dart`, `lib/widgets/scanner/` (6 widget), `lib/core/scanner/barcode_picker.dart`, `scanner_exit.dart`, `test/helpers/fake_mobile_scanner_platform.dart`.
- **Lý do sửa theo review:**
  - Bấm Back hoặc Đóng đúng khung hình vừa nhận mã thì app bật lại camera trên màn đang bị huỷ → thêm kiểm tra `ModalRoute.isCurrentOf` trong `_onDetect` và `_openProduct`, bỏ nhánh tự bật lại camera.
  - Tràn bố cục ở màn 320×568 và màn xoay ngang với chữ 200% → phần dưới cao tối đa 60% vùng an toàn và cuộn được; khung quét thấp lại theo chiều cao; ẩn dòng hướng dẫn khi không đủ chỗ.
  - Chưa cấp quyền camera thì quay lại app vẫn báo lỗi → thêm nút "Thử lại" (ẩn khi thiết bị không hỗ trợ).
- **Test:** `flutter test` 136/136, gồm luồng nhận mã, vòng đời app, lỗi quyền camera, bố cục 320×568 và 640×360 ở chữ 200%. Đã kiểm bằng cách gỡ từng guard.
- **Chưa xác minh:** camera thật, độ nhạy quét, đèn flash, rung.

### 05/11/2026 — PR #7 `feat/product-detail-template`: khung chi tiết dùng chung + skeleton
- **Thêm:** `lib/widgets/product/product_detail_layout.dart`, `product_detail_view.dart`, `product_detail_skeleton.dart`, `product_detail_loading_view.dart`, `product_detail_metrics.dart`, `score_summary_card.dart`, `product_header.dart`, `nutrition_grid.dart`, `nutrient_tile.dart`, `product_thumbnail.dart`, `data_source_footer.dart`, `lib/widgets/async/error_retry_view.dart`, `lib/core/format/nutrient_format.dart`, `lib/core/network/trusted_image_url.dart`, `lib/widgets/common/`.
- **Bỏ:** `lib/widgets/macro_bar.dart`, thay bằng `NutritionGrid`.
- **Lý do sửa theo review:** skeleton lệch vị trí so với nội dung thật → cả hai dựng trên `ProductDetailLayout`, mỗi phần có hàm dựng `.loading()`; vòng điểm bị cắt nét và tương phản kém ở theme tối → thêm `Padding(stroke/2)` và nền `surface`; `ErrorRetryView` không cuộn được khi chữ to.
- **Test:** `flutter test` 91/91, gồm màn 320 px, chữ 200%, sáng và tối, và test so vị trí skeleton với nội dung thật.

### 30/10/2026 — PR #5 `feat/ui-foundation`: nền tảng giao diện
- **Thêm:** `lib/core/theme/` (palette sáng/tối dạng ThemeExtension, spacing, radius, theme), `lib/core/settings/` (chọn và lưu Sáng/Tối), `lib/core/navigation/fluw_page_transitions_builder.dart`, `lib/core/licenses/font_licenses.dart`, `lib/widgets/skeleton/`, `lib/widgets/async/`.
- **Lý do sửa theo review:** icon thanh trạng thái không đổi theo theme; lỗi đọc `shared_preferences` lúc mở app làm treo → đọc lười, bắt mọi lỗi, timeout 2 giây; bấm "Thử lại" hai lần gọi API hai lần.
- **Test:** `flutter test` 61/61, gồm test tương phản màu theo WCAG AA.
