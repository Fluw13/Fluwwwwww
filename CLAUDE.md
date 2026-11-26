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
  - Merge qua GitHub API ghi email chính của tài khoản GitHub của FLuw làm tác giả merge commit. Chỉ merge khi FLuw đã bật "Keep my email addresses private" (Settings → Emails); chưa bật thì chờ (FLuw đồng ý 26/11).
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

## 2. Dự án (cập nhật 21/11/2026)

**Fluw**: ứng dụng tra cứu dinh dưỡng (calo, protein, đường, chất béo...), ghi nhật ký ăn uống và đánh giá nhu cầu theo hồ sơ sức khỏe của người dùng. Trợ lý AI tên **Zero**.

**Chỉ dành cho người lớn (từ 18 tuổi) ở Việt Nam** (FLuw chốt 18/11/2026). Chính sách quyền riêng tư: `PRIVACY.md` ở gốc repo.

Đổi hướng ngày 11/11/2026. Bản cũ (tra cứu thực phẩm và chấm điểm FNS) đã gỡ khỏi cây code; vẫn xem được ở commit `df79e6b`.

| Thành phần | Thực tế |
|---|---|
| Repository | `https://github.com/Fluw13/Fluwwwwww`, branch chính `main` |
| Frontend | Flutter 3.47.9 / Dart 3.13.7, thư mục `frontend/`, chỉ Android và iOS, id `com.fluw.app` |
| Backend | Node.js ≥ 22.9 (22.x) + Express 5, thư mục `backend/`, entry `server.js` |
| Hosting backend | Render, workspace "My Workspace", service `Fluw` (`srv-dbed4jlg1s2s73f7jrdg`), `https://fluw.onrender.com` |
| APK | CI build, tải ở GitHub Actions → artifact `fluw-apk`; chỉ lượt chạy trên `main` lưu APK (giữ 1 ngày), ký bằng keystore thật |

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
- **Màn ngoài thiết kế:** Cài đặt nhắc ghi bữa ăn (`/reminders`), Quyền riêng tư và điều khoản (`/privacy`).

---

## 3. Kiến trúc và quy ước

### Frontend `frontend/lib/`
```
app/                      ghép app: FluwApp, router (go_router), AppTab, nối giữa các feature, xóa toàn bộ dữ liệu; shell/ (header, thanh 5 tab)
core/                     dùng chung: theme, settings, licenses, widget chung, time, nutrition, diary, search, network, database, format, privacy
features/<tên>/
  data/                   gọi API, đọc/ghi SQLite, chuyển đổi JSON
  domain/                 Dart thuần (không import Flutter): model, công thức, quy tắc. Bắt buộc có unit test
  presentation/           màn hình và widget riêng của tính năng
```
- Feature hiện có: `home`, `search`, `scan`, `note`, `profile`, `reminders`, `privacy`, `methodology`.
- Widget test cần thay provider đã override mặc định thì truyền `pumpFluwApp(overrides:)`; chúng nằm ở `ProviderScope` con vì Riverpod không cho override một provider hai lần trong cùng container. Màn tab chỉ là phần thân; header và thanh dưới nằm ở `app/shell/`.
- **Shell (UI0):**
  - `AppShell` (`ConsumerWidget`) = `FluwTopBar` + thân màn + `FluwBottomBar`. Chuyển sang tab khác Tra Cứu/Quét Món (thanh dưới hoặc avatar) thì xóa `diaryTargetProvider`, để khung đã chọn ở Nhật Ký không dính vào lần thêm món sau; đi từ một khung sang Tra Cứu/Quét thì giữ.
  - Header: tiêu đề theo `AppTab.title`, nút Sáng/Tối, chuông (mở `/reminders`, M6b), avatar mở Hồ Sơ.
    - `AppBar` của Flutter tự giới hạn cỡ chữ tiêu đề (`_kMaxTitleTextScaleFactor`); giữ nguyên theo chuẩn Material.
  - Thanh dưới: 5 tab, nút Quét tròn 56 dp nổi 24 dp.
    - Phần nổi nằm trong chiều cao của thanh để nhận được chạm; có test chạm vào mép trên của nút.
    - Nhãn tab to theo cỡ chữ hệ thống đến **130% rồi dừng**, giống `NavigationBar` của Material (thanh cao cố định). Trên màn hẹp, nhãn dài co theo chiều ngang bằng `Flexible` + `FittedBox`.
    - Semantics mỗi tab: nút, có hành động chạm (`onTap`), có trạng thái đang chọn. Nút tròn bị loại khỏi semantics vì tab "Quét Món" bên dưới đã đọc tên.
- **State:** Riverpod 3 (`flutter_riverpod`).
  - `core/settings/`: `themeModeProvider` (Notifier) và `ThemeModeStorage` (shared_preferences, khóa công khai `ThemeModeStorage.key` = `theme_mode`, để "Xóa toàn bộ dữ liệu" giữ lại).
  - `sharedPreferencesProvider` (`SharedPreferences?`, null khi kho không mở được) dùng chung cho các kho cài đặt.
  - `loadPreferences()` chờ tối đa 2 s; mọi lỗi (kể cả `Error`) hoặc quá giờ thì chạy với cài đặt mặc định.
  - Test giả lập kho cài đặt chậm/lỗi bằng `test/helpers/fake_preferences_store.dart` (dev dependency `shared_preferences_platform_interface`).
  - Storage được override trong `main()`; test dùng `test/helpers/pump_fluw_app.dart`. Test cần cuộn tới widget dùng `test/helpers/scroll_to.dart`.
  - Chọn lại "Theo máy": `AppearanceCard` trên Hồ Sơ (M2d).
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
  - `age`: `minimumAgeYears` = 18 (không còn mốc 14), `maximumAgeYears` = 100. `latestAdultBirthDate(today)`: ngày sinh muộn nhất đủ 18 tuổi (hôm nay 29/2 thì là 28/2), dùng làm `lastDate` của bộ chọn ngày sinh.
  - `energy` (BMR, TDEE), `calorie_target`, `protein_target` (`ProteinGroup` và `ProteinTarget`), `reference_weight`.
  - `calorie_target` (A1):
    - `isValidWeeklyChangeKg` so theo 0,01 kg; `weeklyChangeKgFromDailyGap` đổi mức chênh với TDEE ra kg/tuần (7.700 kcal/kg).
    - Giảm cân không thấp hơn `max(BMR, minimumIntakeKcal(formula))` (nữ 1.200, nam 1.500, NHLBI: mức thấp nhất trong các kế hoạch ăn giảm cân cho người tự thực hiện, tài liệu TLC 2005; Practical Guide 2000 cho mức thấp hơn, không dùng làm nguồn; giới tính Khác theo `BmrFormula`). Giữ cân, tăng cân không áp sàn (giữ cân vẫn bằng TDEE dù TDEE < 1.200).
    - `CalorieTarget.raisedTo`: `CalorieFloor.bmr` / `womenMinimum` / `menMinimum` / `maintenance`, `null` khi không nâng; `isRaisedToMinimum`.
    - `maintenance`: mức sàn ≥ TDEE (người nhỏ, lớn tuổi, ít vận động) thì mục tiêu **bằng TDEE**, không đặt thâm hụt. Hồ Sơ ghi "Mức tiêu hao ước tính (TDEE) đã thấp hơn mức tối thiểu khi giảm cân (1,200 kcal nữ, 1,500 kcal nam), nên Fluw để mục tiêu bằng mức giữ cân. Muốn giảm cân, hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng."
  - `reference_weight`: `ReferenceWeight` = `min(cân nặng, 24,9 × chiều cao(m)²)`, cờ `isCapped`. Protein và nước tính theo cân này; BMR, BMI theo cân thật.
  - `protein_target`: không còn nhóm `teen`; `cutting` 1,6–2,4 g/kg (Hector & Phillips 2018); `select` không nhận tuổi. `needsKidneyCaution` khi cận trên > 1,2 g/kg.
  - `health_profile` (`weeklyChangeKg` để trống được), `profile_validation` (giới hạn và `ProfileIssue`), `daily_targets`.
  - M2a:
    - `health_condition`: chỉ tiểu đường, huyết áp cao, mỡ máu đổi chỉ tiêu hoặc gây cảnh báo; các bệnh khác chỉ là ghi chú.
    - `bmi`: thang châu Á. `displayValue` là BMI **cắt xuống** 0,1 (cộng `1e-9` để 25,0 tính ra 24,999… không rơi xuống 24,9). Xếp loại theo số này nên giữ đúng ngưỡng spec và luôn khớp số hiện; giao diện phải hiện đúng `displayValue`.
    - `nutrient_targets`: béo, béo bão hòa, đường, tinh bột theo % năng lượng; `dailySodiumMaxMg` = 2000.
    - `water_target`: 35 ml × cân nặng tham chiếu, là tổng lượng nước kể cả nước trong thức ăn (mức Fluw chọn, đối chiếu EFSA 2010: nữ 2,0 lít, nam 2,5 lít).
    - `HealthProfile` thêm `conditions` và `limitsSugar` (giảm ngọt), đều bắt buộc (không mặc định), để lúc đọc SQLite quên cột thì không compile.
  - `HealthProfile.isPregnantOrBreastfeeding` (`bool?`, bắt buộc truyền): chỉ giữ khi công thức BMR là Nữ (constructor tự bỏ khi Nam hoặc Khác–Nam), `null` = chưa trả lời. Có trong `==`, `hashCode`, `copyWith`.
  - `calculateDailyTargets` trả một trong `InvalidProfile` / `BelowMinimumAge` / `PregnancyOrBreastfeeding` / `AdultTargets` (sealed class, UI phải xử lý đủ 4 trường hợp; `TeenTargets` đã bỏ). Hồ sơ lỗi không ném exception, để hồ sơ cũ trong SQLite không làm crash màn hình khi giới hạn đổi.
    - `BelowMinimumAge`: hồ sơ cũ của người dưới 18 tuổi vẫn đọc được; không có chỉ tiêu, màn ghi "Fluw dành cho người từ 18 tuổi."; dị ứng vẫn cảnh báo.
    - `PregnancyOrBreastfeeding` (xét sau tuổi): không có số nào (calo, macro, BMI, nước), chỉ lời "Nhu cầu năng lượng và đạm khi mang thai hoặc cho con bú khác người thường. Hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng."; dị ứng vẫn cảnh báo.
    - `AdultTargets`: BMR, TDEE, calo, protein, `nutrients`, `bmi`, nước, `referenceWeight`.
  - Giới hạn hồ sơ (FLuw duyệt 12/11, A1 thêm 19/11):
    - chiều cao 100–250 cm, cân nặng 20–300 kg, tuổi tối đa 100 (dưới 18 là `BelowMinimumAge`, không phải `ProfileIssue`);
    - tốc độ đổi cân lớn hơn 0 và không quá 0,5 kg/tuần, chỉ bắt buộc với người lớn muốn tăng/giảm cân và không mang thai/cho con bú;
    - `pregnancyAnswerMissing`: người lớn theo công thức BMR Nữ chưa trả lời câu hỏi mang thai. Hồ sơ nữ lưu trước schema v5 rơi vào đây cho tới khi trả lời (chủ ý: an toàn hơn coi là "Không");
    - `targetBmiTooLow` (giảm cân tới BMI < 18,5, cắt xuống 0,1 như `Bmi`), `loseWhenUnderweight` (đang BMI < 18,5 mà giảm cân; khi đó không báo kèm `targetBmiTooLow`). Chỉ xét khi người lớn, chiều cao và hai cân nặng hợp lệ và `goal == lose`. Tăng cân, giữ cân khi đang thiếu cân vẫn được.
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
  - `AppDatabase` schema v5 (v2 ở M2c: `display_name`, `bmr_formula`; v3 ở M2d: `diet_style`, `allergy_note`, `planned_goal`, bảng `profile_allergies`, `profile_preferences`, `weight_entries`; v4 ở M4: bảng `note_entries`; v5 ở A1: cột `profiles.pregnant_or_breastfeeding` bool null được, `from4To5`), bảng `profiles` (chỉ 1 dòng, `CHECK (id = 1)`) và `profile_conditions`. `appDatabaseProvider` mở file `fluw` bằng `drift_flutter`.
  - Bảng nằm ở `core/` vì `AppDatabase` phải liệt kê mọi bảng; `core/` vẫn không import `features/`.
  - Code sinh `app_database.g.dart` được commit (CI không chạy build_runner). Sinh lại xem mục 4.
  - Schema mỗi phiên bản lưu ở `frontend/drift_schemas/` (`build.yaml`). Tăng `schemaVersion` thì chạy `dart run drift_dev make-migrations` để có bước migration và test đối chiếu.
  - `sqlite3` 3.x tự tải SQLite lúc build (native-assets hook). **Không thêm trực tiếp `sqlite3_flutter_libs`**; bản `0.6.0+eol` trong lock do `drift_flutter` kéo vào, là gói rỗng.
- **`features/profile/data/` (M2b):**
  - `profile_storage_keys`: khóa lưu cố định cho `Sex`, `ActivityLevel`, `TrainingType`, `HealthCondition`, không dùng `name`/`index`. Có test khóa không bao giờ đổi; chỉ được thêm khóa mới.
  - `profile_mapper`: khóa bệnh lạ thì bỏ qua; trường bắt buộc không đọc được thì trả `null`.
  - `ProfileRepository`: `load` (đọc các bảng trong một transaction), `watch` (`customSelect('SELECT 1', readsFrom: ...)` + `asyncMap(load)`, phát lại khi bảng nào đổi), `save`/`clear` trong transaction. `save(profile, weighIn:)` ghi cả lần cân trong cùng transaction (drift lồng bằng savepoint). `save` từ chối số không hữu hạn (SQLite lưu NaN thành NULL).
  - Kết quả đọc là `StoredProfile` (sealed): `NoProfile` / `UnreadableProfile` / `LoadedProfile`. UI phải báo người dùng khi hồ sơ hỏng, không âm thầm mở form trống.
  - Provider: `profileRepositoryProvider`, `storedProfileProvider` (StreamProvider).
  - Test: `test/helpers/in_memory_database.dart` (SQLite trong bộ nhớ, `closeStreamsSynchronously`). `pumpFluwApp` tự tạo database theo app (đóng cùng app kể cả khi test fail), lấy qua `appContainer(tester)`; đọc/ghi database trong widget test phải bọc `tester.runAsync`.
- **`features/profile/presentation/` (M2c):**
  - `ProfileScreen` (tab Hồ Sơ) xử lý đủ `NoProfile` / `UnreadableProfile` / `LoadedProfile` / lỗi đọc (chỉ cho "Thử lại", không mở form trống để khỏi ghi đè).
  - `ProfileSetupScreen` ở route `/profile/setup` trên root navigator (che thanh tab); `app_router` truyền `onEditProfile`, `onOpenPrivacy` để feature không import `app/`.
  - `ProfileDraft`: chữ người dùng gõ → `HealthProfile`, lỗi theo từng ô (`ProfileField`). Tốc độ chỉ giữ khi người lớn muốn đổi cân. Có `==` để biết form có thay đổi thật không (hỏi trước khi bỏ).
  - Câu hỏi mang thai (A1): `ProfileField.pregnancy`, `ProfileDraft.asksPregnancy` (công thức Nữ). "Bạn đang mang thai hoặc cho con bú?" (Có/Không) ngay sau giới tính/công thức; Có thì ghi "Fluw sẽ không tính calo, đạm, BMI và nước; dị ứng vẫn được cảnh báo." và ẩn ô tốc độ. `targetBmiTooLow`, `loseWhenUnderweight` báo dưới ô "Cân nặng mong muốn".
  - Ô mức vận động có helper "Tính cả công việc, đi lại và tập luyện. Fluw dùng hệ số vận động thông dụng (ước tính)."; mô tả từng mức nói về cả ngày. Sức bền: "Chạy bộ, đạp xe, bơi" (bỏ yoga).
  - `DailyTargetsView`, `ProfileOverview` (A1):
    - Ghi chú calo theo `CalorieFloor`: nâng lên mức tối thiểu ("Đã nâng lên mức tối thiểu 1,200 kcal/ngày (nữ) để không ăn quá ít. Ăn thấp hơn cần bác sĩ theo dõi.", nam 1,500), nâng lên BMR, `maintenance` (chữ ở `calorie_target` trên).
    - Số tuần: khi bị nâng dùng tốc độ thực tế `(TDEE − kcal) × 7 / 7700`, "≈ 0.19 kg/tuần · ít nhất khoảng 11 tuần (ước tính; cân thường giảm chậm dần)"; tốc độ làm tròn còn 0 (kể cả `maintenance`) thì "chưa ước tính được thời gian". Chỉ hiện khi có `AdultTargets`.
    - Nước: "Tổng lượng nước (gồm cả nước trong thức ăn)", ghi chú 35 ml/kg (EFSA 2010), "Khoảng 70–80% lượng nước đến từ đồ uống. Người bệnh tim, thận cần hỏi bác sĩ về lượng nước."
    - Cân tham chiếu: "Đạm và nước tính theo cân nặng tham chiếu 76.3 kg (BMI 24.9), không theo cân nặng thật." `needsKidneyCaution`: "Nếu bạn có bệnh thận, hãy hỏi bác sĩ trước khi ăn nhiều đạm."
  - Lưu hồ sơ lần đầu phải qua `ensureHealthDataConsent` (xem Quyền riêng tư bên dưới). Cuối Hồ Sơ (dưới "Cập nhật hồ sơ") có nút "Xóa toàn bộ dữ liệu trên máy".
  - Về Fluw (`AboutCard`) có `PrivacyPolicyButton` và dòng "Fluw không phải thiết bị y tế; không chẩn đoán, điều trị hay phòng bệnh. Số liệu chỉ là ước tính." Màn chưa có hồ sơ / hồ sơ hỏng / lỗi đọc (`ProfileSetupPrompt`) cũng mở được `/privacy`.
  - Mô tả bệnh (`healthConditionDescription`) và "Tôi muốn giảm ngọt" (`diet_section.dart`) nói rõ là mức tham khảo (WHO), không phải chế độ ăn điều trị, không thay thế hướng dẫn của bác sĩ; bỏ "tính từ 18 tuổi" và "(đang xây dựng)". A3 viết lại theo D6 (đường tổng là mức gợi ý, dựa trên khuyến nghị đường tự do WHO 2015) và D11 (huyết áp cao: theo dõi natri 2,000 mg như mọi người lớn, thêm lời khuyên muối hằng ngày). `allergies_section` nói rõ chưa xét "có thể chứa" (vết).
  - Số nhập nhận `58,5` và `58.5`, tối đa 2 chữ số thập phân (`core/format/decimal_text.dart`); hiển thị theo thiết kế: `58.5`, `1,850`.
  - BMI trên màn Hồ Sơ lấy từ `AdultTargets`, nên hồ sơ không hợp lệ không hiện BMI và không crash.
  - `todayProvider` (`core/time/`) làm mới khi app quay lại trước màn hình và tự làm mới sau nửa đêm (Timer); test cố định ngày `appTestToday`.
  - App chạy locale `vi` (`flutter_localizations`); iOS khai báo `CFBundleLocalizations`. `tester.pageBack()` tìm tooltip tiếng Anh nên test bấm `find.byType(BackButton)`.
  - Ô nhập dùng `inputDecorationTheme` (nền `surfaceContainerLow`, bo 16, không viền) như thiết kế.
  - `WeightLogCard`: hồ sơ mang thai hoặc cho con bú chỉ hiện các lần cân, không hiện tiến độ tới cân nặng mong muốn (A3).
