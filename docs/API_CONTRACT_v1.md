# API v1 — hợp đồng giữa backend và app

Tài liệu chính thức cho các route `/api/v1`. Phản hồi mẫu thật (ghi từ server, Open Food Facts và Gemini được thay bằng dữ liệu thử) nằm trong [`contracts/fixtures/`](../contracts/fixtures/README.md). Test `backend/tests/contract/contractFixtures.test.js` bảo đảm các file đó luôn khớp với server; khi đổi contract phải chạy `npm run contract:fixtures` và cập nhật tài liệu này.

- Base URL production: `https://fluw.onrender.com`
- Chỉ có `GET`. Dữ liệu trả về dạng JSON, UTF-8.
- Trường nào không có dữ liệu thì là `null` (hoặc mảng rỗng với danh sách), **không bao giờ đoán hay điền 0**.
- Mã vạch luôn là **chuỗi** (giữ số 0 ở đầu).
- Cách tính điểm: [`docs/SCORING.md`](SCORING.md).

## 1. Định dạng lỗi

```json
{ "success": false, "error": "<thông báo tiếng Việt>", "code": "<MÃ_LỖI>" }
```

App xử lý theo `code`; `error` chỉ để hiển thị và có thể đổi câu chữ.

| `code` | HTTP | Khi nào | Header |
|---|---|---|---|
| `INVALID_QUERY` | 400 | Từ khóa tìm kiếm thiếu, dưới 2 hoặc trên 100 ký tự, có ký tự điều khiển | |
| `INVALID_BARCODE` | 400 | Mã vạch không phải 8, 12, 13 hoặc 14 chữ số, hoặc sai số kiểm tra (12–14 số) | |
| `BAD_REQUEST` | 400 | Request hỏng (ví dụ URL mã hóa sai) | |
| `ROUTE_NOT_FOUND` | 404 | Route không tồn tại | |
| `PRODUCT_NOT_FOUND` | 404 | Open Food Facts không có sản phẩm này | |
| `RATE_LIMITED` | 429 | Một IP gọi quá giới hạn của route (mục 5) | `Retry-After` (giây) |
| `UPSTREAM_RATE_LIMITED` | 503 | Fluw tự giới hạn lượt gọi Open Food Facts, hoặc Open Food Facts trả 429 | `Retry-After` (giây) |
| `UPSTREAM_TIMEOUT` | 504 | Open Food Facts trả lời quá lâu | |
| `UPSTREAM_UNAVAILABLE` | 502 | Không kết nối được hoặc Open Food Facts lỗi | |
| `INTERNAL_ERROR` | 500 | Lỗi không lường trước của server | |

## 2. `GET /api/v1/search?q=<từ khóa>`

Tìm sản phẩm theo tên hoặc thương hiệu. App chỉ gọi khi người dùng bấm tìm, **không gọi theo từng ký tự gõ** (Open Food Facts cấm search-as-you-type).

- `q`: 2–100 ký tự sau khi chuẩn hóa Unicode NFC, bỏ khoảng trắng đầu cuối và gộp khoảng trắng liên tiếp (kể cả tab, xuống dòng) thành một dấu cách. Ký tự điều khiển khác bị từ chối. Phải có ít nhất một chữ cái hoặc chữ số.
- `query` trong phản hồi là từ khóa của chính người gọi sau khi chuẩn hóa.
- Nếu `q` gồm đúng 8, 12, 13 hoặc 14 chữ số, app mở thẳng `GET /api/v1/products/:barcode` thay vì tìm. Chuỗi toàn chữ số có độ dài khác không phải mã vạch hợp lệ; app có thể báo ngay hoặc gửi tìm theo tên.

```json
{
  "success": true,
  "query": "mì hảo hảo",
  "results": [
    { "barcode": "8934563122201", "name": "Mỳ Hảo Hảo", "brand": "Acecook", "quantity": null, "imageUrl": null, "matchesAllWords": false }
  ],
  "total": 1
}
```

