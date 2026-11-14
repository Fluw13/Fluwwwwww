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
- Health check path `/health` (FLuw đặt 12/11, VERIFIED qua cấu hình service). Biến `USDA_API_KEY` FLuw đã thêm 12/11.
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
    - `AppBar` của Flutter tự giới hạn cỡ chữ tiêu đề (`_kMaxTitleTextScaleFactor`); giữ nguyên theo chuẩn Material.
  - Thanh dưới: 5 tab, nút Quét tròn 56 dp nổi 24 dp.
    - Phần nổi nằm trong chiều cao của thanh để nhận được chạm; có test chạm vào mép trên của nút.
    - Nhãn tab to theo cỡ chữ hệ thống đến **130% rồi dừng**, giống `NavigationBar` của Material (thanh cao cố định). Trên màn hẹp, nhãn dài co theo chiều ngang bằng `Flexible` + `FittedBox`.
    - Semantics mỗi tab: nút, có hành động chạm (`onTap`), có trạng thái đang chọn. Nút tròn bị loại khỏi semantics vì tab "Quét Món" bên dưới đã đọc tên.
- **State:** Riverpod 3 (`flutter_riverpod`).
  - `core/settings/`: `themeModeProvider` (Notifier) và `ThemeModeStorage` (shared_preferences, key `theme_mode`).
  - `loadPreferences()` chờ tối đa 2 s; mọi lỗi (kể cả `Error`) hoặc quá giờ thì chạy với cài đặt mặc định.
  - Test giả lập kho cài đặt chậm/lỗi bằng `test/helpers/fake_preferences_store.dart` (dev dependency `shared_preferences_platform_interface`).
  - Storage được override trong `main()`; test dùng `test/helpers/pump_fluw_app.dart`.
  - Chưa có chỗ chọn lại "Theo máy" sau khi đã bấm đổi; thêm vào cài đặt ở M2.
- **Theme** `core/theme/`:
  - `app_palette`: màu lấy từ thiết kế, cộng các màu thiết kế không có (`on*Container`, `tertiaryContainer`, lớp nền giữa) lấy theo tông Material 3 tương ứng, để mỗi nhóm màu đồng tông.
  - Bảng sáng sinh từ `fromSeed(primary, fidelity)` rồi ghi đè trọn từng nhóm màu; bảng tối sinh từ seed `#10B981`.
  - `nutrient_colors` (`ThemeExtension` cho kcal, protein, tinh bột, đường, béo, nước).
  - `app_typography` (`AppFonts`), `app_radius`, `app_theme`.
- **Phông** `assets/fonts/`:
  - TTF tĩnh tách từ variable font của repo google/fonts bằng fontTools: Inter 400–700 (opsz 14), Plus Jakarta Sans 600. Đã kiểm đủ dấu tiếng Việt.
  - Giấy phép OFL ở `assets/licenses/`, đăng ký bằng `registerFontLicenses()`.
- Chỉ `app/` được import `features/`. `core/` không import `features/`. Feature không import thẳng feature khác; phần dùng chung đưa vào `core/`.
- Import dạng `package:fluw/...`, xếp theo alphabet (lint `directives_ordering`). `dart format` độ rộng 120 (đặt trong `analysis_options.yaml`), CI chặn nếu sai format.
- Thứ tự tab chỉ khai báo ở `enum AppTab`; router và thanh điều hướng đều đọc từ đó.
- `features/profile/domain/` (M2):
  - `sex`, `activity_level` (hệ số AF), `training_type`, `weight_goal` (suy ra từ cân nặng mong muốn: làm tròn từng cân nặng đến 0,1 kg rồi so).
  - `age` (mốc 14, 18, tối đa 100).
  - `energy` (BMR, TDEE), `calorie_target` (`isValidWeeklyChangeKg` so theo 0,01 kg), `protein_target` (`ProteinGroup` và `ProteinTarget`).
  - `health_profile` (`weeklyChangeKg` để trống được), `profile_validation` (giới hạn và `ProfileIssue`), `daily_targets`.
  - M2a:
    - `health_condition`: chỉ tiểu đường, huyết áp cao, mỡ máu đổi chỉ tiêu hoặc gây cảnh báo; các bệnh khác chỉ là ghi chú.
    - `bmi`: thang châu Á. `displayValue` là BMI **cắt xuống** 0,1 (cộng `1e-9` để 25,0 tính ra 24,999… không rơi xuống 24,9). Xếp loại theo số này nên giữ đúng ngưỡng spec và luôn khớp số hiện; giao diện phải hiện đúng `displayValue`.
    - `nutrient_targets`: béo, béo bão hòa, đường, tinh bột theo % năng lượng; `dailySodiumMaxMg` = 2000.
    - `water_target`: 35 ml/kg.
    - `HealthProfile` thêm `conditions` và `limitsSugar` (giảm ngọt), đều bắt buộc (không mặc định), để lúc đọc SQLite quên cột thì không compile.
  - `calculateDailyTargets` trả một trong `InvalidProfile` / `BelowMinimumAge` / `TeenTargets` / `AdultTargets` (sealed class, UI phải xử lý đủ 4 trường hợp). Hồ sơ lỗi không ném exception, để hồ sơ cũ trong SQLite không làm crash màn hình khi giới hạn đổi.
    - `TeenTargets`: protein, nước.
    - `AdultTargets`: BMR, TDEE, calo, protein, `nutrients`, `bmi`, nước.
  - Giới hạn hồ sơ (FLuw duyệt 12/11):
    - chiều cao 100–250 cm, cân nặng 20–300 kg, tuổi tối đa 100;
    - tốc độ đổi cân lớn hơn 0 và không quá 0,5 kg/tuần, chỉ bắt buộc với người lớn muốn tăng/giảm cân.
- **Ngày tháng:**
  - Ngày sinh và ngày trong Nhật ký dùng `CalendarDate` (năm, tháng, ngày), không dùng `DateTime`, để không lệch ngày khi đổi múi giờ.
  - "Hôm nay" lấy bằng `CalendarDate.fromDateTime(DateTime.now())`.
  - SQLite lưu dạng chuỗi `yyyy-MM-dd`.