- **Mạng (M3a) `core/network/`:** `ApiClient` (package `http`) GET JSON, mọi lỗi thành `ApiFailure` sealed: `NetworkFailure` (kể cả lỗi TLS/`IOException`), `TimeoutFailure`, `ServerFailure` (giữ status, code, message của backend), `ServerUnavailableFailure` (5xx không có body lỗi chuẩn, vd 502 HTML của Render: "Máy chủ đang khởi động hoặc bận, hãy thử lại sau ít phút."), `InvalidResponseFailure`. `apiBaseUrl` mặc định `https://fluw.onrender.com` (đổi bằng `--dart-define=FLUW_API_BASE_URL`, phải https), `apiTimeout` 70 s vì Render free ngủ. Widget test truyền `MockClient` qua `pumpFluwApp(httpClient:)`; không truyền thì mọi lượt gọi là lỗi mạng. `postBytes` (M5b) gửi ảnh; `apiFailureMessage` (`api_failure_message.dart`) là lời nhắn chung cho mọi `ApiFailure`.
- **`PersonalLimits` (M3a) `core/nutrition/`:** dị ứng (tag OFF + tên người dùng đặt), chỉ tiêu cả ngày (kcal, đường, béo bão hòa, natri; chỉ người lớn có hồ sơ hợp lệ), cờ theo dõi theo bệnh, `profileStatus` (none / loading / unreadable / loaded), `isAdult` (tính từ ngày sinh kể cả khi hồ sơ thiếu số liệu). Cờ `watchesSugar` (tiểu đường, giảm ngọt), `tracksSodium` (A3, D11: mọi người lớn có chỉ tiêu) quyết định dòng natri ở Trang Chủ, Nhật Ký, đánh giá ngày; `watchesSodium` (huyết áp cao) chỉ còn quyết định lời khuyên muối hằng ngày, tô màu khẩu phần chiếm từ 50% ở Chi tiết và "Theo dõi: natri" ở lời chào; `watchesSaturatedFat` (mỡ máu cao) quyết định dòng béo bão hòa. `personalLimitsProvider` trong core, override ở `app/app_overrides.dart` (`crossFeatureOverrides()`, dùng chung cho `main()` và `pumpFluwApp`) bằng `app/personal_limits_from_profile.dart`, để feature search không import feature profile. Hồ sơ hỏng → `unreadable`, UI phải báo, không im lặng như không dị ứng.
- **`features/search/` (M3a):**
  - `data/`: `food_item_json` (đọc hợp đồng M1a; món sai hợp đồng thì bỏ riêng; chỉ nhận link https), `food_api` (`PRODUCT_NOT_FOUND` và `INVALID_BARCODE` → null), `recent_searches_storage` (shared_preferences key `recent_searches`, tối đa 8, lỗi đọc/ghi nào cũng bỏ qua — không phải dữ liệu sức khỏe).
  - `domain/`: `FoodItem` (dùng `NutritionFacts` của core), `SearchResponse` (`isPartial` khi một nguồn lỗi), `food_assessment` (`AllergenCheck`: chưa biết / không trùng trong danh sách đã ghi / trùng nặng-nhẹ; `PortionShare`).
    - `QuickFilter` (C, D13): đường ≤ 5 g/100 g hoặc ≤ 2,5 g/100 ml (đồ uống), protein ≥ 20 g, dưới 200 kcal (`lowSugarMaxPer100g`, `lowSugarMaxPer100ml`, `highProteinMinPer100`, `lowEnergyBelowKcalPer100`); thiếu số liệu thì không đạt. Nhãn "Đường ≤ 5 g", "Protein ≥ 20 g", "Dưới 200 kcal" dưới "Lọc nhanh (trong 100 g/ml)"; bật lọc đường thì hiện `lowSugarDrinkNote`.
    - `card_nutrition` (PR #45, B4): `hasCardNutrition` (có ít nhất kcal, protein hoặc đường). Kết quả **giữ thứ tự của nguồn** (index tìm kiếm OFF cũ, món đúng thường chỉ có số ở trang sản phẩm); thẻ thiếu số liệu ghi "Mở để xem số liệu" (món OFF có mã) hoặc "Chưa có số liệu"; lọc nhanh ẩn chúng và nói ẩn bao nhiêu. Đã bỏ `withNutritionFirst`.
    - Trường tùy chọn từ backend (PR #44/#45): `FoodItem.packageQuantity`, `servingQuantity` (`{amount, unit}`, trường sai dạng thì bỏ riêng trường đó), `nutrientsSuspect`. Chip "Cả chai (440 ml)" / "Cả gói (400 g)" chỉ khi cùng đơn vị với số liệu và trong 1–2000; khẩu phần mặc định = 1 suất (số `servingQuantity` thắng chuỗi `servingSize`), không có thì cả gói, không có nữa thì 100. `nutrientsSuspect` → "Số liệu nguồn có thể sai — hãy đối chiếu nhãn trên bao bì.", loại khỏi lọc nhanh.
    - Số theo 100 không được trông như cả gói (lỗi FLuw báo 22/11, trà sữa latte 8935001282266: OFF chỉ có 26 kcal/100 g, không có dung tích): thẻ kết quả có nhãn "Trong 100 g/ml"; Chi tiết có ô "Tổng năng lượng … cho X g" theo khẩu phần, bảng "Bảng dinh dưỡng trong 100 g" ghi rõ không phải cả gói; nguồn không có dung tích/khẩu phần thì có lời nhắc ngay trên ô khẩu phần (đồ uống: 1 ml ≈ 1 g); thẻ đối chiếu hồ sơ nằm dưới ô khẩu phần ("440 g này chiếm…"); nút thêm ghi "440 g · 114 kcal"; `/barcode` không thấy thì "Sản phẩm không còn trên Open Food Facts, số liệu có thể đã cũ."
    - `serving_size` (`servingAmount`): số cuối có đơn vị g/gr/gram/gam/ml trong `servingSize` ("1 bottle (355 ml)" → 355), làm tròn 0,1, phải cùng đơn vị với số liệu (không đổi g ↔ ml) và trong 1–2000.
  - **Tìm đồ tươi tiếng Việt qua USDA (C, D23):**
    - `vietnamese_text`: `canonicalVietnamese` (chữ thường, dấu dựng sẵn và dấu rời cho cùng một dạng, dấu câu thành dấu cách), `foldVietnamese` (bỏ dấu, đ → d). Dart không có chuẩn hóa Unicode nên tự làm bằng bảng 12 nguyên âm × 6 thanh.
    - `vietnamese_food_glossary`: `vietnameseFoodGlossary` (283 tên viết tay, gồm tên gọi khác), tiếng Anh theo tên USDA, ưu tiên một từ đặc trưng ("pummelo") vì USDA xếp hạng theo từng từ.
    - `englishSearchTermFor(query)`: chỉ khớp khi từ khóa là **một** tên trong bảng, đứng một mình hoặc kèm từ mô tả (`_descriptorWords`: luộc, hấp, nướng, sống, tươi, quả, trái, củ, xanh, đỏ...). Cụm dài nhất thắng ("sữa chua" → yogurt). Có từ lạ (món, hãng) thì không gửi: "phở bò" không thành "beef".
    - **Chiên, rán, xào, kho, khô không phải từ mô tả** (giám đốc sửa khi review): nấu thêm dầu/đường/sốt là món khác, đồ khô đổi số liệu trên 100 g nhiều lần, nên "cá kho" không thành "fish".
    - Gõ không dấu vẫn khớp ("ca chua") nhưng chỉ khi cả từ không dấu ("của" không thành "cua"); dạng bỏ dấu trùng hai món thì bỏ ("dua", "ngo"); "bơ" một mình không dịch.
    - `SearchController.search`: không có `englishQuery` từ ảnh thì lấy từ bảng (Gemini vẫn ưu tiên); `SearchLoaded.englishQuery` để màn hiện "Đã tìm thêm bằng tiếng Anh: ...".
  - `presentation/`: `SearchController` (chỉ kết quả của lần tìm mới nhất được ghi; từ khóa 2–100 ký tự, dọn dấu cách; `clear` cho nút "Xóa từ khóa"), `SearchScreen`, `FoodDetailScreen` (route `/search/food` trên root navigator, món qua `extra`; món OFF gọi `/barcode` để lấy dị ứng và tên tiếng Việt), `PersonalCheckCard`. Calo là mục tiêu ("Vượt mục tiêu calo"), béo bão hòa/natri là giới hạn ("Vượt giới hạn cả ngày"), đường tổng là mức gợi ý ("Cao hơn mức gợi ý cả ngày", màu `tertiary`); xét vượt bằng `isOverAsShown`, % bằng `percentAsShown`. Món USDA ghi "USDA: carb gồm cả chất xơ." Khẩu phần trống/sai: "Nhập khẩu phần hợp lệ để so với chỉ tiêu." (`hasPortion`).
  - Khẩu phần (C, D24): `PortionChips` ("1 khẩu phần (355 ml)" từ bao bì + 50/100/150/200). Mặc định = khẩu phần bao bì, không có thì 100; `/barcode` về sau mang khẩu phần thì đổi theo, trừ khi người dùng đã gõ số khác. Lời báo "Khẩu phần phải trong khoảng 1–2000 g." (D22: không viết "2,000").
  - Món đã ăn gần đây (C, D24): khi chưa tìm, `RecentFoodsSection` hiện `recentFoodsProvider`; chạm mở `RecentFoodSheet` (khẩu phần mặc định = lần trước, ghi bằng số liệu đã lưu, không cần mạng), thêm xong đóng bảng. Chưa hiện ở màn Chi tiết; chưa có "Lặp lại bữa".
  - Chưa làm: "Đã lưu" và nhập món thủ công (M3b).
- **`features/scan/` (M5):** tab Quét Món có 2 chế độ (`SegmentedButton`): Mã vạch và Ảnh món ăn, giữ cả hai trong `IndexedStack` để mã đang gõ hay kết quả nhận diện còn nguyên khi đổi qua lại.
  - Mã vạch (M5a):
    - `mobile_scanner` 7.5.0, chạy trên máy: Android dùng ML Kit gói sẵn trong app, iPhone dùng Apple Vision. Chỉ đọc EAN-13, EAN-8, UPC-A (`noDuplicates`).
    - `domain/gtin`: kiểm chữ số kiểm tra (8/12/13/14 số); camera đọc nhầm thì bỏ qua, không gọi máy chủ. Có ô nhập mã bằng tay: sai độ dài và sai chữ số kiểm tra báo khác nhau (`hasGtinLength`), sửa mã thì lỗi cũ biến mất.
    - `BarcodeCamera` (interface) + `LiveBarcodeCamera`. Camera chỉ chạy khi tab Quét đang hiện (`TickerMode`, mở sản phẩm cũng tắt nó ngay) và đang ở chế độ Mã vạch; `_isOpening` chặn mở hai trang khi camera đọc cùng mã hai lần.
    - `BarcodeCameraView`:
      - Lệnh bật/tắt chạy lần lượt rồi so với trạng thái mới nhất, vì mobile_scanner bỏ qua lệnh tắt lúc đang mở (rời tab ngay sau khi mở vẫn tắt được camera).
      - Tự xử lý vòng đời app theo cách của mobile_scanner cho controller tự tạo: tắt khi `inactive` (khung hình vẫn chạy nên lệnh không bị treo; `hidden`/`paused` thì không còn khung hình), bật khi `resumed`, bỏ qua khi chưa có quyền camera (hộp thoại xin quyền làm app `inactive`).
      - Bị từ chối quyền thì không tự bật lại (Android trước 11 sẽ hỏi mãi); màn lỗi có "Thử lại".
      - Nhận `controller` để test (`FakeController` kế thừa `MobileScannerController`, mock method channel `dev.steenbakker.mobile_scanner/scanner/method` vì bản debug gọi lệnh dừng trước).
    - Quét được → route `/search/barcode/:code` (`BarcodeLookupScreen` ở `features/search`): tra `/barcode` một lần rồi mở `FoodDetailScreen(isFullProduct: true)` (không tra lại); không có thì "Tìm theo tên" / "Quét mã khác"; lỗi mạng có "Thử lại".
    - "Tìm theo tên" phải `pop()` rồi mới `go()`: tab Quét chờ `push` của trang này hoàn tất mới quét tiếp, mà `go` của go_router 18 bỏ trang đi không hoàn tất nó (camera tắt mãi).
    - Android: quyền `CAMERA` + `uses-feature` camera và `camera.autofocus` `required="false"`. iOS: `NSCameraUsageDescription`. Vùng camera có semantics.
  - Ảnh món ăn (M5b):
    - **Chỉ người từ 18 tuổi** (`PersonalLimits.isAdult`): điều khoản Gemini API yêu cầu người dùng từ 18 tuổi. App đã chỉ cho người lớn, nhưng hồ sơ cũ của người dưới 18 vẫn đọc được nên vẫn giữ chặn này. Chưa có hồ sơ, hồ sơ hỏng, dưới 18 thì chỉ hiện lời giải thích, không có nút gửi ảnh.
    - `PhotoRecognitionPanel`: lần đầu hỏi đồng ý gửi ảnh. `PhotoConsentStorage` lưu `photo_recognition_consent_version` (int, `currentVersion` = 2); khóa cũ `photo_recognition_consent` (bool) không còn tính và bị xóa khi đồng ý/rút lại, nên người đã đồng ý chữ cũ được hỏi lại. Không có kho hoặc lỗi thì hỏi lại. Đổi chữ hộp thoại về nội dung thì tăng `currentVersion`.
    - Hộp thoại (A2, D18) nói rõ: ảnh đi qua máy chủ Fluw (Hoa Kỳ) tới Google Gemini, Fluw xóa vị trí và thời gian chụp, không lưu ảnh; gói miễn phí Google có thể dùng ảnh và cho người xem lại; đừng chụp người hay giấy tờ; rút lại đồng ý không xóa được ảnh đã gửi cho Google; "Tính năng này chỉ dành cho người dùng ở Việt Nam."; nút "Đọc chính sách quyền riêng tư" (`onOpenPrivacy` qua `ScanScreen`). Nút "Rút lại đồng ý gửi ảnh" (`withdrawConsent`; Luật 91/2025 cho chủ thể dữ liệu rút lại đồng ý).
    - `FoodPhotoPicker` (interface, trả `Uint8List?`) + `ImageFoodPhotoPicker` (`image_picker`, tối đa 1280 px, chất lượng 80). `image_picker` đổi sang JPEG (PNG giữ PNG) nhưng chép lại EXIF gồm cả GPS và giữ tên file gốc (`scaled_x.heic`). Android chọn ảnh bằng trình chọn của hệ thống, không cần quyền đọc bộ nhớ; chụp ảnh thì `image_picker` tự xin quyền camera.
    - `domain/photo_metadata` (`removePhotoMetadata`): đọc định dạng từ byte đầu; JPEG bỏ APP1 (EXIF, XMP), APP13 (IPTC), COM và mọi thứ sau dấu kết thúc ảnh; PNG bỏ `eXIf`, `tEXt`, `zTXt`, `iTXt`, `tIME`. Định dạng khác hoặc file hỏng thì không gửi (`UnsupportedPhotoFormat`). Test dùng ảnh mẫu thật có GPS ở `test/fixtures/photos/` (sinh bằng Pillow).
    - `RecognitionApi` xóa metadata rồi gọi `POST /api/foods/recognize`, bỏ món sai dạng; mỗi món có `englishQuery` (từ tiếng Anh cho USDA).
    - Kết quả ghi "AI (Google Gemini) gợi ý, có thể sai". Chọn món → `searchRequestProvider` (`core/search/`, so theo identity nên cùng từ khóa vẫn chạy lại; mang theo `englishQuery`) + mở tab Tra Cứu; `SearchScreen` chạy tìm (gửi `en` cho USDA, giữ cho "Thử lại") rồi xóa yêu cầu. Số liệu dinh dưỡng luôn từ OFF/USDA, không từ AI.
    - Lỗi hiện lời nhắn của máy chủ; 413 → "Ảnh quá lớn"; không mở được camera/thư viện ảnh; ảnh không phải JPEG/PNG. Ảnh không có món ăn thì nói rõ. Đang mở camera/thư viện hoặc đang nhận diện thì tắt cả hai nút. Trạng thái và kết quả nằm trong `Semantics(liveRegion)`.
    - iOS: `NSPhotoLibraryUsageDescription`.
    - Chưa làm: `retrieveLostData` của `image_picker` (Android có thể tắt app khi đang mở camera trên máy yếu; người dùng chụp lại).
  - Test: `pumpFluwApp` thay camera bằng `FakeBarcodeCamera` (`appBarcodeCamera(tester)`) và bộ chọn ảnh bằng `FakeFoodPhotoPicker` (`appPhotoPicker(tester)`).
- `core/nutrition/` (dùng chung cho tra cứu, Nhật ký, gợi ý):
  - `Nutrient`: kcal, protein, carb, đường, béo, béo bão hòa, natri (mg).
  - `Nutrients`: thiếu key nghĩa là không có dữ liệu, không phải 0; 0 là dữ liệu thật. Từ chối số âm, NaN, vô cực. Có `==`.
  - `NutritionFacts`: số liệu cho mỗi 100 g hoặc 100 ml kèm `QuantityUnit`, nên lượng ăn luôn cùng đơn vị với số liệu.
  - `NutrientTotals`: tổng các giá trị đã biết kèm số món thiếu dữ liệu. Món nào cũng thiếu thì `knownSum` là `null`; không có món nào thì là 0.
  - `portion_limits` (C): `minPortion` 1, `maxPortion` 2000, `isValidPortion` (Dart thuần để domain dùng được). `QuantityUnit.symbol` ("g"/"ml") để hiển thị; khóa lưu SQLite vẫn là `quantityUnitKeys` riêng.
- `core/widgets/` (C): `portion_input` (ô khẩu phần cho Chi tiết, bảng ghi lại món gần đây, bảng sửa món), `meal_slot_picker` (`MealSlotPicker`, 4 ô giờ, tách từ `AddToNoteBar`).
- `core/diary/` (M4, dùng chung cho Nhật ký, Tra cứu, sau này Quét):
  - `MealSlot` (`night`, `morning`, `afternoon`, `evening`, xếp theo giờ trong ngày). `meal_slot_labels`: thứ tự hiển thị theo thiết kế (Sáng, Trưa / Chiều, Tối, Khuya / Đêm), tên và giờ mỗi khung; tên khung luôn đi kèm giờ để không hiểu nhầm Khuya là sau Tối.
  - `placeMeal` (`MealPlacement`): đổi giờ về giờ địa phương, bỏ giây; 00:00 thuộc Tối hôm trước.
  - `DiaryTarget` (ngày + khung). `DiaryTarget.current(now)` lấy ngày nhật ký từ **cùng một đồng hồ** với giờ ăn (lúc 00:00:30 là Tối hôm trước); không trộn `todayProvider` với `DateTime.now()`. `diaryTargetProvider`: Nhật ký đặt khi bấm "Thêm món" ở một khung, màn Chi tiết đọc làm mặc định, ghi xong thì xóa.
  - `eatenAtFor(day, slot, now)`: đúng khung đang diễn ra thì giữ giờ thật; khung khác thì giờ cố định trong khung (03:00, 09:00, 15:00, 21:00).
  - `FoodLogger` (interface) + `foodLoggerProvider`: tính năng khác ghi món vào Nhật ký mà không import `features/note`; `app_overrides` nối bằng `NoteFoodLogger`. `LoggedFood` chép số liệu, nên nguồn đổi sau này không sửa món đã ăn.
  - M6a chuyển sang `core/diary/`: `NoteEntry` (`id`, `name`, `sourceFoodId`, `facts`, `quantity`, `eatenAt`, có `==`), `NoteDay` + `groupNoteEntries` (ngày mới nhất trước; cùng giờ xếp theo `id`; không sửa được), `NoteWindow`. `DiaryReader` (interface, `NoteRepository` cài, `app_overrides` nối) + `diaryDayProvider(date)` (cửa sổ 00:00 → 00:01 hôm sau, trả `DiaryDay` gồm `NoteDay?` và số dòng hỏng) cho Trang Chủ, nhắc nhở, báo cáo đọc Nhật ký mà không import `features/note`.
  - Món gần đây (C): `distinctRecentFoods` (mỗi món một lần theo `sourceFoodId`, không có thì theo tên + đơn vị), `RecentFoodsReader` (interface, `NoteRepository.watchRecentFoods` cài, đọc 200 dòng mới nhất theo giờ ăn, `app_overrides` nối) + `recentFoodsProvider` (tối đa `recentFoodsLimit` = 8). Không đổi schema.
- `core/widgets/nutrient_progress.dart` (M6a): dòng "đã nạp / chỉ tiêu" + thanh, dùng chung cho Nhật Ký và Trang Chủ. `NutrientTargetKind`: `calorieGoal` (báo vượt mục tiêu), `minimum` (protein), `limit` (natri, béo bão hòa: "Vượt giới hạn cả ngày.", màu lỗi), `suggestion` (đường tổng: "X g / mức gợi ý Y g", cao hơn thì "Cao hơn mức gợi ý cả ngày." màu `tertiary`, không bao giờ màu lỗi), `target` (béo, carb: không cảnh báo). Nhận `nutrient` để so và định dạng theo `shown_amount`. Thiếu số liệu thì "Chưa có dữ liệu", không vẽ thanh.
- `PersonalLimits` (M6a) thêm, đều có mặc định: `fatTargetG`, `carbohydratesTargetG`, `displayName`, `goalLabel`, cờ chế độ ăn `avoidsAnimalProducts` (thuần chay), `limitsCarbohydrates` (keto), `prefersSteamedOrBoiled`, `likesNuts` (chỉ để gợi ý món), `targetsKind` (`TargetsKind`: adult / belowMinimumAge / pregnancyOrBreastfeeding / invalid, không còn `teen`; mỗi loại một lời nhắn, chỉ `invalid` mới bảo kiểm tra hồ sơ). `proteinMinG` chỉ có với `AdultTargets`.
- `currentHourProvider` (`core/time/`): giờ hiện tại, tự làm mới đầu giờ sau và khi quay lại app (`FluwApp` invalidate, vì Timer dừng khi máy ngủ); test cố định `appTestHour` = 9.
- `features/home/` (M6a):
  - `domain/day_evaluation`: đánh giá một ngày theo chỉ tiêu: mọi so sánh qua `shown_amount` (theo số hiện). Calo đạt khi trong ±10% (`calorieToleranceShare` ở `fluw_thresholds`); calo hiện dưới 50% mục tiêu → `VerdictStatus.maybeUnderLogged` ("có thể chưa ghi đủ món", không tính là tốt, không có khoảng thiếu). Protein đủ khi đạt cận dưới; đường tổng "trong / cao hơn mức gợi ý"; natri xét cho mọi người lớn, béo bão hòa chỉ khi có mỡ máu cao. Đạt hết: "Đạt các chỉ tiêu Fluw đang theo dõi." Ngày chưa ghi món không đánh giá. Món nào cũng thiếu một chỉ số → `noData`. Có món thiếu: "vượt" và "đủ" vẫn giữ (tổng đã biết là mức tối thiểu), còn lại thành `incomplete` (không tính là tốt).
  - `domain/nutrition_advice`: `adviceFor(today: null)` khi Nhật ký đang tải/lỗi thì chỉ còn lời nhắc theo hồ sơ. Không coi số thiếu là 0: buổi tối chỉ nói "còn khoảng" khi mọi món có calo; protein thiếu ở vài món thì nói "tối đa". Dị ứng lạc cũng bỏ các loại hạt. Gợi ý theo luật, không gọi AI: dị ứng (tên người dùng đặt + đọc nhãn), hạn chế đồ ngọt (theo dõi đường hoặc đã ≥ 80% giới hạn), muối, béo bão hòa (theo bệnh), bổ sung protein (nhóm thực phẩm, bỏ món dị ứng cả nặng lẫn nhẹ, thuần chay bỏ đồ động vật, keto bỏ đậu lăng; thích hấp/luộc, thích hạt), calo vượt > 10% hoặc buổi tối còn ≥ 300 kcal (chỉ khi đã ghi món). `belowMinimumAge` ("Fluw dành cho người từ 18 tuổi") và `pregnancyOrBreastfeeding` có lời riêng, không nói về calo. Không khẳng định sức khỏe cho món cụ thể.
  - `presentation/`: `HomeScreen` (callback từ `app_router`: Tra Cứu, Quét, Nhật Ký, Hồ Sơ, Thiết lập hồ sơ; hồ sơ không đọc được thì nút mở tab Hồ Sơ, không mở form trống; Nhật ký đang tải thì hiện vòng chờ, không hiện 0), `GreetingCard`, `TodayNutritionCard` (dưới 18 tuổi: "Fluw dành cho người từ 18 tuổi."; mang thai: "Mang thai hoặc cho con bú: Fluw không tính calo."; vòng calo + thanh protein, đường tổng (mức gợi ý), carb, béo, natri (mọi người lớn), thêm béo bão hòa khi có mỡ máu cao; vòng và "Còn lại" cạnh nhau, chồng lên nhau khi màn hẹp/chữ > 150%; thiếu kcal ở vài món thì "Còn lại tối đa", món nào cũng thiếu thì "Chưa có dữ liệu calo"; so vượt theo số đã làm tròn), `TodayMealsCard` (4 khung; khung trống có "Ghi món" đặt `diaryTargetProvider` rồi mở Tra Cứu, semantics nói tên khung; chữ > 130% thì nút xuống dưới tên khung; thiếu kcal ở vài món thì hiện "≥ X kcal"), `DayEvaluationCard` (hôm qua, mỗi dòng có icon + chữ), `AdviceCard`, `QuickActions` (Quét mã vạch, Tra cứu; "Nhập thực phẩm" của thiết kế chờ M3b).
  - Bỏ khỏi thiết kế: "Chuẩn Mục Tiêu", "An toàn", GI, "Êm dạ dày", khẳng định về dạ dày; thẻ nước chờ M8.
  - `HomeScreen.onAddFood` lấy ngày bằng `DiaryTarget.current(ref.read(clockProvider)()).day` (cùng đồng hồ với khung; lúc 00:00:30 vẫn là Nhật ký hôm trước), không dùng `todayProvider` (B9, A3).
- `core/nutrition/shown_amount.dart` (A3, D14): **một quy tắc "vượt" duy nhất**, so theo số đã làm tròn như số hiện (kcal, mg số nguyên; gam 0,1 g, đọc lại từ chuỗi của `formatDecimal`). `isOverAsShown` ("25.0 / 25.0 g" không vượt, "25.1 / 25.0 g" luôn vượt), `isBelowAsShown`, `shownDifference` (không bao giờ "vượt 0"), `percentAsShown` (trên 100% chỉ khi vượt), `formatShownAmount`. Dùng ở `NutrientProgress`, vòng calo, `evaluateDay`, `adviceFor`, `reminderMessage`, `PersonalCheckCard`.
- `core/nutrition/fluw_thresholds.dart` (A3): các ngưỡng Fluw tự chọn, không có nguồn: `calorieToleranceShare` 0,10, `underLoggedShare` 0,5, `nearLimitShare` 0,8 (lời khuyên đường và muối, kể cả người không có huyết áp cao), `eveningStartHour` 18 + `eveningKcalLeft` 300, `watchedPortionShare` 0,5. Màn "Cách Fluw tính" đọc từ đây.
- `features/methodology/presentation/` (A3, D12): màn "Cách Fluw tính" (route `/methodology` trên root navigator), mở từ nút ⓘ ở thẻ "Chỉ tiêu mỗi ngày" (`SectionCard.trailing`) và nút trong "Về Fluw" (`app_router` truyền `onOpenMethodology` qua `ProfileScreen` → `ProfileOverview` → `AboutCard`). `methodology_content.dart` liệt kê mọi công thức kèm nguồn và các ngưỡng tự chọn; test đối chiếu số trên màn với hằng số của app (đổi công thức mà quên sửa chữ thì test fail). Nguồn mức tối thiểu là tài liệu TLC 2005 của NHLBI (Practical Guide 2000 khuyên 1.000–1.200 kcal nữ, 1.200–1.600 kcal nam, không khớp mức của Fluw).
- `features/reminders/` (M6b):
  - `domain/`:
    - `ReminderTime` ("HH:mm"); `ReminderSettings` (mặc định **tắt**, giờ 10:00/17:00/22:00; sắp xếp, không trùng, tối đa `maxTimes` = 10 để id không trùng khi kho hỏng).
    - `reminder_message`: khung theo giờ (< 6 khuya, < 12 sáng, < 19 chiều, còn lại tổng kết). Khuya luôn là lời nhắc chung (00:00 thuộc ngày hôm trước). Hôm nay nói số đã ghi so với chỉ tiêu; món thiếu kcal/protein (hoặc đường khi theo dõi đường) thì nói "thiếu số liệu"; dòng Nhật ký không đọc được thì nói rõ, không bảo "chưa ghi món nào"; chỉ gợi ý "món giàu protein" khi protein đủ số liệu, không có dòng hỏng và còn thiếu; ngày sau là lời nhắc chung. `showsIntake` đánh dấu nhắc có số liệu ăn uống.
    - `reminder_plan`: hẹn 7 ngày, bỏ giờ đã qua, id = ngày × 10 + thứ tự, trong `[0, mealReminderIdEnd)` = `[0, 70)`. **Thông báo khác (nhắc uống nước M8) phải dùng id từ 70 trở lên**, vì hẹn lại sẽ hủy mọi id đang chờ trong dải này.
  - `data/`:
    - `ReminderSettingsStorage` (shared_preferences `reminders_enabled`, `reminder_times`; kho lỗi/null thì mặc định), `reminderSettingsProvider`, `NotificationScheduler` (interface).
    - `LocalNotificationScheduler` (`flutter_local_notifications`, `timezone`):
      - Báo thức không chính xác `inexactAllowWhileIdle`, không cần quyền báo thức chính xác. Android 12+ báo trong khoảng 1 giờ sau giờ đặt (thường sớm hơn); Android cũ hoặc chế độ tiết kiệm pin có thể trễ hơn.
      - Gửi giờ theo zone `UTC` (Android và iOS đều biết tên này): nhắc là một lần vào thời điểm tuyệt đối nên zone nào cũng đúng. Không cần `flutter_timezone` hay cơ sở dữ liệu múi giờ.
      - `replaceAll` chạy lần lượt (tắt ngay khi đang hẹn dở không để sót nhắc); lời gọi đến khi một lượt đang chờ thì gộp vào lượt đó, lượt chỉ áp kế hoạch mới nhất và mọi nơi gọi nhận kết quả của nó. Bỏ giờ còn dưới 10 giây. Một nhắc lỗi thì vẫn hẹn các nhắc còn lại, rồi ném lỗi đầu tiên. Chỉ hủy các id nhắc bữa ăn đang chờ (không `cancelAll`). Khởi động plugin lỗi thì lần sau thử lại.
      - Kênh `meal_reminders`, icon `ic_notification`. Nhắc có số liệu ăn uống: `NotificationVisibility.secret` (không hiện trên màn khóa có mã PIN/hình vẽ/sinh trắc; đa số máy Android mặc định hiện đủ nội dung). Nhắc chung: `private`. iPhone: theo cài đặt Xem trước của máy.
  - `presentation/`:
    - `plannedRemindersProvider` (null khi Nhật ký đang tải/lỗi để giữ lịch cũ).
    - `ReminderSync` (bọc app trong `FluwApp.builder`, `listenManual` + `fireImmediately`): chỉ hẹn lại khi kế hoạch đổi. Lúc mở app luôn gửi kế hoạch một lần, kể cả rỗng, để hủy nhắc còn sót khi lần trước tắt nhắc bị lỗi hoặc app bị đóng giữa chừng (chỉ tốn khởi động plugin và 1 lượt đọc nhắc đang chờ). Lỗi thì báo qua `FlutterError.reportError` và lần sau gửi lại. Quay lại app thì tính lại kế hoạch (bỏ giờ đã qua, đổi múi giờ khi đi xa) và gửi trực tiếp, vì Riverpod không báo khi kế hoạch mới bằng kế hoạch cũ.
    - `ReminderSettingsScreen` (route `/reminders` ngoài nhánh tab; bật thì mới xin quyền, bị từ chối thì vẫn tắt và báo cách bật; đổi giờ bằng `showTimePicker`, chặn trùng; nút về giờ mặc định). Bộ chọn giờ ép `alwaysUse24HourFormat`: mặt đồng hồ theo locale `vi` (24 giờ) nhưng ô gõ giờ theo cài đặt 12/24 giờ của máy, máy để 12 giờ sẽ không gõ được 13–23 (lỗi của Flutter).
  - Bật thì người dùng tự bật (xin quyền đúng lúc cần), không bật sẵn lúc mở app lần đầu.
  - Android: `RECEIVE_BOOT_COMPLETED` + 2 receiver của plugin trong `AndroidManifest.xml`; `isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs` 2.1.4 trong `build.gradle.kts`; AGP 9.1.1 và `compileSdk` ít nhất 37 (plugin yêu cầu tối thiểu, mặc định của Flutter là 36); `drawable-*/ic_notification.png` (chữ F trắng) + `res/raw/keep.xml` giữ icon khi R8 thu gọn tài nguyên (thiếu là thông báo hỏng im lặng). iOS: `AppDelegate` đặt `UNUserNotificationCenter` delegate.
  - Test: `pumpFluwApp` thay bộ hẹn giờ bằng `FakeNotificationScheduler` (`appNotifications(tester)`), `clockProvider` cố định 09:00 ngày `appTestToday`. `LocalNotificationScheduler` test bằng plugin giả (`noSuchMethod`); `ReminderSync` test riêng với đồng hồ đổi được. Bộ chọn giờ trong test: bấm `Icons.keyboard_outlined` rồi gõ giờ, phút, bấm "OK".
- `clockProvider` (`core/time/`): giờ hiện tại dạng hàm để test cố định được.
- `features/note/` (M4):
  - `domain/`: `week` (tuần bắt đầu thứ Hai), `entry_edit` (C: `editNoteEntry` giữ giờ ăn khi ngày và khung không đổi; chuyển thì lấy giờ của `eatenAtFor`).
  - `data/`: bảng `note_entries` (schema v4; giờ lưu ms UTC; số liệu cho 100 g/ml, cột null = không có dữ liệu), `note_entry_mapper` (khóa đơn vị `g`/`ml` cố định; dòng hỏng trả `null`), `NoteRepository` (`watchBetween` trả `NoteWindow` gồm món và **số dòng không đọc được**, `add`, `delete`, `update` thay theo id (món đã bị xóa thì `StateError`), `watchRecentFoods`), `newNoteEntryId`, `weekNoteEntriesProvider` (autoDispose, cửa sổ từ 00:00 thứ Hai đến 00:01 thứ Hai sau vì 00:00–00:00:59 thuộc Tối Chủ nhật).
  - `presentation/`: `NoteScreen` (dải tuần có chấm ngày có món, "Về hôm nay"; báo số món hỏng; tổng ngày; 4 khung; xóa có "Hoàn tác", snackbar xếp hàng chứ không thay nhau để xóa liền hai món vẫn hoàn tác được cả hai; hoàn tác lỗi thì báo), `DaySummaryCard` (kcal là mục tiêu, protein là mức tối thiểu, đường là giới hạn; béo bão hòa/natri chỉ hiện khi có bệnh theo dõi; vượt theo % làm tròn; thiếu số liệu thì ghi rõ, không vẽ thanh), `MealSlotSection`, `NoteEntryTile`, `WeekStrip`. Dải tuần luôn hiện khi đang tải tuần mới (vòng chờ chỉ ở phần dưới).
  - Sửa món đã ghi (C, D24): nút bút chì "Sửa <tên>" trên thẻ món → `EditNoteEntrySheet` (khẩu phần, "Đổi ngày" bằng lịch đến hôm nay, khung giờ). Lưu xong snackbar "Đã sửa X" + "Hoàn tác" (ghi lại bản cũ); lỗi thì "Không sửa được X".
  - Màn Chi tiết (search) có `AddToNoteBar` ghim ở đáy (`bottomNavigationBar`) như thiết kế: 4 ô giờ ngắn (`MealSlotPicker`, `mealSlotShortHours`, "06–12h"...) + tên khung đang chọn, mặc định theo `diaryTargetProvider` hoặc khung hiện tại; ngày khác hôm nay thì ghi rõ ngày và có "Chọn hôm nay"; khẩu phần sai thì tắt nút; lỗi ghi thì báo.
    - Nhận `name`/`sourceFoodId`/`facts` (không nhận `FoodItem`) và `onAdded`, để `RecentFoodSheet` dùng chung.
    - Đọc `foodLoggerProvider`, `diaryTargetProvider.notifier` và giờ (`clockProvider`, không `DateTime.now()`) **trước** `await`: rời trang khi đang ghi thì món vẫn vào Nhật ký và báo "Đã thêm". Cỡ chữ trong thanh dừng ở 130% như `NavigationBar`, để thanh không che hết trang. Ô khung đang chọn nền `primary` chữ `onPrimary` đậm (như ngày đang chọn ở dải tuần), không dùng màu nhạt khó phân biệt.
  - Thanh nằm sau bàn phím (Scaffold không đẩy `bottomNavigationBar` lên), mà bàn phím số của iPhone không có nút Xong → ô khẩu phần có `onTapOutside` bỏ focus, danh sách có `keyboardDismissBehavior.onDrag`.
  - `WeekStrip` tự cuộn ngang tới ngày đang chọn (thứ Bảy, Chủ nhật bị khuất trên màn hẹp). Chỉ cuộn hàng ngày bằng `getOffsetToReveal`, không dùng `Scrollable.ensureVisible` vì nó cuộn cả trang.
  - Giờ cố định khi thêm vào khung khác (vd 21:00) hiện như giờ thật trên thẻ món; chưa đánh dấu là ước tính.
- **Quyền riêng tư (A2):**
  - `PRIVACY.md` ở gốc repo (phiên bản 1, 18/11/2026), URL công khai `https://github.com/Fluw13/Fluwwwwww/blob/main/PRIVACY.md`. Bên chịu trách nhiệm: nhà phát triển cá nhân (GitHub: Fluw13); liên hệ qua GitHub Issues; không ghi tên thật, email.
  - `features/privacy/presentation/privacy_policy_text.dart`: nội dung chính sách dạng dữ liệu (`PolicySection`, `PolicyParagraph`, `PolicyBullets`, `PolicyDataFlows`), đúng từng chữ như `PRIVACY.md`, kể cả `**đậm**`. Test dựng lại `PRIVACY.md` từ dữ liệu này và so bằng nhau: **sửa chính sách thì sửa cả hai nơi**, đổi phiên bản và ngày.
  - `PrivacyScreen` ("Quyền riêng tư và điều khoản"), route `/privacy` ngoài nhánh tab (như `/reminders`). URL công khai và Issues là `SelectableText` + nút sao chép (app không mở trình duyệt, không thêm gói). Cuối màn có nút xóa toàn bộ dữ liệu; xóa từ đây thì `pop()` rồi `go('/profile')`.
  - Mở từ: Về Fluw, màn chưa có hồ sơ / hồ sơ hỏng / lỗi đọc, hộp đồng ý lưu thông tin sức khỏe, hộp đồng ý gửi ảnh. Feature nhận callback `onOpenPrivacy` từ `app_router`.
  - **Đồng ý lưu thông tin sức khỏe (D16):** `core/privacy/health_data_consent.dart` (`HealthDataConsentStorage`: `health_data_consent_version` int, `currentVersion` = 1, và `health_data_consent_agreed_at` ISO 8601 UTC, ghi trước phiên bản; chỉ tính khi phiên bản khớp, đổi chữ thì tăng `currentVersion`) + `core/widgets/health_data_consent_dialog.dart`.
    - `ensureHealthDataConsent(context, ref, onReadPolicy:)` gọi trong `ProfileSetupScreen._save` khi bản nháp hợp lệ. "Để sau" hoặc đóng hộp: không lưu gì, giữ bản nháp, snackbar "Chưa lưu hồ sơ...". "Đọc chính sách" mở `/privacy`, quay lại form còn nguyên, lần lưu sau hỏi lại.
    - Người có hồ sơ từ trước được hỏi ở lần lưu kế tiếp. Ghi cân từ thẻ Hồ Sơ không hỏi. Ghi đồng ý lỗi (kho hỏng) vẫn lưu hồ sơ; lần sau hỏi lại.
    - Test: `pumpFluwApp(healthDataConsent: true)` mặc định (hằng `grantedHealthDataConsent`); test của luồng đồng ý truyền `false`.
  - **Xóa toàn bộ dữ liệu trên máy (D17)** ở `app/` vì đi qua nhiều feature:
    - `app/erase_all_data.dart` (`eraseAllDataProvider`): tắt nhắc (`reminderSettingsProvider.update(defaults)`), `replaceAll([])` hủy nhắc đang chờ (cả khi app tưởng không có), xóa **mọi bảng** của `AppDatabase.allTables` trong một transaction rồi `VACUUM`, xóa lịch sử tìm kiếm, xóa **mọi khóa** shared_preferences trừ `ThemeModeStorage.key`, reset `diaryTargetProvider`, `searchRequestProvider`. Bảng và khóa thêm sau này cũng bị xóa. Mỗi bước chạy kể cả khi bước trước lỗi, rồi ném lỗi đầu tiên. Kho cài đặt null → lỗi.
    - `app/erase_all_data_flow.dart` (`confirmAndEraseAllData`): hộp xác nhận (nói rõ các lựa chọn đồng ý cũng bị xóa, chế độ Sáng/Tối được giữ), snackbar thành công / "Chưa xóa được hết dữ liệu...", lỗi báo qua `FlutterError.reportError`.
    - Nút `core/widgets/erase_all_data_button.dart` (`EraseAllDataButton`) ở cuối Hồ Sơ và cuối màn quyền riêng tư.
  - Chưa làm: xuất dữ liệu (JSON/CSV); cơ chế báo người dùng khi chính sách đổi (mục 9 của chính sách hứa "app sẽ báo"; hiện chỉ đồng ý sức khỏe/ảnh có phiên bản để hỏi lại); tóm tắt quyền riêng tư ở lần mở app đầu tiên.
- **Khởi động:** `main.dart` khóa màn dọc (thiết kế chỉ có màn dọc; màn ngang thì thanh ghim đáy chiếm gần hết chỗ). iOS `Info.plist` cũng chỉ còn màn dọc (iPhone: Portrait; iPad: Portrait + PortraitUpsideDown) + `UIRequiresFullScreen` (iPad đa nhiệm bỏ qua khóa xoay, và App Store đòi đủ 4 hướng nếu thiếu khóa này). `main.dart` đăng ký giấy phép phông và dữ liệu (`core/licenses/`). `FluwApp` gọi `backendWarmUpProvider` (GET `/health`, lỗi thì bỏ qua) lúc mở app và mỗi lần quay lại app, để Render free thức dậy trước khi người dùng tìm. `pumpFluwApp` thay bằng hàm rỗng để `MockClient` của test chỉ thấy lượt gọi test mong đợi.
- **Giấy phép:** thẻ "Về Fluw" (`AboutCard`) trên Hồ Sơ và nút trên màn chưa có hồ sơ mở `showLicensePage(useRootNavigator: true)` (toàn màn hình, che thanh tab) (gói, phông OFL, dữ liệu OFF ODbL/CC BY-SA, USDA CC0). Giấy phép BSD của Flutter và các gói yêu cầu kèm thông báo khi phát hành bản build.
- **Giao diện theo Figma (PR #43, #45, #46; số đo đọc bằng Figma MCP 22/11, file `2E8p4ZnGESwih1lNFyWeMA`):**
  - Cỡ chữ (`core/theme/app_typography.dart`): tiêu đề mục PJS SemiBold 18/24; số lớn PJS **Bold** 28 (-0.56; `PlusJakartaSans-Bold.ttf` đóng gói lại); nhãn Inter Bold 11 (+0.44); `bodyMedium` Inter Medium 13; `bodySmall` Inter Regular 12 màu mờ; `bodyLarge` 14; `titleLarge` 18; thêm `numberMedium` (22 Bold), `value` (Inter Bold 13). Chữ vẫn phóng theo cỡ chữ máy.
  - Widget chung: `AppCard` (bo 16, bóng y1 blur2 5%), `SectionHeader` (icon, tiêu đề, chữ phụ, phần phải tự xuống dòng khi chật), `SectionCard` (bỏ vạch xanh, thêm `icon:`/`subtitle:`; `accentColor` chỉ tô icon), `MealSlotIcon`, `readableOn()` (làm đậm màu biểu đồ đến khi chữ đạt 4.5:1). `AppRadius.card` = 16, `AppRadius.inner` = 12.
  - `core/widgets/nutrient_target_status.dart`: `NutrientTargetKind` và `NutrientTargetStatus.of(...)` (chữ chỉ tiêu, %, thanh, vượt, chữ và màu khi vượt) — mọi hàng/ô "đã nạp / chỉ tiêu" đọc từ đây; vẫn dựa `isOverAsShown`.
  - Hồ Sơ (PR #46): thẻ thể trạng (chiều cao, cân nặng, BMI cùng hàng; khối cân nặng mong muốn với "Đã đạt X%" từ lịch sử cân, ẩn khi chưa đủ 2 lần cân); ô chỉ tiêu có màu; "Dị ứng & bệnh nền" (đỏ: dị ứng nặng; vàng: nhẹ và bệnh có theo dõi; xám: bệnh chỉ ghi chú). Thiết lập: `SegmentedPills` (48 dp, xếp dọc khi chữ to), ô nhập bo 12 (chỉ màn này), dải BMI theo `ProfileDraft.previewBmi` (chỉ khi hồ sơ thật sự có BMI), nút "Lưu hồ sơ" ghim đáy.
  - Cố ý không chép từ thiết kế (sai sự thật hoặc chưa có chức năng): Nutri-Score/Grade, sao đánh giá, GI, % RDI, "Chuẩn mục tiêu", "An toàn", "Hội viên", "chuẩn y khoa", "Độ hoàn thiện hồ sơ", ảnh món/ảnh đại diện, "LIVE RADAR", ước lượng gram từ ảnh, thẻ nước, nhắc thông minh, danh mục món. Nút chính giữ `#006C49` (tương phản).
- **Hiển thị số:** kcal và mg là số nguyên, gram 1 chữ số thập phân (`formatNutrientAmount` ở search, `formatWhole` ở Nhật ký).
- **Icon app:** chữ F trắng + chấm mint trên nền `#006C49` (Plus Jakarta Sans, OFL). Android có icon thích ứng (`mipmap-anydpi-v26`, `values/colors.xml`) và icon cũ; iOS đủ cỡ trong `AppIcon.appiconset` (không kênh alpha). Sinh bằng script Pillow ở scratchpad; FLuw có logo riêng thì thay ảnh.
- Thư viện đang dùng (đều miễn phí, BSD/MIT/Apache): `go_router`, `flutter_riverpod`, `shared_preferences`, `drift` + `drift_flutter`, `collection`, `flutter_localizations`, `http`, `flutter_local_notifications`, `timezone`, `mobile_scanner`, `image_picker`; dev: `drift_dev`, `build_runner`.

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
- CI tạo `key.properties` và `android/app/upload-keystore.jks` từ 4 secret: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, **chỉ khi chạy trên `main`** (push, D21 ở PR #36; thêm Run workflow trên `main` từ PR #47), không bao giờ cho PR. Trên `main` mà thiếu secret thì cảnh báo và dùng debug key.
- PR (và Run workflow trên branch khác) build bằng debug key chỉ để kiểm build, không tải APK lên (kèm `::notice::`). Lượt trên `main` (chỉ `push` và `workflow_dispatch`, danh sách cho phép) tải APK lên, giữ 1 ngày (PR #47): repo Private trên GitHub Free chỉ có 500 MB lưu artifact, mỗi APK khoảng 40 MB, ngày nhiều merge có thể 6 lượt trên `main`, GitHub tính lại dung lượng chậm 6–12 giờ; đầy thì job `android-apk` đỏ và Render không deploy. Cần APK mới thì Run workflow trên `main` (re-run chỉ được trong 30 ngày).
- Biểu thức của GitHub Actions so chuỗi không phân biệt hoa thường (branch `Main` cũng khớp `refs/heads/main`), nên bước keystore kiểm lại `$GITHUB_REF` trong shell, sai thì dừng.
- Ai có APK cũng đọc được tên trong chứng chỉ ký: tạo keystore bằng `-dname "CN=Fluw"` (README), không ghi tên thật.
- Bước có `if` chỉ chặn code build (Gradle, plugin, action) đọc secret; một PR từ branch trong repo sửa chính `ci.yml` vẫn đọc được repo secret. Chặn hẳn bằng Environment `release` (việc FLuw, mục 7; repo Private trên GitHub Free không có Environments, cần GitHub Pro).
- `key.properties`, `*.jks`, `*.keystore` đã nằm trong `android/.gitignore`. Không bao giờ commit.
- `build.gradle.kts` phải `import java.util.Properties`: trong script Gradle, `java` là extension của plugin Java nên `java.util.Properties()` không compile.

### CI `.github/workflows/ci.yml` (PR #36, D21)
- 3 job giữ tên `backend`, `frontend`, `android-apk` (Render `checksPass` và quy tắc merge ở mục 1 dựa vào đó); `timeout-minutes` 10 / 30 / 45.
- Action ghim theo SHA của đúng commit tag đang trỏ tới, kèm chú thích `# vX` (checkout v5.1.0, setup-node v5.0.0, subosito/flutter-action v2.23.0, setup-java v5.7.0, upload-artifact v6.0.0; PR #42 lên Node.js 24). Nâng bản thì đổi cả SHA lẫn chú thích (tra SHA bằng `git ls-remote`).
- `cancel-in-progress` chỉ cho `pull_request`. Lượt chạy trên `main` luôn chạy xong, để Render không bỏ sót commit backend. Nhóm `concurrency` theo cả sự kiện lẫn ref (PR #47): một lượt mới vào nhóm sẽ thay lượt đang chờ trong nhóm, nên Run workflow không được thay lượt push đang chờ.
- Job `frontend` chạy `flutter test` hai lượt: UTC và `TZ=Asia/Ho_Chi_Minh`.

### Backend `backend/`
```
server.js                 khởi động, tắt an toàn khi nhận SIGTERM
src/app.js                ghép middleware và route
src/routes → controllers → services → providers (OFF, USDA, Gemini)
src/lib/                  fetchJson, ttlCache, gtin, budget
src/errors/               HttpError, UpstreamError, BudgetExceededError
src/middlewares/          noSniff, rateLimiter, notFound, errorHandler
tests/                    node:test, helper startServer
```
- Mọi câu trả lời có `X-Content-Type-Options: nosniff` (`middlewares/noSniff.js`). Nén gzip bằng gói `compression` 1.8.2 (MIT), chỉ body từ 1 KB (`/health` không nén); app Flutter (`dart:io HttpClient`) tự giải nén. Đo thật: tìm "sữa chua" từ 6.020 xuống 928 byte.
- Lỗi luôn trả `{ "error": { "code": "...", "message": "..." } }`, không lộ stack trace. `HttpError` (status, code) cho lỗi phía client; `errorHandler` giữ status 4xx của body parser (code `BAD_REQUEST`), mọi lỗi khác (kể cả có `status` 5xx) thành 500 và ghi log.
- **API tra cứu (M1a):**
  - `GET /api/foods/search?q=` (2–100 ký tự, `q` lặp thì 400): gộp Open Food Facts (`search.openfoodfacts.org`, `langs=vi,en`) và USDA (Foundation + SR Legacy), mỗi nguồn 10 món, OFF trước. Trả `{ query, items, sources: { openFoodFacts, usda } }`, trạng thái `ok` / `unavailable` / `not_configured`. Một nguồn lỗi vẫn trả nguồn còn lại; mọi nguồn lỗi thì 503 `SOURCES_UNAVAILABLE`.
  - `GET /api/foods/barcode/:code`: OFF API v2. Kiểm chữ số kiểm tra GTIN (8/12/13/14 số) trước khi gọi; sai thì 400 `INVALID_BARCODE`, không có thì 404 `PRODUCT_NOT_FOUND`.
  - Món (`FoodItem`): `{ id ("off:<mã>" | "usda:<fdcId>"), source, name, brand, barcode, imageUrl, servingSize, basis: { amount: 100, unit: "g" | "ml" }, nutrients: { energyKcal, proteinG, carbohydratesG, sugarsG, fatG, saturatedFatG, sodiumMg }, allergenTags, traceTags, attribution: { source, license, imageLicense, url } }`.
    - `null` = không có dữ liệu, 0 là thật. Số vô lý (trên 100 g/100 g, trên 900 kcal, natri trên 40.000 mg/100 g `MAX_SODIUM_MG_PER_100`; muối ăn khoảng 39.300 mg) thành `null`.
    - `allergenTags`: `null` = chưa biết (USDA, hoặc kết quả tìm kiếm OFF vì search API không trả trường này); `[]` chỉ là chưa ai ghi, **không** có nghĩa an toàn. App phải gọi `/barcode` để lấy dị ứng trước khi cảnh báo.
    - `traceTags` (PR #36): `traces_tags` của OFF ("có thể chứa"), cùng quy tắc với `allergenTags`; USDA luôn `null`. App chưa dùng (bỏ qua trường lạ). Kiểm thật: Nutella `3017624010701` trả `["en:milk","en:nuts","en:soybeans"]`.
    - Search API của OFF cũng không trả `product_name_vi`, nên tên trong kết quả tìm kiếm có thể không phải tiếng Việt.
    - OFF: đơn vị theo `nutrition_data_per` (`100ml` → ml), rồi mới theo số lượng; natri g × 1000; thiếu kcal thì đổi từ kJ ÷ 4,184. USDA: năng lượng 1008 → 2048 → 2047, đường 2000 → 1063.
    - App (M3) phải đổi `"g"`/`"ml"` sang `QuantityUnit` và từ chối giá trị lạ.
  - Mỗi nguồn hẹn giờ 8 s (`lib/fetchJson`, lỗi nào cũng thành `UpstreamError`, có `upstreamStatus` khi nguồn trả lỗi); cache trong bộ nhớ (`lib/ttlCache`): tìm kiếm 1 giờ (chỉ khi không nguồn nào lỗi), mã vạch 24 giờ, không có sản phẩm 1 giờ; tìm kiếm trùng đang chạy dùng chung một lượt gọi.
  - Từ khóa chuẩn hóa NFC trước khi dọn khoảng trắng và kiểm độ dài, nên cache và từ khóa gửi đi giống nhau dù gõ dạng tổ hợp.
  - Rate limit `/api/foods/*` 30 lượt/phút mỗi IP (`express-rate-limit`), `trust proxy` 1 vì Render đứng sau một proxy.
  - **Hạn mức chung cho cả máy chủ (PR #36, D19)** `src/lib/budget.js` (`createBudget`): đếm theo cửa sổ trượt, giới hạn số lượt chạy cùng lúc; nguồn trả 429 thì nghỉ 60 s. Lượt bị từ chối không gọi nguồn, ném `BudgetExceededError`; lượt đã tới nguồn vẫn tính kể cả khi lỗi. Gắn ở service ngay sau cache (cache trúng không tốn lượt), lắp trong `createServices(config, { now })` (đồng hồ để test).

    | Nguồn | Hạn mức | Khi vượt hoặc nguồn trả 429 |
    |---|---|---|
    | OFF tìm kiếm | 10/phút | nguồn `unavailable` (nguồn kia vẫn trả); mọi nguồn hỏng thì 503 `SOURCES_UNAVAILABLE` |
    | OFF sản phẩm (mã vạch) | 90/phút | 503 `SOURCES_UNAVAILABLE`; mã đã có trong cache vẫn trả |
    | USDA | 900/giờ | `unavailable` |
    | Gemini | 8/phút, 200/ngày (cửa sổ trượt 24 giờ), 4 ảnh cùng lúc; đổi bằng `GEMINI_MAX_PER_MINUTE`, `GEMINI_MAX_PER_DAY`, `GEMINI_MAX_CONCURRENT` (sai/thiếu thì mặc định) | 503 `RECOGNITION_BUSY`, log `[Recognition] gemini: 8 calls per 60 s` |

    - Mức công bố của nguồn: OFF 10 lượt tìm/phút và 100 lượt đọc sản phẩm/phút mỗi IP; USDA 1.000 lượt/giờ mỗi key. Mọi người dùng đi qua máy chủ Render, nên dùng chung hạn mức đó.
  - **Sửa theo QA dữ liệu thật (PR #44, FLuw duyệt 22/11):**
    - FoodItem thêm (tùy chọn) `packageQuantity`, `servingQuantity` (`{ amount, unit: "g" | "ml" } | null`; đơn vị có thể khác `basis`, app chỉ dùng khi cùng đơn vị; gói nhiều lốc lấy 1 gói, chuỗi không rõ thì null; đọc ở `providers/openFoodFacts/quantity.js`) và `nutrientsSuspect` (`areNutrientsSuspect` ở `models/nutrients.js`: P + C + F > 105 g/100, hoặc kcal lệch 4P + 4C + 9F > 30% và > 40 kcal; bỏ qua độ lệch kcal khi có cồn/polyol).
    - Basis OFF: "100ml" → ml; "100g" + kem → g; gói/khẩu phần ghi ml → ml kể cả khi OFF ghi "100g" (Coca-Cola 5449000000996: 44 kcal/100 ml); ghi g → g; nhóm đồ uống uống liền (trừ bột pha, đồ khô) → ml; còn lại g.
    - Tìm kiếm: index tìm kiếm OFF dừng khoảng 12/2024, không có số lượng gói, chỉ khớp trường tiếng Anh và không gộp dấu. Nên: đọc `/product` cho tối đa 5 món đầu thiếu kcal hoặc nghi ngờ (qua `barcodeService.find`, chung cache và hạn mức 90/phút, hẹn min(3 s, phần còn lại của 8 s); sản phẩm không còn trên OFF thì bỏ); từ có dấu tìm thêm bản bỏ dấu (`lib/foldVietnamese.js`; lượt gốc trước, cả hai qua hạn mức 10/phút; món của bản bỏ dấu phải chứa đủ mọi từ trong tên/hãng); bỏ trùng mã theo số 0 đầu và món không tên; kết quả còn thiếu chỉ cache 5 phút. `langs=vi,en` giữ nguyên (đo thật: như `en`).
    - Prompt Gemini: `searchQueryEn` chỉ cho một thực phẩm đơn, món ghép để rỗng (parser đổi thành null); bỏ ví dụ "beef pho".
  - Key USDA gửi bằng header `X-Api-Key`, không nằm trong URL. User-Agent `FluwApp/0.2 (+https://github.com/Fluw13/Fluwwwwww/issues)` (liên hệ qua Issues, không có thông tin cá nhân của FLuw).
  - `createApp(services)` nhận service để test; `src/createServices.js` lắp nguồn thật, `server.js` gọi một lần.
  - Chạy thử ở môi trường agent: Node cần `NODE_USE_ENV_PROXY=1 NODE_EXTRA_CA_CERTS=/root/.ccr/ca-bundle.crt` mới đi qua proxy (Render không cần).
- **Nhận diện ảnh (M1c):** `POST /api/foods/recognize`, thân là ảnh thô (`Content-Type` image/jpeg, png, webp, heic, heif), tối đa 4 MB (`express.raw`), rate limit riêng 6 lượt/phút mỗi IP ("Bạn gửi ảnh quá nhanh"), cộng với giới hạn chung 30/phút.
  - Gemini REST `v1beta/models/{GEMINI_MODEL}:generateContent` (mặc định `gemini-flash-latest`), key ở header `x-goog-api-key`, hẹn giờ 25 s. `responseSchema` chỉ có tên món (`nameVi`), từ khóa tiếng Việt (`searchQuery`) và tiếng Anh cho USDA (`searchQueryEn`); prompt cấm ước lượng khối lượng, calo, chất dinh dưỡng.
  - `generationConfig` **chỉ** có `responseMimeType` + `responseSchema`: không `maxOutputTokens` (model có suy nghĩ tính cả token suy nghĩ vào giới hạn, 512 thì hết chỗ trả lời → `MAX_TOKENS` rỗng), không `temperature` (Google khuyên giữ mặc định cho Gemini 3, thấp hơn có thể lặp). Hẹn giờ 25 s chặn thời gian.
  - Trả `{ isFood, foods: [{ name, searchQuery, searchQueryEn }] }` (`searchQueryEn` có thể `null`), tối đa 3 món, bỏ trùng; `isFood` true mà không còn món hợp lệ thì thành false. Bị chặn an toàn (`blockReason` hoặc `finishReason` SAFETY/IMAGE_SAFETY/...) thì coi là không có đồ ăn; phần `thought` bị bỏ; không có chữ trả lời thì `UpstreamError` ghi `finishReason`.
  - Lỗi: chưa có `GEMINI_API_KEY` → 503 `RECOGNITION_NOT_CONFIGURED`; sai kiểu ảnh 415 `UNSUPPORTED_IMAGE`; ảnh rỗng 400 `IMAGE_REQUIRED`; quá 4 MB 413 `BAD_REQUEST`; Gemini 429 (`UpstreamError` mang `upstreamStatus` 429) hoặc vượt hạn mức chung → 503 `RECOGNITION_BUSY`; ảnh sai dạng bị từ chối trước, không tốn lượt; Gemini 400 `INVALID_ARGUMENT` nói về ảnh (không phải `API_KEY_INVALID`) → 422 `IMAGE_UNREADABLE`; key sai, vùng không có gói miễn phí (`FAILED_PRECONDITION`), 403 và lỗi khác → 503 `RECOGNITION_UNAVAILABLE`. **Mọi lỗi đều ghi log** `[Recognition]` kèm status, lý do, lời nhắn của Gemini (`HttpError.detail`, không gửi cho app, không có ảnh hay key).
- `GET /api/foods/search?q=&en=`: `en` (2–100 ký tự, tùy chọn) là từ tiếng Anh chỉ gửi cho USDA (tên USDA toàn tiếng Anh); cache tách theo cả hai từ khóa.
  - Không lưu, không ghi log ảnh. `fetchJson` nhận thêm `method`, `body`, `headers`, `acceptStatuses`, `timeoutMs`.
  - `server.js` ghi log `[Config]` lúc khởi động: USDA, Gemini bật hay tắt, model và hạn mức (không ghi key), vd `[Config] USDA bật, Gemini bật (gemini-flash-latest, 8/phút, 200/ngày, 4 cùng lúc)`, để biết biến môi trường trên Render đã có hiệu lực chưa.
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
- Code dính tới giờ (`placeMeal`, `DiaryTarget`) phải chạy thêm `TZ=Asia/Ho_Chi_Minh flutter test` tại chỗ. CI chạy cả hai lượt từ PR #36.
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
- **Dữ liệu sức khỏe lưu trên máy** (SQLite): hồ sơ, Nhật ký, lịch sử tra cứu, đã lưu, món nhập thủ công, sở thích và chế độ ăn, nước uống, cân nặng. Không gửi chiều cao, cân nặng, bệnh lên server. Chỉ lưu sau khi người dùng đồng ý (D16).
- **Đánh giá sao do người dùng chấm** → cần tài khoản, server và database. Tài khoản chỉ dùng cho đánh giá; dữ liệu sức khỏe vẫn chỉ ở trên máy. Làm ở M7 với Firebase Authentication (Google/email) + PostgreSQL trên Neon + backend Node kiểm ID token. Không dùng Postgres free của Render (hết hạn sau 30 ngày).
- **Nguồn dữ liệu dinh dưỡng:**
  - Đồ đóng gói và mã vạch: Open Food Facts.
  - Đồ tươi: USDA FoodData Central (cần API key miễn phí, đặt ở Render dưới tên `USDA_API_KEY`).
  - Món Việt: Fluw **tự xây bảng dữ liệu**. Mỗi món là một công thức (nguyên liệu, số gram cho 1 suất), dinh dưỡng tính từ số liệu nguyên liệu của USDA (CC0). Trên app ghi "Ước tính theo công thức Fluw". Không chép Bảng thành phần thực phẩm Việt Nam khi chưa rõ giấy phép.
- **Scan ảnh:** Gemini Vision qua backend, chỉ để nhận ra tên thực phẩm; dinh dưỡng tra từ các nguồn trên, không lấy từ AI. Máy chủ Fluw không lưu ảnh.
- **Render:** dùng workspace "My Workspace", service `Fluw` hiện tại chạy backend mới.
- **APK:** FLuw tự tạo keystore và đưa vào GitHub Secrets.
- **Công thức BMR, TDEE, protein, mục tiêu** tính trên máy bằng Dart thuần ở `features/profile/domain/`, có unit test.
- **Chỉ người từ 18 tuổi** (FLuw chốt 18/11/2026, D1; bỏ chế độ 14–17 tuổi của quyết định 11/11). Dưới 18 tuổi không có chỉ tiêu nào; hồ sơ cũ vẫn đọc được. Người lớn là `tuổi ≥ 18`.
- **Tốc độ giảm/tăng cân:** tối đa 0,5 kg/tuần (khoảng ±550 kcal/ngày so với TDEE). Khi giảm cân, mục tiêu calo không thấp hơn `max(BMR, 1.200 kcal nữ / 1.500 kcal nam)` (D3, NHLBI: mức thấp nhất trong các kế hoạch ăn giảm cân cho người tự thực hiện, tài liệu TLC 2005; Practical Guide 2000 cho mức thấp hơn, không dùng làm nguồn; trước là chỉ BMR); mức này ≥ TDEE thì mục tiêu bằng TDEE.
- **Bệnh hỗ trợ bản đầu:**
  - Có cảnh báo tự động:
    - Tiểu đường: theo dõi đường (5% năng lượng, gọi là **mức gợi ý** cho đường tổng, D6).
    - Natri: theo dõi và đánh giá cho **mọi người lớn** (D11, PR #41; trước đó chỉ khi có huyết áp cao).
    - Mỡ máu cao: theo dõi béo bão hòa.
    - Dị ứng: theo tag dị ứng của OFF, có mức độ.
  - Chỉ lưu làm ghi chú, không cảnh báo vì không có dữ liệu purin, độ cay, GI: dạ dày, huyết áp thấp, gout, bệnh tự nhập.
- **Nhắc nhở:** nhắc theo lịch, mặc định 10:00, 17:00, 22:00, người dùng chỉnh được. Nội dung nhắc dựa trên lượng đã nạp so với mục tiêu; ăn chưa đủ thì kèm gợi ý.
- Dữ liệu từ nguồn và nội dung AI phải phân biệt rõ trên giao diện. Thiếu dữ liệu thì ghi "Chưa có dữ liệu", không hiện số 0 hay số bịa.
- Mọi đánh giá sức khỏe ghi rõ là ước tính, không thay thế tư vấn y tế.

### Kiểm tra toàn diện lần 2 (18/11/2026, FLuw giao quyền quyết định cho giám đốc)
FLuw trả lời 2 câu: app chỉ cho người từ 18 tuổi; liên hệ qua GitHub Issues. Các quyết định còn lại (D1–D24) do giám đốc (agent chính) chốt. Luồng làm: A1 (PR #38), A2 (PR #37), C (PR #39), D (PR #36), A3 (PR #41).
- **Hồ sơ an toàn (A1):**
  - D1: chỉ người từ 18 tuổi (xem trên). Bộ chọn ngày sinh tối đa là ngày tròn 18 tuổi.
  - D3: mức sàn calo khi giảm cân như trên; số tuần ước tính theo mức giảm thực tế khi bị nâng. Giám đốc thêm khi review PR #38: sàn ≥ TDEE thì mục tiêu bằng TDEE (`CalorieFloor.maintenance`), không đặt 1.200/1.500 kcal cao hơn mức tiêu hao.
  - D4: cân nặng mong muốn khi giảm cân phải cho BMI ≥ 18,5; đang thiếu cân thì không cho chọn giảm cân.
  - D5: công thức BMR Nữ thì hỏi "Bạn đang mang thai hoặc cho con bú?"; Có thì không tính calo, macro, BMI, nước; dị ứng vẫn cảnh báo.
  - D7: protein theo cân nặng tham chiếu `min(cân nặng, 24,9 × chiều cao(m)²)`; giảm mỡ giữ cơ 1,6–2,4 g/kg (Hector & Phillips 2018, trước là 1,8–2,4 không có nguồn); sức bền bỏ yoga; khoảng protein > 1,2 g/kg thì nhắc người bệnh thận hỏi bác sĩ.
  - D8: giữ số AF, ghi là "hệ số vận động thông dụng (ước tính)"; mô tả mức vận động nói về cả ngày.
  - D9: nước theo cân nặng tham chiếu, là tổng lượng nước kể cả thức ăn; 35 ml/kg là mức Fluw chọn, đối chiếu EFSA 2010.
- **Trình bày chỉ tiêu (A3, PR #41):**
  - D6: đường giữ 10% / 5% nhưng gọi là **mức gợi ý** cho đường tổng; vượt thì "Cao hơn mức gợi ý" (màu cảnh báo, không phải màu lỗi, không "vượt giới hạn").
  - D10: nhãn "Tinh bột" → "Carb (bột đường)" ở mọi chỗ hiển thị (code giữ tên); món USDA ghi "USDA: carb gồm cả chất xơ".
  - D11: natri cho mọi người lớn (WHO < 2.000 mg); béo bão hòa vẫn chỉ khi có mỡ máu cao.
  - D12: màn "Cách Fluw tính" (mở từ ⓘ ở "Chỉ tiêu mỗi ngày" và từ Về Fluw) liệt kê công thức, nguồn và các ngưỡng Fluw tự chọn (±10% calo, 80% đường, 300 kcal buổi tối, 50% một món).
  - D14: đánh giá ngày tốt là "Đạt các chỉ tiêu Fluw đang theo dõi"; calo dưới 50% mục tiêu thì "Có thể chưa ghi đủ món". Một hàm duy nhất trong `core/nutrition/` quyết định "vượt" (so theo số đã làm tròn như số hiện).
- **Pháp lý (A2):**
  - D2: bên chịu trách nhiệm "Nhà phát triển Fluw (cá nhân, GitHub: Fluw13)", liên hệ GitHub Issues; không ghi tên thật, email.
  - D15: màn "Quyền riêng tư và điều khoản" + `PRIVACY.md` cùng nội dung, theo Luật 91/2025/QH15 và Nghị định 356/2025/NĐ-CP.
  - D16: đồng ý lưu thông tin sức khỏe trước lần lưu hồ sơ đầu tiên; không đồng ý thì không lưu.
  - D17: "Xóa toàn bộ dữ liệu trên máy" (hồ sơ, Nhật ký, cân nặng, cài đặt, đồng ý, lịch nhắc; giữ Sáng/Tối), có hỏi xác nhận.
  - D18: hộp đồng ý gửi ảnh nói thêm máy chủ ở Hoa Kỳ, rút đồng ý không xóa được ảnh đã gửi Google, chỉ cho người dùng ở Việt Nam, liên kết chính sách.
- **Backend và CI (D):**
  - D19: hạn mức chung trước khi gọi nguồn ngoài (bảng ở mục 3), natri tối đa 40.000 mg/100 g, `traceTags`, nosniff, NFC, gzip.
  - D20: User-Agent `FluwApp/0.2 (+https://github.com/Fluw13/Fluwwwwww/issues)`.
  - D21: chỉ giải mã keystore khi push lên `main` (PR #47 thêm Run workflow trên `main`; PR vẫn không bao giờ); ghim action bằng SHA; `cancel-in-progress` chỉ cho PR; lượt test `TZ=Asia/Ho_Chi_Minh`; `timeout-minutes`.
- **Sản phẩm (C):**
  - D13: lọc nhanh đường ≤ 5 g/100 g (≤ 2,5 g/100 ml), protein ≥ 20 g, dưới 200 kcal.
  - D22: số giữ kiểu thiết kế "1,850 / 58.5"; giới hạn khẩu phần viết "1–2000 g".
  - D23: bảng tiếng Việt → tiếng Anh viết tay ở frontend, gửi kèm `en` cho USDA khi từ khóa khớp. Chỉ gửi khi từ khóa là đúng một thực phẩm tươi (thêm từ chỉ cách chế biến không đổi số liệu); món nấu (chiên, rán, xào, kho) và đồ khô không gửi (giám đốc chốt khi review PR #39). Bảng 30 món Việt (M1b) để đợt sau.
  - D24: món đã ăn gần đây (từ Nhật ký, không đổi schema), sửa khẩu phần/ngày/khung của món đã ghi, chip khẩu phần + mặc định theo bao bì, món không có số liệu xếp cuối. Nhập món thủ công để M3b.

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

TDEE là ước tính, không phải số calo bắt buộc phải nạp. AF là **hệ số vận động thông dụng (ước tính)**, không phải hệ số FAO/WHO; mức vận động tính cả công việc, đi lại và tập luyện.

**Mục tiêu calo:** TDEE ± tối đa khoảng 550 kcal/ngày (≤ 0,5 kg/tuần, 7.700 kcal/kg).
- Giảm cân: không thấp hơn `max(BMR, 1.200 kcal nữ / 1.500 kcal nam)` (NHLBI: mức thấp nhất trong các kế hoạch ăn giảm cân cho người tự thực hiện, tài liệu TLC 2005; Practical Guide 2000 cho mức thấp hơn, không dùng làm nguồn; giới tính Khác theo công thức BMR đã chọn). Bị nâng thì ghi "Đã nâng lên mức tối thiểu ... Ăn thấp hơn cần bác sĩ theo dõi."
- Mức sàn đó ≥ TDEE thì mục tiêu **bằng TDEE** (giữ cân), ghi rõ lý do và khuyên hỏi bác sĩ hoặc chuyên gia dinh dưỡng.
- Số tuần ước tính khi bị nâng: theo tốc độ thực tế `(TDEE − kcal) × 7 / 7700`, ghi "ít nhất khoảng N tuần (ước tính; cân thường giảm chậm dần)".
- Giữ cân, tăng cân không áp mức sàn.
- Không cho giảm cân tới BMI < 18,5, cũng không cho giảm cân khi đang BMI < 18,5.
- Mang thai hoặc cho con bú: không tính calo, macro, BMI, nước.

**Protein (g/ngày) = W × P**, W là **cân nặng tham chiếu** `min(cân nặng, 24,9 × chiều cao(m)²)` (BMR, BMI vẫn dùng cân thật).

| Nhóm | P (g/kg/ngày) |
|---|---|
| Không tập thường xuyên | 0,8 |
| Vận động nhẹ / sức bền (chạy bộ, đạp xe, bơi) | 1,2–1,4 |
| Gym / tăng cơ | 1,6–2,2 |
| Giảm mỡ giữ cơ (gym + giảm cân) | 1,6–2,4 |

Nhóm chọn theo "hình thức tập" người dùng khai (không tập / nhẹ, sức bền / gym); gym kèm mục tiêu giảm cân thì vào nhóm giảm mỡ giữ cơ. App hiện cả khoảng; coi là **đủ** khi đạt cận dưới. Đây là mức tham khảo, không phải giới hạn tối đa. Cận trên > 1,2 g/kg thì nhắc "Nếu bạn có bệnh thận, hãy hỏi bác sĩ trước khi ăn nhiều đạm." Nguồn: khoảng 1,6–2,2 là phân tích gộp Morton et al. 2018 (British Journal of Sports Medicine); 1,6–2,4 khi thâm hụt calo là Hector & Phillips 2018 (International Journal of Sport Nutrition and Exercise Metabolism); khuyến nghị chung của ISSN (Jäger et al. 2017) là 1,4–2,0. Khi hiện nguồn trên app phải ghi đúng tên nghiên cứu.

**Tinh bột, chất béo, đường (theo % năng lượng mục tiêu, FLuw chọn 11/11):**
- Chất béo = 25% kcal ÷ 9.
- Béo bão hòa < 10% kcal ÷ 9; có mỡ máu cao thì < 7%.
- Đường < 10% kcal ÷ 4; bật "giảm ngọt" hoặc có tiểu đường thì < 5%.
  - Theo WHO là đường tự do; dữ liệu OFF/USDA chỉ có đường tổng, nên ghi rõ là đường tổng. Từ A3 (D6) gọi là **mức gợi ý**, vượt thì "Cao hơn mức gợi ý".
- Tinh bột = (kcal mục tiêu − protein cận dưới × 4 − chất béo × 9) ÷ 4. Từ A3 (D10) hiển thị là "Carb (bột đường)".
  - Ra số âm (hồ sơ cực đoan, vd nặng 300 kg, tập gym, giảm cân) thì không đặt mục tiêu tinh bột, ghi "Chưa tính được"; không kẹp về 0.
- Natri (số cố định, không theo % năng lượng) < 2.000 mg/ngày (WHO), cho mọi người lớn (D11, A3).
- Chỉ có khi có kcal mục tiêu (`AdultTargets`); dưới 18 tuổi, mang thai/cho con bú thì không tính.

**Nước:** 35 ml × cân nặng tham chiếu (kg) mỗi ngày, là **tổng lượng nước kể cả nước trong thức ăn** (khoảng 70–80% đến từ đồ uống). 35 ml/kg là mức Fluw chọn, đối chiếu EFSA 2010 (nữ 2,0 lít, nam 2,5 lít). Người bệnh tim, thận cần hỏi bác sĩ. Người dùng chỉnh được (M8). Không dùng thời tiết.

**BMI** = cân nặng ÷ chiều cao(m)², hiển thị cắt xuống 0,1 (vd 22,96 hiện 22,9), thang châu Á:
- `BMI < 18,5`: thiếu cân;
- `18,5 ≤ BMI < 23`: bình thường;
- `23 ≤ BMI < 25`: thừa cân;
- `BMI ≥ 25`: béo phì.

Chỉ áp dụng khi `tuổi ≥ 18` và không mang thai/cho con bú.

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

- Môi trường cloud của agent: environment "Fluwwwwww" (personal) mở thêm `world.openfoodfacts.org`, `search.openfoodfacts.org`, `api.nal.usda.gov` (FLuw duyệt 13/11) và `productionresultssa3.blob.core.windows.net` (kho artifact của GitHub, để tải APK gửi FLuw, 26/11; link tải của GitHub có thể trỏ sang host `productionresultssa*` khác).

### Việc FLuw làm trên GitHub / Render
- Xóa 22 branch cũ trên GitHub.
- Key USDA cho môi trường agent: lần đầu (13/11) agent lưu nhầm kiểu `Authorization: Bearer` nên USDA báo `API_KEY_INVALID` (không phải lỗi của key). 14/11 lưu lại với header `X-Api-Key`, nhưng proxy chưa áp dụng (thử `X-Api-Key: DEMO_KEY` vẫn không bị thay). Key trên Render chưa có request nào để kiểm; FLuw kiểm bằng cách tìm `chicken breast` trong app (có kết quả USDA là key đúng). Đề xuất M1b dùng bộ dữ liệu tải về của USDA (CC0, không cần key) qua host `fdc.nal.usda.gov`, chờ FLuw đồng ý.
- `GEMINI_API_KEY` trên Render: đã có (log `[Config] ... Gemini bật` ngày 21/11). Kiểm lại bằng log `[Config]` sau mỗi lần deploy.
- **GitHub, ruleset cho `main` (tùy chọn; chỉ làm được khi repo public hoặc tài khoản GitHub Pro; agent không có công cụ tạo ruleset, FLuw quyết 22/11 không bắt buộc, agent vẫn chỉ merge khi CI xanh cả 3 job):** Settings → Rules → Rulesets → New branch ruleset, target `main`: bật "Require a pull request before merging", "Require status checks to pass" (chọn `backend`, `frontend`, `android-apk`), "Block force pushes" và chặn xóa branch.
- **Tùy chọn, GitHub Environment `release` cho keystore (chỉ làm được khi repo public hoặc tài khoản GitHub Pro):** PR sửa `ci.yml` vẫn đọc được repo secret. Cách chặn hẳn:
  - Tạo Environment `release` (Settings → Environments), "Deployment branches and tags" chỉ `main`; chuyển 4 secret `ANDROID_*` sang đó.
  - Agent mở một PR workflow nhỏ thêm vào job `android-apk`: `environment: ${{ github.ref == 'refs/heads/main' && (github.event_name == 'push' || github.event_name == 'workflow_dispatch') && 'release' || '' }}` (trường hợp tên rỗng cho PR chưa kiểm trên GitHub).
  - Không đặt "Required reviewers": job sẽ chờ duyệt, Render chờ CI xanh nên deploy backend cũng bị chặn.
  - Cách tạm: chỉ người tin cậy mới có quyền push branch.
- **Key Gemini (VERIFIED 22/11 qua ảnh FLuw gửi):** key thuộc "Dự án Gemini mặc định", mức thanh toán "Cấp độ miễn phí" (chưa gắn thanh toán). Giới hạn key chỉ dùng "Generative Language API": bỏ, vì key chỉ nằm trên Render và project không gắn thanh toán. Nếu sau này gắn thanh toán: đặt hạn mức chi tiêu vài đô và cảnh báo ngân sách. Nếu hạn mức miễn phí của model thấp hơn 8/phút hoặc 200/ngày: đặt `GEMINI_MAX_PER_MINUTE` / `GEMINI_MAX_PER_DAY` trên Render thấp hơn, rồi xem dòng `[Config]`.
- **Render (VERIFIED 22/11 qua ảnh FLuw gửi):** gói Hobby, "No card on file" nên không thể bị trừ tiền. Băng thông gói Hobby chưa xác minh (nguồn bên thứ ba nói 5 GB/tháng từ 1/8/2026). Tùy chọn: đổi build command sang `npm ci --omit=dev`.
- **Ẩn thông tin cá nhân khỏi repo (FLuw chọn 26/11), làm đúng thứ tự:**
  1. Settings → Emails: bật "Keep my email addresses private" và "Block command line pushes that expose my email". Trước khi bật, merge commit agent làm qua API mang email chính của tài khoản.
  2. Keystore mới bằng `-dname "CN=Fluw"` trong thư mục trống (README), cập nhật 4 secret `ANDROID_*`; bản build sau khi đổi phải gỡ app một lần.
  3. Merge PR #47 (APK chỉ lưu ở `main`, 1 ngày).
  4. Xóa mọi artifact cũ (khoảng 50 APK, 2 GB): `gh api --paginate` để lấy đủ id (mỗi trang chỉ 30), rồi `-X DELETE` từng id. Đợi 6–12 giờ để GitHub tính lại dung lượng (xem ở Billing) rồi mới làm bước 5, để lượt CI đầu tiên sau khi đổi không báo hết dung lượng.
  5. Settings → General → Change visibility → Private. Agent kiểm CI và lần deploy Render kế tiếp (Render phải còn quyền đọc repo qua GitHub).
  - Lịch sử git cũ vẫn còn thông tin cá nhân; Private chỉ ẩn, không xóa. FLuw không chọn viết lại lịch sử.
  - Ngay khi đổi Private, người ngoài không mở được `PRIVACY.md` trên GitHub, GitHub Issues (kênh liên hệ trong chính sách) và link liên hệ trong User-Agent gửi OFF (D20). Hiện chưa có người dùng ngoài FLuw nên chấp nhận; xem mục pháp lý bên dưới.
- Đã xong 12/11: keystore + 4 secret Android, Health Check `/health`, `USDA_API_KEY` trên Render.

### Pháp lý còn mở (trước khi lên cửa hàng)
- Xuất dữ liệu (JSON/CSV) cho người dùng.
- Cơ chế báo người dùng khi chính sách đổi (`PRIVACY.md` mục 9 hứa "app sẽ báo cho bạn"; hiện chỉ đồng ý sức khỏe/ảnh có phiên bản để hỏi lại).
- Google Play / App Store cần URL chính sách quyền riêng tư công khai. Từ lúc repo Private (không chỉ khi lên cửa hàng), người ngoài không mở được `https://github.com/Fluw13/Fluwwwwww/blob/main/PRIVACY.md` lẫn GitHub Issues (kênh liên hệ trong chính sách và trong User-Agent gửi OFF). Trước khi lên cửa hàng: đặt chính sách và kênh liên hệ ở chỗ công khai (vd một repo public riêng chỉ có `PRIVACY.md` + Issues), rồi sửa `PRIVACY.md`, `privacy_policy_text.dart` (tăng phiên bản), README và User-Agent backend.
- Tóm tắt quyền riêng tư ở lần mở app đầu tiên (chưa làm).
- **Chuyển dữ liệu ra nước ngoài (FLuw quyết 22/11: chưa làm; chỉ xem lại, nên hỏi luật sư, khi phát hành công khai trên cửa hàng):** từ khóa, mã vạch, IP tới Render (Hoa Kỳ), ảnh tới Google Gemini. Luật 91/2025 (Điều 20–22) và Nghị định 356/2025 có thể yêu cầu hồ sơ đánh giá tác động nộp Bộ Công an (Cục A05). Miễn trừ / hoãn 5 năm ở Điều 38 dành cho doanh nghiệp nhỏ, khởi nghiệp, không áp dụng khi xử lý dữ liệu nhạy cảm; chưa rõ cá nhân phát triển app miễn phí có thuộc diện nào. Chi tiết ở báo cáo pháp lý (legal.md mục H3, chỉ có trong scratchpad của phiên kiểm tra 18/11).
- **Google Play:** app sức khỏe phải điền Health apps declaration trung thực (dinh dưỡng, ghi bữa ăn, cân nặng; không dùng Health Connect); Play Console Help ghi app sức khỏe có thể phải dùng tài khoản Organization (cần D-U-N-S) → FLuw chọn loại tài khoản trước khi trả 25 USD. Mô tả trên cửa hàng phải có câu "không phải thiết bị y tế, không chẩn đoán, điều trị, chữa hay phòng bệnh" và nhắc hỏi chuyên gia y tế.

---

## 8. Lộ trình

| Mốc | Nội dung | Trạng thái |
|---|---|---|
| M0 | Dọn repo, khung frontend/backend, CI build APK + ký keystore, CLAUDE.md, README | Xong, PR #19 merge 11/11 (`70a58e9`), Render đã deploy |
| UI0 | Hệ thống giao diện theo thiết kế: màu, phông, header, thanh 5 tab có nút Quét nổi, đổi nhãn `AppTab` | Xong, PR #23 (`250c531`) |
| M1 | Backend: `GET /api/foods/search?q=`, `GET /api/foods/barcode/:code`, `POST /api/foods/recognize`; OFF + USDA + bảng món Việt | M1a xong (PR #29, `0a29380`, Render live 14/11); M1c Gemini xong (PR #35, `334147d`); hạn mức chung, `traceTags`, gzip (PR #36, `2ee5f97`, Render live 21/11); M1b 30 món Việt để đợt sau (D23) |
| M2 | Hồ sơ: Thiết lập + Hồ sơ, SQLite, BMI, macro theo %, nước, ghi cân nặng, sở thích và chế độ ăn, dị ứng có mức độ | Xong: công thức (M2a), SQLite (M2b), màn Hồ Sơ + Thiết lập (M2c), dị ứng, chế độ ăn, sở thích, ghi cân nặng, "Theo máy" (M2d); hồ sơ an toàn: chỉ người lớn, mức calo tối thiểu, chặn thiếu cân, mang thai, cân tham chiếu, schema v5 (PR #38, `5f43f33`) |
| M3 | Tra cứu, Chi tiết, Lịch sử & Đã lưu, nhập món thủ công | M3a (Tra cứu + Chi tiết) xong, PR #30 (`ce7c57f`); tìm đồ tươi tiếng Việt qua USDA, lọc nhanh mới, chip khẩu phần, món đã ăn gần đây (PR #39, `d32b827`); M3b (Đã lưu, Lịch sử món đã xem, nhập thủ công) sau |
| M4 | Nhật ký: lịch tuần, 4 khung, thêm/xóa món, SQLite | Xong: domain (#21), SQLite v4, màn Nhật Ký, "Thêm vào Nhật ký" ở Chi tiết; sửa món đã ghi (PR #39) |
| M5 | Quét mã vạch + nhận diện ảnh, chọn khẩu phần | Xong: M5a mã vạch, M5b nhận diện ảnh bằng Gemini miễn phí (FLuw chọn 14/11, PR #35); khẩu phần chọn ở màn Chi tiết; hộp đồng ý gửi ảnh bản 2 (PR #37) |
| M6 | Trang chủ, gợi ý nên/không nên, đánh giá cuối ngày, nhắc 10h/17h/22h | Xong: M6a (PR #33, `e714d28`), M6b nhắc ghi bữa ăn (PR #34, `5226475`); chữ đánh giá ngày và hàm "vượt" chung ở A3 (PR #41, D14) |
| Giao diện + QA thật | Giao diện theo Figma; tester thử dữ liệu OFF thật (16 lỗi B1–B16) | Xong 25/11: PR #43 (nền chung, Trang Chủ, Nhật Ký), #44 (backend B2–B6, B12, B15), #45 (Tra Cứu, Chi tiết, Quét, lỗi app B1, B4, B7–B11, B14, B16), #46 (Hồ Sơ, Thiết lập, tài liệu) |
| Kiểm tra lần 2 | Pháp lý, công thức, sản phẩm, backend (D1–D24, mục 5) | PR #36 (D, backend + CI), #37 (A2, pháp lý), #38 (A1, hồ sơ an toàn), #39 (C, sản phẩm) đã merge 21/11; #41 (A3: D6 đường là mức gợi ý, D10 "Carb (bột đường)", D11 natri cho mọi người lớn, D12 màn "Cách Fluw tính", D14) |
| M7 | Tài khoản + đánh giá sao (Firebase Auth + Neon) | Làm sau; khi bắt đầu, FLuw tạo project Firebase và database Neon |
| M8 | Nước uống: mục tiêu, thêm nhanh, lịch nhắc, cài đặt | Chờ UI0 |
| M9 | Báo cáo tuần/tháng: calo, macro, đường/natri, cân nặng, nước | Chờ M2, M4, M8 |

---

## 9. Ghi nhận kỹ thuật

- **Dữ liệu sức khỏe** là dữ liệu cá nhân nhạy cảm theo Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP (cùng hiệu lực 1/1/2026; Nghị định 356 thay Nghị định 13/2023/NĐ-CP) → giữ trên máy, chỉ xử lý khi người dùng đồng ý.
  - Chủ thể dữ liệu phải được biết dữ liệu nào bị xử lý, để làm gì, ai nhận; đồng ý chỉ có giá trị khi tự nguyện và biết rõ (im lặng không phải là đồng ý). Vì vậy có `PRIVACY.md`, màn `/privacy` và hộp đồng ý trước lần lưu hồ sơ đầu tiên.
  - Số điều khoản lấy từ nguồn thứ cấp, chưa xác nhận nguyên văn.
  - Tài khoản ở M7 cần màn đồng ý, chính sách quyền riêng tư, cho xóa tài khoản ngay trong app (yêu cầu của Google Play và App Store), cơ chế báo cáo đánh giá xấu.
- **Open Food Facts:** dữ liệu ODbL, ảnh CC BY-SA; phải ghi nguồn trên giao diện. Nhiều sản phẩm Việt Nam thiếu `categories_tags` và dinh dưỡng.
- **USDA FoodData Central:** tên thực phẩm bằng tiếng Anh. Từ khóa tiếng Việt đi qua bảng `vietnameseFoodGlossary` (PR #39) hoặc từ tiếng Anh của Gemini; chưa kiểm từng từ trong bảng với USDA thật.
- **Gradle wrapper:** `gradle-wrapper.jar` và `gradlew` bị `.gitignore` của template bỏ qua; Flutter tự tạo khi build.
- **Chữ ký APK:** từ 12/11 CI ký bằng keystore của FLuw (run `43198464929`, không còn cảnh báo thiếu secret). Bản cài trước đó ký bằng debug key nên phải gỡ một lần. Từ PR #36 chỉ build trên `main` có keystore; APK của PR ký bằng debug key, không cài đè được; từ PR #47 không còn lưu APK của PR.
- **M1, khi thêm `express.json()`:** `errorHandler` phải giữ `error.status` 4xx (JSON hỏng → 400, body quá lớn → 413) thay vì trả 500.
- **Express 5** gọi callback của `app.listen` cả khi lỗi; `server.js` đã bỏ qua nhánh lỗi để handler `'error'` xử lý.
- **Chi phí (kiểm 14/11):**
  - Render: 1 web service gói free, không có Postgres/Key Value, tắt preview. Gói free không tự tính tiền; FLuw xem mục Billing trên dashboard để chắc workspace không gắn gói trả phí.
  - GitHub: repo Private (từ khi FLuw đổi, mục 7) trên GitHub Free có 2.000 phút Actions/tháng và 500 MB lưu artifact; hết thì Actions bị chặn (không gắn thanh toán), CI đỏ và Render không deploy. Một lượt CI tốn khoảng 12 phút tính tiền (mỗi job làm tròn lên: frontend 5, android-apk 6, backend 1); 11–25/11 có khoảng 60 lượt, tức khoảng 1.500 phút/tháng ở nhịp làm nhiều. APK chỉ lưu ở `main`, 1 ngày. GitHub Pro (gói Student Developer Pack) có 3.000 phút; dung lượng artifact của Pro chưa xác minh (mạng agent chặn docs.github.com).
  - Figma Starter, Open Food Facts, USDA, phông OFL, mọi gói Flutter/npm: miễn phí. Gemini dùng gói miễn phí, có hạn mức chung ở backend (8/phút, 200/ngày); project của key ở cấp miễn phí, không gắn thanh toán (FLuw kiểm 22/11). Chưa tạo Firebase/Neon (M7): khi tạo, giữ gói free (Firebase Spark, không bật Blaze).
  - Không có lịch tự chạy (scheduled task) nào còn bật.
- **Repo đang public, FLuw chọn chuyển Private (26/11, mục 7):** khi còn public, ai cũng xem được code, CLAUDE.md, ảnh thiết kế, lịch sử commit và tải được APK. Không để thông tin cá nhân của FLuw trong repo, kể cả CLAUDE.md (14/11 đã thay ngày sinh thật trong test; 26/11 bỏ 4 ký tự cuối của key Gemini; lịch sử git cũ vẫn còn vì không force push). APK không chứa dữ liệu của người dùng (dữ liệu sức khỏe chỉ ở SQLite trên máy); 26/11 đã quét 374 file trong APK, không có email, ngày sinh, tên, trừ chứng chỉ ký của keystore cũ (mục 7, bước 2).
- **Sao lưu Android/iCloud:** mặc định bật, hệ điều hành có thể sao lưu SQLite vào tài khoản của chính người dùng; README đã ghi rõ.
- **Gemini:**
  - Gói miễn phí giới hạn lượt/phút và lượt/ngày (hết lượt hoặc vượt hạn mức chung của backend → `RECOGNITION_BUSY`), và Google có thể dùng nội dung gửi lên (kể cả cho người xem lại) để cải thiện sản phẩm → app hỏi đồng ý trước lần gửi ảnh đầu tiên, rút lại được, chỉ gửi ảnh đã xóa vị trí/thời gian chụp, không kèm dữ liệu sức khỏe.
  - Điều khoản bổ sung của Gemini API: người dùng API phải từ 18 tuổi, và (theo bản 2024–2025, chưa xác nhận được bản hiện hành vì mạng agent chặn ai.google.dev) không dùng trong dịch vụ dễ được người dưới 18 tuổi dùng → app chỉ cho người lớn, nhận diện ảnh vẫn chặn hồ sơ cũ dưới 18 tuổi.
  - **Chưa gọi Gemini thật lần nào** (môi trường agent không gửi được key). Render đã có key (log `[Config]` 21/11). FLuw thử một ảnh trong app; lỗi thì xem log `[Recognition]` trên Render.
  - `gemini-flash-latest` là tên Google trỏ tới model Flash hiện hành; đổi bằng biến `GEMINI_MODEL` nếu cần cố định.
  - Điều khoản bổ sung của Gemini API yêu cầu gói trả phí khi phục vụ người dùng ở EEA, Thụy Sĩ, Anh. Kiểm lại điều khoản trước khi lên cửa hàng; nếu vẫn dùng gói miễn phí thì chỉ phát hành ở Việt Nam.

---

## 10. Nhật ký công việc

Mục mới nhất ở trên. Mỗi mục ghi: ngày, PR, đã sửa gì ở file nào, vì sao, test đã chạy.

### 26/11/2026 — Ẩn thông tin cá nhân của FLuw (PR #47)
- **FLuw hỏi:** người khác tải APK có thấy hết thông tin của mình không.
- **Kiểm (không đổi code):**
  - Chứng chỉ ký APK của `main` (đọc bằng script Python ở scratchpad, khối APK Signature Scheme v2) và lịch sử commit (tác giả, nội dung cũ) có thông tin cá nhân; chi tiết chỉ báo FLuw trong chat, không ghi vào repo.
  - Quét 374 file trong APK (`grep -a`): không có email, ngày sinh, tên; chỉ có `Fluw13` (link GitHub công khai trong app).
  - CLAUDE.md có 4 ký tự cuối của key Gemini.
- **FLuw chọn:** chuyển repo sang Private (không viết lại lịch sử); tạo keystore mới tên trung tính ngay. Thứ tự các bước ở mục 7.
- **Sửa:**
  - `ci.yml`: chỉ tải APK lên ở lượt chạy trên `main`, giữ 1 ngày (trước là mọi lượt, 14 ngày). Repo Private chỉ có 500 MB artifact; khoảng 50 APK × 40 MB trong 14 ngày sẽ làm job `android-apk` đỏ. Run workflow trên `main` giờ cũng ký bằng keystore và lưu APK (trước chỉ push), để có APK mới mà không cần merge; PR vẫn không bao giờ nhận keystore. Nhóm `concurrency` tách theo sự kiện.
  - README: lệnh `keytool` thêm `-dname "CN=Fluw"`, chạy trong thư mục trống khi đổi keystore, APK 1 ngày và Run workflow trên `main`; Issues và `PRIVACY.md` không mở được với người ngoài khi Private.
  - CLAUDE.md: bỏ 4 ký tự key; quy tắc chỉ merge sau khi FLuw bật email riêng tư (mục 1); giới hạn của repo Private (mục 9); kênh liên hệ và URL chính sách phải dời ra chỗ công khai trước khi lên cửa hàng (mục 7).
  - Môi trường agent mở thêm host kho artifact của GitHub để tải APK gửi FLuw.
- **Sửa theo review độc lập (trước khi push):** giữ 5 ngày vẫn có thể vượt 500 MB (15 lượt `main` trong 5 ngày) → 2 ngày; re-run chỉ trong 30 ngày → Run workflow trên `main` ký và lưu APK; ruleset và Environments không có cho repo Private trên GitHub Free → ghi rõ; bản nháp ghi số commit và mã commit chứa ngày sinh, tên trong chứng chỉ → bỏ khỏi repo; xóa artifact phải `--paginate` và đợi GitHub tính lại dung lượng; `keytool` mở lại file cũ khi đổi keystore → thư mục trống; số commit có email đếm sai (đếm cả dòng người commit) → bỏ số. Review lần 2: so chuỗi không phân biệt hoa thường và điều kiện dạng loại trừ → danh sách sự kiện cho phép + kiểm `$GITHUB_REF` trong shell; 2 ngày vẫn sát 500 MB → 1 ngày; Run workflow có thể thay lượt push đang chờ → nhóm `concurrency` theo sự kiện; bỏ số dung lượng GitHub Pro chưa xác minh; bỏ ngày sinh giả và tuổi khỏi nhật ký 14/11.
- **Test:** `ci.yml` đọc bằng `yaml.safe_load`, đúng 3 job; bước keystore và bước tải APK cùng điều kiện `github.ref == 'refs/heads/main' && (github.event_name == 'push' || github.event_name == 'workflow_dispatch')`, bước debug key là phủ định (kiểm bằng bảng mọi cặp sự kiện × ref), `retention-days: 1` (bản nháp đầu hỏng YAML vì chữ `main:` trong lệnh `echo`, đã sửa). Không đổi code app, không chạy `flutter test`.

### 22–25/11/2026 — Giao diện theo Figma, tester với dữ liệu thật
- **FLuw báo (22/11):** giao diện chưa giống Figma; tìm "latte trà sữa" thấy 26 kcal/100 ml trong khi chai 440 ml; hỏi sao chưa cử tester.
- **Figma:** đọc file `2E8p4ZnGESwih1lNFyWeMA` bằng Figma MCP (danh sách frame + 1 lượt `use_figma` lấy kiểu chữ, bo góc, padding, màu, bóng của 7 màn). Ảnh app trước/sau chụp 390 dp bằng widget test tạm (`frontend/test/zz_*`, bị `.git/info/exclude`, không commit).
- **Tester (QA):** 40 từ khóa, 66 mã vạch OFF thật → 16 lỗi (B1–B16). Lỗi trà sữa: OFF chỉ có 26 kcal/100 g, không có dung tích; app làm số /100 trông như cả chai và mặc định 100.
- **PR #42:** CI lên Node.js 24 (setup-java v5.7.0, upload-artifact v6.0.0), FLuw duyệt sửa workflow.
- **PR #43** (nền chung, Trang Chủ, Nhật Ký): 630 test. **PR #44** (backend, FLuw duyệt 22/11): 135 test, 46 đột biến (45 bắt, 1 tương đương) + 6 đột biến kiểm chéo đều bắt; chạy thật OFF (latte có 26 kcal ở kết quả tìm, Coca-Cola theo ml/330 ml, Dalat Milk 500 ml, "hảo hảo" ra mì Hảo Hảo). **PR #45** (Tra Cứu, Chi tiết, Quét, lỗi app, đọc 3 trường mới): 652 test. **PR #46** (Hồ Sơ, Thiết lập, CLAUDE.md): 665 test. Mọi lượt cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze`, `dart format` sạch; không tràn ở 320×568 cỡ chữ 200%/310%.
- **Review chéo:** agent chính xem ảnh đặt cạnh Figma từng màn, đọc lại logic dùng chung (`nutrient_target_status`, `readableOn`) và backend (đọc trang sản phẩm, bản bỏ dấu, cờ nghi ngờ), ghép từng đợt không xung đột.
- **Chưa kiểm:** APK trên điện thoại thật, ảnh OFF thật trong app, USDA bằng key thật. Còn lại thấp: chip lọc nhanh chữ hơi to so với thiết kế; gõ không dấu ("tra sua") vẫn ra kết quả kém (index OFF chỉ khớp trường tiếng Anh).

### 21/11/2026 — Kiểm tra toàn diện lần 2 (giám đốc): pháp lý, công thức, sản phẩm, backend
- **Merge PR #35** (M5, `334147d`).
- **Cách làm:** 18/11 kiểm tra 4 mảng (pháp lý, dinh dưỡng, sản phẩm/frontend, backend/hạ tầng). FLuw giao quyền quyết định cho giám đốc (agent chính) và trả lời 2 câu: chỉ người từ 18 tuổi, liên hệ qua GitHub Issues. Giám đốc chốt D1–D24 (mục 5), chia 5 luồng, mỗi luồng một PR; 5 PR (#36–#39, #41) merge ngày 21/11.
- **PR #36 (D: backend + CI, D19–D21, `2ee5f97`):**
  - Backend mới: `src/lib/budget.js`, `src/errors/budgetExceededError.js`, `src/middlewares/noSniff.js`. Sửa: `app.js`, `config.js`, `createServices.js`, `errors/upstreamError.js`, `lib/fetchJson.js`, `models/nutrients.js`, `providers/gemini/client.js`, `providers/openFoodFacts/{client,mapper}.js`, `providers/usda/mapper.js`, 3 service; `server.js`, `.env.example`, gói `compression`. Bỏ code thừa `NUTRIENT_KEYS`, export `parseRecognition`.
  - Vì sao: Gemini là proxy mở (ai cũng tiêu hết hạn mức của key); OFF/USDA giới hạn theo IP của máy chủ; ảnh dồn cùng lúc có thể hết RAM; nguồn lỗi bị gọi lại mỗi lần; từ khóa chưa chuẩn hóa; thiếu nosniff; tốn băng thông.
  - CI: keystore chỉ ở push `main` (trước đây PR từ branch trong repo cũng nhận keystore); action ghim SHA; `cancel-in-progress` chỉ cho PR (trước có thể hủy lượt chạy trên `main`, Render bỏ sót commit); lượt `TZ=Asia/Ho_Chi_Minh`; `timeout-minutes`.
  - Test: `npm test` 98/98 (từ 69), chạy 3 lần đều xanh; `npm audit --omit=dev` 0 lỗ hổng. 34 đột biến, 33 bị bắt, 1 tương đương (`while` thành `if` khi bỏ lượt hết hạn). Chạy thật `node server.js` gọi OFF: `/health` có nosniff, mã vạch Nutella có `traceTags`, tìm kiếm trả `Content-Encoding: gzip`. YAML đọc bằng `yaml.safe_load`, đúng 3 job.
  - **Deploy (VERIFIED qua log Render):** `dep-dc0jtutg1s2s73e507n0` live 21/11 06:49 UTC, log `[Config] USDA bật, Gemini bật (gemini-flash-latest, 8/phút, 200/ngày, 4 cùng lúc)`.
- **PR #37 (A2: pháp lý, D2, D15–D18, `eef8797`):** `PRIVACY.md`, `features/privacy/` (màn `/privacy`), `core/privacy/health_data_consent.dart` + hộp đồng ý trước lần lưu hồ sơ đầu tiên, `core/settings/shared_preferences_provider.dart`, `app/erase_all_data*.dart` + `EraseAllDataButton`, hộp đồng ý gửi ảnh bản 2, dòng "không phải thiết bị y tế" ở Về Fluw, mô tả bệnh và giảm ngọt. Vì sao: app không có chính sách quyền riêng tư, không hỏi đồng ý trước khi lưu dữ liệu sức khỏe (dữ liệu nhạy cảm theo Luật 91/2025), không có cách xóa hết dữ liệu.
  - Test: `flutter test` 481/481 (từ 456), cả UTC và `TZ=Asia/Ho_Chi_Minh`; chính sách trong app trùng `PRIVACY.md`. 12/12 đột biến bị bắt.
- **PR #38 (A1: hồ sơ an toàn, D1, D3, D4, D5, D7, D8, D9, `5f43f33`):** `features/profile/domain/` (age, calorie_target, daily_targets, energy, health_profile, profile_validation, protein_target, water_target, mới `reference_weight`), `data/profile_mapper`, schema v5 (`drift_schema_v5.json`, steps, `.g.dart`), màn Thiết lập và Hồ Sơ, `PersonalLimits`, `personal_limits_from_profile`, Trang Chủ (`nutrition_advice`, `TodayNutritionCard`), một câu ở `PersonalCheckCard`.
  - Vì sao: sàn bằng BMR cho phép mục tiêu ~880 kcal; người thiếu cân đặt được mục tiêu giảm cân tới BMI ~9; không hỏi mang thai mà vẫn tính thâm hụt; protein theo cân thật cho người béo phì ra 41–54% năng lượng; nước 35 ml/kg không giới hạn; số tuần ước tính sai khi calo bị nâng; "giảm mỡ giữ cơ 1,8–2,4" không có nguồn; yoga không phải sức bền.
  - **Giám đốc sửa khi review:** mức tối thiểu ≥ TDEE (vd nữ 45 kg, 150 cm, 60 tuổi, ít vận động: TDEE 1.112 kcal) mà vẫn đặt 1.200 kcal là ăn dư khi muốn giảm cân → mục tiêu bằng TDEE (`CalorieFloor.maintenance`) kèm lời khuyên hỏi bác sĩ hoặc chuyên gia dinh dưỡng, có test (`df6b22c`).
  - Test: `flutter test` 530/530; migration v4→v5 có test đối chiếu dữ liệu; 16/16 đột biến bị bắt (trước phần sửa review).
- **PR #39 (C: sản phẩm và lỗi, D13, D22, D23, D24, `d32b827`):** bảng tiếng Việt → tiếng Anh (283 tên) và chuẩn hóa dấu, lọc nhanh mới, món không có số liệu xếp cuối, chip khẩu phần + mặc định theo bao bì, món đã ăn gần đây, sửa món trong Nhật ký; dùng chung `PortionInput`, `MealSlotPicker`, `portion_limits`, `QuantityUnit.symbol`.
  - Lỗi đã sửa: `AddToNoteBar` đọc ref sau `await` (rời trang khi đang ghi báo lỗi nhầm) và dùng `DateTime.now()`; `diaryTargetProvider` cũ khi đổi tab; `currentHourProvider` không làm mới khi quay lại app; hồ sơ và lần cân không cùng transaction; chữ sai khi khẩu phần trống; 502 HTML của Render báo "Máy chủ trả dữ liệu không đọc được" thay vì đang khởi động; `Info.plist` iOS còn khai báo màn ngang; dải tuần biến mất khi tải tuần mới; code chết `AppSpacing.xl`.
  - **Giám đốc sửa khi review:** chiên, rán, xào, kho, khô không còn là từ mô tả (món thêm dầu/đường/sốt, đồ khô đổi số liệu trên 100 g nhiều lần), nên "cá kho" không gửi "fish" cho USDA, có test (`5524cc4`).
  - Test: `flutter test` 583/583, cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze`, `dart format` sạch. 15 đột biến, 14 bị bắt, 1 lọt vì điều kiện thừa (`_isPlain`) → đã bỏ điều kiện.
- **PR #41 (A3: trình bày chỉ tiêu, D6, D10, D11, D12, D14):** `core/nutrition/shown_amount.dart`, `core/nutrition/fluw_thresholds.dart`, `features/methodology/` (màn `/methodology`), `PersonalLimits.tracksSodium`, `NutrientTargetKind.suggestion`, `VerdictStatus.maybeUnderLogged`, `SectionCard.trailing`; sửa Trang Chủ, Nhật Ký, nhắc nhở, Chi tiết, Hồ Sơ; `WeightLogCard` khi mang thai; B9.
  - Vì sao: đường tổng bị gọi là "giới hạn" màu đỏ dù WHO chỉ nói về đường tự do; "Tinh bột" thực ra là carbohydrate tổng (USDA gồm cả chất xơ); natri < 2 g của WHO áp cho mọi người lớn; "Ăn khá cân đối" nói quá điều app kiểm; ngày ghi thiếu món bị kết luận ăn thiếu; quy tắc "vượt" viết 5 lần theo 2 cách (Trang Chủ "Đã vượt 7 kcal" trong khi Nhật Ký 100% không báo); chưa có chỗ ghi nguồn công thức.
  - Hệ quả của D14: 25.1 / 25.0 g đường giờ là cao hơn mức gợi ý; 2,209 / 2,000 kcal giờ là vượt ±10%.
  - **Giám đốc sửa khi review:** màn ghi nguồn mức tối thiểu 1.200/1.500 kcal là NHLBI Practical Guide 2000, nhưng tài liệu đó khuyên 1.000–1.200 kcal (nữ), 1.200–1.600 kcal (nam) → đổi nguồn sang tài liệu TLC 2005 của NHLBI (kế hoạch ăn giảm cân 1.200–1.500 / 1.500–1.800 kcal), ghi rõ chương trình có bác sĩ theo dõi có thể thấp hơn; sửa cả chú thích ở `calorie_target.dart`.
  - Test: `flutter test` 619/619 (từ 583), cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze`, `dart format` sạch; 30/30 đột biến bị bắt. Chưa làm: chữ "đường" chưa thêm "tổng" ở thẻ món và tổng khung trong Nhật Ký (không phải chỗ so sánh); ngưỡng 50% một khẩu phần ở Chi tiết vẫn so theo tỉ lệ thô.
- **Chưa kiểm:** gọi Gemini thật; APK trên điện thoại thật (camera, bảng sửa món với bàn phím iPhone, `UIRequiresFullScreen` trên iPad); USDA thật với từ tiếng Anh trong bảng. Đã kiểm 22/11: CI trên `main` (run #94, `31d2f4a`) chạy bước keystore có đủ secret (không cảnh báo, bước debug key bị bỏ qua), APK 84,7 MB.
- **Chưa làm:**
  - App: xuất dữ liệu, báo khi chính sách đổi, tóm tắt quyền riêng tư lần mở đầu (mục 7).
  - Backend, CI (ngoài phạm vi D19–D21): kiểm số proxy trước app trên Render (`trust proxy`), `keepAliveTimeout`, ghi `cause.code` khi lỗi mạng, chỉ nhận JPEG/PNG theo byte đầu, Dependabot, `flutter pub get --enforce-lockfile`, kế hoạch lên Node 24.
- **Tài liệu:** CLAUDE.md (mục 2, 3, 5–10) và README.md cập nhật theo ghi chú của 4 luồng; không đổi code.

### 17/11/2026 — M5: quét mã vạch, nhận diện ảnh (M5a, M5b) và API nhận diện (M1c)
- **Merge PR #34** (M6b, `5226475`).
- **Thêm:** `features/scan/` (domain 3, data 3, presentation 5), `features/search/presentation/barcode_lookup_screen`, route `/search/barcode/:code`, `core/search/search_request`, `core/network/api_failure_message`, `ApiClient.postBytes`, `PersonalLimits.isAdult`; backend `providers/gemini/client`, `services/recognitionService`, `POST /api/foods/recognize`, tham số `en` của tìm kiếm, log `[Config]`; gói `mobile_scanner`, `image_picker`. Chi tiết ở mục 3.
- **Sửa theo review độc lập (trước khi push):**
  - **Cao:** bấm "Tìm theo tên" rồi quay lại tab Quét thì camera tắt mãi, "Tra mã" bị khóa (`go` không hoàn tất `push`) → `pop()` rồi `go()`, có test.
  - **Cao:** `maxOutputTokens: 512` với model có suy nghĩ thì Gemini trả rỗng → mọi ảnh báo lỗi → bỏ giới hạn token và `temperature`, xử lý `finishReason` (SAFETY → không có đồ ăn, MAX_TOKENS → lỗi có ghi lý do).
  - Mọi lỗi 400 của Gemini (kể cả key sai, vùng không hỗ trợ) bị báo "ảnh không đọc được" và không ghi log → phân loại theo `status`/`reason`, ghi log mọi lỗi.
  - Android hỏi quyền camera lặp lại sau khi bị từ chối; camera có thể chạy ngầm khi rời tab lúc đang mở → camera tự xử lý vòng đời như mobile_scanner, lệnh bật/tắt chạy lần lượt, bị từ chối thì chỉ thử lại khi bấm.
  - Ảnh gửi đi còn EXIF có GPS (image_picker chép lại) → `removePhotoMetadata` trước khi gửi, định dạng lạ thì không gửi; hộp thoại đồng ý nói thêm chuyện người xem lại và rút lại được.
  - Điều khoản Gemini cấm dịch vụ dễ được người dưới 18 tuổi dùng → chỉ mở nhận diện ảnh cho hồ sơ từ 18 tuổi.
  - Đồ tươi không bao giờ tới USDA (từ khóa tiếng Việt) → Gemini trả thêm `searchQueryEn`, tìm kiếm có `en`.
  - Thấp: kiểu ảnh lấy theo tên file sai → đọc byte đầu; sai chữ số kiểm tra báo riêng; giới hạn 6 ảnh/phút báo đúng chữ; semantics camera, `liveRegion`; đổi chế độ mất kết quả → `IndexedStack`; bấm hai lần khi đang mở thư viện ảnh → tắt nút; `uses-feature camera.autofocus`; rút lại đồng ý.
  - 17 đột biến lọt (8 frontend, 9 backend) → thêm test camera giả, vòng đời, ghép `fetchJson` thật với client Gemini, `createServices` với model và hẹn giờ riêng; kiểm lại 23 đột biến frontend và 19 backend: 2 lọt → 1 thêm test, 1 là code thừa (`!_isOpening` trong điều kiện camera, mở trang đã tắt `TickerMode`) → bỏ.
- **Test:** `flutter test` 456/456 (từ 420), cả UTC và `TZ=Asia/Ho_Chi_Minh`; `npm test` 69/69 (từ 55); `flutter analyze`, `dart format` sạch. Chưa kiểm: gọi Gemini thật (môi trường agent không gửi được key), camera và chọn ảnh trên máy thật, APK (job `android-apk`).

### 15/11/2026 — M6b: nhắc ghi bữa ăn
- **Merge PR #33** (M6a, `e714d28`).
- **Thêm:** `features/reminders/` (domain 4, data 4, presentation 3), `core/time/clock_provider`, chuông trên header, route `/reminders`, cấu hình Android/iOS cho thông báo hẹn giờ. Chi tiết ở mục 3.
- **Sửa theo review độc lập (trước khi push):**
  - **Cao:** `compileSdk` 36 trong khi `flutter_local_notifications` 23 cần 37 (README của plugin) → `maxOf(flutter.compileSdkVersion, 37)`.
  - **Cao:** bật rồi tắt nhắc ngay khi đang hẹn 21 nhắc thì `cancelAll` chen giữa vòng hẹn, còn 18 nhắc vẫn đến dù công tắc tắt → `replaceAll` chạy lần lượt, chỉ áp kế hoạch mới nhất.
  - Zone dự phòng `'UTC'` không có trong `timezone/data/latest.dart`; máy để múi giờ UTC không bao giờ bật được nhắc, và lỗi khởi động bị nhớ mãi → bỏ `flutter_timezone` và cơ sở dữ liệu múi giờ, gửi giờ theo zone `UTC`; khởi động lỗi thì lần sau thử lại.
  - Một giờ vừa qua lúc hẹn làm plugin ném lỗi, sau `cancelAll` thì cả tuần mất nhắc → bỏ giờ còn dưới 10 giây, mỗi nhắc một try/catch.
  - Món thiếu số đường mà vẫn hiện "đường 3 / 25 g" như tổng đủ; dòng Nhật ký hỏng bị bỏ im lặng ("chưa ghi món nào" là sai) → nói "thiếu số liệu" và số món không đọc được.
  - Nhắc có số liệu ăn uống (dòng đường gợi ý bệnh tiểu đường) hiện đủ trên màn khóa của đa số máy Android → `secret` cho nhắc có số liệu.
  - Thấp: giờ 00:00–05:59 bị coi là buổi sáng ("Bạn đã ăn sáng chưa?" lúc 3 giờ sáng) → khung khuya, lời nhắc chung; `cancelAll` xóa cả thông báo đã hiện và sẽ xóa nhắc uống nước → chỉ hủy id nhắc bữa ăn; tắt nhắc vẫn khởi động plugin mỗi lần mở app → bỏ; đổi múi giờ không hẹn lại → tính lại khi quay lại app; chú thích "trễ vài phút" sai → sửa (Android 12+ đến khoảng 1 giờ).
  - Tự tìm khi viết test: máy để 12 giờ thì ô gõ giờ của bộ chọn giờ từ chối 13–23 mà không có SA/CH để chọn → ép 24 giờ.
  - 5 đột biến lọt và scheduler chưa có test → thêm test plugin giả, provider kế hoạch, `ReminderSync`, bộ chọn giờ; kiểm lại 21 đột biến, đều bị bắt.
- **Review lần 2 (phần sửa ở trên):** H1, H2, M1–M5 đã sửa đúng. Sửa thêm:
  - Tắt nhắc mà lệnh hủy lỗi (hoặc app bị đóng giữa chừng) thì không bao giờ hủy lại, nhắc cũ vẫn đến tới 7 ngày → lúc mở app luôn gửi kế hoạch một lần (kể cả rỗng); quay lại app thì gửi trực tiếp.
  - Có dòng Nhật ký hỏng mà vẫn gợi ý "món giàu protein" → chỉ gợi ý khi không có dòng hỏng.
  - Lỗi của lượt gộp có thể về sai nơi gọi → lời gọi đến khi một lượt đang chờ thì gộp vào lượt đó và nhận cùng kết quả; khởi động lỗi chỉ xóa đúng lần thử của mình.
  - Chữ "không hiện trên màn khóa" thêm điều kiện có khóa màn hình (màn hình và README).
  - 2 đột biến lọt (áp mọi kế hoạch thay vì mới nhất, bỏ số dòng hỏng) → thêm test đếm lượt hẹn, test provider; kiểm 6 đột biến, 1 lọt vì `_wanted = null` thừa → bỏ dòng đó.
- **Test:** `flutter test` 420/420 (từ 383), cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze`, `dart format` sạch. Chưa kiểm: build APK có plugin mới (job `android-apk`), thông báo thật trên máy.

### 15/11/2026 — M6a: Trang Chủ
- **Merge PR #32** (kiểm tra toàn bộ, `aec59db`).
- **FLuw chọn (14/11):** nhận diện ảnh dùng Gemini gói miễn phí (M1c + M5b); FLuw đã có key Gemini.
- **Thêm:** `core/diary/` (chuyển `NoteEntry`, `NoteDay`, `NoteWindow`; thêm `DiaryReader`, `diaryDayProvider`), `core/widgets/nutrient_progress`, `core/time/current_hour_provider`, `PersonalLimits` thêm trường cho Trang Chủ, `features/home/` (domain 2, presentation 7). Chi tiết ở mục 3.
- **Sửa theo review độc lập (trước khi push):**
  - **Cao:** số thiếu bị coi là 0 (buổi tối báo "còn khoảng 2,083 kcal, đừng bỏ bữa" khi món không có calo; vòng ghi "Chưa có" mà dòng dưới ghi còn 2,083; Nhật ký lỗi vẫn ghi "đã nạp 0 g đường") → không tính khi thiếu, "tối đa"/"ít nhất", vòng chờ khi đang tải, `today: null` khi lỗi.
  - **Cao:** hồ sơ đọc lỗi → nút "Nhập lại hồ sơ" mở form trống, có thể ghi đè hồ sơ thật → nút mở tab Hồ Sơ (chỉ cho "Thử lại" khi lỗi đọc).
  - Dưới 18 tuổi bị bảo "thiết lập hồ sơ người lớn", dưới 14 tuổi bị bảo kiểm tra hồ sơ → `TargetsKind`.
  - Thiếu số liệu vẫn được chấm "trong giới hạn"/"cân đối" → `VerdictStatus.incomplete`; báo số món hỏng trong đánh giá hôm qua.
  - Hàng bữa ăn ở cỡ chữ 310% bóp tên khung còn 44 dp → nút xuống dưới.
  - Thấp: so vượt calo theo số làm tròn; semantics "Ghi món" nói tên khung, ô lối tắt có vai trò nút, vòng calo đọc "ít nhất"; thêm thanh natri/béo bão hòa khi theo dõi; ghi "chưa tính được" khi người lớn không có mục tiêu tinh bột; dị ứng lạc bỏ các loại hạt; gợi ý buổi tối theo `currentHourProvider`.
  - 5 đột biến lọt (cờ thuần chay, đổi béo/tinh bột, cửa sổ ngày, bỏ lọc ngày, ngưỡng 80%) → thêm test; kiểm lại 8 đột biến, đều bị bắt.
- **Test:** `flutter test` 383/383 (từ 346), cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze`, `dart format` sạch. Đã chụp Trang Chủ 390 dp (test tạm, không commit). Chưa kiểm: APK, máy thật.

### 14/11/2026 — Kiểm tra toàn bộ (chi phí, pháp lý, công thức, code, tốc độ, UI)
- **Merge PR #31** (M4, `4da2d23`).
- **Kiểm, không cần sửa:**
  - Công thức BMR, TDEE, mục tiêu calo, protein, béo/đường/tinh bột, nước, BMI, tuổi đúng mục 6.
  - Backend gọi 2 nguồn song song, cache có giới hạn, gộp tìm trùng.
  - Không còn lịch tự chạy; Render/GitHub không có gì tính phí (mục 9).
- **Đo tốc độ:**
  - Backend chạy tại chỗ gọi OFF thật: tìm 0,15–0,67 s, có cache 0,002 s, mã vạch 0,6 s.
  - SQLite với 6.570 món (3 năm): thêm/xóa ~1 ms, đọc 1 tuần 20 ms.
  - Chỉ Render free ngủ mới chậm (~50 s lần đầu).
- **Sửa:**
  - Ngày sinh thật của FLuw trong 6 file test (repo public) → ngày giả.
  - Icon app là logo Flutter (thương hiệu của Google) → icon Fluw cho Android (kể cả adaptive) và iOS.
  - Không có trang giấy phép (BSD của Flutter/gói cần kèm thông báo; OFF yêu cầu ghi nguồn) → `AboutCard` + `showLicensePage`, `registerDataLicenses`.
  - Render free ngủ làm lần tìm đầu chậm → `wakeUpBackend` khi mở app.
  - Thêm vào Nhật ký phải cuộn qua cả bảng dinh dưỡng, lệch thiết kế → `AddToNoteBar` ghim đáy.
  - Thứ Bảy/Chủ nhật bị khuất trên dải tuần → tự cuộn tới ngày đang chọn.
  - kcal hiện "42.3 kcal" ở Tra cứu, nơi khác số nguyên → `formatNutrientAmount`.
  - Code thừa: `Nutrients.asMap` (không còn dùng); `NutrientTotal.isComplete` dùng ở `DaySummaryCard`.
  - README lỗi thời (ghi "Đang xây dựng", còn Nutri-Score đã bỏ) và câu quyền riêng tư chưa nói tới sao lưu của hệ điều hành → sửa.
- **Chưa làm (báo FLuw):**
  - Trang Chủ (M6) và Quét Món (M5) vẫn là màn "Đang xây dựng"; app mở vào Trang Chủ.
  - Muốn Render không ngủ: ping định kỳ (sửa workflow, cần FLuw duyệt) hoặc gói trả phí; khuyên giữ free.
- **Sửa theo review độc lập (trước khi push):**
  - **Cao:** thanh thêm món ghim đáy bị bàn phím số che, iPhone không có nút Xong nên không thêm được với khẩu phần đã sửa → `onTapOutside` + `keyboardDismissBehavior.onDrag`, có test.
  - Trang giấy phép mở lồng trong tab Hồ Sơ (2 thanh tiêu đề, còn thanh tab) → `useRootNavigator: true`, có test.
  - Ô khung đang chọn chỉ khác nền nhạt (tương phản 1,17:1) → nền `primary`.
  - Màn ngang trên máy nhỏ còn rất ít chỗ cho nội dung → khóa màn dọc.
  - Đánh thức máy chủ chỉ lúc mở app lạnh, không test được → chuyển vào `FluwApp`, gọi cả khi quay lại app, có test.
  - README mục quyền riêng tư ghi tính năng chưa có như đã có, thiếu `/health` và ảnh tải từ OFF → tách "Đang áp dụng" / "Dự kiến".
  - Thêm test semantics và chiều cao 48 dp cho ô khung giờ.
  - User-Agent gửi OFF chưa có thông tin liên hệ (chờ FLuw).
  - Trước khi lên Google Play/App Store: chính sách quyền riêng tư, tài khoản nhà phát triển (Google $25 một lần, Apple $99/năm).
- **Test:** `flutter test` 346/346 (từ 334), cả UTC và `TZ=Asia/Ho_Chi_Minh`; `npm test` 55/55; `flutter analyze`, `dart format` sạch. Đã chụp màn Nhật Ký và Chi tiết (test tạm, không commit). Chưa kiểm: APK và icon trên máy thật (job `android-apk`).

### 14/11/2026 — M4: Nhật ký ăn uống
- **Merge PR #30** (M3a, `ce7c57f`). APK run #71 có Tra Cứu và Chi tiết.
- **Thêm:** `core/diary/` (chuyển `meal_slot`, `meal_placement` từ `features/note/domain`; thêm `meal_slot_labels`, `meal_time`, `diary_target`, `logged_food`, `food_logger`), `core/database/note_tables.dart` + schema v4, `features/note/data/` (6 file), `domain/week`, `presentation/` (6 file), `search/presentation/add_to_note_card`; `PersonalLimits.proteinMinG`; `pumpFluwApp(overrides:)`. Chi tiết ở mục 3.
- **Sửa theo review độc lập (trước khi push):**
  - **Cao:** thêm món lúc 00:00 thì ngày lấy từ `todayProvider`, khung lấy từ giờ thật → lưu 21:00 ngày mới (tương lai) → `DiaryTarget.current(now)` lấy cả ngày và khung từ một đồng hồ.
  - **Cao:** `todayProvider` cũ khi để màn mở qua nửa đêm → tự làm mới bằng Timer.
  - Nút "Thêm món vào buổi X" bỏ qua ngày và khung đang xem → `diaryTargetProvider`.
  - Hoàn tác lỗi bị nuốt; xóa liền hai món mất hoàn tác của món đầu → báo lỗi, snackbar xếp hàng.
  - Có huyết áp cao / mỡ máu cao mà tổng ngày không hiện natri / béo bão hòa; vượt giới hạn không báo → thêm dòng theo cờ theo dõi, báo vượt theo % làm tròn.
  - Dòng hỏng bị bỏ im lặng → `NoteWindow.unreadableCount`, màn báo số món hỏng.
  - Thanh tiến độ vẽ ở 0 khi chưa có dữ liệu; thiếu semantics; "Đạm" → "Protein (đạm)"; provider tuần thành autoDispose.
  - Bỏ kiểm số không hữu hạn trong `NoteRepository.add` (code chết: `NoteEntry`, `Nutrients` đã chặn).
  - Đột biến "mở rộng cửa sổ tuần" lọt test → cửa sổ thu đúng [00:00 thứ Hai, 00:01 thứ Hai sau), có test món 00:00:59 và 00:01.
  - Chưa làm (thấp): giờ cố định chưa đánh dấu ước tính; chưa chọn ngày khác ngoài ngày nhật ký từ màn Chi tiết (trừ khi đi từ Nhật ký).
- **Test:**
  - `flutter test` 334/334 (từ 301), cả UTC và `TZ=Asia/Ho_Chi_Minh`; `flutter analyze`, `dart format` sạch.
  - Migration v3→v4 có test đối chiếu dữ liệu. Luồng: Nhật ký trống, món theo ngày/khung, tổng so với hồ sơ, natri khi huyết áp cao, vượt mục tiêu/giới hạn, hồ sơ hỏng, dòng hỏng, thiếu số liệu, xóa + hoàn tác (cả xóa liền hai món), thêm từ Chi tiết (khung hiện tại và từ một khung của ngày đang xem), ghi lỗi, ranh giới tuần, 320×568 cỡ chữ 200%/310%.
  - Review chạy 9 đột biến (7 lọt); sau khi sửa, kiểm lại 13 đột biến, đều bị bắt.
  - Chưa kiểm: APK (job `android-apk`), điện thoại thật.

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
