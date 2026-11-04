# Tài liệu bàn giao dự án Fluw

**Ứng dụng:** Fluw, quét mã vạch thực phẩm và phân tích dinh dưỡng bằng AI **Zero**
**Cập nhật:** 04/11/2026, phần backend theo API v1 (nhánh `chore/remove-legacy-api`, đã gỡ route cũ `/api/product/:query`)
**Phiên bản app:** 1.0.0+1

> File này dành cho lập trình viên. Bản tóm tắt dễ đọc cho mọi người là `FLUW_PROJECT_HANDOFF.docx`.

---

## 1. Luồng chính

Người dùng quét mã vạch hoặc tìm theo tên → app gọi `GET /api/v1/search` (chọn sản phẩm trong danh sách) hoặc thẳng `GET /api/v1/products/:barcode` → backend lấy dữ liệu Open Food Facts và tính **Điểm Fluw** 0–100 bằng công thức công khai → app hiển thị sản phẩm, điểm và cách tính → khi người dùng bấm "Hỏi Zero", app gọi `GET /api/v1/products/:barcode/analysis` để Gemini giải thích điểm (AI không chấm điểm).

Mức điểm do backend tính và gửi kèm nhãn (đặc tả: `docs/SCORING.md`):

| Điểm | Mức (`level`) | Nhãn |
| :--- | :--- | :--- |
| 70-100 | `good` | Tốt |
| 40-69 | `moderate` | Trung bình |
| 0-39 | `limit` | Nên hạn chế |

Thiếu dữ liệu cần thiết (danh mục, chỉ số dinh dưỡng, chất xơ, % rau củ quả, thành phần) thì không chấm và ghi "Chưa đủ dữ liệu".

## 2. Hạ tầng

| Thành phần | Công nghệ | Ghi chú |
| :--- | :--- | :--- |
| Repository | GitHub `Fluw13/Fluwwwwww` | Nhánh chính `main` |
| Backend | Node.js, Express 5 | Entry `backend/server.js` |
| Hosting | Render, `https://fluw.onrender.com` | Deploy tự động từ `main` |
| AI | `@google/genai`, model đọc từ `GEMINI_MODEL` | Mặc định `gemini-3.5-flash-lite`; biến trên Render được ưu tiên |
| Dữ liệu thực phẩm | OpenFoodFacts | API v2 theo mã vạch, `search.openfoodfacts.org` theo tên |
| Mobile | Flutter (Dart SDK `^3.13.7`) | Android là mục tiêu chính, `applicationId = com.fluw.app` |
| Ký app Android | `frontend/android/app/upload-keystore.jks`, alias `upload` | Mật khẩu trong `frontend/android/key.properties`, không commit |

## 3. Backend (`backend/`)

Hợp đồng API đầy đủ: `docs/API_CONTRACT_v1.md`; phản hồi mẫu: `contracts/fixtures/`. Quyết định kiến trúc: `docs/adr/`.

