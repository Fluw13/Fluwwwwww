# Fluw

Ứng dụng di động giúp bạn tra cứu dinh dưỡng của thực phẩm, ghi lại những gì đã ăn trong ngày và biết mình cần nạp bao nhiêu calo, protein theo chiều cao, cân nặng và mục tiêu. Trợ lý AI của app tên là **Zero**.

**Fluw dành cho người từ 18 tuổi ở Việt Nam.** Fluw không phải thiết bị y tế; mọi con số chỉ là ước tính tham khảo.

> Dùng được: **Trang Chủ**, **Hồ Sơ**, **Tra Cứu** + Chi tiết sản phẩm, **Nhật Ký**, **Quét Món** (mã vạch và ảnh món ăn), nhắc ghi bữa ăn, **Quyền riêng tư và điều khoản**.

## Tính năng

| Tính năng | Mô tả | Trạng thái |
|---|---|---|
| Tra cứu | Tìm calo, protein (đạm), đường, chất béo của đồ đóng gói, trái cây, đồ tươi, món nấu chín, bánh kẹo | Xong: tìm kiếm, lọc nhanh (đường ≤ 5 g, protein ≥ 20 g, dưới 200 kcal trong 100 g/ml), tìm gần đây, món đã ăn gần đây. Gõ tên đồ tươi bằng tiếng Việt ("ức gà luộc", "ca chua") thì app tự tìm thêm bằng tiếng Anh ở USDA. Món Việt chưa có |
| Quét | Quét mã vạch sản phẩm, hoặc chụp ảnh để nhận diện thực phẩm | Xong: quét mã vạch trên máy, nhập mã bằng tay, nhận diện tên món qua ảnh (Google Gemini, chỉ cho người dùng ở Việt Nam) rồi tra số liệu. Chưa thử Gemini thật và camera trên điện thoại thật |
| Thông tin sản phẩm | Tên, ảnh, thương hiệu, chỉ số dinh dưỡng theo khẩu phần, đối chiếu dị ứng và chỉ tiêu theo hồ sơ, ghi nguồn dữ liệu | Xong; chọn nhanh khẩu phần (khẩu phần trên bao bì, 50/100/150/200) |
| Nhật ký | Lịch theo tuần, thêm/sửa/xóa món theo 4 khung giờ, tổng theo buổi và theo ngày, đánh giá cuối ngày | Xong: sửa khẩu phần, ngày, khung giờ của món đã ghi (có Hoàn tác) |
| Hồ sơ sức khỏe | Chiều cao, cân nặng, ngày sinh, giới tính, vận động, hình thức tập, mục tiêu, mang thai/cho con bú, BMI, bệnh, dị ứng có mức độ, sở thích và chế độ ăn | Xong |
| Gợi ý | Calo, protein, carb (bột đường), chất béo, đường, natri nên nạp; món nên/không nên dùng; nhắc theo lịch 10h, 17h, 22h (tự chỉnh được) | Xong: Trang chủ, gợi ý theo hồ sơ, đánh giá hôm qua, nhắc ghi bữa ăn (bật ở nút chuông), màn "Cách Fluw tính" ghi công thức và nguồn |
| Quyền riêng tư | Chính sách trong app, đồng ý trước khi lưu dữ liệu sức khỏe, xóa toàn bộ dữ liệu trên máy | Xong |
| Nước uống | Mục tiêu nước mỗi ngày, thêm nhanh 200/350/500 ml, lịch nhắc uống nước | Chưa làm |
| Báo cáo | Biểu đồ calo theo tuần/tháng, tỉ lệ macro, cảnh báo đường/natri, cân nặng | Chưa làm |
| Lịch sử & Đã lưu | Xem lại những gì đã tìm hoặc quét, lưu món yêu thích, nhập món thủ công | Chưa làm |
| Tài khoản và đánh giá | Đăng nhập để chấm sao cho sản phẩm | Chưa làm |

**Thanh điều hướng:** Trang Chủ · Tra Cứu · Quét Món (nút giữa) · Nhật Ký · Hồ Sơ. Thiết kế gốc ở `design/figma/`.

**Khung giờ trong Nhật ký:** Sáng 06:00–12:00 · Trưa/Chiều 12:01–18:00 · Tối 18:01–24:00 · Khuya/Đêm 00:01–05:59. Khung Khuya tính vào ngày mới; riêng 00:00 tính là 24:00 của ngày hôm trước.

## App tính nhu cầu thế nào

