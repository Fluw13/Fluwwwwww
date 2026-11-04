# Fluw

Ứng dụng quét mã vạch thực phẩm và phân tích dinh dưỡng bằng AI **Zero**.

Luồng chính: quét mã vạch hoặc tìm theo tên → chọn sản phẩm → backend lấy dữ liệu Open Food Facts và tính **Điểm Fluw** (0–100) bằng công thức công khai → khi người dùng hỏi, Zero (Gemini) giải thích điểm đó.

- Hợp đồng API: [`docs/API_CONTRACT_v1.md`](docs/API_CONTRACT_v1.md), phản hồi mẫu trong [`contracts/fixtures/`](contracts/fixtures/README.md).
- Cách tính điểm: [`docs/SCORING.md`](docs/SCORING.md).
- Quyết định kiến trúc: [`docs/adr/`](docs/adr/).

## Cấu trúc

| Thư mục | Công nghệ | Vai trò |
| :--- | :--- | :--- |
| `backend/` | Node.js, Express 5 | API `GET /api/v1/search`, `GET /api/v1/products/:barcode`, `GET /api/v1/products/:barcode/analysis`, `GET /health` |
| `frontend/` | Flutter | Ứng dụng di động (Android là mục tiêu chính) |

Backend theo từng lớp: `routes/v1` → `controllers/v1` → `services` (`searchService`, `productDetailsService`, `analysisService`) → các client và mapper; điểm tính ở `scoring/` (hàm thuần). Lỗi được xử lý tập trung ở `middlewares/errorHandler.js` với `AppError`.

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
| `GEMINI_TIMEOUT_SECONDS` | `15` | Thời gian chờ Gemini tối đa, gồm cả lần thử lại |
| `AI_DAILY_LIMIT` | `200` | Số lượt gọi Gemini tối đa mỗi ngày (UTC) trên toàn server; vượt thì `aiError: AI_DAILY_LIMIT` |
| `OFF_CONTACT_EMAIL` | (trống = dùng link GitHub của dự án) | Email liên hệ trong User-Agent gửi tới OpenFoodFacts (`Fluw/<version> (<email>)`), theo yêu cầu của OpenFoodFacts |
| `SEARCH_RATE_LIMIT_PER_MINUTE` / `PRODUCT_RATE_LIMIT_PER_MINUTE` / `ANALYSIS_RATE_LIMIT_PER_MINUTE` | `10` / `30` / `10` | Số request tối đa mỗi IP mỗi phút cho từng route v1 |
| `OFF_READS_PER_MINUTE` / `OFF_SEARCHES_PER_MINUTE` | `14` / `9` | Số lượt gọi Open Food Facts tối đa mỗi phút trên toàn server (OFF cho phép 15 / 10) |
| `SEARCH_CACHE_TTL_MINUTES` | `60` | Thời gian giữ kết quả tìm kiếm v1 |
| `TRUST_PROXY_HOPS` | `1` | Số proxy đứng trước server (Render), để rate limit đọc đúng IP |
| `CORS_ORIGINS` | (trống = cho phép mọi origin) | Danh sách origin web được phép, cách nhau bằng dấu phẩy. App di động không bị ảnh hưởng. |
| `CACHE_TTL_HOURS` / `CACHE_MAX_ENTRIES` | `24` / `500` | Thời gian giữ và số mục tối đa của cache sản phẩm và cache giải thích |

### Bảo mật và dữ liệu

