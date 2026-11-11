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
- Không yêu cầu FLuw gửi secret trong chat. Key cho môi trường agent thì xin qua form bảo mật (`request_credential`); key cho Render thì FLuw tự nhập trên dashboard.
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
| Hosting backend | Render, workspace "My Workspace", service `Fluw` (`srv-dbed4jlg1s2s73f7jrdg`), `https://fluw.onrender.com` |
| APK | CI build, tải ở GitHub Actions → artifact `fluw-apk` |

**Render (VERIFIED 11/11/2026):**
- Cấu hình build và chạy: root dir `backend`, build `npm install`, start `node server.js`, gói free, region virginia.
- Auto-deploy từ `main`, kích hoạt `checksPass` (chỉ deploy khi CI xanh).
- **Health check path chưa đặt.**
- Gói free ngủ sau 15 phút không có request; request đầu tiên sau đó chậm khoảng 50 giây. App phải hiện trạng thái chờ và đặt timeout đủ dài.

### Các trang
Trang chủ, Tìm kiếm, Quét (mã vạch và nhận diện ảnh), **Note** (nhật ký ăn uống), Cá nhân (hồ sơ sức khỏe), Lịch sử tra cứu, Thông tin sản phẩm, Chi tiết sản phẩm.

---

## 3. Kiến trúc và quy ước

### Frontend `frontend/lib/`
```
app/                      ghép app: FluwApp, router (go_router), shell 5 tab, AppTab
core/                     dùng chung: theme, widget chung, time (CalendarDate), (sau này) network, database, format
features/<tên>/
  data/                   gọi API, đọc/ghi SQLite, chuyển đổi JSON
  domain/                 Dart thuần (không import Flutter): model, công thức, quy tắc. Bắt buộc có unit test
  presentation/           màn hình và widget riêng của tính năng
```
- Feature hiện có: `home`, `search`, `scan`, `note`, `profile`.
- Chỉ `app/` được import `features/`. `core/` không import `features/`. Feature không import thẳng feature khác; phần dùng chung đưa vào `core/`.
- Import dạng `package:fluw/...`, xếp theo alphabet (lint `directives_ordering`). `dart format` độ rộng 120 (đặt trong `analysis_options.yaml`), CI chặn nếu sai format.
- Thứ tự tab chỉ khai báo ở `enum AppTab`; router và thanh điều hướng đều đọc từ đó.
- `features/profile/domain/` (M2):
  - `sex`, `activity_level` (hệ số AF), `training_type`, `weight_goal` (suy ra từ cân nặng mong muốn: làm tròn từng cân nặng đến 0,1 kg rồi so).
  - `age` (mốc 14, 18, tối đa 120).
  - `energy` (BMR, TDEE), `calorie_target` (`isValidWeeklyChangeKg` so theo 0,01 kg), `protein_target` (`ProteinGroup` và `ProteinTarget`).
  - `health_profile` (`weeklyChangeKg` để trống được), `profile_validation` (giới hạn và `ProfileIssue`), `daily_targets`.
  - `calculateDailyTargets` trả một trong `InvalidProfile` / `BelowMinimumAge` / `TeenTargets` / `AdultTargets` (sealed class, UI phải xử lý đủ 4 trường hợp). Hồ sơ lỗi không ném exception, để hồ sơ cũ trong SQLite không làm crash màn hình khi giới hạn đổi.
  - Giới hạn hồ sơ (agent đề xuất, chờ FLuw duyệt ở mục 7):
    - chiều cao 100–250 cm, cân nặng 20–300 kg, tuổi tối đa 120;
    - tốc độ đổi cân lớn hơn 0 và không quá 0,5 kg/tuần, chỉ bắt buộc với người lớn muốn tăng/giảm cân.
- **Ngày tháng:**
  - Ngày sinh và ngày trong Note dùng `CalendarDate` (năm, tháng, ngày), không dùng `DateTime`, để không lệch ngày khi đổi múi giờ.
  - "Hôm nay" lấy bằng `CalendarDate.fromDateTime(DateTime.now())`.
  - SQLite lưu dạng chuỗi `yyyy-MM-dd`.
