# Fluw — Ghi chú tuân thủ pháp lý & điều khoản dịch vụ

> Tài liệu kỹ thuật dùng để sàng lọc rủi ro, **không phải tư vấn pháp lý**. Cần người có chuyên môn pháp lý xem xét trước khi phát hành trên CH Play.
> Cập nhật: 29/10/2026 · Nhánh `chore/legal-security-hardening`.

Mức độ tin cậy: **VERIFIED** (đã đối chiếu nguồn chính thức trong đợt này), **LIKELY**, **UNKNOWN** (cần xác minh thêm).

---

## 1. Open Food Facts (nguồn dữ liệu sản phẩm)

### 1.1. Giấy phép — VERIFIED (trang tài liệu API của OFF)

| Thành phần | Giấy phép | Nghĩa vụ chính |
|---|---|---|
| Cơ sở dữ liệu | Open Database License (ODbL) | Ghi nguồn; cơ sở dữ liệu phái sinh công khai phải chia sẻ cùng giấy phép (share-alike) |
| Nội dung từng bản ghi | Database Contents License (DbCL) | — |
| Ảnh sản phẩm | Creative Commons Attribution-ShareAlike (CC BY-SA) | Ghi tác giả ("Open Food Facts contributors"), chia sẻ cùng giấy phép; ảnh có thể chứa yếu tố đồ họa của bên thứ ba thuộc quyền khác |

Triển khai trong app: màn hình chi tiết hiển thị
*"Dữ liệu: Open Food Facts (openfoodfacts.org) — giấy phép ODbL. Ảnh sản phẩm: Open Food Facts contributors — CC BY-SA."* (FE-2).

### 1.2. Giới hạn tần suất — VERIFIED

- 15 request/phút/IP cho mọi truy vấn đọc sản phẩm (`GET /api/v*/product`).
- 10 request/phút/IP cho truy vấn tìm kiếm (`GET /api/v*/search`, `/cgi/search.pl`).
- Không dùng tìm kiếm kiểu search-as-you-type.

Rủi ro: mọi request của người dùng hiện đi qua một backend trên Render → OFF thấy **một IP chung**. Biện pháp đợt này: cache 24 giờ trong bộ nhớ, rate limit 30 request/phút/IP phía Fluw, xử lý HTTP 429 của OFF (→ 503 + `Retry-After: 60`). Kiến trúc gọi OFF trực tiếp từ app được ghi ở mục "Ngoài phạm vi" của spec.

Lưu ý: trang tài liệu OFF ghi giới hạn tìm kiếm cho `GET /api/v*/search`; backend Fluw dùng `POST https://search.openfoodfacts.org/search` (dịch vụ search-a-licious). Giới hạn riêng của dịch vụ này: **UNKNOWN**.

### 1.3. User-Agent bắt buộc — VERIFIED

Định dạng OFF yêu cầu: `AppName/Version (ContactEmail)`.
Backend gửi `Fluw/<version trong package.json> (<OFF_CONTACT_EMAIL>)`; nếu biến môi trường chưa đặt thì dùng `Fluw/<version> (https://github.com/Fluw13/Fluwwwwww)`. Chủ dự án cần đặt `OFF_CONTACT_EMAIL` là email thật của mình trên Render.

### 1.4. Nguyên tắc lưu trữ

- **Không** tạo cơ sở dữ liệu lưu bền (file, DB) chứa dữ liệu OFF khi chưa có ý kiến pháp lý về nghĩa vụ share-alike của ODbL đối với "cơ sở dữ liệu phái sinh".
- Cache hiện tại chỉ nằm trong bộ nhớ tiến trình, tối đa 500 mục, TTL 24 giờ, mất khi khởi động lại.

---

## 2. Google Gemini API

Bản điều khoản spec tham chiếu: 20/05/2025. Bản đang công bố khi kiểm tra ngày 29/10/2026: hiệu lực 23/03/2026, cập nhật lần cuối 28/04/2026 — các điều khoản dưới đây vẫn có trong bản này (VERIFIED). Cần đọc lại bản mới nhất trước mỗi lần phát hành.

