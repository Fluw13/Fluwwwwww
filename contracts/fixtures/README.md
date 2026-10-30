# Contract fixtures — phản hồi mẫu của API v1

Mỗi file là một phản hồi HTTP thật của backend Fluw, dùng chung cho test backend và test app Flutter. Mô tả các trường: [`docs/API_CONTRACT_v1.md`](../../docs/API_CONTRACT_v1.md).

## Định dạng

```json
{
  "request": "GET /api/v1/products/8930000000019",
  "status": 200,
  "headers": { "retry-after": "60" },
  "body": { "success": true, "...": "..." }
}
```

- `headers` chỉ ghi các header mà app cần đọc (hiện là `retry-after`).
- `product.source.fetchedAt` được cố định để file không đổi giữa các lần tạo.

## Cách tạo

```bash
cd backend
npm run contract:fixtures
```

- Script chạy server thật trong bộ nhớ, thay Open Food Facts bằng dữ liệu trong `backend/tests/fixtures/off/` và thay Gemini bằng câu trả lời ghi sẵn, rồi gọi từng route.
- Test `backend/tests/contract/contractFixtures.test.js` tạo lại các phản hồi và so với file trên đĩa. Khi đổi contract mà quên chạy lại script thì test fail.
- Giới hạn lượt dùng khi tạo fixture được đặt trong `LIMITS_FOR_CAPTURE` (search 4 lượt/phút để có mẫu `error-rate-limited`, AI 2 lượt/ngày để có mẫu `analysis-ai-daily-limit`).

## Nguồn dữ liệu và giấy phép

- Sản phẩm mã `8930000000xxx` là **sản phẩm thử do Fluw tự tạo** (tên có "(dữ liệu thử)", thương hiệu "Fluw Test"), không phải sản phẩm thật. Đường dẫn ảnh của chúng chỉ minh họa định dạng.
- Kết quả tìm kiếm trong `search-*.json` lấy từ dữ liệu thật của [Open Food Facts](https://world.openfoodfacts.org), theo giấy phép [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/); ảnh sản phẩm của Open Food Facts theo giấy phép [CC BY-SA](https://creativecommons.org/licenses/by-sa/3.0/).
- Nội dung `analysis-ok.json` là câu trả lời mẫu do Fluw viết để mô phỏng Gemini; mọi con số trong đó lấy từ điểm của sản phẩm thử tương ứng.
