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
- **Không push trực tiếp vào `main`. Không deploy production** khi FLuw chưa cho phép rõ ràng.
- **Quyền merge (FLuw cho phép 11/11/2026):**
  - Agent được tự merge PR **không thêm, sửa, xóa hay đổi tên file nào trong `backend/` và `.github/workflows/`**, khi đủ 3 điều kiện:
    - CI xanh cả 3 job `backend`, `frontend`, `android-apk`;
    - đã có review chéo;
    - các lỗi review đã sửa.
  - Merge bằng merge commit, tiêu đề `Merge PR #N: ...`.
  - PR có đụng `backend/` hoặc `.github/workflows/` thì phải chờ FLuw duyệt.
    - `backend/`: merge là Render deploy production.
    - Workflow CI: CI xanh là điều kiện để Render deploy.
  - Quy tắc này dựa trên việc Render đặt root dir `backend` (đổi file ngoài `backend/` không làm Render deploy). Đổi root dir hoặc build filter của Render thì phải xem lại quy tắc.
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

### Các trang (theo thiết kế Figma, ảnh ở `design/figma/`)
- **5 tab:** Trang Chủ, Tra Cứu, **Quét Món** (nút tròn nổi ở giữa), **Nhật Ký**, Hồ Sơ.
- **Màn mở từ tab:**
  - Chi tiết sản phẩm.
  - Lịch sử & Đã lưu.
  - Thiết lập hồ sơ.
  - Báo cáo tuần/tháng.
  - Nước uống.
  - Cài đặt nhắc uống nước.

---

## 3. Kiến trúc và quy ước

### Frontend `frontend/lib/`
```
app/                      ghép app: FluwApp, router (go_router), AppTab; shell/ (header, thanh 5 tab)
core/                     dùng chung: theme, settings, licenses, widget chung, time (CalendarDate), nutrition, (sau này) network, database, format
features/<tên>/
  data/                   gọi API, đọc/ghi SQLite, chuyển đổi JSON
  domain/                 Dart thuần (không import Flutter): model, công thức, quy tắc. Bắt buộc có unit test
  presentation/           màn hình và widget riêng của tính năng
```
- Feature hiện có: `home`, `search`, `scan`, `note`, `profile`. Màn tab chỉ là phần thân; header và thanh dưới nằm ở `app/shell/`.
- **Shell (UI0):**
  - `AppShell` = `FluwTopBar` + thân màn + `FluwBottomBar`.
  - Header: tiêu đề theo `AppTab.title`, nút Sáng/Tối, avatar mở Hồ Sơ. Chưa có chuông thông báo; thêm ở M6/M8 khi có nhắc nhở.
  - Thanh dưới: 5 tab, nút Quét tròn 56 dp nổi 24 dp.
    - Phần nổi nằm trong chiều cao của thanh để nhận được chạm.
    - Nhãn tab co bằng `Flexible` + `FittedBox`, không giới hạn cỡ chữ.
- **State:** Riverpod 3 (`flutter_riverpod`).
  - `core/settings/`: `themeModeProvider` (Notifier) và `ThemeModeStorage` (shared_preferences, key `theme_mode`).
  - `loadPreferences()` chờ tối đa 2 s; lỗi hoặc quá giờ thì chạy với cài đặt mặc định.
  - Storage được override trong `main()`; test dùng `test/helpers/pump_fluw_app.dart`.
  - Chưa có chỗ chọn lại "Theo máy" sau khi đã bấm đổi; thêm vào cài đặt ở M2.
- **Theme** `core/theme/`:
  - `app_palette` (màu lấy từ thiết kế), `nutrient_colors` (`ThemeExtension` cho kcal, protein, tinh bột, đường, béo, nước).
  - `app_typography` (`AppFonts`), `app_radius`, `app_theme`.
- **Phông** `assets/fonts/`:
  - TTF tĩnh tách từ variable font của repo google/fonts bằng fontTools: Inter 400–700 (opsz 14), Plus Jakarta Sans 600–800. Đã kiểm đủ dấu tiếng Việt.
  - Giấy phép OFL ở `assets/licenses/`, đăng ký bằng `registerFontLicenses()`.
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
  - Ngày sinh và ngày trong Nhật ký dùng `CalendarDate` (năm, tháng, ngày), không dùng `DateTime`, để không lệch ngày khi đổi múi giờ.
  - "Hôm nay" lấy bằng `CalendarDate.fromDateTime(DateTime.now())`.
  - SQLite lưu dạng chuỗi `yyyy-MM-dd`.