- Tối đa 10 kết quả, đã xếp hạng: khớp đúng dấu trước khớp không dấu, khớp tên trước khớp thương hiệu.
- `matchesAllWords`:
  - `true`: tên hoặc thương hiệu chứa đủ mọi từ của từ khóa (không phân biệt dấu, chữ hoa).
  - `false`: không có sản phẩm nào khớp đủ, đây là kết quả gần đúng (khớp ít nhất một nửa số từ). App nên ghi chú "kết quả gần đúng".
- Không có kết quả phù hợp → `results: []`, `total: 0` (HTTP 200). Không bao giờ trả một sản phẩm bất kỳ.
- Nếu từ khóa có dấu và lần tìm đầu không có sản phẩm khớp đủ, server tự tìm thêm một lần bằng từ khóa không dấu ("hảo hảo" → "hao hao"). Nếu lần tìm thêm lỗi thì vẫn trả kết quả lần đầu nhưng không lưu cache, để lần sau tìm lại đủ.
- `barcode` luôn có và luôn mở được bằng route sản phẩm (kết quả có mã sai độ dài hoặc sai số kiểm tra bị bỏ); `name`, `brand`, `quantity`, `imageUrl` có thể `null`. `imageUrl` chỉ là https từ `images.openfoodfacts.org` hoặc `static.openfoodfacts.org`.
- Lỗi: `INVALID_QUERY`, `RATE_LIMITED`, `UPSTREAM_*`.
- Fixture: `search-results`, `search-partial-results`, `search-empty`, `error-invalid-query`, `error-rate-limited`.

## 3. `GET /api/v1/products/:barcode`

Chi tiết sản phẩm và Điểm Fluw. Header `X-Cache: HIT|MISS`.

- `barcode`: GTIN 8, 12, 13 hoặc 14 chữ số (mã 9–11 số bị từ chối). Mã 12–14 số phải đúng số kiểm tra. Mã 8 số không kiểm tra (có thể là UPC-E).
- Chuẩn hóa: mã 12 số (UPC-A) thêm số 0 ở đầu; mã 14 số bắt đầu bằng 0 bỏ số 0 đó. `product.barcode` là mã đã chuẩn hóa.

```json
{ "success": true, "product": { ... }, "score": { ... } }
```

### 3.1. `product`

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `barcode` | string | Luôn có |
| `name`, `genericName`, `brand`, `quantity` | string \| null | `name` và `genericName` ưu tiên bản tiếng Việt, rồi ngôn ngữ chính của sản phẩm (`name` thêm tiếng Anh) |
| `manufacturer` | `{brandOwner, manufacturingPlaces}` | Mỗi trường string \| null |
| `images` | `{front, ingredients, nutrition}` | Mỗi ảnh là `null` hoặc `{small, display, full}`: 200 px, 400 px, ảnh gốc. Chỉ https từ máy chủ ảnh Open Food Facts. App chỉ tải `full` khi người dùng mở phóng to |
| `ingredients` | `{text, language}` \| null | Cả object là `null` khi không có danh sách thành phần |
| `allergens`, `traces` | `[{tag, label}]` | Chất gây dị ứng khai báo / "có thể chứa". `label` tiếng Việt khi có |
| `additives` | `[{tag, code, name}]` | Ví dụ `{"tag": "en:e471", "code": "E471", "name": "Mono- và diglycerid của axit béo"}`; `name` có thể null |
| `novaGroup` | 1–4 \| null | Chỉ để tham khảo, **không tính vào điểm** |
| `nutrition` | `{basis, per100, preparedPer100}` | `basis`: `"100g"` hoặc `"100ml"` (đồ uống). `per100` / `preparedPer100` (sau khi pha, có thể null): `energyKcal, energyKj, fat, saturatedFat, carbohydrates, sugars, fiber, proteins, salt`, mỗi giá trị number \| null. Chỉ lấy số liệu theo 100 g/100 ml, không dùng số theo khẩu phần |
| `source` | object | `provider: "Open Food Facts"`, `url`, `license: "ODbL"`, `imagesLicense: "CC BY-SA"`, `lastModified` (ISO 8601 \| null), `fetchedAt` (ISO 8601) |

### 3.2. `score`

