# Fluw

Ứng dụng quét mã vạch thực phẩm và phân tích dinh dưỡng bằng AI **Zero**.

Luồng chính: quét mã vạch hoặc nhập tên sản phẩm → tra cứu OpenFoodFacts → Gemini chấm điểm sức khỏe (0-100) → hiển thị kết quả.

## Cấu trúc

| Thư mục | Công nghệ | Vai trò |
| :--- | :--- | :--- |
| `backend/` | Node.js, Express 5 | API `GET /api/product/:query`, `GET /health` |
| `frontend/` | Flutter | Ứng dụng di động (Android là mục tiêu chính) |

Backend theo từng lớp: `routes` → `controllers` → `services` (`productService` điều phối cache, `foodApiService`, `aiService`), lỗi được xử lý tập trung ở `middlewares/errorHandler.js` với `AppError`.

| Thư mục backend | Trách nhiệm |
| :--- | :--- |
| `src/services/openFoodFacts/` | `openFoodFactsClient` (HTTP, User-Agent, timeout, phân loại lỗi), `productNormalizer` (chuẩn hóa dữ liệu), `allergenMapper` (tên dị ứng tiếng Việt) |
| `src/services/ai/` | `geminiClient` (gọi Gemini, timeout, lỗi), `analysisPrompt` (prompt + schema), `analysisParser` (kiểm tra đầu ra AI) |
| `src/errors/` | `AppError`, danh sách mã lỗi `errorCodes` |

Phản hồi lỗi có dạng `{ "success": false, "error": "<thông báo tiếng Việt>", "code": "<MÃ_LỖI>" }`. Mã lỗi: `INVALID_QUERY`, `INVALID_BARCODE`, `BAD_REQUEST`, `ROUTE_NOT_FOUND`, `PRODUCT_NOT_FOUND`, `RATE_LIMITED`, `UPSTREAM_RATE_LIMITED` (kèm header `Retry-After`), `UPSTREAM_TIMEOUT`, `UPSTREAM_UNAVAILABLE`, `INTERNAL_ERROR`.

## Chạy backend

```bash
cd backend
cp .env.example .env   # điền GEMINI_API_KEY
npm install
npm run dev
npm test
```

### Biến môi trường

| Biến | Mặc định | Ý nghĩa |
| :--- | :--- | :--- |
| `GEMINI_API_KEY` | (bắt buộc) | API key Gemini. Chỉ đặt trong `.env` hoặc trên Render, không commit. |
| `GEMINI_MODEL` | `gemini-3.6-flash` | Model dùng để phân tích |
| `OFF_CONTACT_EMAIL` | (trống = dùng link GitHub của dự án) | Email liên hệ trong User-Agent gửi tới OpenFoodFacts (`Fluw/<version> (<email>)`), theo yêu cầu của OpenFoodFacts |
| `RATE_LIMIT_WINDOW_MINUTES` / `RATE_LIMIT_MAX_REQUESTS` | `15` / `30` | Số lần tra cứu tối đa mỗi IP trong một khoảng thời gian |
| `TRUST_PROXY_HOPS` | `1` | Số proxy đứng trước server (Render), để rate limit đọc đúng IP |
| `CORS_ORIGINS` | (trống = cho phép mọi origin) | Danh sách origin web được phép, cách nhau bằng dấu phẩy. App di động không bị ảnh hưởng. |
| `CACHE_TTL_HOURS` / `CACHE_MAX_ENTRIES` | `24` / `500` | Thời gian giữ và số kết quả tối đa trong cache |

### Bảo mật và dữ liệu

