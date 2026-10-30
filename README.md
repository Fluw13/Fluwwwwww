# Fluw

Ứng dụng quét mã vạch thực phẩm và phân tích dinh dưỡng bằng AI **Zero**.

Luồng chính (API v1): quét mã vạch hoặc tìm theo tên → chọn sản phẩm → backend lấy dữ liệu Open Food Facts và tính **Điểm Fluw** (0–100) bằng công thức công khai → khi người dùng hỏi, Zero (Gemini) giải thích điểm đó.

- Hợp đồng API: [`docs/API_CONTRACT_v1.md`](docs/API_CONTRACT_v1.md), phản hồi mẫu trong [`contracts/fixtures/`](contracts/fixtures/README.md).
- Cách tính điểm: [`docs/SCORING.md`](docs/SCORING.md).
- Quyết định kiến trúc: [`docs/adr/`](docs/adr/).

## Cấu trúc

| Thư mục | Công nghệ | Vai trò |
| :--- | :--- | :--- |
| `backend/` | Node.js, Express 5 | API `GET /api/v1/search`, `GET /api/v1/products/:barcode`, `GET /api/v1/products/:barcode/analysis`, `GET /health`; route cũ `GET /api/product/:query` chạy song song đến khi app chuyển hết sang v1 |
| `frontend/` | Flutter | Ứng dụng di động (Android là mục tiêu chính) |

Backend theo từng lớp: `routes` → `controllers` → `services` (`productService` điều phối cache, `foodApiService`, `aiService`), lỗi được xử lý tập trung ở `middlewares/errorHandler.js` với `AppError`.

| Thư mục backend | Trách nhiệm |
| :--- | :--- |
| `src/routes/v1/`, `src/controllers/v1/` | Route và controller API v1 |
| `src/services/openFoodFacts/` | `openFoodFactsClient` (HTTP, User-Agent, timeout, phân loại lỗi), `upstreamBudget` (giới hạn lượt gọi OFF toàn server), các mapper chuyển dữ liệu OFF sang contract (`productDetailsMapper`, `imageMapper`, `nutritionMapper`, `ingredientsMapper`, `additiveMapper`, `allergenMapper`, `scoringInputsMapper`, `searchResultMapper`) |
| `src/scoring/` | Tính Điểm Fluw: hàm thuần, không gọi mạng (`computeFluwScore`, `nutrition/*`, `additives/*`, `scoreVersion`, `scoreLabels`) |
| `src/services/search/` | `searchService` (tìm, tìm thêm không dấu, cache), `searchRanker` (xếp hạng) |
| `src/services/` | `productDetailsService` (sản phẩm + điểm, cache, gộp request trùng), `analysisService` (Zero giải thích điểm) |
| `src/services/ai/` | `geminiClient` (gọi Gemini, timeout, lỗi), `explanationPrompt` / `explanationParser` (prompt và kiểm tra đầu ra của Zero), `aiUsageGuard` (giới hạn lượt/ngày) |
| `src/validators/` | Kiểm tra mã vạch và từ khóa |
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
| `GEMINI_MODEL` | `gemini-3.5-flash-lite` | Model dùng để giải thích điểm |
| `GEMINI_TIMEOUT_SECONDS` | `15` | Thời gian chờ Gemini tối đa (gồm cả lần thử lại) của API v1. Route cũ giữ 40 giây |
| `AI_DAILY_LIMIT` | `200` | Số lượt gọi Gemini tối đa mỗi ngày (UTC) trên toàn server; vượt thì `aiError: AI_DAILY_LIMIT` |
| `OFF_CONTACT_EMAIL` | (trống = dùng link GitHub của dự án) | Email liên hệ trong User-Agent gửi tới OpenFoodFacts (`Fluw/<version> (<email>)`), theo yêu cầu của OpenFoodFacts |
| `SEARCH_RATE_LIMIT_PER_MINUTE` / `PRODUCT_RATE_LIMIT_PER_MINUTE` / `ANALYSIS_RATE_LIMIT_PER_MINUTE` | `10` / `30` / `10` | Số request tối đa mỗi IP mỗi phút cho từng route v1 |
| `OFF_READS_PER_MINUTE` / `OFF_SEARCHES_PER_MINUTE` | `14` / `9` | Số lượt gọi Open Food Facts tối đa mỗi phút trên toàn server (OFF cho phép 15 / 10) |
| `SEARCH_CACHE_TTL_MINUTES` | `60` | Thời gian giữ kết quả tìm kiếm v1 |
| `RATE_LIMIT_WINDOW_MINUTES` / `RATE_LIMIT_MAX_REQUESTS` | `15` / `30` | Giới hạn mỗi IP của route cũ `/api/product` |
| `TRUST_PROXY_HOPS` | `1` | Số proxy đứng trước server (Render), để rate limit đọc đúng IP |
| `CORS_ORIGINS` | (trống = cho phép mọi origin) | Danh sách origin web được phép, cách nhau bằng dấu phẩy. App di động không bị ảnh hưởng. |
| `CACHE_TTL_HOURS` / `CACHE_MAX_ENTRIES` | `24` / `500` | Thời gian giữ và số mục tối đa của cache sản phẩm và cache giải thích |