Cấu trúc chi tiết và ý nghĩa từng con số: [`docs/SCORING.md`](SCORING.md). Tóm tắt:

```json
{
  "version": "fluw-score-1.0",
  "weights": { "nutrition": 0.7, "additives": 0.3 },
  "total": { "value": 31, "level": "limit", "label": "Nên hạn chế",
             "calculation": { "nutritionWeighted": 12.6, "additivesWeighted": 18, "sum": 30.6 } },
  "nutrition": { "value": 18, "status": "computed", "productType": "food", "productTypeLabel": "Thực phẩm",
                 "basis": "as_sold", "points": 21, "negativePoints": 21, "positivePoints": 0,
                 "band": { "pointsMin": 19, "pointsMax": 55, "scoreMin": 0, "scoreMax": 19 },
                 "indicators": [ ... ], "missing": [] },
  "additives": { "value": 60, "status": "computed", "count": 4,
                 "band": { "countMin": 3, "countMax": 4, "score": 60 }, "missing": [] },
  "missing": [],
  "disclaimer": "..."
}
```

- `total.value` là `null` (cùng `level`, `label`, `calculation`) khi thiếu một trong hai điểm thành phần. App ghi "Chưa đủ dữ liệu để tính điểm tổng", không vẽ vòng điểm và liệt kê `missing[].label`.
- `total.level`: `good` (Tốt, ≥ 70) · `moderate` (Trung bình, 40–69) · `limit` (Nên hạn chế, < 40). App dùng `label` backend gửi, không tự áp ngưỡng.
- `total.calculation`: các số đã nhân trọng số để app in phép tính (ví dụ "18 × 0,7 + 60 × 0,3 = 30,6 → 31") mà không tự tính.
- `nutrition.status`: `computed` · `missing_data` (thiếu danh mục, chỉ số dinh dưỡng, chất xơ hoặc tỷ lệ rau củ quả) · `needs_prepared_data` (sản phẩm phải pha, chưa có số liệu sau pha) · `not_applicable` (ví dụ đồ uống có cồn).
- `nutrition.basis`: `as_sold` · `prepared` · null.
- `nutrition.indicators[]`: `{key, label, effect: "negative"|"positive", value, unit, per, points, maxPoints, range: {min, minInclusive, max, maxInclusive}, status: "counted"|"excluded_by_rule"|"estimated", note}`. `range.min`/`range.max` có thể null (khoảng hở). Khi không chấm thì `indicators` rỗng.
- `additives.status`: `computed` · `missing_ingredients` · `ingredients_not_recognized` (hơn một nửa thành phần chưa nhận diện).
- `missing`: `[{key, label}]`, gộp từ hai điểm thành phần, ví dụ `{"key": "nutrition.fiber", "label": "Chất xơ"}`.
- Lỗi: `INVALID_BARCODE`, `PRODUCT_NOT_FOUND`, `RATE_LIMITED`, `UPSTREAM_*`.
- Fixture: `product-food-complete`, `product-yogurt-good`, `product-beverage`, `product-water`, `product-needs-prepared-data`, `product-missing-category`, `product-missing-fiber`, `product-not-applicable`, `product-ingredients-not-recognized`, `error-invalid-barcode`, `error-product-not-found`, `error-upstream-rate-limited`.

## 4. `GET /api/v1/products/:barcode/analysis`

Zero (Gemini) giải thích Điểm Fluw đã tính. App gọi riêng, sau khi đã hiển thị sản phẩm (mặc định khi người dùng bấm "Hỏi Zero"). Header `X-Cache: HIT|MISS`.

```json
{
  "success": true,
  "barcode": "8930000000019",
  "scoreVersion": "fluw-score-1.0",
  "aiGenerated": true,
  "aiAnalysis": {
    "summary": "…",
    "highlights": ["…"],
    "recommendation": "…",
    "alternatives": ["Bánh quy nguyên cám ít đường"]
  },
  "aiError": null,
  "disclaimer": "Nội dung do AI (Zero) tạo …"
}
```

