# CHANGELOG

## 2026-10-29 — `chore/legal-security-hardening` (vòng 1)

Spec: `docs/ENGINEERING_HANDOFF_LEGAL_SECURITY.md` v1.0. Commit gốc `83b74f9` (main).
Reviewer: **chưa duyệt** (chờ reviewer ghi APPROVED).

### Bảng trạng thái

| ID | Trạng thái | Ghi chú |
|---|---|---|
| BE-1 | Done | Prompt yêu cầu `score` 0–100; server kẹp 0–100 (`clampScore`) và tự suy ra `scoreRating` (`deriveScoreRating`: ≥70 Tốt, 40–69 Trung bình, <40 Nên hạn chế); bỏ text mẫu bị đảo chữ. |
| BE-2 | Done | Bỏ "chuẩn WHO/chuẩn y tế"; quy tắc an toàn y tế + chống prompt injection nằm trong `systemInstruction`; dữ liệu sản phẩm đặt trong khối `<product_data>` dạng JSON, xóa thẻ phân cách trùng trong dữ liệu; cắt `product_name`/`brands` ≤ 200, `ingredients_text` ≤ 2000 ký tự; `responseMimeType: 'application/json'` + `responseSchema`; server vẫn validate kiểu/trường bắt buộc; model từ `GEMINI_MODEL`, mặc định `gemini-3.6-flash`. Tên model: UNKNOWN (chủ dự án xác minh). |
| BE-3 | Done | Đã `git grep` xác nhận không còn nơi dùng, rồi xóa `src/services/geminiService.js`, `src/routes/productRoutes.js`; `npm uninstall @google/generative-ai` (cập nhật cả `package-lock.json`). |
| BE-4 | Done | `trust proxy 1`, `helmet()`, `express-rate-limit` cho `/api/` (mặc định 30/phút/IP, `RATE_LIMIT_PER_MINUTE`, 429 JSON), `express.json({ limit: '10kb' })`, CORS theo `ALLOWED_ORIGINS` (không đặt → cho phép tất cả như cũ), validate `:barcode`. |
| BE-5 | Done | Cache Map trong bộ nhớ, TTL 24h (`CACHE_TTL_SECONDS`), tối đa 500 mục (`CACHE_MAX_ENTRIES`), loại mục cũ nhất; chỉ cache kết quả có AI; không lưu bền. Có gộp request trùng đang chạy (in-flight dedupe). |
| BE-6 | Done | User-Agent `Fluw/<version> (<OFF_CONTACT_EMAIL>)`, fallback URL GitHub; timeout 10s cho cả GET mã vạch và POST tìm kiếm; lỗi có kiểu `NOT_FOUND`/`RATE_LIMITED`/`UPSTREAM_TIMEOUT`/`UPSTREAM_UNAVAILABLE`; HTTP 404 hoặc `status !== 1` → `NOT_FOUND`; giữ `page_size: 1`. |
| BE-7 | Done | 400/404/503 + `Retry-After: 60`/504/502/500; thông điệp tiếng Việt, không chứa `error.message` gốc; log chi tiết bằng `console.error`; AI lỗi → 200, `aiAnalysis: null`, `aiAvailable: false`; có AI → `aiAvailable: true`, `aiAnalysis.aiGenerated: true`, `aiAnalysis.disclaimer`. |
| BE-8 | Done | `backend/.env.example`; `"test": "node --test"`, `"start": "node server.js"`; `main` đổi `index.js` → `server.js`; code tách thành hàm thuần + inject HTTP client/AI client; đủ nhóm test yêu cầu; smoke test đã chạy. |
| FE-1 | Done (chưa compile) | Nhãn "Do AI tạo" cạnh tiêu đề "Zero Deep Think"; dòng miễn trừ dưới thẻ AI, ưu tiên `disclaimer` từ backend, fallback chuỗi mặc định. |
| FE-2 | Done (chưa compile) | Dòng ghi nguồn mới (ODbL + CC BY-SA), chỉ text. |
| FE-3 | Done (chưa compile) | `ProductModel.hasAiAnalysis` (đọc `aiAvailable`, fallback `aiAnalysis != null`), `score` kẹp 0–100, thêm `disclaimer`; khi không có AI: ẩn vòng điểm + `scoreRating` + thẻ AI, hiện thông báo "Chưa có phân tích AI…", vẫn hiện macro. |
| FE-4 | Done (chưa compile) | Bỏ comment debug và tiêu đề "CHI TIẾT LỖI TỪ SERVER"; `ApiException(userMessage, debugDetail)`; chi tiết kỹ thuật chỉ hiện khi `kDebugMode`; timeout 20s; body không phải JSON → thông điệp chung, không hiển thị HTML. |
| FE-5 | Done | `android:usesCleartextTraffic="false"` trong `src/main/AndroidManifest.xml` (đã kiểm tra XML well-formed). |
| DOC-1 | Done | `docs/LEGAL_COMPLIANCE.md` (đã đối chiếu trang API của OFF và điều khoản Gemini bản hiện hành; có danh sách nguồn). |
| DOC-2 | Done | `docs/PRIVACY_POLICY_DRAFT.md` (đầu file ghi "BẢN NHÁP"; placeholder `[EMAIL LIÊN HỆ]`). |
| DOC-3 | Done | File này. |