| File / thư mục | Vai trò |
| :--- | :--- |
| `server.js` | Nạp `.env`, khởi động server, dừng êm khi nhận `SIGTERM`/`SIGINT` |
| `src/app.js` | Cấu hình Express: CORS, `trust proxy`, `/health`, mount `/api/v1`, xử lý lỗi |
| `src/routes/v1/`, `src/controllers/v1/` | `search`, `products/:barcode`, `products/:barcode/analysis` |
| `src/middlewares/routeRateLimiters.js` | Giới hạn mỗi IP mỗi phút cho từng route |
| `src/middlewares/errorHandler.js` | Trả lỗi dạng JSON; lỗi lạ trả 500, không lộ chi tiết |
| `src/validators/` | `barcodeValidator` (GTIN 8–14 số, số kiểm tra, chuẩn hóa), `gtinCheckDigit`, `searchQueryValidator` |
| `src/services/search/` | `searchService` (tìm, tìm thêm không dấu, cache), `searchRanker` (xếp hạng, kết quả gần đúng) |
| `src/search/foldVietnamese.js` | Bỏ dấu tiếng Việt, nhận biết từ khóa có dấu |
| `src/services/productDetailsService.js` | Sản phẩm + điểm, cache, gộp request trùng |
| `src/services/analysisService.js` | Zero giải thích điểm: kiểm tra cấu hình, hạn mức ngày, cache theo phiên bản điểm |
| `src/services/openFoodFacts/openFoodFactsClient.js` | Gọi Open Food Facts (User-Agent, timeout 10 s, `fields=`), phân loại lỗi 404/429/502/504 |
| `src/services/openFoodFacts/upstreamBudget.js` | Giới hạn lượt gọi Open Food Facts toàn server (14 đọc + 9 tìm mỗi phút) |
| `src/services/openFoodFacts/*Mapper.js` | Chuyển dữ liệu Open Food Facts sang contract: ảnh, dinh dưỡng, thành phần, phụ gia, dị ứng, dữ liệu tính điểm, kết quả tìm |
| `src/scoring/` | Tính Điểm Fluw (hàm thuần): `computeFluwScore`, `nutrition/*`, `additives/*`, `scoreVersion`, `scoreLabels`, `scoreLevel` |
| `src/services/ai/geminiClient.js` | Gọi Gemini (timeout 15 s, thử lại 1 lần với lỗi tạm thời, 429 không thử lại) |
| `src/services/ai/explanationPrompt.js`, `explanationParser.js` | Prompt + schema không có trường điểm; kiểm tra đầu ra |
| `src/services/ai/aiUsageGuard.js` | Giới hạn lượt gọi Gemini mỗi ngày (`AI_DAILY_LIMIT`) |
| `src/services/ai/delimitedJson.js` | Đặt dữ liệu cộng đồng trong khối `<product_data>` đã escape (chống prompt injection) |
| `src/cache/TtlCache.js` | Cache trong bộ nhớ có hạn dùng và giới hạn số mục |
| `src/config/env.js` | Đọc số nguyên dương từ biến môi trường |
| `src/errors/` | `AppError`, danh sách mã lỗi `errorCodes` (gồm `AI_*`) |
| `scripts/contractFixtures/` | Tạo lại `contracts/fixtures` (`npm run contract:fixtures`) |

### Biến môi trường

Xem `backend/.env.example` và README: `GEMINI_API_KEY` (bắt buộc), `GEMINI_MODEL`, `GEMINI_TIMEOUT_SECONDS`, `AI_DAILY_LIMIT`, `PORT`, `OFF_CONTACT_EMAIL`, `OFF_READS_PER_MINUTE`, `OFF_SEARCHES_PER_MINUTE`, `SEARCH_RATE_LIMIT_PER_MINUTE`, `PRODUCT_RATE_LIMIT_PER_MINUTE`, `ANALYSIS_RATE_LIMIT_PER_MINUTE`, `TRUST_PROXY_HOPS`, `CORS_ORIGINS`, `CACHE_TTL_HOURS`, `CACHE_MAX_ENTRIES`, `SEARCH_CACHE_TTL_MINUTES`.

## 4. Frontend (`frontend/lib/`)

App chỉ gọi API v1 (`docs/API_CONTRACT_v1.md`). Điểm Fluw do backend tính (`docs/SCORING.md`); app chỉ hiển thị, không tự tính hay tự áp ngưỡng. Zero (AI) chỉ giải thích điểm, không có điểm. Quy ước giao diện: `docs/FRONTEND_UI_FOUNDATION.md`.

