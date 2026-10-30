# ADR 0002 — API có phiên bản `/api/v1` và gỡ route cũ

- Trạng thái: **Đã duyệt** (FLuw, 30/10/2026). `/api/v1` thực hiện ở B3–B4; gỡ route cũ ở nhánh `chore/remove-legacy-api` (B5 + F9).

## Bối cảnh
- Route cũ `GET /api/product/:query` vừa tra theo mã vạch vừa tìm theo tên, tự chọn kết quả đầu tiên và gọi Gemini ngay trong request.
- Hệ quả: "Hảo hảo" ra nhầm "Vĩnh Hảo" vì không có danh sách để người dùng chọn; tra cứu chậm vì chờ AI; không tách được lỗi tìm kiếm, lỗi sản phẩm và lỗi AI.
- App chưa phát hành, chưa có người dùng ngoài nhóm phát triển.

## Quyết định
- Thêm các route có phiên bản, mỗi route một việc:
  - `GET /api/v1/search?q=` — danh sách kết quả đã xếp hạng;
  - `GET /api/v1/products/:barcode` — chi tiết + Điểm Fluw;
  - `GET /api/v1/products/:barcode/analysis` — Zero giải thích, tải riêng.
- Contract ghi trong `docs/API_CONTRACT_v1.md`, phản hồi mẫu trong `contracts/fixtures/` được test so khớp với server ở mỗi lần chạy `npm test`.
- Thay đổi phá vỡ contract sau này phải ra `/api/v2`, không sửa ngầm v1.
- Route cũ chạy song song cho tới khi app chuyển hết sang v1, rồi gỡ theo thứ tự:
  1. App chuyển mọi nơi gọi sang v1 (nhánh frontend).
  2. `git grep` chứng minh không còn nơi gọi code cũ.
  3. FLuw thử app trên máy thật với server Render.
  4. Merge nhánh gỡ code cũ: route trả `404 ROUTE_NOT_FOUND`; test bảo mật và lỗi được chuyển sang v1, không xóa.

## Đánh đổi
- Vì app chưa phát hành nên gỡ route cũ ngay, không giữ thời gian chuyển tiếp dài. Khi đã có người dùng, mỗi phiên bản API cũ phải giữ đến khi bản app dùng nó hết được hỗ trợ.
- Ba nhánh PR nối tiếp nhau (backend → frontend → gỡ code cũ) nên phải merge đúng thứ tự.

## Hệ quả
- App gọi 2–3 request nhỏ thay vì một request dài; sản phẩm và điểm hiện ngay, AI tải sau.
- Mã lỗi là một phần của contract; câu chữ `error` có thể đổi.