### File đã đổi

- Backend: `backend/server.js`, `backend/package.json`, `backend/package-lock.json`, `backend/.env.example` (mới), `backend/src/app.js` (mới), `backend/src/config.js` (mới), `backend/src/errors.js` (mới), `backend/src/cache.js` (mới), `backend/src/validation/productQuery.js` (mới), `backend/src/controllers/productController.js`, `backend/src/services/aiService.js`, `backend/src/services/foodApiService.js`.
- Backend đã xóa: `backend/src/services/geminiService.js`, `backend/src/routes/productRoutes.js`.
- Backend test (mới): `backend/test/{aiService,app,cache,foodApiService,productController,productQuery}.test.js`.
- Frontend: `frontend/lib/models/product_model.dart`, `frontend/lib/services/api_service.dart`, `frontend/lib/screens/product_detail_screen.dart`, `frontend/android/app/src/main/AndroidManifest.xml`.
- Tài liệu: `docs/LEGAL_COMPLIANCE.md` (mới), `docs/PRIVACY_POLICY_DRAFT.md` (mới), `CHANGELOG.md` (mới).

### Thay đổi contract API (chỉ thêm trường, route giữ nguyên)

- Thành công: thêm `aiAvailable` (boolean) cấp cao. `aiAnalysis` có thể là `null`. Trong `aiAnalysis`: `score` nay thang 0–100 (trước 1–10), `scoreRating` do server suy ra, `calories/protein/fat/carbs` lấy từ dữ liệu OFF (không lấy từ AI), thêm `aiGenerated`, `disclaimer`.
- Lỗi: thêm trường `code` (`INVALID_INPUT`, `NOT_FOUND`, `RATE_LIMITED`, `UPSTREAM_TIMEOUT`, `UPSTREAM_UNAVAILABLE`, `INTERNAL_ERROR`; rate limit của Fluw: `TOO_MANY_REQUESTS`). HTTP status không còn luôn là 404.
- Tương thích ngược: bản app cũ đang cài vẫn đọc được response (đọc `error` bất kể status; `aiAnalysis: null` được xử lý bằng `?? {}`), nhưng bản cũ vẫn hiển thị điểm giả 50 khi không có AI — chỉ hết khi phát hành bản app mới.

### Incident "OpenFoodFacts HTTP 404" — chưa đóng