- **Giới tính và tên (M2c):** `Sex` có `other`; khi đó người lớn phải chọn `BmrFormula` (Nam/Nữ), thiếu thì `ProfileIssue.bmrFormulaMissing`. Constructor tự bỏ `bmrFormulaForOther` khi giới tính không phải Khác. `displayName` để trống được, không có ảnh.
- **Dị ứng, chế độ ăn, cân nặng (M2d, FLuw chốt 13/11):**
  - `Allergen`: 14 nhóm theo `allergens_tags` của Open Food Facts (`openFoodFactsTag`), mỗi nhóm `AllergySeverity` Nặng/Nhẹ; thêm mới mặc định Nặng. Dị ứng tự gõ (`allergyNote`) chỉ là ghi chú, không cảnh báo.
  - `DietStyle` (5) và `FoodPreference` (3) chỉ để gợi ý món, không đổi chỉ tiêu. "Giảm ngọt" vẫn là `limitsSugar` vì đổi giới hạn đường.
  - Gói trong `DietaryPreferences` (`HealthProfile.dietary`), có `==` theo nội dung.
  - Đọc SQLite: khóa dị ứng lạ → `UnreadableProfile` (không âm thầm tắt cảnh báo); mức lạ → Nặng; chế độ ăn lạ → Bình thường; thói quen lạ bỏ qua.
  - `plannedGoal`: hướng mục tiêu lưu lúc thiết lập. Cân chạm hoặc vượt mục tiêu thì `hasReachedTarget`, `goal` thành giữ cân (calo = TDEE) và màn Hồ Sơ báo "đã đạt" (FLuw chọn 13/11). Dòng cũ thiếu cột thì suy từ cân nặng.
  - `WeightLogRepository`: 1 lần cân/ngày (ghi lại cùng ngày thì thay). Lần cân mới nhất (kể cả cùng ngày) thành cân nặng hồ sơ; ghi bù ngày cũ hơn thì không. Lưu form với cân nặng mới cũng ghi một lần cân hôm nay. `ProfileRepository.clear()` xóa cả lịch sử cân.
  - Tiến độ (`goalProgress`) tính từ lần cân đầu, chỉ khi lần đó nằm đúng phía của hướng mục tiêu hiện tại.
  - `AppearanceCard` trên màn Hồ Sơ cho chọn lại "Theo máy".
  - Widget test: mỗi lần ghi database trong `tester.runAsync` chỉ một thao tác, `pumpAndSettle` giữa các lần; hai lần ghi liền trong một `runAsync` bị khóa chéo với lần đọc lại của app chạy bằng thời gian giả.
- **`HealthProfile` (M2b):**
  - Có `==`, `hashCode`, `copyWith`. `conditions` so bằng `SetEquality`, `hashCode` bằng `Object.hashAllUnordered`, bọc `Set.unmodifiable`.
  - `conditionNote`: ghi chú "bệnh tự nhập", chỉ để ghi chú.
  - `copyWith` nhận hàm cho trường để trống được, để đặt `null` có chủ ý: `copyWith(weeklyChangeKg: () => null)`.
- **SQLite (drift) `core/database/` (M2b):**
  - `AppDatabase` schema v3 (v2 ở M2c: `display_name`, `bmr_formula`; v3 ở M2d: `diet_style`, `allergy_note`, `planned_goal`, bảng `profile_allergies`, `profile_preferences`, `weight_entries`), bảng `profiles` (chỉ 1 dòng, `CHECK (id = 1)`) và `profile_conditions`. `appDatabaseProvider` mở file `fluw` bằng `drift_flutter`.
  - Bảng nằm ở `core/` vì `AppDatabase` phải liệt kê mọi bảng; `core/` vẫn không import `features/`.
  - Code sinh `app_database.g.dart` được commit (CI không chạy build_runner). Sinh lại xem mục 4.
  - Schema mỗi phiên bản lưu ở `frontend/drift_schemas/` (`build.yaml`). Tăng `schemaVersion` thì chạy `dart run drift_dev make-migrations` để có bước migration và test đối chiếu.
  - `sqlite3` 3.x tự tải SQLite lúc build (native-assets hook). **Không thêm trực tiếp `sqlite3_flutter_libs`**; bản `0.6.0+eol` trong lock do `drift_flutter` kéo vào, là gói rỗng.
- **`features/profile/data/` (M2b):**
  - `profile_storage_keys`: khóa lưu cố định cho `Sex`, `ActivityLevel`, `TrainingType`, `HealthCondition`, không dùng `name`/`index`. Có test khóa không bao giờ đổi; chỉ được thêm khóa mới.
  - `profile_mapper`: khóa bệnh lạ thì bỏ qua; trường bắt buộc không đọc được thì trả `null`.
  - `ProfileRepository`: `load` (đọc các bảng trong một transaction), `watch` (`customSelect('SELECT 1', readsFrom: ...)` + `asyncMap(load)`, phát lại khi bảng nào đổi), `save`/`clear` trong transaction. `save` từ chối số không hữu hạn (SQLite lưu NaN thành NULL).
  - Kết quả đọc là `StoredProfile` (sealed): `NoProfile` / `UnreadableProfile` / `LoadedProfile`. UI phải báo người dùng khi hồ sơ hỏng, không âm thầm mở form trống.
  - Provider: `profileRepositoryProvider`, `storedProfileProvider` (StreamProvider).
  - Test: `test/helpers/in_memory_database.dart` (SQLite trong bộ nhớ, `closeStreamsSynchronously`). `pumpFluwApp` tự tạo database theo app (đóng cùng app kể cả khi test fail), lấy qua `appContainer(tester)`; đọc/ghi database trong widget test phải bọc `tester.runAsync`.