- **Khi làm phần data M2:** thêm `==`, `hashCode`, `copyWith` cho `HealthProfile` (Riverpod và test lưu/đọc SQLite cần).
- Thư viện dự kiến, **chỉ thêm khi dùng tới**: `flutter_riverpod` (state), `drift` (SQLite), `http`, `mobile_scanner`, `image_picker`, `flutter_local_notifications`, `flutter_localizations`.

### Android signing
- `android/app/build.gradle.kts` đọc `android/key.properties` nếu có. Không có thì bản release ký bằng debug key.
- CI tạo `key.properties` và `android/app/upload-keystore.jks` từ 4 secret: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. Thiếu secret thì CI cảnh báo và dùng debug key.
- `key.properties`, `*.jks`, `*.keystore` đã nằm trong `android/.gitignore`. Không bao giờ commit.
- `build.gradle.kts` phải `import java.util.Properties`: trong script Gradle, `java` là extension của plugin Java nên `java.util.Properties()` không compile.
- PR từ branch trong repo (kể cả branch của agent) nhận được keystore thật; PR từ fork thì không. Muốn chặt hơn thì chỉ ký ở `push main` hoặc dùng GitHub Environment có bảo vệ.

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
- Không có Android SDK trong môi trường agent → không build APK tại chỗ, không kiểm được `build.gradle.kts`. CI build APK ở job `android-apk`.
- Proxy của môi trường agent chỉ cho push vào branch của phiên. Tạo tag, xóa branch khác phải để FLuw làm trên GitHub.
- Render MCP không sửa được cấu hình service (chỉ đọc, đổi biến môi trường, trigger deploy).

---

## 5. Quyết định đã chốt (FLuw duyệt 11/11/2026)

- **Git:** giữ lịch sử, dọn code bằng commit. Không force push. Xóa toàn bộ 22 branch cũ, kể cả 4 branch có commit chưa merge (FLuw tự xóa trên GitHub).
- **Tên:** app "Fluw", trợ lý "Zero", tab nhật ký tên **"Note"**.
- **Giao diện:** theo Figma của FLuw. File Figma `2E8p4ZnGESwih1lNFyWeMA` có Page 1 trống và gói Starter đã hết lượt gọi MCP → **FLuw gửi ảnh PNG từng màn**. Chưa có ảnh thì không tự dựng giao diện chi tiết.
- **Dữ liệu sức khỏe lưu trên máy** (SQLite): hồ sơ, Note, lịch sử tra cứu, sở thích. Không gửi chiều cao, cân nặng, bệnh lên server.
- **Đánh giá sao do người dùng chấm** → cần tài khoản, server và database. Tài khoản chỉ dùng cho đánh giá; dữ liệu sức khỏe vẫn chỉ ở trên máy. Làm ở M7 với Firebase Authentication (Google/email) + PostgreSQL trên Neon + backend Node kiểm ID token. Không dùng Postgres free của Render (hết hạn sau 30 ngày).
- **Nguồn dữ liệu dinh dưỡng:**
  - Đồ đóng gói và mã vạch: Open Food Facts.
  - Đồ tươi: USDA FoodData Central (cần API key miễn phí, đặt ở Render dưới tên `USDA_API_KEY`).
  - Món Việt: Fluw **tự xây bảng dữ liệu**. Mỗi món là một công thức (nguyên liệu, số gram cho 1 suất), dinh dưỡng tính từ số liệu nguyên liệu của USDA (CC0). Trên app ghi "Ước tính theo công thức Fluw". Không chép Bảng thành phần thực phẩm Việt Nam khi chưa rõ giấy phép.