- VERIFIED (code cũ): axios ném lỗi với mọi status ≠ 2xx, nên HTTP 404 từ OFF rơi vào nhánh "Lỗi kết nối đến máy chủ OpenFoodFacts (Mã lỗi HTTP: 404)", controller trả 404 cho mọi lỗi.
- LIKELY: OFF trả HTTP 404 cho mã vạch không tồn tại trong cơ sở dữ liệu → thông báo cũ gây hiểu nhầm là lỗi kết nối.
- Sau thay đổi: OFF 404 / `status !== 1` → `NOT_FOUND` → HTTP 404 với thông điệp "Không tìm thấy sản phẩm trên Open Food Facts…". Có test (`foodApiService.test.js`).
- Chưa xác minh: chưa có mã vạch gây lỗi thực tế, không truy cập được OFF/production từ môi trường này (proxy chặn `world.openfoodfacts.org`). Cần chủ dự án thử lại với đúng mã vạch sau khi deploy.

### Kiểm tra đã chạy (kết quả thật, Node v22.23.4, npm 10.9.9)

| Lệnh | Kết quả |
|---|---|
| `cd backend && npm ci` | OK, `found 0 vulnerabilities` |
| `npm uninstall @google/generative-ai` | OK, `found 0 vulnerabilities` |
| `npm install express-rate-limit helmet` | OK — `express-rate-limit@8.7.1`, `helmet@8.3.0`, `found 0 vulnerabilities` |
| `cd backend && npm test` (`node --test`) | `# tests 44` · `# pass 44` · `# fail 0` · `# cancelled 0` · `# skipped 0` |
| `node --check` cho 15 file `.js` trong `backend/` (trừ `node_modules`) | 15/15 OK |
| Smoke test: `env -u GEMINI_API_KEY PORT=<ngẫu nhiên 25712> node server.js` | Khởi động OK (`Server is running on port 25712`); không có `backend/.env` |
| `curl /api/does-not-exist` | `HTTP/1.1 404`, `Content-Type: application/json`, `{"success":false,"error":"Đường dẫn API không tồn tại trên hệ thống: /api/does-not-exist"}`, có header `X-Content-Type-Options: nosniff` |
| `curl /api/product/%20` | 400, `{"success":false,"code":"INVALID_INPUT",...}` |
| `curl /api/product/<101 ký tự 'a'>` | 400, `INVALID_INPUT` |
| `curl /api/product/123` | 400, `INVALID_INPUT` |
| `curl /api/product/%E0%A4%A` (escape lỗi) | 400, `{"success":false,"error":"Yêu cầu không hợp lệ."}` |
| Tắt server (`kill`) | OK |
| `npm audit --omit=dev` | `found 0 vulnerabilities` |
| `git diff origin/main --stat` (sau khi stage) | 27 files changed, 1790 insertions(+), 342 deletions(-) (chưa tính file CHANGELOG này) |
| Rà secret trong diff (grep khóa `AIza…`, `password`, `secret`, `token`, private key, email) | Chỉ có false positive: chuỗi trong test, nội dung spec. Không có secret. Email trong test dùng tên miền dành riêng `.test`. |
| `AndroidManifest.xml` | Parse XML (python `xml.dom.minidom`) OK |
| 3 file Dart đã sửa | Chỉ kiểm tra cân bằng ngoặc bằng script; **không** compile |

Nhóm test (`backend/test/`): clamp/rating ở các biên −5, 0, 39, 40, 69, 70, 100, 150 và giá trị không phải số (BE-1); prompt có khối phân cách, cắt độ dài, không còn "WHO" (BE-2); validate input (BE-4); 429 JSON từ rate limiter, helmet, CORS (BE-4); cache TTL + giới hạn mục + in-flight dedupe (BE-5); OFF 404/`status 0`/429/timeout/5xx/không kết nối, User-Agent, timeout 10s (BE-6); map status 400/404/503+Retry-After/504/502/500, không lộ message gốc, AI lỗi → 200 + `aiAvailable:false` và không cache (BE-7). Tất cả stub HTTP/AI client; test HTTP chỉ dùng `127.0.0.1`.