- **`features/profile/presentation/` (M2c):**
  - `ProfileScreen` (tab Hồ Sơ) xử lý đủ `NoProfile` / `UnreadableProfile` / `LoadedProfile` / lỗi đọc (chỉ cho "Thử lại", không mở form trống để khỏi ghi đè).
  - `ProfileSetupScreen` ở route `/profile/setup` trên root navigator (che thanh tab); `app_router` truyền `onEditProfile` để feature không import `app/`.
  - `ProfileDraft`: chữ người dùng gõ → `HealthProfile`, lỗi theo từng ô (`ProfileField`). Tốc độ chỉ giữ khi người lớn muốn đổi cân. Có `==` để biết form có thay đổi thật không (hỏi trước khi bỏ).
  - Số nhập nhận `58,5` và `58.5`, tối đa 2 chữ số thập phân (`core/format/decimal_text.dart`); hiển thị theo thiết kế: `58.5`, `1,850`.
  - BMI trên màn Hồ Sơ lấy từ `AdultTargets`, nên hồ sơ không hợp lệ không hiện BMI và không crash.
  - `todayProvider` (`core/time/`) làm mới khi app quay lại trước màn hình; test cố định ngày `appTestToday`.
  - App chạy locale `vi` (`flutter_localizations`); iOS khai báo `CFBundleLocalizations`. `tester.pageBack()` tìm tooltip tiếng Anh nên test bấm `find.byType(BackButton)`.
  - Ô nhập dùng `inputDecorationTheme` (nền `surfaceContainerLow`, bo 16, không viền) như thiết kế.
- **Mạng (M3a) `core/network/`:** `ApiClient` (package `http`) GET JSON, mọi lỗi thành `ApiFailure` sealed: `NetworkFailure` (kể cả lỗi TLS/`IOException`), `TimeoutFailure`, `ServerFailure` (giữ status, code, message của backend), `InvalidResponseFailure`. `apiBaseUrl` mặc định `https://fluw.onrender.com` (đổi bằng `--dart-define=FLUW_API_BASE_URL`, phải https), `apiTimeout` 70 s vì Render free ngủ. Widget test truyền `MockClient` qua `pumpFluwApp(httpClient:)`; không truyền thì mọi lượt gọi là lỗi mạng.
- **`PersonalLimits` (M3a) `core/nutrition/`:** dị ứng (tag OFF + tên người dùng đặt), chỉ tiêu cả ngày (kcal, đường, béo bão hòa, natri; chỉ người lớn có hồ sơ hợp lệ), cờ theo dõi theo bệnh, `profileStatus` (none / loading / unreadable / loaded). `personalLimitsProvider` trong core, override ở `app/app_overrides.dart` (`crossFeatureOverrides()`, dùng chung cho `main()` và `pumpFluwApp`) bằng `app/personal_limits_from_profile.dart`, để feature search không import feature profile. Hồ sơ hỏng → `unreadable`, UI phải báo, không im lặng như không dị ứng.
- **`features/search/` (M3a):**
  - `data/`: `food_item_json` (đọc hợp đồng M1a; món sai hợp đồng thì bỏ riêng; chỉ nhận link https), `food_api` (`PRODUCT_NOT_FOUND` và `INVALID_BARCODE` → null), `recent_searches_storage` (shared_preferences key `recent_searches`, tối đa 8, lỗi đọc/ghi nào cũng bỏ qua — không phải dữ liệu sức khỏe).
  - `domain/`: `FoodItem` (dùng `NutritionFacts` của core), `SearchResponse` (`isPartial` khi một nguồn lỗi), `QuickFilter` (ít đường <5 g, giàu protein >20 g, dưới 200 kcal theo 100 g/ml; thiếu số liệu thì không đạt), `food_assessment` (`AllergenCheck`: chưa biết / không trùng trong danh sách đã ghi / trùng nặng-nhẹ; `PortionShare`).
  - `presentation/`: `SearchController` (chỉ kết quả của lần tìm mới nhất được ghi; từ khóa 2–100 ký tự, dọn dấu cách), `SearchScreen`, `FoodDetailScreen` (route `/search/food` trên root navigator, món qua `extra`; món OFF gọi `/barcode` để lấy dị ứng và tên tiếng Việt; người dùng tự nhập khẩu phần 1–2.000), `PersonalCheckCard`. Calo là mục tiêu ("Vượt mục tiêu calo"), đường/béo bão hòa/natri là giới hạn ("Vượt giới hạn cả ngày"); xét vượt theo % đã làm tròn.
  - Chưa làm: "Thêm vào Nhật ký" (sau M4), "Đã lưu" và nhập món thủ công (M3b).
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
- Thư viện đang dùng: `go_router`, `flutter_riverpod`, `shared_preferences`, `drift` + `drift_flutter`, `collection`, `flutter_localizations`, `http`; dev: `drift_dev`, `build_runner`. Dự kiến, **chỉ thêm khi dùng tới**: `mobile_scanner`, `image_picker`, `flutter_local_notifications`.

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
- **Phông (VERIFIED 12/11 bằng so khớp điểm ảnh với ảnh thiết kế):**
  - **Cách đo:**
    - cắt vùng chữ trong `design/figma/01-trang-chu.png`;
    - vẽ cùng câu chữ bằng phông ứng viên;
    - co về cùng kích thước, đo trung bình độ lệch điểm ảnh (0 là trùng khớp).
    - Script nằm ở scratchpad, không nằm trong repo; chạy lại thì làm theo các bước trên.
  - **Tiêu đề, header, số:** Plus Jakarta Sans **600** thắng ở cả 7 mẫu:

    | Mẫu | 600 | 700 | 800 |
    |---|---|---|---|
    | "Bữa Ăn Hôm Nay" | **0,048** | 0,067 | 0,098 |
    | "Dinh Dưỡng Hôm Nay" | **0,052** | 0,071 | 0,107 |
    | "Đề Xuất Dinh Dưỡng Thông Minh" | **0,057** | 0,079 | 0,117 |
    | "Lối Tắt Nhanh" | **0,052** | 0,089 | 0,119 |
    | header "Trang" | **0,042** | 0,064 | 0,097 |
    | số "1,420" | **0,052** | 0,058 | 0,110 |
    | số "430" | **0,068** | 0,073 | 0,107 |

    So với phông khác trên mẫu "Bữa Ăn Hôm Nay": Inter 700 lệch 0,110, Manrope 0,129, Be Vietnam Pro 0,136.
  - **Nội dung:** Inter, lệch 0,116; Manrope 0,130; các phông còn lại từ 0,153. Mới so 1 mẫu, nên chắc chắn ở mức vừa.
  - Đã so với 10 phông ứng viên: Be Vietnam Pro, Manrope, Lexend, DM Sans, Outfit, Work Sans, Public Sans, Nunito Sans...
  - Đóng gói file phông trong app, không tải lúc chạy.
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
- Lỗi luôn trả `{ "error": { "code": "...", "message": "..." } }`, không lộ stack trace. `HttpError` (status, code) cho lỗi phía client; `errorHandler` giữ status 4xx của body parser (code `BAD_REQUEST`), mọi lỗi khác (kể cả có `status` 5xx) thành 500 và ghi log.
- **API tra cứu (M1a):**
  - `GET /api/foods/search?q=` (2–100 ký tự, `q` lặp thì 400): gộp Open Food Facts (`search.openfoodfacts.org`, `langs=vi,en`) và USDA (Foundation + SR Legacy), mỗi nguồn 10 món, OFF trước. Trả `{ query, items, sources: { openFoodFacts, usda } }`, trạng thái `ok` / `unavailable` / `not_configured`. Một nguồn lỗi vẫn trả nguồn còn lại; mọi nguồn lỗi thì 503 `SOURCES_UNAVAILABLE`.
  - `GET /api/foods/barcode/:code`: OFF API v2. Kiểm chữ số kiểm tra GTIN (8/12/13/14 số) trước khi gọi; sai thì 400 `INVALID_BARCODE`, không có thì 404 `PRODUCT_NOT_FOUND`.
  - Món (`FoodItem`): `{ id ("off:<mã>" | "usda:<fdcId>"), source, name, brand, barcode, imageUrl, servingSize, basis: { amount: 100, unit: "g" | "ml" }, nutrients: { energyKcal, proteinG, carbohydratesG, sugarsG, fatG, saturatedFatG, sodiumMg }, allergenTags, attribution: { source, license, imageLicense, url } }`.
    - `null` = không có dữ liệu, 0 là thật. Số vô lý (trên 100 g/100 g, trên 900 kcal) thành `null`.
    - `allergenTags`: `null` = chưa biết (USDA, hoặc kết quả tìm kiếm OFF vì search API không trả trường này); `[]` chỉ là chưa ai ghi, **không** có nghĩa an toàn. App phải gọi `/barcode` để lấy dị ứng trước khi cảnh báo.
    - Search API của OFF cũng không trả `product_name_vi`, nên tên trong kết quả tìm kiếm có thể không phải tiếng Việt.
    - OFF: đơn vị theo `nutrition_data_per` (`100ml` → ml), rồi mới theo số lượng; natri g × 1000; thiếu kcal thì đổi từ kJ ÷ 4,184. USDA: năng lượng 1008 → 2048 → 2047, đường 2000 → 1063.
    - App (M3) phải đổi `"g"`/`"ml"` sang `QuantityUnit` và từ chối giá trị lạ.
  - Mỗi nguồn hẹn giờ 8 s (`lib/fetchJson`, lỗi nào cũng thành `UpstreamError`); cache trong bộ nhớ (`lib/ttlCache`): tìm kiếm 1 giờ (chỉ khi không nguồn nào lỗi), mã vạch 24 giờ, không có sản phẩm 1 giờ; tìm kiếm trùng đang chạy dùng chung một lượt gọi.
  - Rate limit `/api/foods/*` 30 lượt/phút mỗi IP (`express-rate-limit`), `trust proxy` 1 vì Render đứng sau một proxy.
  - Key USDA gửi bằng header `X-Api-Key`, không nằm trong URL. User-Agent `FluwApp/0.1` (không ghi thông tin cá nhân của FLuw).
  - `createApp(services)` nhận service để test; `src/createServices.js` lắp nguồn thật, `server.js` gọi một lần.
  - Chạy thử ở môi trường agent: Node cần `NODE_USE_ENV_PROXY=1 NODE_EXTRA_CA_CERTS=/root/.ccr/ca-bundle.crt` mới đi qua proxy (Render không cần).
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

