# ADR 0001 — Backend tính điểm bằng quy tắc, AI chỉ giải thích

- Trạng thái: **Đã duyệt** (FLuw, 30/10/2026). Đã thực hiện ở B2 (`backend/src/scoring/`) và B4 (`/api/v1/products/:barcode/analysis`).

## Bối cảnh
- Trước v1, Gemini tự chấm điểm 0–100 trong lúc tra cứu sản phẩm. Gemini chỉ nhận năng lượng, đạm, béo, carbohydrate; không có đường, muối, béo bão hòa, chất xơ.
- Hệ quả: cùng một sản phẩm có thể ra điểm khác nhau mỗi lần; không giải thích được điểm đến từ đâu; khi Gemini lỗi hoặc hết hạn mức thì không có điểm; AI nằm trên đường chính nên tra cứu chậm.
- FLuw yêu cầu điểm phải công khai: công thức, trọng số, từng chỉ số, ngưỡng, nguồn dữ liệu, và ghi "Chưa đủ dữ liệu" thay vì đoán.

## Các phương án
1. Giữ AI chấm điểm, chỉ sửa prompt. Không xác định, không kiểm chứng được.
2. App tự tính điểm. Mỗi bản app một công thức; sửa công thức phải phát hành lại app.
3. **Backend tính điểm bằng hàm thuần, có phiên bản; AI chỉ giải thích điểm đã tính.**

## Quyết định
Chọn phương án 3.
- Điểm Fluw = 70% điểm dinh dưỡng (thuật toán Nutri-Score 2022/2023 quy đổi 0–100) + 30% điểm phụ gia. Đặc tả: `docs/SCORING.md`.
- Hàm tính điểm không gọi mạng, không phụ thuộc AI, có golden test (51 ca tham chiếu của Open Food Facts).
- Mọi thay đổi ngưỡng, dải, trọng số hoặc quy tắc dữ liệu phải tăng `SCORE_VERSION`.
- Thiếu dữ liệu cần thiết thì không chấm và liệt kê mục thiếu.
- AI (Zero) nhận bảng điểm đã tính, schema đầu ra không có trường điểm, chạy ở route riêng, lỗi AI không ảnh hưởng điểm.

## Đánh đổi
- Phải tự duy trì bảng ngưỡng Nutri-Score; Fluw tự viết code theo ngưỡng công bố, không sao chép code AGPL của Open Food Facts.
- Sản phẩm Việt Nam thường thiếu chất xơ hoặc danh mục trên Open Food Facts, nên nhiều sản phẩm sẽ "Chưa đủ dữ liệu". Chấp nhận để không hiển thị điểm đoán.
- Gemini vẫn tốn lượt gọi khi người dùng hỏi Zero; giới hạn bằng `AI_DAILY_LIMIT` và cache.

## Hệ quả
- App hiển thị đúng số backend trả về, in phép tính từ `total.calculation`, không tự áp ngưỡng.
- Điểm không đổi giữa các lần gọi cùng dữ liệu, kiểm thử được bằng test.
- Không dùng logo hay chữ cái A–E của Nutri-Score; văn phong trung lập.