| File / thư mục | Vai trò |
| :--- | :--- |
| `main.dart` | Tạo `FluwApiClient` dùng chung cả phiên và `ThemeModeController`, dựng `FluwApp` |
| `data/api/fluw_api_client.dart` | Gọi `/health`, `/api/v1/search`, `/api/v1/products/:barcode`, `/api/v1/products/:barcode/analysis`. Origin qua `--dart-define=API_ORIGIN` (`api_config.dart`, mặc định `https://fluw.onrender.com`). Timeout 70/70/90 s đến khi máy chủ trả lời, sau đó 20/20/35 s (`api_timeouts.dart`). Hủy request khi rời màn (`ApiCancelToken`, `AbortableRequest`). Không ghi log URL |
| `data/api/fluw_api_exception.dart`, `api_error_kind.dart` | Lỗi có kiểu: mã server, HTTP status, `Retry-After` (số giây hoặc HTTP-date), mạng, timeout, đã hủy, phản hồi không hợp lệ |
| `data/api/fluw_api_scope.dart` | Đưa client xuống cây widget (test thay bằng API giả) |
| `models/search/`, `models/product/`, `models/score/`, `models/analysis/` | Model v1, đọc an toàn mọi trường có thể `null` |
| `models/score_level.dart` | Mức `good` / `moderate` / `limit` theo mã backend; nhãn chữ lấy từ `score.total.label` |
| `core/search/search_input.dart` | Phân loại ô tìm: 8/12/13/14 chữ số mở thẳng sản phẩm, từ khóa 2–100 ký tự có chữ/số mới tìm |
| `core/navigation/app_routes.dart` | Nơi duy nhất mở sản phẩm / tìm kiếm (màn chính, kết quả, máy quét) |
| `core/format/` | Số kiểu Việt, ngày, câu chữ của điểm (`score_format.dart`), câu lỗi AI |
| `core/scanner/` | Chọn mã vạch hợp lệ từ camera, lý do thoát máy quét |
| `screens/home_screen.dart` | Ô tìm kiếm (chỉ gửi khi bấm tìm), nút quét |
| `screens/scanner_screen.dart` | Camera `mobile_scanner` (EAN/UPC), khung quét, đèn, nhập tay |
| `screens/search_results_screen.dart` | Kết quả tìm, gần đúng, rỗng, lỗi, 429 đếm ngược |
| `screens/product_detail_screen.dart` | Tải sản phẩm v1, lỗi + thử lại, dựng `ProductDetailView` |
| `screens/score_explanation_screen.dart` | "Cách Fluw tính điểm": từng chỉ số, dải, phụ gia, mục thiếu, NOVA, nguồn |
| `screens/product_image_screen.dart` | Xem ảnh lớn; chỉ ở đây mới tải ảnh gốc |
| `widgets/product/` | Khung chi tiết dùng chung (`ProductDetailView`, `ProductDetailLayout`), skeleton cùng bố cục, thẻ điểm, dinh dưỡng, thành phần, phụ gia, nguồn dữ liệu, `ZeroAnalysisSection` |
| `widgets/score/` | Phần dùng chung của thẻ điểm và màn giải thích |
| `widgets/search/` | Thẻ kết quả tìm kiếm, danh sách, màn tải |
| `widgets/zero_analysis_card.dart` | Thẻ Zero: "Hỏi Zero", đang viết, kết quả, lỗi; nhãn "Nội dung do AI tạo" |
| `widgets/circular_score_ring.dart` | Vòng điểm, màu theo mức backend |
| `widgets/tag_section.dart` | Danh sách thẻ (dị ứng, "có thể chứa") |
| `widgets/async/` | `AsyncContent`, `ErrorRetryView`, `ApiErrorView`, nút thử lại đếm ngược, banner trạng thái tải |

Thư mục `linux/`, `macos/`, `windows/` được giữ để có thể build bản desktop; `web/` dùng khi chạy `flutter run -d chrome`.

## 5. Chạy và kiểm thử

```bash
cd backend && cp .env.example .env && npm install && npm run dev
cd backend && npm test
cd frontend && flutter pub get && flutter run
cd frontend && flutter analyze && flutter test
```

GitHub Actions (`.github/workflows/ci.yml`) tự chạy `npm test` và `flutter analyze`/`flutter test` cho mỗi pull request và mỗi lần push lên `main`.

## 6. Nhật ký sửa lỗi QA (29/10/2026, sau PR #1)

QA rà lại `main` sau PR #1 theo danh sách 19 lỗi đã báo cáo. PR #1 đã xử lý phần lớn; ba lỗi còn lại được sửa trong đợt này:

| Mã | Lỗi | Cách sửa |
| :--- | :--- | :--- |
| BE-02 | Gemini lỗi hoặc thiếu `GEMINI_API_KEY` làm cả request thất bại, mất luôn dữ liệu sản phẩm; app ném lỗi khi thiếu điểm | Backend trả 200 với `aiAnalysis: null` + `aiError`, không lưu cache kết quả này. App ẩn vòng điểm, hiện thẻ "Chưa có đánh giá AI" kèm lý do |
| BE-03 | Thiếu giá trị trên 100 g thì backend lấy giá trị theo khẩu phần, hiển thị sai số liệu | Chỉ đọc khóa `_100g` |
| BE-04 | Sản phẩm chỉ có năng lượng theo kJ hiển thị "—" ở ô Calo | Quy đổi kJ sang kcal |

Kiểm thử: backend `npm test` 32/32. Frontend được kiểm tra bằng `flutter analyze`/`flutter test` trên GitHub Actions.

### Đợt sửa lỗi 30/10/2026 (phát hiện khi chạy thử trên production)

| Lỗi | Cách sửa |
| :--- | :--- |
| Gemini thỉnh thoảng lỗi tạm thời, app hiện "Chưa có đánh giá AI" dù gọi lại thì được | Bật thử lại 1 lần của SDK cho lỗi 408, 429, 500, 502-504 và lỗi mạng, dùng chung timeout của lần gọi (lần 3: bỏ thử lại với 429) |
| Tìm "mì hảo hảo" ra "Nước khoáng Vĩnh Hảo" do chỉ lấy kết quả đầu tiên | Lấy 10 kết quả, chọn kết quả khớp nhiều từ nhất |
| App có thể báo quá thời gian khi Render vừa khởi động (~50 s) | Timeout app 120 s, đánh thức server khi mở màn hình chính, gợi ý trên màn hình chờ |
| Mã vạch sai số kiểm tra vẫn gửi đi OpenFoodFacts và báo "không tìm thấy" | Kiểm tra số kiểm tra mã 12-14 chữ số, trả 400 |
| Sản phẩm chỉ có `energy-kj_100g` hiện "—" ở ô Calo | Đọc thêm `energy-kj_100g` khi thiếu `energy_100g` |