- **Khi làm phần data M2:** thêm `==`, `hashCode`, `copyWith` cho `HealthProfile` (Riverpod và test lưu/đọc SQLite cần).
- `core/nutrition/` (dùng chung cho tra cứu, Nhật ký, gợi ý):
  - `Nutrient`: kcal, protein, carb, đường, béo, béo bão hòa, natri (mg).
  - `Nutrients`: thiếu key nghĩa là không có dữ liệu, không phải 0; 0 là dữ liệu thật. Từ chối số âm, NaN, vô cực. Có `==`.
  - `NutritionFacts`: số liệu cho mỗi 100 g hoặc 100 ml kèm `QuantityUnit`, nên lượng ăn luôn cùng đơn vị với số liệu.
  - `NutrientTotals`: tổng các giá trị đã biết kèm số món thiếu dữ liệu. Món nào cũng thiếu thì `knownSum` là `null`; không có món nào thì là 0.
- `features/note/domain/` (M4):
  - `MealSlot` (`night`, `morning`, `afternoon`, `evening`, xếp theo giờ trong ngày). Màn Nhật ký hiện theo thứ tự thiết kế: Sáng, Trưa/Chiều, Tối, Khuya/Đêm, nên thứ tự hiển thị khác thứ tự enum. Tiêu đề mỗi khung luôn in giờ (vd "00:01 - 05:59") để không hiểu nhầm Khuya là sau Tối.
  - `placeInNote`: đổi giờ về giờ địa phương trước khi xếp, bỏ giây; 00:00 thuộc Tối hôm trước.
  - `NoteEntry` (`id`, `facts`, `quantity`, `eatenAt`).
  - `NoteDay` và `groupNoteEntries`: ngày mới nhất đứng đầu; món cùng giờ xếp theo `id` vì `List.sort` không ổn định; danh sách và map đều không sửa được.
  - Khi làm phần data M4: thêm `==` cho `NoteEntry`, sinh `id` lúc tạo món.
- Thư viện đang dùng: `go_router`, `flutter_riverpod`, `shared_preferences`. Dự kiến, **chỉ thêm khi dùng tới**: `drift` (SQLite), `http`, `mobile_scanner`, `image_picker`, `flutter_local_notifications`, `flutter_localizations`.

### Thiết kế (`design/figma/`, 11 ảnh PNG xuất 2x từ Figma)
- Đọc ảnh dài: cắt thành đoạn khoảng 1100 px bằng Pillow (`python3 -I`), không đọc nguyên ảnh.
- Chiều rộng ảnh khác nhau (780–1027 px) vì frame rộng khác nhau. Đo kích thước theo tỉ lệ với khung màn (390 dp), không chia 2 cho mọi ảnh.
- **Bảng màu sáng** (Material 3, lấy mẫu từ ảnh):

  | Vai trò | Màu |
  |---|---|
  | primary | `#006C49` |
  | xanh sáng (vòng tiến độ, thanh) | `#10B981` |
  | primaryContainer | `#6FFBBE` |
  | secondary (protein, nước) | `#006398` |
  | secondaryContainer | `#CCE5FF` |
  | tertiary | `#855300` |
  | đường | `#FEA619` |
  | béo | `#FFB95F` |
  | error | `#BA1A1A` |
  | errorContainer | `#FFF0EF` |
  | surface | `#FAF8FF` |
  | surfaceContainerLow | `#F2F3FF` |
  | surfaceContainerHighest | `#DAE2FD` |
  | onSurface | `#131B2E` |
  | onSurfaceVariant | `#3C4A42` |