# Sau khi sửa bảng drift: sinh lại code rồi format (bộ sinh in độ rộng 80, repo dùng 120; quên format thì CI fail)
dart run build_runner build && dart format lib test
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

**BMI** = cân nặng ÷ chiều cao(m)², hiển thị cắt xuống 0,1 (vd 22,96 hiện 22,9), thang châu Á:
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
- Không còn câu hỏi mở.

- Môi trường cloud của agent: environment "Fluwwwwww" (personal) mở thêm `world.openfoodfacts.org`, `search.openfoodfacts.org`, `api.nal.usda.gov` (FLuw duyệt 13/11).

### Việc FLuw làm trên GitHub / Render
- Xóa 22 branch cũ trên GitHub.
- Key USDA lưu cho môi trường agent (form bảo mật, 13/11) bị USDA báo `API_KEY_INVALID`. FLuw kiểm lại key, và kiểm `USDA_API_KEY` trên Render có cùng key đúng không.
- Đã xong 12/11: keystore + 4 secret Android, Health Check `/health`, `USDA_API_KEY` trên Render.

---

## 8. Lộ trình

| Mốc | Nội dung | Trạng thái |
|---|---|---|
| M0 | Dọn repo, khung frontend/backend, CI build APK + ký keystore, CLAUDE.md, README | Xong, PR #19 merge 11/11 (`70a58e9`), Render đã deploy |
| UI0 | Hệ thống giao diện theo thiết kế: màu, phông, header, thanh 5 tab có nút Quét nổi, đổi nhãn `AppTab` | Xong, PR #23 (`250c531`) |
| M1 | Backend: `GET /api/foods/search?q=`, `GET /api/foods/barcode/:code`, `POST /api/foods/recognize`; OFF + USDA + bảng món Việt | M1a xong (PR #29, `0a29380`, Render live 14/11); M1b 30 món Việt chờ key USDA chạy được; M1c Gemini (sau, FLuw kiểm key trước) |
| M2 | Hồ sơ: Thiết lập + Hồ sơ, SQLite, BMI, macro theo %, nước, ghi cân nặng, sở thích và chế độ ăn, dị ứng có mức độ | Xong: công thức (M2a), SQLite (M2b), màn Hồ Sơ + Thiết lập (M2c), dị ứng, chế độ ăn, sở thích, ghi cân nặng, "Theo máy" (M2d) |
| M3 | Tra cứu, Chi tiết, Lịch sử & Đã lưu, nhập món thủ công | M3a (Tra cứu + Chi tiết) xong; M3b (Đã lưu, Lịch sử món đã xem, nhập thủ công) sau; nút "Thêm vào Nhật ký" sau M4 |
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
- **Chữ ký APK:** từ 12/11 CI ký bằng keystore của FLuw (run `43198464929`, không còn cảnh báo thiếu secret). Bản cài trước đó ký bằng debug key nên phải gỡ một lần.
- **M1, khi thêm `express.json()`:** `errorHandler` phải giữ `error.status` 4xx (JSON hỏng → 400, body quá lớn → 413) thay vì trả 500.
- **Express 5** gọi callback của `app.listen` cả khi lỗi; `server.js` đã bỏ qua nhánh lỗi để handler `'error'` xử lý.
- **Gemini:** gói miễn phí giới hạn lượt/ngày, và Google có thể dùng nội dung gửi lên để cải thiện sản phẩm. Model và biến môi trường Gemini trên Render chưa kiểm tra lại.

---

## 10. Nhật ký công việc

Mục mới nhất ở trên. Mỗi mục ghi: ngày, PR, đã sửa gì ở file nào, vì sao, test đã chạy.

### 14/11/2026 — M3a: màn Tra Cứu và Chi tiết sản phẩm
- **Merge PR #29** (M1a, `0a29380`), FLuw duyệt. **Deploy (VERIFIED qua log Render):** `dep-dbs17uff3r2c73dscfm0` live 07:56 UTC, Node 22.23.5, `npm install` 0 lỗ hổng, log `Server is running on port 5000`, không lỗi. Chưa gọi thử `/api/foods/*` từ ngoài (mạng agent chặn `fluw.onrender.com`).
- **FLuw chốt:** M3a (tra cứu + chi tiết) trước; Đã lưu, nhập thủ công ở M3b; "Thêm vào Nhật ký" sau M4.
- **Thêm:** `core/network/` (4 file), `core/nutrition/personal_limits*`, `app/app_overrides.dart`, `app/personal_limits_from_profile.dart`, `features/search/` data (4), domain (7), presentation (12); route `/search/food`; package `http`. Chi tiết ở mục 3.
- **Sửa theo review độc lập (trước khi push):**
  - **Cao:** lỗi TLS (wifi có trang đăng nhập, proxy) không được bắt → Tra Cứu quay chờ mãi → bắt `IOException`.
  - **Cao:** hồ sơ hỏng làm cảnh báo dị ứng tắt im lặng → `ProfileStatus.unreadable`, card báo rõ.
  - Dòng phần trăm tràn ở cỡ chữ 200% → `Wrap`; test cỡ chữ lớn có hồ sơ người lớn.
  - Mã OFF sai GTIN làm "Thử lại" hỏng vĩnh viễn → `INVALID_BARCODE` coi như không có.
  - Calo là mục tiêu, không phải giới hạn; "100%" kèm "vượt" → xét theo % làm tròn.
  - Dưới 18 tuổi bị mời thiết lập lại hồ sơ; storage chỉ bắt `Exception`, giá trị sai kiểu làm crash; từ khóa >100 ký tự vẫn gọi máy chủ; chờ dị ứng không có chữ giải thích; hướng dẫn backend local dùng http (bị chặn); ảnh giải mã nguyên cỡ.
  - Thêm test cho các đột biến lọt: race tìm kiếm, lỗi tải sản phẩm + thử lại, vượt giới hạn, natri theo dõi, trạng thái đang tải dị ứng.
- **Test:**
  - `flutter test` 301/301 (từ 252), cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze`, `dart format` sạch.
  - Fixture JSON theo đúng hợp đồng backend, số liệu lấy từ fixture OFF thật của M1a.
  - Kiểm 10 đột biến cho phần sửa review, đều bị bắt.
  - Đã chụp ảnh 390 dp màn Tra Cứu và Chi tiết (test tạm, không commit).
  - Chưa kiểm: gọi backend production từ app thật (mạng agent chặn), APK (job `android-apk`).

### 13/11/2026 — M1a: API tra cứu thực phẩm và mã vạch (backend)
- **Merge PR #28** (M2d, `9c8b644`).
- **Môi trường:** tạo environment "Fluwwwwww" (mở OFF và USDA), FLuw duyệt. Key USDA nhập qua form báo không hợp lệ; tạm test USDA bằng mẫu dựng theo tài liệu, review kiểm thêm bằng `DEMO_KEY`.
- **Thêm** ở `backend/src/`: `config`, `createServices`, `errors/` (HttpError, UpstreamError), `lib/` (fetchJson, ttlCache, gtin), `models/nutrients`, `providers/openFoodFacts/` và `providers/usda/` (client + mapper), `services/` (foodSearchService, barcodeService), `controllers/foodController`, `routes/foodRoutes`, `middlewares/rateLimiter`. `app.js` thành `createApp(services)`; `server.js` lắp service thật. Thêm `express-rate-limit`. Chi tiết ở mục 3.
- **Sửa theo review độc lập (trước khi push):**
  - **Cao:** tra mã vạch đồ uống (`nutrition_data_per: 100ml`, vd Coca-Cola) ra toàn `null` → luôn đọc `_100g`, đơn vị theo `nutrition_data_per`; thêm fixture thật Coca-Cola.
  - Món Foundation của USDA thiếu đường (id 1063) → đọc 2000 rồi 1063; năng lượng ưu tiên Atwater riêng 2048.
  - Không có rate limit, mã vạch không kiểm chữ số kiểm tra → `express-rate-limit` + `trust proxy`, kiểm GTIN.
  - Thiếu test lắp service (key USDA, số kết quả, TTL không có sản phẩm), test 5xx của errorHandler.
  - Thêm: chặn số vô lý, đọc dự phòng `energy_100g`, giấy phép ảnh CC BY-SA, hủy body khi lỗi, gộp tìm kiếm trùng đang chạy.
  - User-Agent: review đề xuất thêm URL repo làm thông tin liên hệ; chưa thêm vì đó là thông tin của FLuw, chờ FLuw quyết.
- **Test:**
  - `npm test` 55/55 (từ 4). Fixture OFF là dữ liệu thật (sữa chua Vinamilk, Coca-Cola, tìm "sữa chua").
  - Kiểm 9 đột biến cho phần sửa review, đều bị bắt.
  - Chạy thật `node server.js` gọi OFF: tìm "sữa chua", "phở"; mã vạch Vinamilk, Coca-Cola (100 ml, 42,25 kcal); mã sai chữ số kiểm tra trả 400.
  - Chưa kiểm: USDA bằng key thật (key báo không hợp lệ); deploy Render (chờ FLuw duyệt merge).

### 13/11/2026 — M2d: dị ứng, chế độ ăn, sở thích, ghi cân nặng, "Theo máy"
- **Merge PR #27** (M2c, `fd59787`).
- **FLuw chốt:** M2d trước, M1 chia 3 PR; dị ứng 14 nhóm + 2 mức; 30 món Việt do Zero viết; Gemini làm sau. Khi cân đạt mục tiêu: coi như giữ cân và báo.
- **Thêm:** domain `allergen`, `diet_style`, `food_preference`, `dietary_preferences`, `weight_entry`, `goal_progress`; data `dietary_mapper`, `weight_log_repository`; giao diện `allergies_section`, `diet_section`, `dietary_summary_card`, `weight_log_card`, `record_weight_dialog`, `appearance_card`; schema v3 + migration. Chi tiết ở mục 3.
- **Sửa theo review độc lập (trước khi push):**
  - Ghi cân vượt mục tiêu làm app tự chuyển sang tăng cân (calo TDEE + 550) → `plannedGoal`, đạt thì giữ cân và báo.
  - Tiến độ báo 100% khi mục tiêu đổi hướng → chỉ tính khi lần cân đầu nằm đúng phía.
  - Hộp thoại ghi cân và hộp thoại "Bỏ thay đổi?" tràn khi bàn phím mở / cỡ chữ lớn → `scrollable: true`.
  - Lịch sử cân lệch cân nặng hồ sơ khi sửa ở form; `clear()` để lại lịch sử → form ghi lần cân hôm nay, `clear()` xóa lịch sử.
  - Lỗi đọc lịch sử hiện thành "chưa ghi lần nào" → báo lỗi riêng.
  - Test thiếu: lưu lại sau khi bỏ dị ứng/thói quen, `clear()` xóa bảng con, `watch` khi chỉ bảng thói quen đổi, ghi lại cùng ngày đổi cân nặng hồ sơ.
- **Test:**
  - `flutter test` 252/252, cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze`, `dart format` sạch.
  - Migration v2→v3 có test đối chiếu dữ liệu. Luồng: thêm/đổi mức dị ứng, chế độ ăn, thói quen; ghi cân (lịch sử, cân nặng hồ sơ, tiến độ 30%); ô cân ngoài giới hạn; "Theo máy"; đạt mục tiêu; đổi hướng; 320×568 cỡ chữ 200%/310% kể cả hộp thoại khi bàn phím mở.
  - Kiểm 6 đột biến cho phần sửa review, đều bị bắt.
  - Chưa kiểm: APK (job `android-apk`), điện thoại thật.

### 12/11/2026 — M2c: màn Hồ Sơ và Thiết lập hồ sơ
- **Merge PR #26** (M2b, `b0188f0`).
- **FLuw chốt:** tách M2c (phần 1–3 + màn Hồ Sơ) và M2d (dị ứng, chế độ ăn, sở thích); tên tùy chọn, không ảnh; giới tính Khác làm ngay.
- **Domain/data:** `BmrFormula`, `Sex.other`, `displayName`, `goal_duration` (số tuần làm tròn lên theo 0,1 kg), schema v2 + migration `stepByStep` + test đối chiếu v1→v2 có dữ liệu.
- **Giao diện:** 13 file ở `features/profile/presentation/`, `core/widgets/section_card`, `core/format/decimal_text`, `core/time/today_provider`, route `/profile/setup`, locale `vi`, `inputDecorationTheme`. Chi tiết ở mục 3.
- **Chữ trên màn:** bỏ "chuẩn y khoa", GI, HIPAA, NutriTrack, cộng đồng 24.000+; bệnh chỉ ghi chú thì nói rõ chưa có dữ liệu để cảnh báo.
- **Sửa theo review độc lập (trước khi push):**
  - Hồ sơ lưu tốc độ 0 làm màn Hồ Sơ crash (`estimateWeeksToTarget` ném lỗi) → chỉ tính số tuần khi tốc độ hợp lệ; BMI lấy từ `AdultTargets`.
  - Chỉ chạm vào ô (đổi con trỏ) cũng bị hỏi "Bỏ thay đổi?" → so bản nháp hiện tại với bản ban đầu (`ProfileDraft ==`).
  - Đang lưu mà bấm quay lại thì mở hộp thoại → chặn quay lại khi đang lưu.
  - Lỗi đọc dữ liệu mở form trống có thể ghi đè hồ sơ → chỉ "Thử lại".
  - `todayProvider` không đổi qua nửa đêm/sinh nhật → làm mới khi app quay lại.
  - Bộ chọn ngày cho chọn người 101 tuổi, ngày cũ ngoài khoảng gây assert → mốc đúng 100 tuổi, kẹp `initialDate`.
  - Mô tả huyết áp cao hứa theo dõi natri khi chưa có → ghi "đang xây dựng"; tiểu đường/mỡ máu ghi "tính từ 18 tuổi".
  - Mốc protein "đủ" làm tròn đến gram, lệch domain (0,1 g) → hiện 1 chữ số thập phân.
  - Đổi từ Khác sang Nam/Nữ còn giữ công thức BMR → constructor tự bỏ.
  - Ô ngày sinh thiếu semantics nút; dòng lỗi không được đọc → `Semantics(button)`, `liveRegion`.
  - iOS thiếu `CFBundleLocalizations` cho `vi` → đã thêm.
- **Test:**
  - `flutter test` 221/221, cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze` sạch, `dart format` sạch.
  - Test luồng: chưa có hồ sơ, hồ sơ đã lưu (số liệu tính tay: 2,083 kcal, protein 126–168 g, BMI 22.8), dưới 18 tuổi, hồ sơ hỏng, tốc độ 0, tạo mới (lịch tiếng Việt, giới tính Khác, công thức Nữ), sửa và lưu, lưu khi thiếu (7 lỗi), hỏi khi bỏ thay đổi, không hỏi khi chỉ chạm ô; 320×568 cỡ chữ 200% và 310% không tràn.
  - Kiểm 4 đột biến cho phần sửa review, đều bị bắt.
  - Đã chụp ảnh 390 dp màn Hồ Sơ và Thiết lập (test tạm, không commit) để so với thiết kế.
  - Chưa kiểm được: APK build (xem job `android-apk`), chạy trên điện thoại thật.

### 12/11/2026 — M2b: lưu hồ sơ sức khỏe trên máy (SQLite/drift)
- **Xác minh việc FLuw làm:**
  - Keystore: CI run `43198464929` bước `Prepare release keystore` không cảnh báo, APK release build xong.
  - Health Check: `healthCheckPath: /health` trong cấu hình service, deploy `dep-dbqp953rjlhs73a2me10` `live`.
  - `USDA_API_KEY`: theo lời FLuw; service có 2 deploy `service_updated` lúc 10:26–10:27 UTC. Chưa tự xem tên biến.
- **Thêm:** `core/database/` (4 file + `.g.dart`), `features/profile/data/` (5 file), `build.yaml`, `drift_schemas/fluw/drift_schema_v1.json`, `CalendarDate.tryParse`. Chi tiết ở mục 3.
- **Sửa:** `HealthProfile` thêm `conditionNote`, `==`, `hashCode`, `copyWith`, bọc `Set.unmodifiable` (constructor hết `const`).
- **Sửa theo review độc lập (trước khi push):**
  - Lưu NaN thì `SqliteException` (cột NOT NULL) hoặc âm thầm thành `null` → `save` từ chối số không hữu hạn.
  - `copyWith` dùng sentinel `Object?` nên truyền `int` crash lúc chạy → đổi sang tham số hàm có kiểu.
  - Hồ sơ hỏng lẫn với chưa có hồ sơ → `StoredProfile` sealed.
  - Test widget sau này sẽ mở database thật → `pumpFluwApp` override bằng database trong bộ nhớ.
  - Chưa export schema → `build.yaml` + `make-migrations`.
  - Sinh lại `.g.dart` ra độ rộng 80 làm CI format fail → ghi lệnh ở mục 4.
  - Test watch bỏ `distinct()` để bắt cả lần phát thừa; thêm test số nhiều chữ số thập phân, ghi chú rỗng.
- **Test:**
  - `flutter test` 185/185, cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze` sạch, `dart format` sạch. Test repository chạy 5 lần liền đều xanh.
  - Kiểm 12 đột biến, đều bị bắt: không xóa bệnh cũ khi lưu, `clear` không xóa bệnh, bỏ `conditionNote`, `tryParse` thiếu `^`, `hashAll` có thứ tự, bỏ `CHECK`, bỏ `Set.unmodifiable`, `==` bỏ `limitsSugar`, bỏ chặn NaN, bỏ chặn NaN ở `weeklyChangeKg`, hồ sơ hỏng thành `NoProfile`, `copyWith` bỏ qua giá trị mới.
  - Chưa kiểm được: chưa có test bắt lỗi bỏ transaction trong `clear`. APK có `sqlite3` chưa build tại chỗ, xem job `android-apk`.

### 12/11/2026 — Xác minh phông theo thiết kế, chỉnh độ đậm tiêu đề
- **Merge PR #24** (M2a, `6539885`).
- **FLuw nhờ làm 4 việc:**
  - Làm được: xác định phông. Figma MCP vẫn hết lượt, nên so khớp điểm ảnh 8 mẫu chữ trong `design/figma/` (7 mẫu tiêu đề và số, 1 mẫu nội dung) với 10 phông ứng viên. Kết quả ở mục 3.
  - Không làm được, đã hướng dẫn FLuw tự làm:
    - tạo keystore và GitHub Secrets (không có công cụ; đây là khóa ký app của FLuw);
    - `USDA_API_KEY` (cần email của FLuw; key Render do FLuw tự nhập);
    - Health Check Path (Render MCP không sửa được cấu hình service);
    - xóa 22 branch (proxy và GitHub MCP không cho).
- **Sửa:**
  - `app_typography.dart`: mọi kiểu chữ tiêu đề và số dùng Plus Jakarta Sans 600 (trước là 700/800).
  - Gỡ `PlusJakartaSans-Bold.ttf` và `PlusJakartaSans-ExtraBold.ttf` vì không còn dùng; `load_app_fonts.dart` theo đó.
- **Sửa theo review độc lập:**
  - Bản đầu ghi "số lớn 700" và "lệch 0,04–0,06" mà script chỉ chạy lại được 2 mẫu. Mẫu số "430" lúc đó cũng chưa so với 600.
  - Đo lại đủ 7 mẫu với cả 600/700/800 thì 600 thắng ở mọi mẫu, kể cả số → đổi số lớn sang 600 và ghi bảng số liệu ở mục 3.
- **Test:** `flutter test` 164/164 (thêm 1 test độ đậm), `flutter analyze` sạch.

### 12/11/2026 — M2a: BMI, chỉ tiêu dinh dưỡng theo % năng lượng, nước, tuổi tối đa 100
- **Merge PR #23** (UI0, `250c531`).
- **FLuw chốt:** tuổi tối đa 100; chiều cao 100–250 cm, cân nặng 20–300 kg giữ nguyên.
- **Thêm** ở `frontend/lib/features/profile/domain/`: `health_condition`, `bmi`, `nutrient_targets`, `water_target` (chi tiết ở mục 3).
- **Sửa:**
  - `age.dart`: tối đa 100.
  - `health_profile.dart`: thêm `conditions`, `limitsSugar` (mặc định rỗng / tắt).
  - `daily_targets.dart`: trả thêm BMI, chỉ tiêu dinh dưỡng, nước.
- **Quyết định kỹ thuật:**
  - BMI xếp loại theo số đã làm tròn 0,1 để nhãn luôn khớp số hiện trên màn.
  - Tinh bột âm thì `null` ("Chưa tính được"); đúng 0 thì vẫn là 0.
- **Test:**
  - Trước review: `flutter test` 161/161 (thêm 14), chạy ở cả UTC và `TZ=Asia/Ho_Chi_Minh`. `flutter analyze` sạch, `dart format` sạch.
  - Số mong đợi tính tay, vd 2000 kcal, protein 112 g → béo 500/9 g, tinh bột 263 g.
  - Kiểm 15 đột biến:
    - mốc BMI, xếp loại theo số chưa làm tròn;
    - tỉ lệ béo, mỡ máu, tiểu đường, giảm ngọt;
    - tinh bột âm/0; nước; cận protein; tuổi 101.
  - Lần đầu lọt đột biến "không truyền giảm ngọt"; thêm test thì bắt được cả 15.
- **Sửa theo review độc lập (trước khi push):**
  - BMI xếp loại theo số làm tròn làm ngưỡng lùi 0,05 so với spec (22,96 thành thừa cân) → đổi sang cắt xuống 0,1. Ca thật 64 kg / 160 cm: máy tính ra 24,999… nên cần `+1e-9`.
  - Thiếu test cho calo bị nâng lên BMR → thêm test (nữ 50 kg, 160 cm, ít vận động: 1239 kcal, béo 34,42 g, tinh bột 142,31 g).
  - `conditions`/`limitsSugar` có mặc định → bắt buộc.
  - `stomachUlcer` hẹp hơn spec ("dạ dày") → đổi thành `stomach` trước khi có dữ liệu lưu.
  - `Set` không so sánh theo nội dung và khóa lưu bệnh lý → ghi vào việc của M2b.
  - Tổng: `flutter test` 163/163 (thêm 16). Kiểm thêm 3 đột biến cho phần sửa; đột biến "bỏ `1e-9`" lần đầu lọt, đổi sang ca 64 kg / 160 cm thì bắt được.

### 12/11/2026 — UI0: hệ thống giao diện theo thiết kế
- **Merge PR #22** (thiết kế + phạm vi, `dfcacae`).
- **Thêm** (chi tiết ở mục 3):
  - `core/theme/` 4 file mới, `core/settings/` 3 file, `core/licenses/font_licenses.dart`.
  - `app/shell/` 5 file; `assets/fonts/` 7 file, `assets/licenses/` 2 file.
- **Sửa:**
  - `AppTab` theo nhãn thiết kế, thêm `title`.
  - `FluwApp` đọc `themeModeProvider`; `main()` đọc cài đặt, đăng ký giấy phép phông.
  - 5 màn tab bỏ `Scaffold`/`AppBar` riêng.
- **Sửa theo review độc lập (trước khi push):**
  - Semantics tab bỏ mất hành động chạm (`excludeSemantics`), nên Switch Access và Voice Access không bấm được tab → thêm `onTap` vào `Semantics`.
  - `FittedBox` co nhãn về gần 100% nên nhãn không hề to lên; CLAUDE.md ghi "không giới hạn" là sai.
    - Khôi phục giới hạn 130% như `NavigationBar`.
    - Có test đo nhãn to đúng 120% / 130% / 130% ở cỡ chữ 120% / 200% / 310%.
  - Bảng màu sáng chỉ ghi đè một phần, các nhóm màu lệch tông (tertiaryContainer xanh dương, lớp nền giữa ngả xanh lá) → ghi đè trọn nhóm.
  - `loadPreferences` chỉ bắt `Exception`; plugin ném `Error` thì app kẹt ở màn chờ → bắt `Object`.
  - 7 đột biến lọt test → thêm test:
    - semantics tab; nút Quét nổi và chạm mép trên;
    - giá trị hỏng khi máy để Tối;
    - `loadPreferences` (đọc được, Exception, Error, quá giờ); ghi lỗi không ném;
    - tương phản chữ trên các container; thứ tự và tông các lớp nền.
- **Gỡ lại sau khi kiểm chứng:**
  - Ảnh chụp trong test có dải đen trên thanh dưới; đã thử `ColoredBox` để tô nền.
  - Chụp lại với bóng đổ thật thì thấy dải đen chỉ do test tắt bóng đổ, nên gỡ `ColoredBox` và test đi kèm.
  - Gỡ luôn `extendBody` + `SafeArea` thừa.
- **Test:**
  - `flutter test` 147/147 (thêm 43), chạy ở cả UTC và `TZ=Asia/Ho_Chi_Minh`. `flutter analyze` sạch, `dart format` sạch.
  - Test mới: 5 tab đúng nhãn, header đổi theo tab, nút Quét và avatar, không tràn ở 320×568 với cỡ chữ 200% và 310% (phông thật).
  - Test mới: Sáng/Tối theo máy, bấm đổi và lưu, mở lại dùng lựa chọn đã lưu, giá trị hỏng thì về theo máy.
  - Test mới: màu đúng thiết kế, độ tương phản AA ở cả sáng và tối, phông tiêu đề/nội dung, giấy phép phông.
  - Kiểm 10 đột biến, đều bị bắt:
    - nút Quét hoặc avatar mở sai tab;
    - không lưu lựa chọn; giá trị hỏng không về theo máy; bỏ `themeMode`;
    - nút chính về `#10B981`; tiêu đề sai phông;
    - nhãn tab sai; thiếu giấy phép phông;
    - bỏ `Flexible` ở nhãn tab. Lần đầu lọt, vì phông test có ký tự vuông; thêm `loadAppFonts()` thì bắt được.
  - Sau review: kiểm thêm 12 đột biến (gồm 7 đột biến review chỉ ra), đều bị bắt.
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
