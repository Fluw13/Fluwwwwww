# Fluw

Ứng dụng di động giúp bạn tra cứu dinh dưỡng của thực phẩm, ghi lại những gì đã ăn trong ngày và biết mình cần nạp bao nhiêu calo, protein theo chiều cao, cân nặng và mục tiêu. Trợ lý AI của app tên là **Zero**.

> Đã xong khung dự án, giao diện nền theo thiết kế (màu, phông, thanh 5 tab), công thức hồ sơ (BMR, TDEE, calo, protein, BMI, chất béo/đường/tinh bột, nước) và cách xếp món vào Nhật ký. Nội dung các màn vẫn ghi "Đang xây dựng".

## Tính năng

| Tính năng | Mô tả | Trạng thái |
|---|---|---|
| Tra cứu | Tìm calo, protein (đạm), đường, chất béo của đồ đóng gói, trái cây, đồ tươi, món nấu chín, bánh kẹo | Chưa làm |
| Quét | Quét mã vạch sản phẩm, hoặc chụp ảnh để nhận diện thực phẩm tươi (cà chua, hành...) | Chưa làm |
| Thông tin sản phẩm | Tên, ảnh, nhà cung cấp, Nutri-Score, các chỉ số dinh dưỡng, thành phần, đánh giá theo hồ sơ của bạn | Chưa làm |
| Nhật ký | Lịch theo tuần, thêm/xóa món theo 4 khung giờ, tổng theo buổi và theo ngày, đánh giá cuối ngày | Xong phần xếp món và tính tổng |
| Hồ sơ sức khỏe | Chiều cao, cân nặng, ngày sinh, giới tính, vận động, hình thức tập, mục tiêu, BMI, bệnh, dị ứng có mức độ, sở thích và chế độ ăn | Xong công thức BMR, TDEE, calo, protein, BMI, chất béo/đường/tinh bột, nước |
| Gợi ý | Calo, protein, tinh bột, chất béo, đường nên nạp; món nên/không nên dùng; nhắc theo lịch 10h, 17h, 22h (tự chỉnh được) | Chưa làm |
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

**Tổng năng lượng tiêu hao trong ngày:** `TDEE = BMR × hệ số vận động`

| Mức vận động | Hệ số |
|---|---|
| Ít vận động | 1,2 |
| Hoạt động nhẹ | 1,375 |
| Hoạt động vừa | 1,55 |
| Hoạt động nhiều | 1,725 |
| Hoạt động rất cao | 1,9 |

**Mục tiêu calo khi muốn giảm/tăng cân:** lệch khỏi TDEE tối đa khoảng 550 kcal/ngày (không quá 0,5 kg/tuần) và không bao giờ thấp hơn BMR.

**Protein:** `cân nặng(kg) × P`

| Nhóm | P (g/kg/ngày) |
|---|---|
| 14 đến dưới 18 tuổi | 0,85 |
| Từ 18 tuổi, không tập thường xuyên | 0,8 |
| Vận động nhẹ / sức bền (chạy bộ, đạp xe, yoga) | 1,2–1,4 |
| Gym / tăng cơ | 1,6–2,2 |
| Giảm mỡ giữ cơ (đang thâm hụt calo) | 1,8–2,4 |

Các mức tập luyện chỉ áp dụng từ 18 tuổi.

**Dưới 18 tuổi:** app không tính calo, vì công thức của người lớn không phù hợp với tuổi đang phát triển. Tuổi 14 đến dưới 18 chỉ hiện mức protein tham khảo và khuyên hỏi chuyên gia; dưới 14 tuổi app không tính.

**Tinh bột, chất béo, đường** tính theo % năng lượng mục tiêu:
- Chất béo khoảng 25%.
- Béo bão hòa dưới 10% (mỡ máu cao: dưới 7%).
- Đường dưới 10% (giảm ngọt hoặc tiểu đường: dưới 5%).
- Tinh bột là phần còn lại.

**Nước** khoảng 35 ml mỗi kg cân nặng. **BMI** theo thang cho người châu Á.

Mọi con số chỉ là **ước tính tham khảo**, không thay thế tư vấn của bác sĩ hay chuyên gia dinh dưỡng.