- **Nút chính và nút Quét dùng `#006C49`** (FLuw chọn 11/11). Lý do: `#10B981` với chữ trắng chỉ đạt độ tương phản 2,5:1, dưới chuẩn WCAG AA.
- **`#10B981` không dùng làm màu chữ**, vì trên nền sáng cũng chỉ đạt khoảng 2,5:1. Vòng tiến độ và thanh màu này luôn có số đi kèm, để thông tin không chỉ dựa vào màu.
- Thiết kế chỉ có giao diện sáng; giao diện tối sinh từ cùng seed.
- **Phông** (nhìn từ ảnh; FLuw chưa chắc, tạm dùng): tiêu đề Plus Jakarta Sans, nội dung Inter. Đóng gói file phông trong app, không tải lúc chạy.
- **Bỏ hoặc sửa chữ sai sự thật trong thiết kế:**
  - "NutriTrack" → Fluw.
  - Bỏ: "chuẩn y khoa", "HIPAA/GDPR", "24.000+ thành viên", "Hội viên", "Apple Health", "LIVE RADAR 60FPS 98,4%", Nutri-Score "A+" và "/100", chỉ số GI, "độ no", "thời gian chuẩn bị", điểm "92/100", "100% khớp", "an toàn tuyệt đối", khẳng định y khoa về dạ dày.
  - Không ước lượng khối lượng từ ảnh; người dùng chọn khẩu phần.
  - Số sao ẩn đến M7.

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
- Bẫy khi test giao diện:
  - Phông mặc định của `flutter test` có ký tự vuông, nên không bắt được tràn chiều cao ở cỡ chữ lớn. Test cỡ chữ lớn phải gọi `loadAppFonts()` (`test/helpers/load_app_fonts.dart`).
  - `flutter test` tắt bóng đổ (`debugDisableShadows`), nên ảnh chụp trong test có dải đen ở mép thanh dưới. Đây không phải lỗi; muốn xem bóng thật thì đặt `debugDisableShadows = false`.
- Code dính tới giờ (`placeInNote`) phải chạy thêm `TZ=Asia/Ho_Chi_Minh flutter test`. CI chạy UTC nên không bắt được lỗi quên `toLocal()`. Đã đề xuất FLuw thêm `TZ` vào workflow (sửa workflow cần FLuw duyệt).
- Môi trường cloud của agent không có Flutter sẵn: tải SDK `flutter_linux_3.47.9-stable.tar.xz` từ `storage.googleapis.com` vào scratchpad, `chown` thư mục SDK. **Không chạy `git config --global --add safe.directory`.**
- Không có Android SDK trong môi trường agent → không build APK tại chỗ, không kiểm được `build.gradle.kts`. CI build APK ở job `android-apk`.
- Proxy của môi trường agent chỉ cho push vào branch của phiên. Tạo tag, xóa branch khác phải để FLuw làm trên GitHub.
- Render MCP không sửa được cấu hình service (chỉ đọc, đổi biến môi trường, trigger deploy).

---

## 5. Quyết định đã chốt (FLuw duyệt 11/11/2026)

- **Git:** giữ lịch sử, dọn code bằng commit. Không force push. Xóa toàn bộ 22 branch cũ, kể cả 4 branch có commit chưa merge (FLuw tự xóa trên GitHub).
- **Tên:** app "Fluw", trợ lý "Zero". Tab nhật ký tên **"Nhật Ký"** (đổi lại từ "Note" ngày 11/11 cho khớp thiết kế); trong code vẫn là `note`.
- **Giao diện:** theo Figma của FLuw, ảnh ở `design/figma/`. Gói Figma Starter chỉ có vài lượt gọi MCP mỗi tháng, nên không dùng MCP; màn mới thì FLuw xuất PNG 2x.
- **Chức năng thêm từ thiết kế (FLuw duyệt 11/11):**
  - Theo dõi và nhắc uống nước.
  - Báo cáo tuần/tháng và ghi cân nặng.
  - Đã lưu và nhập món thủ công.
  - Sở thích và chế độ ăn.
- **Trợ lý AI chat (màn Báo cáo):** chưa làm ở bản đầu, vì phải gửi dữ liệu sức khỏe lên Gemini.
- **Lệch giữa thiết kế và spec, chốt theo đề xuất của agent:**
  - Tên khung theo thiết kế (Sáng / Trưa-Chiều / Tối / Khuya-Đêm), giờ theo spec. Màn Nhật ký hiện Khuya cuối cùng, nhưng món lúc khuya vẫn thuộc ngày mới.
  - Tách "mức vận động" và "hình thức tập" thành 2 ô.
  - Hỏi ngày sinh đầy đủ (thiết kế chỉ hỏi năm).
  - Giới tính "Khác" thì hỏi thêm tính BMR theo công thức Nam hay Nữ.
  - BMI theo thang châu Á; natri dưới 2.000 mg/ngày (WHO).
