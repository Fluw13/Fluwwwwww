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
| `src/cache/TtlCache.js` | Cache trong bộ nhớ có hạn dùng và giới hạn số mục |
| `src/cache/productCacheKey.js` | Tạo khóa cache từ mã vạch hoặc tên đã chuẩn hóa |
| `src/config/env.js` | Đọc số nguyên dương từ biến môi trường |
| `src/services/foodApiService.js` | Gọi OpenFoodFacts (ưu tiên tiếng Việt), chuẩn hóa dữ liệu, phân loại lỗi 404/502/504 |
| `src/services/aiService.js` | Gọi Gemini, prompt, schema, kiểm tra phản hồi |
| `src/middlewares/errorHandler.js` | Trả lỗi dạng JSON; lỗi lạ trả 500, không lộ chi tiết |
| `src/middlewares/rateLimiter.js` | Giới hạn số lần tra cứu theo IP |
| `src/errors/AppError.js` | Lỗi có mã HTTP và mã lỗi tùy chọn (`AI_*`) |

### API contract

`GET /api/product/:query`, với `query` là mã vạch 8-14 chữ số hoặc tên sản phẩm (tối đa 100 ký tự).

```json
{
  "success": true,
  "barcode": "8934563138164",
  "product": {
    "barcode": "8934563138164",
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
- `aiAnalysis` có thể là `null` khi Gemini lỗi, quá hạn, trả kết quả không hợp lệ hoặc chưa cấu hình key. Khi đó vẫn trả HTTP 200 kèm dữ liệu sản phẩm, và `aiError` là `AI_NOT_CONFIGURED`, `AI_UNAVAILABLE` hoặc `AI_INVALID_RESPONSE`. Kết quả thiếu phân tích AI không được lưu cache.
- Lỗi: `{ "success": false, "error": "…" }`, mã 400 (đầu vào sai), 404 (không tìm thấy), 429 (quá giới hạn), 502/504 (OpenFoodFacts lỗi hay quá hạn), 500 (lỗi không lường trước).

### Biến môi trường

Xem `backend/.env.example` và README: `GEMINI_API_KEY` (bắt buộc), `GEMINI_MODEL`, `PORT`, `RATE_LIMIT_WINDOW_MINUTES`, `RATE_LIMIT_MAX_REQUESTS`, `TRUST_PROXY_HOPS`, `CORS_ORIGINS`, `CACHE_TTL_HOURS`, `CACHE_MAX_ENTRIES`.

## 4. Frontend (`frontend/lib/`)

| File | Vai trò |
| :--- | :--- |
| `main.dart` | Theme Material 3, màn hình đầu |
| `core/app_colors.dart` | Bảng màu dùng chung |
| `models/product_model.dart` | Parse phản hồi API; `score` là `null` khi không có phân tích AI |
| `models/score_level.dart` | Ngưỡng điểm, nhãn và màu |
| `services/api_service.dart` | Gọi API (timeout 60 s, `ApiException`), URL qua `--dart-define=API_BASE_URL` |
| `screens/home_screen.dart` | Ô tìm kiếm, nút quét |
| `screens/scanner_screen.dart` | Camera `mobile_scanner`, chỉ EAN/UPC |
| `screens/product_detail_screen.dart` | Loading, lỗi + thử lại, kết quả |
| `widgets/circular_score_ring.dart` | Vòng điểm |
| `widgets/macro_bar.dart` | 4 chỉ số dinh dưỡng, "—" khi thiếu dữ liệu |
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

## 7. Việc còn mở

### Cần chủ dự án quyết định hoặc cung cấp
- [ ] Email liên hệ thật cho `docs/PRIVACY_POLICY.md` và User-Agent gửi OpenFoodFacts (đang là `contact@fluw.app`).
- [ ] Đăng chính sách quyền riêng tư lên URL công khai cho Google Play.
- [ ] `ndkVersion = "30.0.16248370"` đang cố định trong `android/app/build.gradle.kts`, máy khác có thể không có bản NDK này.
- [ ] Cache hiện nằm trong bộ nhớ, mất khi server khởi động lại. Khi có database có thể chuyển sang cache bền vững.
- [ ] Android cần `minSdkVersion 23` (bản bàn giao cũ ghi app crash camera trên máy thật nếu thấp hơn). Giá trị này đang đặt trong `android/local.properties`, file không được commit, nên máy khác sẽ không có.

### Lộ trình sản phẩm (đề xuất, chưa triển khai)
- [ ] Database và đăng nhập (Supabase hoặc Firebase): `users`, `food_logs`, `favorites`.
- [ ] Theo dõi dinh dưỡng: mục tiêu calo (TDEE), tổng macro theo ngày, biểu đồ tuần/tháng.
- [ ] Phát hành Google Play: tài khoản Play Console, ảnh giới thiệu, icon 1024x1024.
- [ ] Xem lại sản phẩm đã quét khi offline.
- [ ] Nhận diện món ăn không có mã vạch bằng ảnh.