Kiểm thử: backend `npm test` 67/67 (sau khi gộp với PR #2); chạy thử thủ công server thật với OpenFoodFacts và Gemini giả lập; frontend kiểm tra bằng `flutter analyze`/`flutter test` trên GitHub Actions. Review độc lập: xem PR #3.

Rủi ro đã biết: một số ít sản phẩm trên OpenFoodFacts được lưu dưới mã vạch sai số kiểm tra (do người đóng góp nhập sai) sẽ không tra được bằng mã đó; khi Gemini hết hạn mức (429) thì app chỉ hiện dữ liệu sản phẩm (`AI_RATE_LIMITED`, từ lần 3 không còn thử lại) — hạn mức gói miễn phí là rủi ro vận hành.

### Đợt sửa lỗi 30/10/2026 (lần 2, sau khi deploy PR #3)

| Lỗi | Bằng chứng | Cách sửa |
| :--- | :--- | :--- |
| Tìm "mì hảo hảo" (có dấu) vẫn ra "Nước khoáng Vĩnh Hảo"; "mi hao hao" thì đúng | Production sau PR #3 | Đếm cả từ lặp lại ("hảo hảo" khớp "Hao Hao" 2 lần, "Vĩnh Hảo" 1 lần), từ có cả ở tên và thương hiệu chỉ tính một lần; bằng điểm thì ưu tiên sản phẩm có tên, rồi (từ khóa từ 2 từ) tên ít từ thừa; chấm riêng tên tiếng Việt và tiếng Anh |
| Gemini đôi khi chậm quá 20 giây, app hiện "Chưa có đánh giá AI" | Production: "sữa chua vinamilk" trả `AI_UNAVAILABLE` sau 20,47 s, gọi lại có điểm sau 7,3 s. Nguyên nhân hết giờ là LIKELY (chưa đối chiếu log Render) | Timeout Gemini 20 → 40 giây (vẫn nằm trong 120 giây của app) |

Đánh đổi đã chấp nhận: với từ khóa từ 2 từ trở lên, khi số từ khớp bằng nhau thì tên ngắn hơn được ưu tiên hơn thứ tự của máy tìm kiếm (ví dụ "sữa chua vinamilk" chọn "Sữa chua Vinamilk" thay vì "Sữa chua ăn Vinamilk có đường").

### Đợt sửa lỗi 30/10/2026 (lần 3, sau khi deploy PR #4)

| Lỗi | Bằng chứng | Cách sửa |
| :--- | :--- | :--- |
| "mì hảo hảo", "hảo hảo" vẫn ra sai sản phẩm | Production sau PR #4: ra "Mì" (Koreno) và nước Vĩnh Hảo; "mi hao hao" thì đúng. Suy ra máy tìm kiếm không trả mì Hảo Hảo trong 10 kết quả đầu khi từ khóa có dấu | Khi kết quả đầu không khớp đủ từ và từ khóa có dấu, tìm thêm bằng bản không dấu (timeout 5 s; lỗi thì vẫn dùng kết quả lần đầu) rồi gộp |
| Gemini trả `AI_UNAVAILABLE` chỉ sau ~2 giây | Production: 5/6 lượt lỗi trong 1,6-2,4 s (không phải timeout). Gói miễn phí của `gemini-3.6-flash` chỉ có 5 lượt/phút, 20 lượt/ngày (nguồn thứ cấp). Nguyên nhân hết hạn mức là LIKELY, chưa xem được log Render | Lỗi 429 không thử lại nữa (thử lại chỉ tốn thêm hạn mức) và trả mã riêng `AI_RATE_LIMITED`; app hiện "Zero đã hết lượt phân tích" |

Sau khi deploy, mã `aiError` trên production sẽ cho biết chắc lỗi Gemini có phải hết hạn mức hay không.

## 7. Việc còn mở

### Cần chủ dự án quyết định hoặc cung cấp
- [ ] Email liên hệ thật cho `docs/PRIVACY_POLICY.md` và User-Agent gửi OpenFoodFacts (đang là `contact@fluw.app`).
- [ ] Đăng chính sách quyền riêng tư lên URL công khai cho Google Play.
- [ ] `ndkVersion = "30.0.16248370"` đang cố định trong `android/app/build.gradle.kts`, máy khác có thể không có bản NDK này.
- [ ] Hạn mức Gemini gói miễn phí: mặc định trong code đã là `gemini-3.5-flash-lite` (500 lượt/ngày theo nguồn thứ cấp) và `AI_DAILY_LIMIT=200`, nhưng nếu Render đang đặt `GEMINI_MODEL=gemini-3.6-flash` (20 lượt/ngày) thì biến đó được ưu tiên. Cần kiểm tra và sửa biến trên Render, hoặc bật thanh toán.
- [ ] Cache hiện nằm trong bộ nhớ, mất khi server khởi động lại. Khi có database có thể chuyển sang cache bền vững.
- [ ] Android cần `minSdkVersion 23` (bản bàn giao cũ ghi app crash camera trên máy thật nếu thấp hơn). Giá trị này đang đặt trong `android/local.properties`, file không được commit, nên máy khác sẽ không có.

### Lộ trình sản phẩm (đề xuất, chưa triển khai)
- [ ] Database và đăng nhập (Supabase hoặc Firebase): `users`, `food_logs`, `favorites`.
- [ ] Theo dõi dinh dưỡng: mục tiêu calo (TDEE), tổng macro theo ngày, biểu đồ tuần/tháng.
- [ ] Phát hành Google Play: tài khoản Play Console, ảnh giới thiệu, icon 1024x1024.
- [ ] Xem lại sản phẩm đã quét khi offline.
- [ ] Nhận diện món ăn không có mã vạch bằng ảnh.
