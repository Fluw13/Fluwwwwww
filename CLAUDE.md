# CLAUDE.md — Sổ tay cho agent làm việc trên Fluw

Đọc file này trước khi bắt đầu, ghi lại vào mục 10 sau khi làm xong. Đọc file này thay cho việc quét toàn bộ repo.

---

## 1. Quy tắc làm việc (FLuw đặt ra, bắt buộc)

### Đọc và sửa file
- Chỉ đọc đúng file, đúng vị trí liên quan đến yêu cầu. Không quét toàn bộ repo mỗi lần sửa hay kiểm tra lỗi.
- Chỉ sửa đúng chỗ cần sửa; phần đang đúng giữ nguyên.
- Sửa thứ dùng chung (contract API, widget dùng nhiều màn): tìm theo tên hàm/biến để biết nơi bị ảnh hưởng, không đọc trọn các file đó.
- Mỗi file một trách nhiệm, đặt đúng thư mục theo mục 3. Không code đường tắt, không dữ liệu thừa, không dồn nhiều chức năng vào một file.
- Không comment dư thừa; chỉ comment khi cần giải thích lý do kỹ thuật hoặc một quyết định không hiển nhiên.

### Trước khi sửa
- Báo lỗi tìm được và phương án đề xuất, **chờ FLuw đồng ý rồi mới làm**.
- Khi sửa: nói rõ sai ở đâu, vì sao sai, cách khắc phục, rồi mới đưa code.

### Git (không được tự ý vượt)
- Mỗi mốc / tính năng / bug fix một Pull Request để FLuw xem.
- **Không push trực tiếp vào `main`. Không tự merge PR. Không deploy production** khi FLuw chưa cho phép rõ ràng.
- Không ghi đè thay đổi sẵn có của FLuw. Working tree có thay đổi lạ thì kiểm tra trước.
- Trước khi push: phải có agent khác review chéo và các lỗi review đã sửa.
- Commit bằng danh tính git đã cấu hình sẵn, không ghi tên FLuw làm tác giả.

### Bảo mật
- Không hardcode API key, token, mật khẩu. Không đưa secret vào code, log, tài liệu, screenshot hay memory.
- Không yêu cầu FLuw gửi secret trong chat.
- Không bịa kết quả test, git hay deployment. Test nào chưa chạy thì ghi rõ là chưa chạy.

### Sau khi làm xong
- Ghi vào mục 10: đã sửa gì, ở file nào, vì sao, test nào đã chạy.
- Không viết tài liệu bàn giao nào khác (không file Word, không file handoff). CLAUDE.md cho agent, README.md cho FLuw.

---

## 2. Dự án (cập nhật 11/11/2026)

**Fluw**: ứng dụng tra cứu dinh dưỡng (calo, protein, đường, chất béo...), ghi nhật ký ăn uống và đánh giá nhu cầu theo hồ sơ sức khỏe của người dùng. Trợ lý AI tên **Zero**.

Đổi hướng ngày 11/11/2026. Bản cũ (tra cứu thực phẩm và chấm điểm FNS) đã gỡ khỏi cây code; vẫn xem được ở commit `df79e6b`.

| Thành phần | Thực tế |
|---|---|
| Repository | `https://github.com/Fluw13/Fluwwwwww`, branch chính `main` |
| Frontend | Flutter 3.47.9 / Dart 3.13.7, thư mục `frontend/`, chỉ Android và iOS, id `com.fluw.app` |
| Backend | Node.js ≥ 22.9 (22.x) + Express 5, thư mục `backend/`, entry `server.js` |
| Hosting backend | Render: `https://fluw.onrender.com`, tự deploy khi `main` đổi. Cấu hình service **chưa kiểm tra** (chờ FLuw xác nhận workspace) |
| APK | CI build, tải ở GitHub Actions → artifact `fluw-apk` |

### Các trang
Trang chủ, Tìm kiếm, Quét (mã vạch và nhận diện ảnh), Nhật ký (trang "note"), Cá nhân (hồ sơ sức khỏe), Lịch sử tra cứu, Thông tin sản phẩm, Chi tiết sản phẩm.

---

## 3. Kiến trúc và quy ước