- **Scan ảnh:** Gemini Vision qua backend, chỉ để nhận ra tên thực phẩm; dinh dưỡng tra từ các nguồn trên, không lấy từ AI. Máy chủ Fluw không lưu ảnh.
- **Render:** dùng workspace "My Workspace", service `Fluw` hiện tại chạy backend mới.
- **APK:** FLuw tự tạo keystore và đưa vào GitHub Secrets.
- **Công thức BMR, TDEE, protein, mục tiêu** tính trên máy bằng Dart thuần ở `features/profile/domain/`, có unit test.
- **Dưới 18 tuổi:** không dùng Mifflin–St Jeor, không tính calo. `14 ≤ tuổi < 18` chỉ hiện protein 0,85 g/kg kèm lời khuyên gặp chuyên gia. `tuổi < 14` chặn tính toán. Người lớn là `tuổi ≥ 18`.
- **Tốc độ giảm/tăng cân:** tối đa 0,5 kg/tuần (khoảng ±550 kcal/ngày so với TDEE). Mục tiêu calo không bao giờ thấp hơn BMR.
- **Bệnh hỗ trợ bản đầu:**
  - Tiểu đường: theo dõi đường.
  - Huyết áp cao: theo dõi natri.
  - Mỡ máu cao: theo dõi béo bão hòa.
  - Dị ứng: theo tag dị ứng của OFF.
- **Nhắc nhở:** nhắc theo lịch, mặc định 10:00, 17:00, 22:00, người dùng chỉnh được. Nội dung nhắc dựa trên lượng đã nạp so với mục tiêu; ăn chưa đủ thì kèm gợi ý.
- Dữ liệu từ nguồn và nội dung AI phải phân biệt rõ trên giao diện. Thiếu dữ liệu thì ghi "Chưa có dữ liệu", không hiện số 0 hay số bịa.
- Mọi đánh giá sức khỏe ghi rõ là ước tính, không thay thế tư vấn y tế.

---

## 6. Đặc tả công thức (FLuw cung cấp)

**BMR (Mifflin–St Jeor), chỉ cho người từ 18 tuổi:** W = cân nặng (kg), H = chiều cao (cm), A = tuổi (năm)
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

TDEE là ước tính, không phải số calo bắt buộc phải nạp.

**Mục tiêu calo:** TDEE ± tối đa khoảng 550 kcal/ngày (≤ 0,5 kg/tuần), không thấp hơn BMR.

**Protein (g/ngày) = W × P**

| Nhóm | P (g/kg/ngày) |
|---|---|
| `14 ≤ tuổi < 18` (mọi mức tập luyện) | 0,85 |
| `tuổi ≥ 18`, không tập thường xuyên | 0,8 |
| Vận động nhẹ / sức bền (chạy bộ, đạp xe, yoga) | 1,2–1,4 |
| Gym / tăng cơ | 1,6–2,2 |
| Giảm mỡ giữ cơ (đang thâm hụt calo) | 1,8–2,4 |

Các mức tập luyện chỉ áp dụng khi `tuổi ≥ 18`. Nhóm chọn theo "hình thức tập" người dùng khai (không tập / nhẹ, sức bền / gym); gym kèm mục tiêu giảm cân thì vào nhóm giảm mỡ giữ cơ. App hiện cả khoảng; coi là **đủ** khi đạt cận dưới. Đây là mức tham khảo, không phải giới hạn tối đa. Nguồn cho khoảng 1,6–2,2 là phân tích gộp Morton et al. 2018 (British Journal of Sports Medicine); khuyến nghị chung của ISSN (Jäger et al. 2017) là 1,4–2,0. Khi hiện nguồn trên app phải ghi đúng tên nghiên cứu.

**Khung giờ trang Note** (tính theo phút, bỏ giây):
- Sáng 06:00–12:00, Chiều 12:01–18:00, Tối 18:01–24:00, Đêm 00:01–05:59.
- **Đêm thuộc ngày mới** (ngày theo lịch). Riêng 00:00 là "24:00", thuộc khung Tối của ngày hôm trước.
- Ngoài cùng là nhóm theo ngày; mỗi khung và mỗi ngày có tổng calo, protein, đường...
- "Đạm" và "protein" là một chỉ số, hiển thị là "Protein (đạm)".

---

## 7. Đang chờ FLuw

### Câu hỏi
1. **Ảnh PNG từng màn** từ Figma.
2. **Giới hạn hồ sơ:** chiều cao 100–250 cm, cân nặng 20–300 kg, tuổi tối đa 120. Có cần đổi không?