**Năng lượng cơ bản (BMR, công thức Mifflin–St Jeor)**
- Nam: `BMR = 10 × cân nặng(kg) + 6,25 × chiều cao(cm) − 5 × tuổi + 5`
- Nữ: `BMR = 10 × cân nặng(kg) + 6,25 × chiều cao(cm) − 5 × tuổi − 161`

**Tổng năng lượng tiêu hao trong ngày:** `TDEE = BMR × hệ số vận động` (hệ số thông dụng, là ước tính; mức vận động tính cả công việc, đi lại và tập luyện).

| Mức vận động | Hệ số |
|---|---|
| Ít vận động | 1,2 |
| Hoạt động nhẹ | 1,375 |
| Hoạt động vừa | 1,55 |
| Hoạt động nhiều | 1,725 |
| Hoạt động rất cao | 1,9 |

**Mục tiêu calo khi muốn giảm/tăng cân:** lệch khỏi TDEE tối đa khoảng 550 kcal/ngày (không quá 0,5 kg/tuần).
- Khi giảm cân, không thấp hơn BMR và không thấp hơn **1.200 kcal (nữ) / 1.500 kcal (nam)**. Đây là mức thấp nhất trong các kế hoạch ăn giảm cân NHLBI (Viện Tim, Phổi và Máu Hoa Kỳ) đưa cho người tự thực hiện; ăn thấp hơn cần bác sĩ theo dõi. Nếu mức tối thiểu này đã bằng hoặc cao hơn TDEE, app để mục tiêu bằng mức giữ cân và khuyên hỏi bác sĩ.
- Không cho đặt mục tiêu giảm cân xuống mức thiếu cân (BMI dưới 18,5), và không cho giảm cân khi đang thiếu cân.

**Protein:** `cân nặng tham chiếu(kg) × P`. Cân nặng tham chiếu là cân nặng thật, nhưng không quá mức ứng với BMI 24,9.

| Nhóm | P (g/kg/ngày) |
|---|---|
| Không tập thường xuyên | 0,8 |
| Vận động nhẹ / sức bền (chạy bộ, đạp xe, bơi) | 1,2–1,4 |
| Gym / tăng cơ | 1,6–2,2 |
| Giảm mỡ giữ cơ (gym + giảm cân) | 1,6–2,4 |

Người có bệnh thận nên hỏi bác sĩ trước khi ăn nhiều đạm.

**Mang thai hoặc cho con bú:** app không tính calo, đạm, BMI và nước (nhu cầu khác người thường, hãy hỏi bác sĩ); dị ứng vẫn được cảnh báo.

**Carb (bột đường), chất béo, đường** tính theo % năng lượng mục tiêu:
- Chất béo khoảng 25%.
- Béo bão hòa dưới 10% (mỡ máu cao: dưới 7%).
- Đường tổng dưới 10% (giảm ngọt hoặc tiểu đường: dưới 5%). Đây là **mức gợi ý**, không phải giới hạn: WHO khuyên về đường tự do, còn dữ liệu sản phẩm chỉ có đường tổng. Cao hơn thì app ghi "Cao hơn mức gợi ý".
- Carb là phần còn lại (số liệu USDA tính cả chất xơ).
- Natri dưới 2.000 mg/ngày (WHO), theo dõi cho mọi người lớn.

App so "vượt" theo đúng số đang hiện trên màn (kcal, mg là số nguyên; gram 1 chữ số thập phân). Công thức, nguồn và các ngưỡng Fluw tự chọn xem trong app: Hồ Sơ → nút ⓘ ở "Chỉ tiêu mỗi ngày", hoặc Về Fluw → "Cách Fluw tính".

**Nước** khoảng 35 ml mỗi kg cân nặng tham chiếu, tính cả nước trong thức ăn. **BMI** theo thang cho người châu Á.

Mọi con số chỉ là **ước tính tham khảo**, không thay thế tư vấn của bác sĩ hay chuyên gia dinh dưỡng.

## Quyền riêng tư