- AI **không có trường điểm**. Điểm chỉ lấy từ `score` của route sản phẩm.
- `highlights`: 0–5 ý. `alternatives`: 0–3 **nhóm sản phẩm chung**, không thương hiệu.
- AI lỗi vẫn trả **HTTP 200** với `aiAnalysis: null` và `aiError`:

| `aiError` | Ý nghĩa | App nên |
|---|---|---|
| `AI_NOT_CONFIGURED` | Server chưa có `GEMINI_API_KEY` | Ẩn nút thử lại |
| `AI_UNAVAILABLE` | Gemini lỗi hoặc quá thời gian | Cho thử lại |
| `AI_INVALID_RESPONSE` | Gemini trả nội dung không đúng định dạng | Cho thử lại |
| `AI_RATE_LIMITED` | Gemini từ chối vì hết hạn mức của nhà cung cấp | Báo thử lại sau |
| `AI_DAILY_LIMIT` | Fluw đã dùng hết số lượt gọi AI tự đặt cho ngày hôm nay (UTC) | Báo quay lại ngày mai, ẩn nút thử lại |

- Giải thích được cache theo mã vạch, phiên bản điểm và đúng dữ liệu đã gửi cho AI (mặc định 24 giờ): dữ liệu sản phẩm hoặc điểm đổi thì Zero giải thích lại. Lỗi không được cache. Nhiều request trùng cùng lúc chỉ gọi Gemini một lần.
- Dùng lại cache sản phẩm, nên mở sản phẩm rồi hỏi Zero **không tốn thêm lượt gọi Open Food Facts**.
- Lỗi HTTP (không phải lỗi AI): như route sản phẩm.
- Fixture: `analysis-ok`, `analysis-ai-unavailable`, `analysis-ai-daily-limit`.

## 5. Giới hạn và cache (mặc định, đổi được qua biến môi trường)

| Giới hạn | Mặc định | Biến |
|---|---|---|
| Search mỗi IP | 10 lượt/phút | `SEARCH_RATE_LIMIT_PER_MINUTE` |
| Products mỗi IP | 30 lượt/phút | `PRODUCT_RATE_LIMIT_PER_MINUTE` |
| Analysis mỗi IP | 10 lượt/phút | `ANALYSIS_RATE_LIMIT_PER_MINUTE` |
| Toàn server gọi Open Food Facts | 14 lượt đọc + 9 lượt tìm mỗi phút (OFF cho phép 15 + 10) | `OFF_READS_PER_MINUTE`, `OFF_SEARCHES_PER_MINUTE` |
| Gọi Gemini toàn server | 200 lượt giải thích/ngày (UTC). Mỗi lượt có thể gồm 2 request tới Gemini khi lần đầu gặp lỗi tạm thời | `AI_DAILY_LIMIT` |
| Cache sản phẩm và giải thích | 24 giờ, tối đa 500 mục | `CACHE_TTL_HOURS`, `CACHE_MAX_ENTRIES` |
| Cache tìm kiếm | 60 phút | `SEARCH_CACHE_TTL_MINUTES` |

- Cache nằm trong bộ nhớ, mất khi server khởi động lại. Fluw không lưu lâu dài dữ liệu Open Food Facts.
- Giới hạn theo IP có thể chặn nhầm nhiều người dùng chung một IP (mạng di động). Chấp nhận khi app chưa phát hành; khi phát hành cần định danh theo thiết bị (kế hoạch riêng).
- `/health` trả `{ "success": true, "status": "ok" }`, dùng để đánh thức server Render (cold start khoảng 50 giây).

## 6. Quy tắc cho app

- Timeout: trước khi `/health` trả OK trong phiên: search/products 70 giây, analysis 90 giây; sau đó 20 / 20 / 35 giây.
- 429/503 có `Retry-After`: khóa nút và đếm ngược, không tự gửi lại.
- Phản hồi không phải JSON (trang HTML lỗi của Render/Cloudflare) → báo máy chủ tạm lỗi.
- Không ghi mã vạch hay từ khóa vào log.
- Hiển thị nguồn "Open Food Facts · ODbL · ảnh CC BY-SA" và link `source.url` ở màn chi tiết.