### Việc FLuw làm trên GitHub / Render
- Duyệt và merge PR #19 (M0). Merge xong Render deploy khung mới, API cũ `/api/product/*` biến mất.
- Xóa 22 branch cũ trên GitHub.
- Tạo keystore, thêm 4 secret Android (hướng dẫn trong README).
- Đặt Health Check Path `/health` cho service `Fluw` trên Render.
- Đăng ký USDA API key, thêm biến `USDA_API_KEY` trên Render (làm trước M1).

---

## 8. Lộ trình

| Mốc | Nội dung | Trạng thái |
|---|---|---|
| M0 | Dọn repo, khung frontend/backend, CI build APK + ký keystore, CLAUDE.md, README | PR #19 đang review |
| M1 | Backend: `GET /api/foods/search?q=`, `GET /api/foods/barcode/:code`, `POST /api/foods/recognize`; OFF + USDA + bảng món Việt | Chờ USDA key |
| M2 | Hồ sơ sức khỏe + công thức BMR/TDEE/protein/mục tiêu | Domain xong (chờ review); giao diện, lưu SQLite chờ PNG |
| M3 | Tìm kiếm, thông tin + chi tiết sản phẩm, lịch sử tra cứu | Chờ M1, PNG |
| M4 | Note theo ngày và 4 khung giờ, tổng theo buổi và ngày | Chờ PNG |
| M5 | Quét mã vạch + nhận diện ảnh | Chờ M1 |
| M6 | Gợi ý nên/không nên, nhắc 10h/17h/22h, sở thích | Chờ M2–M4 |
| M7 | Tài khoản + đánh giá sao | Chờ câu 4 |

---

## 9. Ghi nhận kỹ thuật

- **Dữ liệu sức khỏe** là dữ liệu cá nhân nhạy cảm theo Nghị định 13/2023/NĐ-CP → giữ trên máy.
  - Tài khoản ở M7 cần màn đồng ý, chính sách quyền riêng tư, cho xóa tài khoản ngay trong app (yêu cầu của Google Play và App Store), cơ chế báo cáo đánh giá xấu.
- **Open Food Facts:** dữ liệu ODbL, ảnh CC BY-SA; phải ghi nguồn trên giao diện. Nhiều sản phẩm Việt Nam thiếu `categories_tags` và dinh dưỡng.
- **USDA FoodData Central:** tên thực phẩm bằng tiếng Anh. Từ khóa tiếng Việt cần bảng ánh xạ hoặc dịch trước khi tìm.
- **Gradle wrapper:** `gradle-wrapper.jar` và `gradlew` bị `.gitignore` của template bỏ qua; Flutter tự tạo khi build.
- **Chữ ký APK:** chưa có secret keystore thì mỗi lần CI build một debug key mới → không cài đè được, phải gỡ bản cũ. Cần có keystore trước khi M2 bắt đầu lưu dữ liệu.
- **M1, khi thêm `express.json()`:** `errorHandler` phải giữ `error.status` 4xx (JSON hỏng → 400, body quá lớn → 413) thay vì trả 500.
- **Express 5** gọi callback của `app.listen` cả khi lỗi; `server.js` đã bỏ qua nhánh lỗi để handler `'error'` xử lý.
- **Gemini:** gói miễn phí giới hạn lượt/ngày, và Google có thể dùng nội dung gửi lên để cải thiện sản phẩm. Model và biến môi trường Gemini trên Render chưa kiểm tra lại.

---

## 10. Nhật ký công việc

Mục mới nhất ở trên. Mỗi mục ghi: ngày, PR, đã sửa gì ở file nào, vì sao, test đã chạy.

### 11/11/2026 — M2 (phần domain): công thức BMR, TDEE, mục tiêu calo, protein
- **Quyết định FLuw đồng ý:**
  - Bảng món Việt tính từ công thức món × số liệu USDA.
  - Protein hiện cả khoảng, đủ khi đạt cận dưới; gym kèm giảm cân thì vào nhóm giảm mỡ giữ cơ.
  - Tài khoản: Firebase Auth + Neon Postgres.