### Bảo mật và dữ liệu

- Đầu vào giới hạn 100 ký tự, không chấp nhận ký tự điều khiển.
- Dữ liệu OpenFoodFacts (do cộng đồng đóng góp) được đặt trong khối riêng trong prompt và cắt bớt độ dài, Gemini được dặn bỏ qua mọi chỉ dẫn nằm trong đó. Ký tự `<`, `>`, `&` được escape để dữ liệu không thể tự đóng khối `<product_data>`.
- Đầu ra của Gemini được kiểm tra lại: điểm phải là số thật (không chấp nhận `null`), danh sách chỉ giữ chuỗi và bị giới hạn độ dài.
- Giá trị dinh dưỡng chỉ lấy theo 100 g (không dùng số liệu theo khẩu phần); không có dữ liệu thì trả về `null`, không phải `0`. Sản phẩm chỉ có năng lượng theo kJ được quy đổi sang kcal.
- Khi Gemini lỗi hoặc chưa cấu hình, API vẫn trả HTTP 200 với `aiAnalysis: null` và `aiError` cho biết lý do.
- API v1: điểm do backend tính, AI chỉ nhận bảng điểm đã tính và không có trường điểm trong đầu ra. Gemini có timeout 15 giây, giới hạn `AI_DAILY_LIMIT` lượt mỗi ngày; giải thích được cache theo mã vạch + phiên bản điểm.
- Route cũ: gọi Gemini có timeout 40 giây (tự thử lại 1 lần khi gặp lỗi tạm thời 408, 500, 502-504 hoặc lỗi mạng, vẫn nằm trong 40 giây; lỗi 429 hết hạn mức không thử lại và trả `aiError: AI_RATE_LIMITED`), gọi OpenFoodFacts có timeout 10 giây (lần tìm thêm bản không dấu: 5 giây). Tổng tối đa 55 giây, còn dư cho cold start của Render (~50 giây) trong giới hạn 120 giây của app; app gọi `/health` khi mở để đánh thức server.
- Mã vạch 12-14 chữ số (UPC-A, EAN-13, GTIN-14) được kiểm tra số kiểm tra; sai thì trả `400 INVALID_BARCODE` thay vì gọi OpenFoodFacts.
- OpenFoodFacts trả 404 → `PRODUCT_NOT_FOUND`; trả 429 → `503 UPSTREAM_RATE_LIMITED` kèm `Retry-After: 60`; các lỗi khác → 502/504.
- Tra cứu theo mã vạch chỉ lấy các trường cần dùng (`fields=`) thay vì cả tài liệu sản phẩm.
- Server dừng êm khi nhận `SIGTERM`/`SIGINT` (ngừng nhận kết nối mới, chờ request đang chạy).
- Chính sách quyền riêng tư (bản nháp): [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md).

### Route cũ `/api/product/:query`: cache và tìm kiếm

Phần này chỉ áp dụng cho route cũ, sẽ gỡ khi app chuyển hết sang v1. API v1 xem [`docs/API_CONTRACT_v1.md`](docs/API_CONTRACT_v1.md).


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