- **Dữ liệu sức khỏe lưu trên máy** (SQLite): hồ sơ, Nhật ký, lịch sử tra cứu, đã lưu, món nhập thủ công, sở thích và chế độ ăn, nước uống, cân nặng. Không gửi chiều cao, cân nặng, bệnh lên server.
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
  - Có cảnh báo tự động:
    - Tiểu đường: theo dõi đường.
    - Huyết áp cao: theo dõi natri.
    - Mỡ máu cao: theo dõi béo bão hòa.
    - Dị ứng: theo tag dị ứng của OFF, có mức độ.
  - Chỉ lưu làm ghi chú, không cảnh báo vì không có dữ liệu purin, độ cay, GI: dạ dày, huyết áp thấp, gout, bệnh tự nhập.
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

**Tinh bột, chất béo, đường (theo % năng lượng mục tiêu, FLuw chọn 11/11):**
- Chất béo = 25% kcal ÷ 9.
- Béo bão hòa < 10% kcal ÷ 9; có mỡ máu cao thì < 7%.
- Đường < 10% kcal ÷ 4; bật "giảm ngọt" hoặc có tiểu đường thì < 5%.
  - Theo WHO là đường tự do; dữ liệu OFF/USDA chỉ có đường tổng, nên ghi rõ là đường tổng.
- Tinh bột = (kcal mục tiêu − protein cận dưới × 4 − chất béo × 9) ÷ 4.
  - Ra số âm (hồ sơ cực đoan, vd nặng 300 kg, tập gym, giảm cân) thì không đặt mục tiêu tinh bột, ghi "Chưa tính được"; không kẹp về 0.
- Dưới 18 tuổi không có kcal mục tiêu nên không tính các mục này.

**Nước:** 35 ml × cân nặng (kg) mỗi ngày, người dùng chỉnh được. Không dùng thời tiết.

**BMI** = cân nặng ÷ chiều cao(m)², thang châu Á:
- `BMI < 18,5`: thiếu cân;
- `18,5 ≤ BMI < 23`: bình thường;
- `23 ≤ BMI < 25`: thừa cân;
- `BMI ≥ 25`: béo phì.

Chỉ áp dụng khi `tuổi ≥ 18`.

**Khung giờ trang Nhật ký** (tính theo phút, bỏ giây):
- Sáng 06:00–12:00, Chiều 12:01–18:00, Tối 18:01–24:00, Đêm 00:01–05:59.
- Tên hiển thị theo thiết kế: Sáng, Trưa/Chiều, Tối, Khuya/Đêm; tên trong code giữ nguyên.
- **Đêm thuộc ngày mới** (ngày theo lịch). Riêng 00:00 là "24:00", thuộc khung Tối của ngày hôm trước.
- Ngoài cùng là nhóm theo ngày; mỗi khung và mỗi ngày có tổng calo, protein, đường...
- "Đạm" và "protein" là một chỉ số, hiển thị là "Protein (đạm)".

---

## 7. Đang chờ FLuw

### Câu hỏi
1. **Phông chữ:** FLuw chưa chắc. Đang tạm dùng Plus Jakarta Sans (tiêu đề) và Inter (nội dung). FLuw chọn một đoạn chữ trong Figma, xem tên phông ở bảng Typography rồi báo.
2. **Giới hạn hồ sơ:** chiều cao 100–250 cm, cân nặng 20–300 kg, tuổi tối đa 120. Có cần đổi không?

### Việc FLuw làm trên GitHub / Render
- Xóa 22 branch cũ trên GitHub.
- Tạo keystore, thêm 4 secret Android (hướng dẫn trong README).
- Đặt Health Check Path `/health` cho service `Fluw` trên Render.
- Đăng ký USDA API key, thêm biến `USDA_API_KEY` trên Render (làm trước M1).

---

## 8. Lộ trình