- **Thêm:**
  - 11 file trong `frontend/lib/features/profile/domain/` (xem mục 3), Dart thuần, không import Flutter.
  - `frontend/lib/core/time/calendar_date.dart`.
- **Quyết định kỹ thuật:**
  - Tuổi tính từ ngày sinh, không lưu số tuổi. Người sinh 29/2 thì ở năm không nhuận được thêm tuổi từ 1/3.
  - ±550 kcal/ngày lấy từ 0,5 kg × 7700 kcal/kg ÷ 7.
  - Giảm cân bị chặn ở BMR thì có cờ `isRaisedToBmr` để UI giải thích.
  - So mốc protein "đủ" theo đơn vị 0,1 g, vì `42,2 × 0,85` trong máy ra `35,870000000000005`.
- **Sửa theo review độc lập (trước khi push):**
  - Thiếu giới hạn tuổi tối đa: sinh năm 1800 ra calo âm → thêm `birthDateTooOld` (trên 120 tuổi).
  - `weeklyChangeKg` bắt buộc cả khi giữ cân → cho để trống, chỉ bắt buộc với người lớn tăng/giảm cân (`weeklyChangeMissing`).
  - Hồ sơ lỗi ném `ArgumentError` → trả `InvalidProfile(issues)`.
  - `DateTime` lệch ngày theo múi giờ → thêm `CalendarDate`.
  - `WeightGoal` làm tròn hiệu số (69,96 → 70,04 bị coi là tăng) → làm tròn từng cân nặng.
  - `0.1*3 + 0.2` bị coi là vượt 0,5 → so theo 0,01 kg.
  - NaN làm crash → NaN bị coi là không hợp lệ hoặc chưa đủ.
  - Bổ sung test cho 9 đột biến trước đó lọt qua: tháng sinh, mốc 14/18 trong `calculateDailyTargets`, hệ số từng nhóm protein, cận dưới cân nặng mong muốn, tốc độ âm.
- **Test:**
  - 61 test ở `test/features/profile/domain/` và `test/core/time/`, số mong đợi tính tay.
  - `flutter test` 67/67, `flutter analyze` sạch, `dart format` sạch.
  - Kiểm 20 đột biến (gồm 9 đột biến review chỉ ra): lần nào cũng có test fail.

### 11/11/2026 — PR #19 (tiếp): ghi quyết định của FLuw, đổi tab Note, ký APK bằng keystore
- **Sửa theo review độc lập (trước khi push):**
  - **Cao:** `build.gradle.kts` dùng `java.util.Properties()` sẽ không compile, vì `java` trong script Gradle trỏ tới extension của plugin Java. Đã đổi thành `import java.util.Properties`.
  - CI: decode base64 bằng `--ignore-garbage`, để CRLF/BOM từ Windows không làm fail. Có base64 mà thiếu 3 secret còn lại thì báo `::error::` rõ ràng.
  - README:
    - Lệnh PowerShell dùng `$PWD` và `Set-Content -NoNewline -Encoding ascii`.
    - Gọi `keytool.exe` có dấu cách bằng `&`.
    - Mật khẩu key phải giống hệt mật khẩu keystore (PKCS12); mật khẩu không dấu, tối thiểu 6 ký tự.
  - Mốc tuổi ghi rõ `14 ≤ tuổi < 18`, người lớn `tuổi ≥ 18`.
  - Lịch nhắc thống nhất: nhắc theo lịch, nội dung tùy lượng đã nạp.
  - Chạy thử lại bước keystore với 3 trường hợp: không secret (cảnh báo, exit 0), thiếu mật khẩu (exit 1), base64 lẫn CRLF và BOM (decode đúng).
- **Quyết định FLuw trả lời:** ghi vào mục 5–8.
  - Món Việt tự xây bảng; đồ tươi lấy từ USDA.
  - Sao do người dùng chấm, làm ở M7.
  - Đồng ý các đề xuất về dưới 18 tuổi, tốc độ giảm cân, bệnh hỗ trợ.
  - Bảng protein theo mục tiêu.
  - Nhắc lúc 10h/17h/22h.
  - Khung Đêm thuộc ngày mới.
  - Tab đổi tên thành Note.
  - Đồng ý dùng Render hiện có.
  - FLuw tự tạo keystore.
  - Xóa 22 branch cũ.