### Frontend `frontend/lib/`
```
app/                      ghép app: FluwApp, router (go_router), shell 5 tab, AppTab
core/                     dùng chung: theme, widget chung, (sau này) network, database, format
features/<tên>/
  data/                   gọi API, đọc/ghi SQLite, chuyển đổi JSON
  domain/                 Dart thuần (không import Flutter): model, công thức, quy tắc. Bắt buộc có unit test
  presentation/           màn hình và widget riêng của tính năng
```
- Chỉ `app/` được import `features/`. `core/` không import `features/`. Feature không import thẳng feature khác; phần dùng chung đưa vào `core/`.
- Import dạng `package:fluw/...`. `dart format` độ rộng 120 (đặt trong `analysis_options.yaml`), CI chặn nếu sai format.
- Thứ tự tab chỉ khai báo ở `enum AppTab`; router và thanh điều hướng đều đọc từ đó.
- Thư viện dự kiến, **chỉ thêm khi dùng tới**: `flutter_riverpod` (state), `drift` (SQLite), `http`, `mobile_scanner`, `image_picker`, `flutter_local_notifications`, `flutter_localizations`.

### Backend `backend/`
```
server.js                 khởi động, tắt an toàn khi nhận SIGTERM
src/app.js                ghép middleware và route
src/routes → controllers → services → providers (OFF, USDA, Gemini)
src/middlewares/          notFound, errorHandler
tests/                    node:test, helper startServer
```
- Lỗi luôn trả `{ "error": { "code": "...", "message": "..." } }`, không lộ stack trace.
- Hợp đồng với Render, không được đổi: chạy `node server.js` trong `backend/`, đọc `PORT`, có `GET /health`.
- Biến môi trường khai báo trong `backend/.env.example`; local dùng `.env` (Node đọc bằng `--env-file-if-exists`).

---

## 4. Chạy và kiểm thử