| Mốc | Nội dung | Trạng thái |
|---|---|---|
| M0 | Dọn repo, khung frontend/backend, CI build APK + ký keystore, CLAUDE.md, README | Xong, PR #19 merge 11/11 (`70a58e9`), Render đã deploy |
| UI0 | Hệ thống giao diện theo thiết kế: màu, phông, header, thanh 5 tab có nút Quét nổi, đổi nhãn `AppTab` | Đang review (PR) |
| M1 | Backend: `GET /api/foods/search?q=`, `GET /api/foods/barcode/:code`, `POST /api/foods/recognize`; OFF + USDA + bảng món Việt | Chờ USDA key |
| M2 | Hồ sơ: Thiết lập + Hồ sơ, SQLite, BMI, macro theo %, nước, ghi cân nặng, sở thích và chế độ ăn, dị ứng có mức độ | #20 xong BMR/TDEE/calo/protein; còn BMI, macro %, nước |
| M3 | Tra cứu, Chi tiết, Lịch sử & Đã lưu, nhập món thủ công | Chờ M1 |
| M4 | Nhật ký: lịch tuần, 4 khung, thêm/xóa món, SQLite | Domain xong (#21) |
| M5 | Quét mã vạch + nhận diện ảnh, chọn khẩu phần | Chờ M1 |
| M6 | Trang chủ, gợi ý nên/không nên, đánh giá cuối ngày, nhắc 10h/17h/22h | Chờ M2–M4 |
| M7 | Tài khoản + đánh giá sao (Firebase Auth + Neon) | Làm sau; khi bắt đầu, FLuw tạo project Firebase và database Neon |
| M8 | Nước uống: mục tiêu, thêm nhanh, lịch nhắc, cài đặt | Chờ UI0 |
| M9 | Báo cáo tuần/tháng: calo, macro, đường/natri, cân nặng, nước | Chờ M2, M4, M8 |

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

### 12/11/2026 — UI0: hệ thống giao diện theo thiết kế
- **Merge PR #22** (thiết kế + phạm vi, `dfcacae`).
- **Thêm** (chi tiết ở mục 3):
  - `core/theme/` 4 file mới, `core/settings/` 3 file, `core/licenses/font_licenses.dart`.
  - `app/shell/` 5 file; `assets/fonts/` 7 file, `assets/licenses/` 2 file.
- **Sửa:**
  - `AppTab` theo nhãn thiết kế, thêm `title`.
  - `FluwApp` đọc `themeModeProvider`; `main()` đọc cài đặt, đăng ký giấy phép phông.
  - 5 màn tab bỏ `Scaffold`/`AppBar` riêng.
- **Gỡ lại sau khi kiểm chứng:**
  - Ảnh chụp trong test có dải đen trên thanh dưới; đã thử `ColoredBox` để tô nền.
  - Chụp lại với bóng đổ thật thì thấy dải đen chỉ do test tắt bóng đổ, nên gỡ `ColoredBox` và test đi kèm.
  - Gỡ luôn `extendBody` + `SafeArea` thừa.
- **Test:**
  - `flutter test` 128/128 (thêm 24), chạy ở cả UTC và `TZ=Asia/Ho_Chi_Minh`. `flutter analyze` sạch, `dart format` sạch.
  - Test mới: 5 tab đúng nhãn, header đổi theo tab, nút Quét và avatar, không tràn ở 320×568 với cỡ chữ 200% và 310% (phông thật).
  - Test mới: Sáng/Tối theo máy, bấm đổi và lưu, mở lại dùng lựa chọn đã lưu, giá trị hỏng thì về theo máy.
  - Test mới: màu đúng thiết kế, độ tương phản AA ở cả sáng và tối, phông tiêu đề/nội dung, giấy phép phông.
  - Kiểm 10 đột biến, đều bị bắt:
    - nút Quét hoặc avatar mở sai tab;
    - không lưu lựa chọn; giá trị hỏng không về theo máy; bỏ `themeMode`;
    - nút chính về `#10B981`; tiêu đề sai phông;
    - nhãn tab sai; thiếu giấy phép phông;
    - bỏ `Flexible` ở nhãn tab. Lần đầu lọt, vì phông test có ký tự vuông; thêm `loadAppFonts()` thì bắt được.
  - Đã chụp ảnh app 390×844 bằng test tạm (không commit) để so với thiết kế, cả sáng và tối.
  - APK chưa build tại chỗ; xem job `android-apk`.

### 11/11/2026 — Nhận thiết kế Figma, chốt phạm vi theo thiết kế
- **Merge PR #21** (M4 domain, `b53e986`).
- **Xác minh quy tắc tự merge:** sau khi merge #20 (không đụng `backend/`), Render không tạo deploy mới. Deploy gần nhất vẫn là `dep-dbq9t0tbedkc739l7h80` của #19.
- **Thiết kế:**
  - FLuw gửi zip 11 màn PNG 2x, lưu ở `design/figma/` với tên không dấu.
  - Đã đọc hết các màn, lấy mẫu bảng màu (mục 3).
- **FLuw chốt:**
  - Thêm 4 nhóm chức năng: nước, báo cáo + cân nặng, đã lưu + nhập thủ công, chế độ ăn.
  - 5 tab, tên "Nhật Ký".
  - Macro theo % năng lượng.
  - Chưa làm trợ lý AI chat.
  - Các đề xuất về chỗ lệch giữa thiết kế và spec: không phản đối.
  - Nút chính dùng `#006C49` cho đủ độ tương phản; phông tạm dùng Plus Jakarta Sans + Inter.
- **Sửa theo review độc lập:**
  - Thang BMI hở khoảng (22,95 không thuộc mức nào) → viết bằng `<`/`≤`.
  - Tinh bột có thể âm với hồ sơ cực đoan → dùng cận dưới protein, âm thì "Chưa tính được".
  - `#10B981` không làm màu chữ.
  - Ghi rõ thứ tự khung hiển thị khác enum, tên khung hiển thị, nhãn tab đổi ở UI0.
  - Danh sách dữ liệu lưu trên máy thiếu đã lưu, món nhập tay, sở thích.
  - README còn sơ đồ thư mục cũ; "công thức xong" thành "xong BMR/TDEE/calo/protein".
- **Test:** không có code thay đổi.

### 11/11/2026 — M4 (phần domain): khung giờ Note, gom món theo ngày, tổng dinh dưỡng
- **Merge PR #20** (M2 domain, `cac1f81`), agent tự merge theo quyền ở mục 1: CI xanh, đã review, không đụng `backend/` hay workflow.
- **Thêm:**
  - `frontend/lib/core/nutrition/` (5 file), `CalendarDate.addDays`.
  - `frontend/lib/features/note/domain/` (4 file).
  - Chi tiết ở mục 3.
- **Sửa theo review độc lập (trước khi push):**
  - Giờ dạng UTC bị xếp sai khung: lúc 00:00 giờ Việt Nam bị xếp vào Chiều hôm trước. Đã thêm `toLocal()`.
  - Tổng khi món nào cũng thiếu dữ liệu ra 0 → trả `null`.
  - `unit` không dùng khi tính, nhập 200 ml cho số liệu theo 100 g vẫn được → thêm `NutritionFacts` gói số liệu cùng đơn vị.
  - Map ngoài của `entriesBySlot` sửa được, gây crash → `Map.unmodifiable`.
  - Thêm `id` cho `NoteEntry`, dùng làm khóa phụ khi sắp xếp.
  - `Nutrients` có `==` và `asMap()`.
  - Bổ sung test cho 3 đột biến trước đó lọt qua: 00:00:59, tổng ngày bỏ khung Đêm, từ chối giá trị 0.
- **Test:**
  - `flutter test` 104/104, chạy ở cả UTC và `TZ=Asia/Ho_Chi_Minh`. `flutter analyze` sạch, `dart format` sạch.
  - Kiểm 16 đột biến dưới `TZ=Asia/Ho_Chi_Minh`: lần nào cũng có test fail.

### 11/11/2026 — Merge PR #19 và deploy backend khung mới
- **Merge:** FLuw cho phép, merge commit `70a58e9`. CI trên `main` xanh cả 3 job.
- **Deploy (VERIFIED qua log Render, 16:58 UTC):**
  - Node 22.23.5, chọn theo `engines`.
  - `npm install` báo 0 lỗ hổng.
  - Có log `Server is running on port 5000`; deploy `dep-dbq9t0tbedkc739l7h80` ở trạng thái `live`.
  - API cũ `/api/product/*` đã gỡ khỏi production.
- **Chưa kiểm:** gọi `/health` từ ngoài, vì mạng của môi trường agent chặn `fluw.onrender.com`.
- **Quyền merge mới:** FLuw cho agent tự merge PR không đụng `backend/` (ghi ở mục 1).
  - Theo review chéo, quy tắc được thắt chặt thêm: PR đụng `.github/workflows/` cũng phải chờ FLuw duyệt, vì CI xanh là điều kiện để Render deploy.

### 11/11/2026 — M2 (phần domain, PR #20): công thức BMR, TDEE, mục tiêu calo, protein
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