- **Sửa nguồn trích dẫn:** khoảng 1,6–2,2 g/kg là của Morton et al. 2018, không phải ISSN (ISSN 2017 khuyến nghị 1,4–2,0).
- **Đổi tên** `features/diary` → `features/note` (`NoteScreen`, `AppTab.note`, path `/note`, nhãn "Note") để code khớp tên trên giao diện.
- **Ký APK:**
  - `android/app/build.gradle.kts` đọc `key.properties` nếu có; không có thì dùng debug key.
  - CI thêm bước tạo keystore từ 4 secret; thiếu secret thì cảnh báo, không fail.
- **Render:** đọc cấu hình service `Fluw` (chỉ đọc), khớp hợp đồng `node server.js` / `PORT`; health check chưa đặt.
- **Test:**
  - `flutter analyze` sạch, `dart format` sạch, `flutter test` 6/6.
  - Chạy thử bước keystore của CI bằng secret giả: có secret thì tạo đúng `key.properties` (kể cả mật khẩu có `%`); không có secret thì thoát 0 kèm cảnh báo.
  - `build.gradle.kts` chưa kiểm tại chỗ (không có Android SDK); xem kết quả job `android-apk`.

### 11/11/2026 — M0: đổi hướng dự án, dọn repo, dựng khung (PR #19)
- **Gỡ:** toàn bộ `backend/`, `frontend/`, `docs/`, `FLUW_PROJECT_HANDOFF.docx`, `FLUW_PROJECT_HANDOFF.md`, CLAUDE.md và README cũ. Lý do: FLuw đổi hướng sang ứng dụng theo dõi calo/protein.
- **Backend mới:**
  - `server.js` (giữ cách tắt an toàn của bản cũ), `src/app.js` (`/health`, tắt `x-powered-by`), `src/middlewares/notFound.js`, `errorHandler.js`, `tests/`.
  - Bỏ `dotenv`, `axios`, `cors`, `@google/genai`, `express-rate-limit` vì M0 chưa dùng; thêm lại ở mốc cần.
- **Frontend mới:**
  - `flutter create` lại, chỉ Android/iOS, id `com.fluw.app`, quyền INTERNET ở manifest chính, bỏ comment TODO của template.
  - `lib/app/` (FluwApp, router, shell, AppTab), `lib/core/theme/`, `lib/core/widgets/empty_state.dart`.
  - 5 màn khung ở `lib/features/*/presentation/` ghi rõ "Đang xây dựng".
- **CI:** ghim Flutter 3.47.9, thêm kiểm tra `dart format`, thêm job `android-apk` build APK release và tải lên artifact `fluw-apk`.
- **Không làm được:** tạo tag `legacy-v0` và xóa 22 branch cũ, vì proxy chặn push ngoài branch của phiên. Lịch sử vẫn giữ; bản cũ ở `df79e6b`.
- **Sửa theo review độc lập:**
  - `server.js`: cổng bị chiếm vẫn in "Server is running" (callback Express 5 nhận lỗi).
  - `engines` thành `>=22.9.0 <23`, vì `--env-file-if-exists` cần Node 22.9.
  - Thêm test kiểm `notFound` và `errorHandler` là hai middleware cuối của app; gỡ `errorHandler` thì test fail.
  - CI thêm `permissions: contents: read`.
  - README: ghi rõ phần quyền riêng tư là dự kiến, thư mục nào chưa có, cảnh báo APK phải gỡ bản cũ trước khi cài.
  - Hoãn sang M1: `errorHandler` giữ status 4xx.
- **Test:**
  - `npm test` 4/4; `npm start` trả `{"status":"ok"}` ở `/health`; cổng bị chiếm thì thoát mã 1.
  - `flutter analyze` sạch, `dart format` sạch, `flutter test` 6/6.
  - CI run `43053812316`: backend, frontend, android-apk đều success; artifact `fluw-apk` khoảng 22 MB. Chưa thử cài trên điện thoại thật.
