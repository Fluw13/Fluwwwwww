# Tài liệu bàn giao dự án Fluw

**Ứng dụng:** Fluw, quét mã vạch thực phẩm và phân tích dinh dưỡng bằng AI **Zero**
**Cập nhật:** 29/10/2026, theo code trên nhánh `review/refactor-fixes` (PR #1)
**Phiên bản app:** 1.0.0+1

> Các file `FLUW_PROJECT_HANDOFF.doc` và `FLUW_PROJECT_HANDOFF_Updated.doc` là bản cũ (thực chất là HTML) và đã lỗi thời. File này là bản đúng.

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
| `src/controllers/productController.js` | Gọi dữ liệu sản phẩm rồi gọi AI, trả kết quả |
| `src/services/foodApiService.js` | Gọi OpenFoodFacts, kiểm tra đầu vào, chuẩn hóa dữ liệu |
| `src/services/aiService.js` | Gọi Gemini, prompt, schema, kiểm tra phản hồi |
| `src/middlewares/errorHandler.js` | Trả lỗi dạng JSON; lỗi lạ trả 500, không lộ chi tiết |
| `src/middlewares/rateLimiter.js` | Giới hạn số lần tra cứu theo IP |
| `src/errors/AppError.js` | Lỗi có mã HTTP |

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
  }
}
```

- `nutriments`: giá trị trên 100 g; `null` là không có dữ liệu, khác với `0`.
- `product.allergens`: lấy từ nhãn (OpenFoodFacts). `aiAnalysis.allergens`: AI gợi ý thêm từ danh sách thành phần.
- Lỗi: `{ "success": false, "error": "…" }`, mã 400 (đầu vào sai), 404 (không tìm thấy), 429 (quá giới hạn), 502/504 (OpenFoodFacts hoặc Gemini lỗi hay quá hạn), 500.

### Biến môi trường

Xem `backend/.env.example` và README: `GEMINI_API_KEY` (bắt buộc), `GEMINI_MODEL`, `PORT`, `RATE_LIMIT_WINDOW_MINUTES`, `RATE_LIMIT_MAX_REQUESTS`, `TRUST_PROXY_HOPS`, `CORS_ORIGINS`.

## 4. Frontend (`frontend/lib/`)

| File | Vai trò |
| :--- | :--- |
| `main.dart` | Theme Material 3, màn hình đầu |
| `core/app_colors.dart` | Bảng màu dùng chung |
| `models/product_model.dart` | Parse phản hồi API |
| `models/score_level.dart` | Ngưỡng điểm, nhãn và màu |
| `services/api_service.dart` | Gọi API (timeout 60 s, `ApiException`), URL qua `--dart-define=API_BASE_URL` |
| `screens/home_screen.dart` | Ô tìm kiếm, nút quét |
| `screens/scanner_screen.dart` | Camera `mobile_scanner`, chỉ EAN/UPC |
| `screens/product_detail_screen.dart` | Loading, lỗi + thử lại, kết quả |
| `widgets/circular_score_ring.dart` | Vòng điểm |
| `widgets/macro_bar.dart` | 4 chỉ số dinh dưỡng, "—" khi thiếu dữ liệu |
| `widgets/zero_analysis_card.dart` | Phân tích Zero và tuyên bố miễn trừ AI |
| `widgets/tag_section.dart` | Danh sách thẻ (dị ứng, gợi ý thay thế) |

## 5. Chạy và kiểm thử

```bash
cd backend && cp .env.example .env && npm install && npm run dev
cd backend && npm test
cd frontend && flutter pub get && flutter run
cd frontend && flutter analyze && flutter test
```

## 6. Việc còn mở

### Cần chủ dự án quyết định hoặc cung cấp
- [ ] Email liên hệ thật cho `docs/PRIVACY_POLICY.md` và User-Agent gửi OpenFoodFacts (đang là `contact@fluw.app`).
- [ ] Đăng chính sách quyền riêng tư lên URL công khai cho Google Play.
- [ ] Có xóa 2 file `.doc` lỗi thời và các thư mục `linux/`, `macos/`, `windows/`, `web/` nếu chỉ phát hành Android không.
- [ ] `ndkVersion = "30.0.16248370"` đang cố định trong `android/app/build.gradle.kts`, máy khác có thể không có bản NDK này.
- [ ] Cache kết quả theo mã vạch để giảm chi phí Gemini.
- [ ] Tìm theo tên đang dùng `langs: ['en']`, có thể kém với sản phẩm Việt Nam.

### Lộ trình sản phẩm (đề xuất, chưa triển khai)
- [ ] Database và đăng nhập (Supabase hoặc Firebase): `users`, `food_logs`, `favorites`.
- [ ] Theo dõi dinh dưỡng: mục tiêu calo (TDEE), tổng macro theo ngày, biểu đồ tuần/tháng.
- [ ] Phát hành Google Play: tài khoản Play Console, ảnh giới thiệu, icon 1024x1024.
- [ ] Xem lại sản phẩm đã quét khi offline.
- [ ] Nhận diện món ăn không có mã vạch bằng ảnh.