- Đầu vào giới hạn 100 ký tự, không chấp nhận ký tự điều khiển.
- Dữ liệu OpenFoodFacts (do cộng đồng đóng góp) được đặt trong khối riêng trong prompt và cắt bớt độ dài, Gemini được dặn bỏ qua mọi chỉ dẫn nằm trong đó. Ký tự `<`, `>`, `&` được escape để dữ liệu không thể tự đóng khối `<product_data>`.
- Đầu ra của Gemini được kiểm tra lại: điểm phải là số thật (không chấp nhận `null`), danh sách chỉ giữ chuỗi và bị giới hạn độ dài.
- Giá trị dinh dưỡng chỉ lấy theo 100 g (không dùng số liệu theo khẩu phần); không có dữ liệu thì trả về `null`, không phải `0`. Sản phẩm chỉ có năng lượng theo kJ được quy đổi sang kcal.
- Khi Gemini lỗi hoặc chưa cấu hình, API vẫn trả dữ liệu sản phẩm với `aiAnalysis: null` và `aiError` cho biết lý do.
- Gọi Gemini có timeout 40 giây (tự thử lại 1 lần khi gặp lỗi tạm thời 408, 500, 502-504 hoặc lỗi mạng, vẫn nằm trong 40 giây; lỗi 429 hết hạn mức không thử lại và trả `aiError: AI_RATE_LIMITED`), gọi OpenFoodFacts có timeout 10 giây (lần tìm thêm bản không dấu: 5 giây). Tổng tối đa 55 giây, còn dư cho cold start của Render (~50 giây) trong giới hạn 120 giây của app; app gọi `/health` khi mở để đánh thức server.
- Mã vạch 12-14 chữ số (UPC-A, EAN-13, GTIN-14) được kiểm tra số kiểm tra; sai thì trả `400 INVALID_BARCODE` thay vì gọi OpenFoodFacts.
- OpenFoodFacts trả 404 → `PRODUCT_NOT_FOUND`; trả 429 → `503 UPSTREAM_RATE_LIMITED` kèm `Retry-After: 60`; các lỗi khác → 502/504.
- Tra cứu theo mã vạch chỉ lấy các trường cần dùng (`fields=`) thay vì cả tài liệu sản phẩm.
- Server dừng êm khi nhận `SIGTERM`/`SIGINT` (ngừng nhận kết nối mới, chờ request đang chạy).
- Chính sách quyền riêng tư (bản nháp): [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md).

### Cache và tìm kiếm

- Kết quả thành công (sản phẩm + phân tích AI) được lưu trong bộ nhớ theo mã vạch hoặc tên đã chuẩn hóa, mặc định 24 giờ, tối đa 500 mục (bỏ mục ít dùng nhất). Lỗi và kết quả thiếu phân tích AI không được lưu, để lần sau gọi lại Gemini. Header `X-Cache: HIT|MISS` cho biết kết quả lấy từ đâu.
- Nhiều yêu cầu cùng lúc cho cùng một sản phẩm chỉ gọi Gemini một lần.
- Cache nằm trong bộ nhớ của server: mất khi Render khởi động lại.
- Tìm theo tên ưu tiên tiếng Việt (`langs: vi, en`) và dùng `product_name_vi`, `ingredients_text_vi` khi có.
- Lấy 10 kết quả rồi chọn sản phẩm có tên/thương hiệu khớp nhiều từ nhất với từ khóa (không phân biệt dấu và chữ hoa, có đếm từ lặp lại, từ có cả ở tên và thương hiệu chỉ tính một lần, `src/search/pickBestSearchHit.js`). Bằng điểm thì ưu tiên sản phẩm có tên; với từ khóa từ 2 từ trở lên thì tiếp theo ưu tiên tên ít từ thừa; vẫn bằng thì giữ thứ tự của máy tìm kiếm.
- Nếu từ khóa có dấu mà không kết quả nào khớp đủ các từ, tìm thêm một lần bằng bản không dấu ("mì hảo hảo" → "mi hao hao"), gộp kết quả (bỏ trùng mã vạch) rồi chọn lại (`src/services/openFoodFacts/productSearch.js`). Lần tìm thêm có timeout 5 giây; nếu nó lỗi mà lần đầu đã có kết quả thì vẫn dùng kết quả lần đầu. Mỗi lần tìm thêm được ghi log `[Search Fallback]` để theo dõi tỉ lệ.

## Chạy frontend

```bash
cd frontend
flutter pub get
flutter run
flutter test
```

Mặc định ứng dụng gọi `https://fluw.onrender.com`. Để trỏ tới backend khác:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/product
```

Build bản release cần tạo `frontend/android/key.properties` từ file `key.properties.example`. Không commit file này và file `.jks`.

Yêu cầu Flutter 3.44 trở lên (do `shared_preferences`). Kiến trúc giao diện (theme sáng/tối, skeleton, chuyển trang) xem [`docs/FRONTEND_UI_FOUNDATION.md`](docs/FRONTEND_UI_FOUNDATION.md).