```bash
# Backend
cd backend && npm install && npm test && npm run dev

# Frontend
cd frontend
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
- Môi trường cloud của agent không có Flutter sẵn: tải SDK `flutter_linux_3.47.9-stable.tar.xz` từ `storage.googleapis.com` vào scratchpad, `chown` thư mục SDK. **Không chạy `git config --global --add safe.directory`.**
- Không có Android SDK trong môi trường agent → không build APK tại chỗ. CI build APK release (ký bằng debug key) ở job `android-apk`.
- Proxy của môi trường agent chỉ cho push vào branch của phiên. Tạo tag, xóa branch khác phải để FLuw làm trên GitHub.

---

## 5. Quyết định đã chốt (FLuw duyệt 11/11/2026)

- **Git:** giữ lịch sử, dọn code bằng commit. Không force push.
- **Giao diện:** theo Figma của FLuw. File Figma `2E8p4ZnGESwih1lNFyWeMA` có Page 1 trống và gói Starter đã hết lượt gọi MCP → **FLuw gửi ảnh PNG từng màn**. Chưa có ảnh thì không tự dựng giao diện chi tiết.
- **Dữ liệu cá nhân lưu trên máy** (SQLite), không đăng nhập, không gửi hồ sơ sức khỏe lên server. Gỡ app là mất dữ liệu.
- **Scan ảnh:** Gemini Vision qua backend. Ảnh chỉ dùng để nhận diện tên thực phẩm, không lưu; dinh dưỡng tra từ nguồn dữ liệu, không lấy từ AI (trừ khi FLuw chọn khác ở câu hỏi 5).
- **Công thức BMR, TDEE, protein, mục tiêu** tính trên máy bằng Dart thuần ở `features/profile/domain/`, có unit test. Backend không nhận chiều cao, cân nặng, bệnh.
- Dữ liệu từ nguồn và nội dung AI phải phân biệt rõ trên giao diện. Thiếu dữ liệu thì ghi "Chưa có dữ liệu", không hiện số 0 hay số bịa.
- Mọi đánh giá sức khỏe ghi rõ là ước tính, không thay thế tư vấn y tế.

---

## 6. Đặc tả công thức (FLuw cung cấp)

**BMR (Mifflin–St Jeor):** W = cân nặng (kg), H = chiều cao (cm), A = tuổi (năm)
- Nam: `BMR = 10W + 6.25H - 5A + 5`
- Nữ: `BMR = 10W + 6.25H - 5A - 161`

**TDEE = BMR × AF**

| Mức vận động | AF |
|---|---|
| Ít vận động | 1,2 |
| Hoạt động nhẹ | 1,375 |
| Hoạt động vừa | 1,55 |
| Hoạt động nhiều | 1,725 |
| Hoạt động rất cao | 1,9 |

TDEE là ước tính, không phải số calo bắt buộc phải nạp. Người dưới 18 tuổi không dùng trực tiếp công thức người lớn.

**Protein (g/ngày) = W × P**

| Nhóm | P (g/kg/ngày) |
|---|---|
| Người trưởng thành khỏe mạnh | 0,8 |
| Thanh thiếu niên 14–18 tuổi | 0,85 |
| Người trưởng thành tập luyện thường xuyên | cao hơn, tùy cường độ và mục tiêu (chờ FLuw chốt con số) |

Đây là mức tham khảo, không phải giới hạn tối đa.

**Khung giờ trang Nhật ký** (tính theo phút, bỏ giây):
- Sáng 06:00–12:00, Chiều 12:01–18:00, Tối 18:01–24:00 (00:00 thuộc Tối), Đêm 00:01–05:59.
- Ngoài cùng là nhóm theo ngày; mỗi khung và mỗi ngày có tổng calo, protein, đường...
- "Đạm" và "protein" là một chỉ số, hiển thị là "Protein (đạm)".

---

## 7. Câu hỏi đang chờ FLuw

1. **Ảnh PNG từng màn** từ Figma.
2. **Nguồn dữ liệu:** đồ đóng gói lấy từ Open Food Facts; đồ tươi lấy từ USDA FoodData Central (cần API key miễn phí). Món Việt (phở, cơm tấm...) chọn một trong hai: Gemini ước tính kèm nhãn "AI ước tính", hoặc tự xây bảng dữ liệu.
3. **Số sao đánh giá:** bỏ, do app tính từ dinh dưỡng (ghi rõ cách tính), hay người dùng chấm (cần tài khoản và server)?
4. **Dưới 18 tuổi:** đề xuất không dùng Mifflin, chỉ hiện protein 0,85 g/kg cho 14–18 tuổi kèm khuyên gặp chuyên gia; dưới 14 tuổi chặn tính.
5. **Tốc độ giảm/tăng cân:** đề xuất tối đa 0,5 kg/tuần (khoảng ±550 kcal/ngày), mục tiêu calo không thấp hơn BMR.
6. **Bệnh hỗ trợ bản đầu:** đề xuất tiểu đường (đường), huyết áp cao (natri), mỡ máu cao (béo bão hòa), dị ứng (theo OFF).
7. **Giờ nhắc mặc định:** đề xuất 7h, 12h, 19h, thêm 21h nếu chưa đủ calo/protein; người dùng chỉnh được.
8. **Khung Đêm (00:01–05:59) thuộc ngày nào:** ngày hôm trước hay ngày mới?
9. **Giữ tên** app "Fluw" và trợ lý "Zero"? Tab "Nhật ký" có muốn đổi thành "Note"?
10. **Render:** dùng workspace "My Workspace" và thay service `fluw` hiện tại?
11. **APK:** giữ ký bằng debug key, hay tạo keystore release (FLuw tự tạo, đưa vào GitHub Secrets)?
12. **Protein cho người tập luyện:** con số cụ thể (ví dụ 1,2–1,6 g/kg)?
13. **4 branch có commit chưa merge** (`chore/legal-security-hardening`, `chore/remove-legacy-api`, `feat/api-v1-backend`, `feat/api-v1-frontend`): xóa luôn hay giữ? 18 branch còn lại đã nằm trọn trong `main`, FLuw xóa trên GitHub (agent không có quyền).

---

## 8. Lộ trình

| Mốc | Nội dung | Trạng thái |
|---|---|---|
| M0 | Dọn repo, khung frontend/backend, CI build APK, CLAUDE.md, README | Đang review (PR). **Merge là Render deploy khung mới ngay, API cũ `/api/product/*` biến mất** |
| M1 | Backend: `GET /api/foods/search?q=`, `GET /api/foods/barcode/:code`, `POST /api/foods/recognize`; deploy Render | Chờ câu 2, 10 |
| M2 | Hồ sơ sức khỏe + công thức BMR/TDEE/protein/mục tiêu | Chờ PNG, câu 4, 5, 12 |
| M3 | Tìm kiếm, thông tin + chi tiết sản phẩm, lịch sử tra cứu | Chờ M1, PNG, câu 3 |
| M4 | Nhật ký theo ngày và 4 khung giờ, tổng theo buổi và ngày | Chờ PNG, câu 8 |
| M5 | Quét mã vạch + nhận diện ảnh | Chờ M1 |
| M6 | Gợi ý nên/không nên, nhắc nhở, sở thích | Chờ câu 6, 7 |

---

## 9. Ghi nhận kỹ thuật

- Dữ liệu sức khỏe là dữ liệu cá nhân nhạy cảm theo Nghị định 13/2023/NĐ-CP → giữ trên máy. Nếu sau này có tài khoản/đồng bộ thì cần màn đồng ý, chính sách quyền riêng tư và cho xóa tài khoản trong app.
- Open Food Facts: dữ liệu ODbL, ảnh CC BY-SA; phải ghi nguồn trên giao diện. Nhiều sản phẩm Việt Nam thiếu `categories_tags` và dinh dưỡng.
- `android/gradle/wrapper/gradle-wrapper.jar`, `gradlew` bị `.gitignore` của template bỏ qua; Flutter tự tạo khi build.
- Runner CI tạo debug keystore mới mỗi lần → mỗi APK một chữ ký, không cài đè được, phải gỡ bản cũ (mất dữ liệu SQLite). Cần keystore cố định trong GitHub Secrets trước khi M2 bắt đầu lưu dữ liệu (câu 11).
- M1, khi thêm `express.json()`: `errorHandler` phải giữ `error.status` 4xx (JSON hỏng → 400, body quá lớn → 413) thay vì trả 500.
- Express 5 gọi callback của `app.listen` cả khi lỗi; `server.js` đã bỏ qua nhánh lỗi để handler `'error'` xử lý.
- Gói Gemini miễn phí giới hạn lượt/ngày; model đang dùng trên Render chưa kiểm tra lại.

---

## 10. Nhật ký công việc

Mục mới nhất ở trên. Mỗi mục ghi: ngày, PR, đã sửa gì ở file nào, vì sao, test đã chạy.

### 11/11/2026 — M0: đổi hướng dự án, dọn repo, dựng khung
- **Gỡ:** toàn bộ `backend/`, `frontend/`, `docs/`, `FLUW_PROJECT_HANDOFF.docx`, `FLUW_PROJECT_HANDOFF.md`, CLAUDE.md và README cũ. Lý do: FLuw đổi hướng sang ứng dụng theo dõi calo/protein.
- **Backend mới:** `server.js` (giữ cách tắt an toàn của bản cũ), `src/app.js` (`/health`, tắt `x-powered-by`), `src/middlewares/notFound.js`, `errorHandler.js`, `tests/`. Bỏ `dotenv`, `axios`, `cors`, `@google/genai`, `express-rate-limit` vì M0 chưa dùng; thêm lại ở mốc cần.
- **Frontend mới:** `flutter create` lại, chỉ Android/iOS, id `com.fluw.app`, quyền INTERNET ở manifest chính, bỏ comment TODO của template. `lib/app/` (FluwApp, router, shell, AppTab), `lib/core/theme/`, `lib/core/widgets/empty_state.dart`, 5 màn khung ở `lib/features/*/presentation/` ghi rõ "Đang xây dựng".
- **CI:** ghim Flutter 3.47.9, thêm kiểm tra `dart format`, thêm job `android-apk` build APK release và tải lên artifact `fluw-apk`.
- **Không làm được:** tạo tag `legacy-v0` và xóa 22 branch cũ, vì proxy chặn push ngoài branch của phiên. Lịch sử vẫn giữ; bản cũ ở `df79e6b`.
- **Sửa theo review độc lập:**
  - `server.js`: cổng bị chiếm vẫn in "Server is running" (callback Express 5 nhận lỗi).
  - `engines` thành `>=22.9.0 <23`, vì `--env-file-if-exists` cần Node 22.9.
  - Thêm test kiểm `notFound` và `errorHandler` là hai middleware cuối của app; gỡ `errorHandler` thì test fail.
  - CI thêm `permissions: contents: read`.
  - README: ghi rõ phần quyền riêng tư là dự kiến (kèm điều khoản Gemini gói miễn phí), thư mục nào chưa có, và cảnh báo APK phải gỡ bản cũ trước khi cài.
  - Hoãn sang M1: `errorHandler` giữ status 4xx (chưa có body parser nào sinh lỗi 4xx).
- **Test:** `npm test` 4/4; `npm start` trả `{"status":"ok"}` ở `/health`; cổng bị chiếm thì thoát mã 1 và không in log sai. `flutter analyze` sạch, `dart format` sạch, `flutter test` 6/6; bỏ `SingleChildScrollView` khỏi `EmptyState` thì test 320×568 chữ 200% fail. Job `android-apk` chưa chạy tại chỗ (không có Android SDK); kết quả xem trên CI của PR.