## Quyền riêng tư (thiết kế dự kiến)

- Hồ sơ sức khỏe, Nhật ký, lịch sử tra cứu, đã lưu, món nhập thủ công, sở thích, nước uống và cân nặng sẽ **chỉ lưu trên điện thoại**, không gửi lên máy chủ.
- Tài khoản chỉ dùng để chấm sao cho sản phẩm. Dữ liệu sức khỏe không gắn với tài khoản.
- Ảnh chụp để nhận diện sẽ đi qua máy chủ Fluw tới Google Gemini để nhận ra tên thực phẩm. Máy chủ Fluw không lưu ảnh; Google xử lý ảnh theo điều khoản Gemini API (với gói miễn phí, Google có thể dùng nội dung gửi lên để cải thiện sản phẩm).
- Dữ liệu sản phẩm lấy từ [Open Food Facts](https://world.openfoodfacts.org) (giấy phép ODbL) và [USDA FoodData Central](https://fdc.nal.usda.gov) (phạm vi công cộng); món Việt từ bảng dữ liệu do Fluw tự xây.

## Kiến trúc

```
Điện thoại (Flutter)
  ├─ Hồ sơ, Nhật ký, lịch sử, đã lưu, sở thích, nước, cân nặng: SQLite trên máy
  ├─ Công thức BMR / TDEE / protein: tính trên máy
  └─ Tra cứu, quét, nhận diện ảnh, đánh giá ──► Backend Fluw (Node.js, Render)
                                                  ├─ Open Food Facts (đồ đóng gói, mã vạch)
                                                  ├─ USDA FoodData Central (đồ tươi)
                                                  ├─ Bảng món Việt của Fluw
                                                  ├─ Google Gemini (nhận diện ảnh)
                                                  └─ Tài khoản + database đánh giá (M7)
```

```
frontend/   app Flutter (Android, iOS)
  lib/app/        ghép app: router, thanh điều hướng
  lib/core/       theme, widget dùng chung, ngày tháng, dinh dưỡng
  lib/features/   mỗi tính năng một thư mục: data/ (sẽ thêm), domain/ (công thức), presentation/ (màn hình)
backend/    API Node.js + Express
  src/            app.js, middlewares/; sẽ thêm routes/, controllers/, services/, providers/
  tests/
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

1. Vào tab **Actions** của repo trên GitHub, chọn lần chạy **CI** mới nhất có dấu xanh.
2. Ở mục **Artifacts**, tải **fluw-apk** (file .zip) và giải nén ra `app-release.apk`.
3. Chép file vào điện thoại, mở và cho phép "Cài ứng dụng không rõ nguồn gốc" khi được hỏi.

Khi **chưa có keystore** trong GitHub Secrets, CI ký APK bằng một khóa debug mới mỗi lần build. Lúc đó muốn cài bản mới phải gỡ bản cũ trước, và gỡ app là mất dữ liệu trên máy. Có keystore rồi thì các bản sau cài đè được, giữ nguyên dữ liệu. Riêng lần chuyển từ khóa debug sang keystore vẫn phải gỡ bản cũ một lần.

### Tạo keystore (làm một lần)

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
| M1 | API tra cứu, mã vạch, nhận diện ảnh; deploy Render |
| **M2** | Hồ sơ sức khỏe *(xong công thức; đang làm lưu dữ liệu và giao diện)* |
| M3 | Tra cứu, chi tiết sản phẩm, lịch sử & đã lưu |
| M4 | Nhật ký theo ngày và khung giờ *(phần tính toán xong)* |
| M5 | Quét mã vạch và nhận diện ảnh |
| M6 | Trang chủ, gợi ý, nhắc nhở |
| M7 | Tài khoản và đánh giá sao |
| M8 | Nước uống và nhắc uống nước |
| M9 | Báo cáo tuần/tháng |

## Bản cũ

Phiên bản trước (tra cứu thực phẩm và chấm điểm FNS) đã được gỡ ở mốc M0. Toàn bộ mã nguồn cũ vẫn xem được tại commit `df79e6b`.
