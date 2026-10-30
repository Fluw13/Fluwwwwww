# Tài liệu bàn giao dự án Fluw

**Ứng dụng:** Fluw, quét mã vạch thực phẩm và phân tích dinh dưỡng bằng AI **Zero**
**Cập nhật:** 29/10/2026, theo code trên nhánh `main` (sau khi gộp PR #1 và đợt sửa lỗi QA cùng ngày)
**Phiên bản app:** 1.0.0+1

> File này dành cho lập trình viên. Bản tóm tắt dễ đọc cho mọi người là `FLUW_PROJECT_HANDOFF.docx`.

---

## 1. Luồng chính

Người dùng quét mã vạch hoặc nhập tên sản phẩm → Flutter gọi `GET /api/product/:query` → backend tra cứu OpenFoodFacts → Gemini (Zero) chấm điểm 0-100 → app hiển thị kết quả.

Điểm sức khỏe dùng 3 mức, định nghĩa tại `frontend/lib/models/score_level.dart`:

| Điểm | Mức | Màu |
| :--- | :--- | :--- |
| 70-100 | Tốt | Xanh `#00E676` |
| 40-69 | Trung bình | Vàng `#FFD600` |
| 0-39 | Kém | Đỏ `#FF3D00` |

## 2. Hạ tầng

| Thành phần | Công nghệ | Ghi chú |
| :--- | :--- | :--- |
| Repository | GitHub `Fluw13/Fluwwwwww` | Nhánh chính `main` |
| Backend | Node.js, Express 5 | Entry `backend/server.js` |
| Hosting | Render, `https://fluw.onrender.com` | Deploy tự động từ `main` |
| AI | `@google/genai`, model đọc từ `GEMINI_MODEL` | Mặc định `gemini-3.6-flash` |
| Dữ liệu thực phẩm | OpenFoodFacts | API v2 theo mã vạch, `search.openfoodfacts.org` theo tên |
| Mobile | Flutter (Dart SDK `^3.13.7`) | Android là mục tiêu chính, `applicationId = com.fluw.app` |
| Ký app Android | `frontend/android/app/upload-keystore.jks`, alias `upload` | Mật khẩu trong `frontend/android/key.properties`, không commit |

## 3. Backend (`backend/`)

| File | Vai trò |
| :--- | :--- |
| `server.js` | Nạp `.env`, khởi động server |
| `src/app.js` | Cấu hình Express: CORS, `trust proxy`, `/health`, mount route, xử lý lỗi |
| `src/routes/productRoutes.js` | `GET /:query` |
| `src/controllers/productController.js` | Nhận request, trả JSON và header `X-Cache` |
| `src/services/productService.js` | Điều phối: kiểm tra đầu vào, cache, gộp request trùng, gọi dữ liệu rồi AI; AI lỗi thì vẫn trả dữ liệu sản phẩm |
| `src/validators/productQueryValidator.js` | Kiểm tra từ khóa, nhận diện mã vạch |
| `src/validators/gtinCheckDigit.js` | Kiểm tra số kiểm tra mã vạch 12-14 chữ số |
| `src/search/pickBestSearchHit.js` | Chọn kết quả tìm theo tên khớp nhiều từ nhất |
| `src/search/foldVietnamese.js` | Bỏ dấu tiếng Việt, nhận biết từ khóa có dấu |
| `src/services/openFoodFacts/productSearch.js` | Tìm theo tên; khi cần thì tìm thêm bản không dấu và gộp kết quả |
| `src/cache/TtlCache.js` | Cache trong bộ nhớ có hạn dùng và giới hạn số mục |
| `src/cache/productCacheKey.js` | Tạo khóa cache từ mã vạch hoặc tên đã chuẩn hóa |
| `src/config/env.js` | Đọc số nguyên dương từ biến môi trường |
| `src/services/foodApiService.js` | Chọn tra theo mã vạch hay theo tên, trả sản phẩm đã chuẩn hóa |
| `src/services/openFoodFacts/openFoodFactsClient.js` | Gọi OpenFoodFacts (User-Agent, timeout 10 s, `fields=`, ưu tiên tiếng Việt), phân loại lỗi 404/429/502/504 |
| `src/services/openFoodFacts/productNormalizer.js` | Chuẩn hóa dữ liệu sản phẩm (chỉ số liệu 100 g, kJ sang kcal) |
| `src/services/openFoodFacts/allergenMapper.js` | Đổi mã dị ứng sang tên tiếng Việt |
| `src/services/aiService.js` | Ghép prompt, gọi Gemini, kiểm tra phản hồi |
| `src/services/ai/geminiClient.js` | Gọi Gemini (timeout 40 s, thử lại 1 lần với lỗi tạm thời) |
| `src/services/ai/analysisPrompt.js` | Prompt, quy tắc chống prompt injection, schema đầu ra |
| `src/services/ai/analysisParser.js` | Kiểm tra và làm sạch đầu ra của Gemini |
| `src/middlewares/errorHandler.js` | Trả lỗi dạng JSON; lỗi lạ trả 500, không lộ chi tiết |
| `src/middlewares/rateLimiter.js` | Giới hạn số lần tra cứu theo IP |
| `src/errors/AppError.js` | Lỗi có mã HTTP và mã lỗi tùy chọn |
| `src/errors/errorCodes.js` | Danh sách mã lỗi trả về cho app (`INVALID_BARCODE`, `PRODUCT_NOT_FOUND`, `AI_*`...) |

### API contract

`GET /api/product/:query`, với `query` là mã vạch 8-14 chữ số hoặc tên sản phẩm (tối đa 100 ký tự). Mã 12-14 chữ số sai số kiểm tra trả 400.

```json
{
  "success": true,
  "barcode": "8934563138165",
  "product": {
    "barcode": "8934563138165",
    "product_name": "…",
    "brands": "…",
    "image_front_url": "https://…",
    "ingredients_text": "… hoặc null",
    "allergens": ["sữa"],
    "nutriments": { "energy-kcal": 450, "proteins": 9, "fat": null, "carbohydrates": 62 }
  },
  "aiAnalysis": {
    "score": 35,
    "deepThink": "…",
    "recommendation": "…",
    "allergens": ["…"],
    "alternatives": ["…"]
  },
  "aiError": null
}
```

- `nutriments`: chỉ đọc giá trị trên 100 g (khóa `_100g` của OpenFoodFacts), không bao giờ dùng giá trị theo khẩu phần. `null` là không có dữ liệu, khác với `0`. Nếu chỉ có năng lượng theo kJ thì quy đổi sang kcal (chia 4,184, làm tròn 1 chữ số thập phân).
- `product.allergens`: lấy từ nhãn (OpenFoodFacts). `aiAnalysis.allergens`: AI gợi ý thêm từ danh sách thành phần.
- `aiAnalysis` có thể là `null` khi Gemini lỗi, quá hạn, trả kết quả không hợp lệ hoặc chưa cấu hình key. Khi đó vẫn trả HTTP 200 kèm dữ liệu sản phẩm, và `aiError` là `AI_NOT_CONFIGURED`, `AI_UNAVAILABLE`, `AI_RATE_LIMITED` (Gemini hết hạn mức, HTTP 429) hoặc `AI_INVALID_RESPONSE`. Kết quả thiếu phân tích AI không được lưu cache.
- Lỗi: `{ "success": false, "error": "…", "code": "<MÃ_LỖI>" }` (danh sách mã: README), mã 400 (đầu vào sai), 404 (không tìm thấy), 429 (quá giới hạn), 502/504 (OpenFoodFacts lỗi hay quá hạn), 500 (lỗi không lường trước).

### Biến môi trường

Xem `backend/.env.example` và README: `GEMINI_API_KEY` (bắt buộc), `GEMINI_MODEL`, `PORT`, `RATE_LIMIT_WINDOW_MINUTES`, `RATE_LIMIT_MAX_REQUESTS`, `TRUST_PROXY_HOPS`, `CORS_ORIGINS`, `CACHE_TTL_HOURS`, `CACHE_MAX_ENTRIES`.

## 4. Frontend (`frontend/lib/`)

| File | Vai trò |
| :--- | :--- |
| `main.dart` | Theme Material 3, màn hình đầu |
| `core/app_colors.dart` | Bảng màu dùng chung |
| `models/product_model.dart` | Parse phản hồi API; `score` là `null` khi không có phân tích AI |
| `models/score_level.dart` | Ngưỡng điểm, nhãn và màu |
| `services/api_service.dart` | Gọi API (timeout 120 s để chờ Render khởi động, `ApiException`), đánh thức server qua `/health`, URL qua `--dart-define=API_BASE_URL` |
| `screens/home_screen.dart` | Ô tìm kiếm, nút quét |
| `screens/scanner_screen.dart` | Camera `mobile_scanner`, chỉ EAN/UPC |
| `screens/product_detail_screen.dart` | Loading, lỗi + thử lại, kết quả |
| `widgets/circular_score_ring.dart` | Vòng điểm |
| `widgets/product/` | Khung chi tiết dùng chung (`ProductDetailView`, `ProductDetailLayout`) và skeleton cùng bố cục; xem `docs/FRONTEND_UI_FOUNDATION.md` |
| `widgets/zero_analysis_card.dart` | Phân tích Zero và tuyên bố miễn trừ AI |
| `widgets/tag_section.dart` | Danh sách thẻ (dị ứng, gợi ý thay thế) |
| `widgets/ai_unavailable_card.dart` | Thẻ "Chưa có đánh giá AI" kèm lý do, hiện thay cho vòng điểm |

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
- [ ] Hạn mức Gemini gói miễn phí (20 lượt/ngày với `gemini-3.6-flash`) không đủ cho app thật. Cần chọn: đổi `GEMINI_MODEL` sang model có hạn mức cao hơn (ví dụ `gemini-3.5-flash-lite`, 500 lượt/ngày) hoặc bật thanh toán.
- [ ] Cache hiện nằm trong bộ nhớ, mất khi server khởi động lại. Khi có database có thể chuyển sang cache bền vững.
- [ ] Android cần `minSdkVersion 23` (bản bàn giao cũ ghi app crash camera trên máy thật nếu thấp hơn). Giá trị này đang đặt trong `android/local.properties`, file không được commit, nên máy khác sẽ không có.

### Lộ trình sản phẩm (đề xuất, chưa triển khai)
- [ ] Database và đăng nhập (Supabase hoặc Firebase): `users`, `food_logs`, `favorites`.
- [ ] Theo dõi dinh dưỡng: mục tiêu calo (TDEE), tổng macro theo ngày, biểu đồ tuần/tháng.
- [ ] Phát hành Google Play: tài khoản Play Console, ảnh giới thiệu, icon 1024x1024.
- [ ] Xem lại sản phẩm đã quét khi offline.
- [ ] Nhận diện món ăn không có mã vạch bằng ảnh.