### Chưa kiểm tra được

- **Dart/Flutter chưa compile**: workspace không có Flutter SDK → chưa chạy `flutter analyze`, `flutter test`, build APK. Rủi ro chính: lỗi cú pháp/kiểu chưa phát hiện; có thể có lint mức info (ví dụ `prefer_const_constructors`). Chủ dự án cần chạy trước khi merge.
- Gọi thật OpenFoodFacts và Gemini: bị chặn mạng trong môi trường này (proxy từ chối `world.openfoodfacts.org`). Chưa xác minh `responseSchema` hoạt động với model `gemini-3.6-flash` thật.
- `trust proxy 1` đúng số hop của Render: LIKELY, chưa kiểm tra trên Render.
- Lệnh start thực tế trên Render: UNKNOWN. Trước đây không có script `start` nên `npm start` mặc định chạy `node server.js`; nay `npm start` và `node server.js` đều chạy cùng file.
- UI trên thiết bị thật (độ rộng hàng tiêu đề "Zero Deep Think" + nhãn trên màn hình hẹp đã bọc `Flexible`, nhưng chưa xem bằng mắt).

### Phát hiện thêm (không sửa, ngoài phạm vi)

1. `frontend/lib/widgets/circular_score_ring.dart`: `Text('')` — vòng điểm không hiển thị con số, chỉ có "/100".
2. `product_detail_screen.dart`: `FutureBuilder(future: ApiService.fetchProductByBarcode(...))` tạo Future trong `build()` của `StatelessWidget` → gọi lại API mỗi lần rebuild.
3. `frontend/ios/Runner/Info.plist` không có `NSCameraUsageDescription` → app iOS có thể crash khi mở camera / bị App Store từ chối.
4. Dữ liệu dinh dưỡng thiếu được chuẩn hóa thành `0` ở backend → không phân biệt được "0 thật" và "thiếu dữ liệu" (cả trên UI lẫn prompt AI). Sửa cần đổi contract (`null`).
5. Không có timeout cho lời gọi Gemini. OFF tối đa 10s + Gemini không giới hạn, trong khi app timeout 20s → app có thể báo hết thời gian trong khi server vẫn đang xử lý. Gợi ý: `config.httpOptions.timeout` của `@google/genai`.
6. `FLUW_PROJECT_HANDOFF.md`, `FLUW_PROJECT_HANDOFF.doc`, `FLUW_PROJECT_HANDOFF_Updated.doc` còn mô tả `src/services/geminiService.js` (đã xóa) → tài liệu lỗi thời.
7. `frontend/lib/widgets/score_badge.dart` dùng ngưỡng 80/60/40, khác `circular_score_ring.dart` (70/40); hiện không được dùng ở đâu.
8. Tìm theo tên dùng `POST search.openfoodfacts.org/search` với `langs: ['en']` — có thể kém chính xác với từ khóa tiếng Việt; giới hạn tần suất của dịch vụ này UNKNOWN.
9. Cache và bộ đếm rate limit nằm trong bộ nhớ một tiến trình: mất khi Render khởi động lại/ngủ, không chia sẻ nếu chạy nhiều instance.
10. Máy quét có thể đọc mã QR chứa văn bản dài → backend nay trả 400 với thông điệp thân thiện; app chưa lọc loại mã trước khi gọi API.
11. `dotenv@18` in dòng `◇ injected env (0) from .env` khi khởi động (không in giá trị).
12. Điều khoản Gemini API đang công bố (hiệu lực 23/03/2026, cập nhật 28/04/2026) mới hơn bản 20/05/2025 mà spec tham chiếu; các điều khoản liên quan vẫn còn (xem `docs/LEGAL_COMPLIANCE.md`).
13. Mã vạch UPC-A/EAN-13 (có/không có số 0 đầu) chưa được chuẩn hóa → cùng sản phẩm có thể tạo 2 khóa cache.