| Điều khoản | Hệ quả cho Fluw |
|---|---|
| Người dùng API phải từ 18 tuổi trở lên | Chủ tài khoản API phải ≥ 18 tuổi; xem xét giới hạn độ tuổi trong chính sách của app |
| Gói miễn phí (Unpaid Services): Google dùng nội dung gửi lên và phản hồi để cải thiện sản phẩm; người đánh giá có thể đọc, gắn nhãn input/output | **Không** gửi dữ liệu cá nhân, nhạy cảm hoặc bí mật vào gói miễn phí. Hiện backend chỉ gửi dữ liệu sản phẩm công khai từ OFF |
| Ứng dụng cung cấp cho người dùng ở EEA, Thụy Sĩ, Vương quốc Anh chỉ được dùng gói trả phí | Chuyển sang gói trả phí trước khi phát hành ở các khu vực này |
| Không dựa vào dịch vụ cho tư vấn y tế, sức khỏe tâm thần, pháp lý, tài chính hoặc chuyên môn khác | Prompt không còn tuyên bố "chuẩn WHO/chuẩn y tế", cấm chẩn đoán; app gắn nhãn "Do AI tạo" và hiển thị miễn trừ trách nhiệm (BE-2, BE-7, FE-1) |

Tên model mặc định `gemini-3.6-flash` (cấu hình qua `GEMINI_MODEL`): **UNKNOWN** — chủ dự án cần xác minh model còn hoạt động.

---

## 3. Pháp luật Việt Nam về bảo vệ dữ liệu cá nhân

- Luật Bảo vệ dữ liệu cá nhân và **Nghị định 356/2025/NĐ-CP** hướng dẫn thi hành, hiệu lực từ **01/01/2026**, thay thế Nghị định 13/2023/NĐ-CP — VERIFIED (nguồn thứ cấp: PwC Việt Nam).
- Các nghĩa vụ cần lưu ý khi Fluw bắt đầu xử lý dữ liệu cá nhân (theo spec, cần chuyên gia pháp lý xác nhận chi tiết — LIKELY):
  - Sự đồng ý rõ ràng, tự nguyện, có thể rút lại của chủ thể dữ liệu.
  - Lập hồ sơ đánh giá tác động xử lý dữ liệu cá nhân (DPIA).
  - Chỉ định bộ phận/người phụ trách bảo vệ dữ liệu cá nhân.
- Áp dụng khi thêm: đăng nhập/tài khoản, nhật ký ăn uống, lịch sử quét, dữ liệu sức khỏe (dị ứng, bệnh lý — có thể là dữ liệu nhạy cảm).
- Trạng thái hiện tại (đã đối chiếu code): app **chưa** có tài khoản, **chưa** lưu lịch sử, chỉ gửi chuỗi mã vạch/từ khóa tới backend. Nhật ký truy cập của Render (IP, URL) là UNKNOWN — cần kiểm tra cấu hình Render.

---

## 4. Việc cần làm trước khi phát hành

1. Đặt `OFF_CONTACT_EMAIL`, `GEMINI_MODEL` trên Render.
2. Đặt budget alert cho Gemini; chuyển gói trả phí trước khi gửi dữ liệu cá nhân hoặc phát hành ở EEA/UK/Thụy Sĩ.
3. Người có chuyên môn pháp lý xem tài liệu này và `docs/PRIVACY_POLICY_DRAFT.md`.
4. Đọc lại điều khoản OFF và Gemini bản mới nhất.

---

## 5. Nguồn

- Open Food Facts — API documentation (giấy phép, rate limit, User-Agent): https://openfoodfacts.github.io/openfoodfacts-server/api
- Open Database License (ODbL) v1.0: https://opendatacommons.org/licenses/odbl/1-0/
- Database Contents License (DbCL) v1.0: https://opendatacommons.org/licenses/dbcl/1-0/
- Creative Commons BY-SA (phiên bản áp dụng cho ảnh OFF: LIKELY 3.0, cần xác nhận trên trang OFF): https://creativecommons.org/licenses/by-sa/3.0/
- Open Food Facts — Điều kiện sử dụng API (forum): https://forum.openfoodfacts.org/t/conditions-to-use-the-open-food-facts-api/443
- Gemini API Additional Terms of Service: https://ai.google.dev/gemini-api/terms
- PwC Việt Nam — Quy định mới về bảo vệ dữ liệu cá nhân (Nghị định 356/2025/NĐ-CP): https://www.pwc.com/vn/vn/publications/legal-news-brief/20260128-new-rules-personal-data-protection.html
- Toàn văn Nghị định 356/2025/NĐ-CP (Thư viện Pháp luật): https://thuvienphapluat.vn/van-ban/Quyen-dan-su/Nghi-dinh-356-2025-ND-CP-huong-dan-Luat-Bao-ve-du-lieu-ca-nhan-687428.aspx
