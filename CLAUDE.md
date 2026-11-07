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
| Trạng thái | `main@3b760d4` (07/11/2026): FNS v1 đã merge (#10–#14) và Render đã deploy. PR #15 (sửa phân loại Nutella) đang chờ duyệt. |
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
- **Điểm là Fluw Nutrition Score (FNS) 0–10, do engine thuần ở backend tính** (`backend/src/services/scoring/`, theo HSR Guide v9). Gemini **không chấm điểm**, chỉ giải thích; Flutter chỉ hiển thị, không chép công thức. Chi tiết ở `docs/ADR-001-FNS-V1.md` (từ PR #11).
  - Dữ liệu OFF là dữ liệu cộng đồng, nên điểm có trạng thái `PROVISIONAL` và giao diện ghi "Tạm tính".
  - `NOT_SCORED` hiện lý do và các trường còn thiếu, không bao giờ hiện 0/10.
  - FVNL dùng ước tính từ thành phần của OFF, gắn `FVNL_ESTIMATED`.
  - Nhãn mức điểm là Cao/Trung bình/Thấp, mô tả điểm chứ không phán xét sản phẩm.
  - Không gọi là điểm của WHO, Bộ Y tế hay HSR.

---

## 5. Việc còn lại

### Chờ FLuw
1. Thử trên điện thoại thật: camera, quyền camera, độ nhạy quét, đèn flash, chuyển Sáng/Tối và giữ lựa chọn sau khi tắt app.
2. Email hỗ trợ thật.
3. Bản chính thức của Điều khoản và Chính sách quyền riêng tư (cần người có chuyên môn pháp lý).
4. Duyệt kế hoạch v1 (`/api/v1`, B0–B5 và F1, F3–F9). Các phần frontend phụ thuộc v1 chưa làm: danh sách kết quả tìm kiếm, giải thích điểm.
5. Chọn `GEMINI_MODEL`: `gemini-3.5-flash-lite` (500 lượt/ngày) hay giữ `gemini-3.6-flash` (20 lượt/ngày), hoặc bật thanh toán.
6. Cho phép xóa các branch đã merge trên GitHub.
7. Duyệt PR #15: Nutella bị báo "ngoài phạm vi" do tag bột ca cao trên OFF (chi tiết ở mục 6).
8. Đối chiếu HSR calculator chính thức cho 6 mục trong `RULES_REVIEW_ITEMS` (`scoringRules.js`). Còn mục nào thì engine chưa trả `VERIFIED`.

### Chưa làm, cần backend và pháp lý
- `feat/auth-ui`: đăng nhập, đồng bộ lịch sử, xóa tài khoản. Điều kiện: backend auth + database, màn đồng ý, DPIA, cho xóa tài khoản ngay trong app (yêu cầu của Google Play và App Store), lịch sử chỉ lưu mã vạch và từ khóa để giảm rủi ro ODbL.

### Ghi nhận kỹ thuật (không chặn)
- Chuyển `zero_analysis_card.dart`, `tag_section.dart`, `ai_unavailable_card.dart` vào `widgets/product/`.
- Thống nhất độ rộng dòng `dart format` cho toàn repo, làm ở PR riêng.
  - Bẫy đã gặp: formatter của Dart 3.13 (style mới, bỏ qua dấu phẩy cuối) xuống dòng lại cả những dòng không liên quan trong file cũ.
  - Trước khi có PR thống nhất, chỉ format file mới (`dart format -l 120`); file cũ thì giữ style bằng tay.
- Tên tag OFF trong `backend/src/services/openFoodFacts/categoryResolver.js` (`en:yogurts`, `en:cheeses`, …) và tên field ước tính FVNL đang ở mức LIKELY. Cần kiểm tra trên response thật.
- Đo tỷ lệ FNS `NOT_SCORED` theo `reason_codes` sau khi deploy.
- Mã vạch dùng trong test backend phải đúng số kiểm tra GTIN, nếu không API trả 400 trước khi tới logic.
- `mobile_scanner`: app vào nền đúng lúc camera đang khởi động thì camera có thể vẫn chạy. Hạn chế của thư viện gốc.
- Nếu đổi `CACHE_TTL_HOURS` trên Render thì phải sửa câu "mặc định 24 giờ" trong `frontend/lib/content/legal_pages.dart` và `docs/PRIVACY_POLICY.md`.

---

## 6. Nhật ký công việc

Mục mới nhất ở trên. Mỗi mục ghi: ngày, PR, đã sửa gì ở file nào, vì sao, test đã chạy.

### 07/11/2026 — Merge FNS v1 và kiểm chứng trên production
- **Merge** (FLuw cho phép): #12 → #10 vào `main` (`514d505`); #14 → #13 → #11 vào `main` (`3b760d4`). Trước khi merge #11 đã kiểm tra hai điều: cây code giống hệt commit đã test `931411a` (0 file khác), và CI xanh.
- **Deploy:** Render tự deploy khoảng 90 giây sau merge. Response thật có `fns`; `aiAnalysis` không còn `score`.
- **Kết quả production (VERIFIED, 07/11/2026):**

| Mã vạch | Sản phẩm | `fns` | Ghi chú |
|---|---|---|---|
| `5449000000996` | Coca-Cola | `PROVISIONAL`, 0,0, C1 | Đúng, khớp Test A |
| `8934840000130` | Vĩnh Hảo | `OUT_OF_SCOPE` | Đúng, nước chưa chấm trong v1 |
| `8934563635138`, `8934673607827` | Hảo Hảo, Vinamilk sữa chua | `CATEGORY_UNRESOLVED` | Trên OFF các sản phẩm này không có `categories_tags`. Đúng thiết kế, nhưng nhiều sản phẩm Việt Nam sẽ chưa có điểm. |
| `3017620422003` | Nutella | `OUT_OF_SCOPE` | **Sai**, sửa ở PR #15 |

- **PR #15 `fix/fns-category-conflict`** (đang chờ duyệt):
  - Nguyên nhân: OFF gắn Nutella vừa là kem phết, vừa là `en:cocoa-and-chocolate-powders`.
  - Cách sửa: tách loại trừ cứng (`EXCLUDED_TAGS`, luôn `OUT_OF_SCOPE`) khỏi nhóm cần pha (`AS_PREPARED_TAGS`). Nhóm cần pha mà đi kèm tag thực phẩm thì trả `null`.
  - Test: `npm test` 150/150.
- **Việc tiếp theo quan trọng nhất:** sản phẩm Việt Nam thường thiếu `categories_tags` trên OFF. Muốn có điểm cho nhóm này cần thêm nguồn phân loại; đây là quyết định sản phẩm, chờ FLuw.

### 07/11/2026 — PR #14 `feat/fns-flutter`: Flutter hiển thị FNS 0–10
- **Thêm:**
  - `lib/models/fns_result.dart`: đọc object `fns`; điểm ngoài 0–10 hoặc trạng thái lạ thì không hiện điểm.
  - `lib/content/fns_copy.dart`: mọi câu chữ về FNS.
  - `lib/core/format/score_format.dart`: định dạng "7,8".
  - `lib/widgets/product/fns_not_scored_card.dart`, `fns_breakdown_card.dart` ("Cách Fluw tính điểm").
- **Sửa:**
  - `product_model.dart`: `score` int 0–100 → `fns`. `hasAnalysis` không còn phụ thuộc vào điểm.
  - `score_level.dart`: ngưỡng 6,7 / 3,3, nhãn Cao/Trung bình/Thấp.
  - `circular_score_ring.dart`, `score_pill.dart`, `score_summary_card.dart`: thang /10.
  - `product_detail_view.dart`: thẻ Zero đứng trước thẻ giải thích để khớp skeleton.
  - `product_summary.dart`, `ai_unavailable_card.dart` (một câu).
- **Bỏ:** mục "Lựa chọn lành mạnh hơn". Lý do: AI không được tự tạo sản phẩm thay thế.
- **Lý do sửa theo test:**
  - Skeleton lệch 47 px ở cỡ chữ 200%, vì hai chip xuống dòng tùy dữ liệu. Đã sửa bố cục, không nới lỏng test.
  - "Nhóm so sánh" dài ngắn tùy dữ liệu nên chuyển sang thẻ giải thích.
- **Sửa theo review độc lập:**
  - Lý do `OUT_OF_SCOPE` liệt kê đủ trà, cà phê, gia vị, muối, giấm.
  - Backend cũ không trả `fns` thì ghi "Chưa có kết quả chấm điểm".
  - "Đã xác minh" đổi thành "Số liệu đã đối chiếu".
- **Test:** `flutter analyze` sạch, `flutter test` 201/201 (Flutter 3.47.9). Không xóa test cũ, chỉ đổi giá trị mong đợi sang thang 0–10.

### 07/11/2026 — PR #13 `feat/fns-api-integration`: nối FNS vào API
- **Thêm:**
  - `backend/src/services/openFoodFacts/categoryResolver.js`: từ `categories_tags` ra nhóm C1…C3D. Không chắc thì trả `null`; nhóm ngoài phạm vi trả `OUT_OF_SCOPE`.
  - `fnsInputMapper.js`: natri g → mg, basis theo đơn vị gói, FVNL ước tính.
  - `backend/tests/fnsIntegration.test.js`.
- **Sửa:**
  - `openFoodFactsClient.js`: lấy thêm `categories_tags`, `quantity`, `product_quantity_unit`, `serving_quantity`.
  - `productNormalizer.js`: thêm kJ không làm tròn, béo bão hòa, đường, xơ, natri, muối, canxi, ước tính FVNL.
  - `productService.js`, `productController.js`: thêm `fns` vào response.
  - `analysisPrompt.js`, `analysisParser.js`, `aiService.js`: Gemini nhận FNS để giải thích. Điểm AI tự trả bị bỏ; `alternatives` luôn `[]`.
  - `README.md`.
  - Engine: thêm `OUT_OF_SCOPE`, `FVNL_ESTIMATED`, `baseline_components`.
- **Lý do:** thiếu FVNL làm gần như mọi sản phẩm `RATING_AMBIGUOUS`. OFF có ước tính FVNL từ thành phần, nên dùng ước tính đó kèm cờ, thay vì điền 0.
- **Sửa theo review độc lập (lỗi nghiêm trọng, phát hiện trước khi push):**
  - Bản đầu mặc định C2 cho mọi tag lạ, nên sản phẩm chỉ có tag `vi:` bị chấm theo nhóm sai: nước ngọt ra 6,7 thay vì 0.
  - Nay C2 cần tag thuộc `FOOD_TAGS`.
  - `en:butters` chỉ tính là bơ khi kèm `en:dairies`.
  - Sữa chua uống không bị đoán nhóm.
  - Dầu ăn bỏ ước tính FVNL dương.
- **Test:** `npm test` 149/149. Đã có test cho các ca: Gemini lỗi thì điểm FNS không đổi; thiếu FVNL thì `NOT_SCORED`; tag lạ hoặc tag tiếng Việt thì không đoán nhóm.

### 07/11/2026 — PR #11 `feat/fns-engine-v1`: engine FNS v1
- **Thêm:**
  - `backend/src/services/scoring/`, 9 file, mỗi file một trách nhiệm: bảng HSR v9 Tables 1–7 có version và deep-freeze, tra điểm, kiểm tra đầu vào, baseline, modifier, quy đổi 0–10, mã lý do, bộ điều phối.
  - `backend/tests/fns{Rules,Normalizer,Engine}.test.js`, `docs/ADR-001-FNS-V1.md`.
- **Cách xử lý dữ liệu thiếu:** tính cận tốt nhất và tệ nhất của điểm thô, chỉ chấm khi hai cận cùng mức. Đã có property test vét cạn cho cách này.
- **Lý do sửa theo review (agent độc lập):**
  - Chặn `VERIFIED` khi bộ quy tắc còn `NEEDS_REVIEW`.
  - Test Table 7 gõ tay độc lập.
  - `"<x"` là khoảng mở.
  - Chặn giá trị vượt giới hạn vật lý.
- **Test:** `npm test` 129/129 lúc mở PR; CI backend và frontend đều success.
- **Sự cố quy trình:** khi cài Flutter trên cloud đã lỡ chạy `git config --global --add safe.directory`. Đã gỡ ngay; cách đúng là `chown` thư mục SDK.

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