- Đầu vào giới hạn 100 ký tự, không chấp nhận ký tự điều khiển.
- Dữ liệu OpenFoodFacts (do cộng đồng đóng góp) được đặt trong khối riêng trong prompt và cắt bớt độ dài, Gemini được dặn bỏ qua mọi chỉ dẫn nằm trong đó. Ký tự `<`, `>`, `&` được escape để dữ liệu không thể tự đóng khối `<product_data>`.
- Đầu ra của Gemini được kiểm tra lại: chỉ giữ 4 trường giải thích (không có điểm), danh sách chỉ giữ chuỗi và bị giới hạn số ý, độ dài.
- Giá trị dinh dưỡng chỉ lấy theo 100 g/100 ml (không dùng số liệu theo khẩu phần); không có dữ liệu thì trả về `null`, không phải `0`. Năng lượng quy đổi qua lại giữa kJ và kcal, muối tính từ natri khi thiếu.
- Khi Gemini lỗi hoặc chưa cấu hình, API vẫn trả HTTP 200 với `aiAnalysis: null` và `aiError` cho biết lý do.
- Điểm do backend tính; AI chỉ nhận bảng điểm đã tính và không có trường điểm trong đầu ra.
- Gemini có timeout 15 giây (`GEMINI_TIMEOUT_SECONDS`), tự thử lại 1 lần khi gặp lỗi tạm thời 408, 500, 502-504 hoặc lỗi mạng trong cùng thời gian đó; lỗi 429 hết hạn mức không thử lại và trả `aiError: AI_RATE_LIMITED`. Tối đa `AI_DAILY_LIMIT` lượt gọi mỗi ngày, vượt thì `aiError: AI_DAILY_LIMIT`.
- Gọi Open Food Facts có timeout 10 giây (lần tìm thêm bản không dấu: 5 giây), tối đa 14 lượt đọc + 9 lượt tìm mỗi phút trên toàn server; vượt thì `503 UPSTREAM_RATE_LIMITED` kèm `Retry-After`.
- Mã vạch 12-14 chữ số (UPC-A, EAN-13, GTIN-14) được kiểm tra số kiểm tra; sai thì trả `400 INVALID_BARCODE` thay vì gọi OpenFoodFacts.
- Open Food Facts trả 404 → `PRODUCT_NOT_FOUND`; trả 429 → `503 UPSTREAM_RATE_LIMITED` kèm `Retry-After: 60`; các lỗi khác → 502/504.
- Tra cứu theo mã vạch chỉ lấy các trường cần dùng (`fields=`) thay vì cả tài liệu sản phẩm.
- Server dừng êm khi nhận `SIGTERM`/`SIGINT` (ngừng nhận kết nối mới, chờ request đang chạy).
- Chính sách quyền riêng tư (bản nháp): [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md).

### Cache và tìm kiếm

- Sản phẩm + điểm được lưu trong bộ nhớ theo mã vạch; phần giải thích của Zero theo mã vạch, phiên bản điểm và đúng dữ liệu đã gửi cho AI. Mặc định 24 giờ, tối đa 500 mục (bỏ mục ít dùng nhất). Lỗi không được lưu. Header `X-Cache: HIT|MISS` cho biết kết quả lấy từ đâu.
- Nhiều yêu cầu cùng lúc cho cùng một sản phẩm chỉ gọi Open Food Facts một lần, và chỉ gọi Gemini một lần.
- Cache nằm trong bộ nhớ của server: mất khi Render khởi động lại. Fluw không lưu lâu dài dữ liệu Open Food Facts.
- Tìm theo tên trả tối đa 10 kết quả đã xếp hạng (`src/services/search/searchRanker.js`): chỉ giữ sản phẩm khớp đủ các từ của từ khóa (không phân biệt dấu, chữ hoa); không có thì trả kết quả gần đúng (khớp ít nhất một nửa số từ, `matchesAllWords: false`); không có gì phù hợp thì trả danh sách rỗng.
- Nếu lần tìm đầu không có sản phẩm khớp đủ và từ khóa có dấu, tìm thêm một lần bằng bản không dấu ("hảo hảo" → "hao hao", timeout 5 giây); lần này lỗi thì vẫn dùng kết quả lần đầu nhưng không lưu cache. Log chỉ ghi độ dài từ khóa và số kết quả, không ghi nội dung người dùng gõ.

## Chạy frontend

```bash
cd frontend
flutter pub get
flutter run
flutter test
```

Mặc định ứng dụng gọi API v1 tại `https://fluw.onrender.com`. Để trỏ tới backend khác, truyền **origin** (scheme, host, cổng; không kèm đường dẫn):

```bash
flutter run --dart-define=API_ORIGIN=http://10.0.2.2:5000
```

Tùy chọn: `--dart-define=ZERO_AUTO_LOAD=true` cho phần giải thích của Zero tự tải khi mở sản phẩm (mặc định tắt, người dùng bấm "Hỏi Zero").

Build bản release cần tạo `frontend/android/key.properties` từ file `key.properties.example`. Không commit file này và file `.jks`.

Yêu cầu Flutter 3.44 trở lên (do `shared_preferences`). Kiến trúc giao diện (theme sáng/tối, skeleton, chuyển trang) xem [`docs/FRONTEND_UI_FOUNDATION.md`](docs/FRONTEND_UI_FOUNDATION.md).