Bản đầy đủ: [`PRIVACY.md`](PRIVACY.md), cũng có trong app (Hồ Sơ → Về Fluw → Quyền riêng tư và điều khoản). Liên hệ, góp ý: [GitHub Issues](https://github.com/Fluw13/Fluwwwwww/issues) (trang công khai, đừng đăng thông tin sức khỏe ở đó).

Căn cứ: Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP (hiệu lực 1/1/2026). Thông tin sức khỏe là dữ liệu cá nhân nhạy cảm, nên app phải nói rõ dữ liệu nào được xử lý, để làm gì, ai nhận, và chỉ lưu khi bạn đồng ý.

- Hồ sơ sức khỏe, Nhật ký, cân nặng, giờ nhắc, lịch sử tìm kiếm **chỉ lưu trên điện thoại**; Fluw không gửi chúng lên máy chủ. App hỏi bạn đồng ý trước lần lưu hồ sơ đầu tiên. Nếu bạn bật sao lưu của Android (Google) hoặc iCloud, hệ điều hành có thể sao lưu dữ liệu app vào tài khoản của chính bạn.
- Xóa hết: Hồ Sơ → **"Xóa toàn bộ dữ liệu trên máy"** (giữ lại chế độ Sáng/Tối), hoặc gỡ app.
- Khi tra cứu, app gửi từ khóa hoặc mã vạch (kèm địa chỉ IP) lên máy chủ Fluw (Render, Hoa Kỳ); máy chủ hỏi tiếp Open Food Facts (Pháp) và USDA (Hoa Kỳ). Mỗi lần mở app, app gọi máy chủ một lần (`/health`, không kèm dữ liệu) để máy chủ gói miễn phí thức dậy sớm.
- Ảnh sản phẩm tải thẳng từ Open Food Facts, nên họ thấy địa chỉ IP của bạn.
- Quét mã vạch chạy trên điện thoại (Android: Google ML Kit, iPhone: Apple Vision); hình camera không rời máy. ML Kit có thể gửi cho Google thông tin thiết bị và hiệu năng (không có hình camera).
- Nhận diện món qua ảnh: chỉ khi bạn chụp hoặc chọn ảnh, chỉ cho người dùng ở Việt Nam, và app hỏi đồng ý trước lần đầu (rút lại được trong màn Quét). App xóa vị trí (GPS) và thời gian chụp trước khi gửi. Ảnh đi qua máy chủ Fluw tới Google Gemini (Hoa Kỳ), không kèm dữ liệu sức khỏe. Máy chủ Fluw không lưu ảnh; với gói miễn phí, Google có thể lưu ảnh và cho người xem lại, và rút lại đồng ý không xóa được ảnh đã gửi. Đừng chụp người hay giấy tờ. Số liệu dinh dưỡng vẫn lấy từ Open Food Facts/USDA, không lấy từ AI.
- Nhắc ghi bữa ăn chạy trên điện thoại. Trên Android có khóa màn hình, nhắc có số liệu ăn uống không hiện trên màn khóa; trên iPhone, nội dung hiện theo cài đặt Xem trước của máy. Điện thoại có thể gửi nhắc muộn hơn giờ đặt (Android 12 trở lên thường trong vòng 1 giờ).
- Dữ liệu sản phẩm lấy từ [Open Food Facts](https://world.openfoodfacts.org) (ODbL) và [USDA FoodData Central](https://fdc.nal.usda.gov) (phạm vi công cộng). Giấy phép đầy đủ: Hồ Sơ → Về Fluw.

**Khi cập nhật app:** hồ sơ nữ lưu từ bản cũ sẽ được hỏi câu mang thai/cho con bú (chỉ tiêu tạm ẩn tới khi trả lời); người đã đồng ý gửi ảnh ở bản cũ sẽ được hỏi lại; lần lưu hồ sơ kế tiếp sẽ hỏi đồng ý lưu thông tin sức khỏe.

Dự kiến, chưa làm: xuất dữ liệu ra file; báo trong app khi chính sách đổi; tài khoản (chỉ dùng để chấm sao, dữ liệu sức khỏe không gắn với tài khoản).

## Kiến trúc

```
Điện thoại (Flutter)
  ├─ Hồ sơ, Nhật ký, cân nặng (sau này: đã lưu, nước): SQLite trên máy; cài đặt, đồng ý: bộ nhớ cài đặt trên máy
  ├─ Công thức BMR / TDEE / protein: tính trên máy
  └─ Tra cứu, quét, nhận diện ảnh ──► Backend Fluw (Node.js, Render)
                                        ├─ Open Food Facts (đồ đóng gói, mã vạch)
                                        ├─ USDA FoodData Central (đồ tươi)
                                        ├─ Google Gemini (nhận diện ảnh)
                                        └─ (sau này) bảng món Việt, tài khoản + đánh giá (M7)
```

```
frontend/   app Flutter (Android, iOS)
  lib/app/        ghép app: router, thanh điều hướng, nối các tính năng
  lib/core/       theme, widget dùng chung, ngày tháng, dinh dưỡng, database, mạng
  lib/features/   mỗi tính năng một thư mục: data/, domain/ (công thức), presentation/ (màn hình)
backend/    API Node.js + Express
  src/            app.js, routes/, controllers/, services/, providers/, lib/, middlewares/
  tests/
PRIVACY.md  chính sách quyền riêng tư
```

## Chạy trên máy

Yêu cầu: Flutter 3.47.9, Node.js 22.9 trở lên (bản 22.x).

```bash
cd backend
npm install
npm test
npm run dev
```

```bash
cd frontend
flutter pub get
flutter test
flutter run
```

## Cài APK lên điện thoại Android

1. Vào tab **Actions** của repo trên GitHub, chọn lần chạy **CI** mới nhất có dấu xanh **của branch `main`** (cột branch ghi `main`, sự kiện `push`).
2. Ở mục **Artifacts**, tải **fluw-apk** (file .zip) và giải nén ra `app-release.apk`.
3. Chép file vào điện thoại, mở và cho phép "Cài ứng dụng không rõ nguồn gốc" khi được hỏi.

Chỉ bản build từ `main` được ký bằng keystore của bạn, nên cài đè được bản cũ và giữ nguyên dữ liệu. APK của Pull Request ký bằng khóa debug: không cài đè được bản đã cài từ `main` (phải gỡ app, mất dữ liệu), nên chỉ dùng để thử nhanh trên máy khác. Trên `main` mà thiếu secret keystore thì CI cũng dùng khóa debug và báo cảnh báo.

### Tạo keystore (làm một lần, đã xong 12/11/2026)

1. Tạo file keystore. Lệnh `keytool` có sẵn trong JDK:

   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Trên Windows, nếu không gọi được `keytool` thì dùng bản đi kèm Android Studio (PowerShell):

   ```powershell
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Mật khẩu: **chữ cái không dấu và số, tối thiểu 6 ký tự**. Nếu được hỏi mật khẩu riêng cho key thì nhập **giống hệt** mật khẩu keystore.

2. Chuyển file sang dạng base64 (chạy trong thư mục chứa `upload-keystore.jks`):
   - Windows (PowerShell): `[Convert]::ToBase64String([IO.File]::ReadAllBytes("$PWD\upload-keystore.jks")) | Set-Content -NoNewline -Encoding ascii keystore-base64.txt`
   - macOS: `base64 -i upload-keystore.jks -o keystore-base64.txt`
   - Linux: `base64 -w 0 upload-keystore.jks > keystore-base64.txt`

3. Trên GitHub: **Settings → Secrets and variables → Actions → New repository secret**, thêm 4 secret:

   | Tên | Giá trị |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | nội dung file `keystore-base64.txt` |
   | `ANDROID_KEYSTORE_PASSWORD` | mật khẩu keystore |
   | `ANDROID_KEY_ALIAS` | `upload` |
   | `ANDROID_KEY_PASSWORD` | giống hệt mật khẩu keystore |

4. Xóa `keystore-base64.txt`.
5. Cất `upload-keystore.jks` và mật khẩu ở nơi an toàn: mất chúng thì không cập nhật được app trên Google Play.
6. Không commit file `.jks`, không gửi file hay mật khẩu cho ai, kể cả trong chat.

## Lộ trình

| Mốc | Nội dung |
|---|---|
| M0 | Khung dự án, CI build và ký APK *(xong)* |
| UI0 | Hệ thống giao diện theo thiết kế: màu, phông, thanh 5 tab *(xong)* |
| M1 | API tra cứu, mã vạch, nhận diện ảnh; deploy Render *(xong, còn bảng món Việt)* |
| M2 | Hồ sơ sức khỏe *(xong)* |
| M3 | Tra cứu, chi tiết sản phẩm, lịch sử & đã lưu *(xong tra cứu và chi tiết)* |
| M4 | Nhật ký theo ngày và khung giờ *(xong)* |
| M5 | Quét mã vạch và nhận diện ảnh *(xong)* |
| M6 | Trang chủ, gợi ý, nhắc nhở *(xong)* |
| Kiểm tra lần 2 | Pháp lý, công thức an toàn, tra cứu tiếng Việt, backend *(xong)* |
| M7 | Tài khoản và đánh giá sao |
| M8 | Nước uống và nhắc uống nước |
| M9 | Báo cáo tuần/tháng |

## Bản cũ

Phiên bản trước (tra cứu thực phẩm và chấm điểm FNS) đã được gỡ ở mốc M0. Toàn bộ mã nguồn cũ vẫn xem được tại commit `df79e6b`.
