# 📋 TÀI LIỆU BÀN GIAO & TỔNG KẾT TOÀN DIỆN DỰ ÁN FLUW

> Lưu ý (29/10/2026): mục III mô tả cấu trúc backend cũ (src/index.js, geminiService.js) đã lỗi thời — xem CHANGELOG.md và backend/src/.

**Dự án:** Ứng dụng Di động Quét Mã Vạch & Trợ Lý Dinh Dưỡng Thông Minh AI  
**Tên ứng dụng:** **Fluw**  
**Tên Trợ lý AI:** **Zero**  
**Thời gian cập nhật:** 24/10/2026  
**Phiên bản:** v1.0.0 (Production Ready Build)

---

## I. TỔNG QUAN ĐỊNH VỊ DỰ ÁN
* **Ý tưởng cốt lõi:** Người dùng sử dụng camera điện thoại quét mã vạch của bất kỳ sản phẩm đồ ăn / thức uống nào trên thị trường. Ứng dụng sẽ tra cứu thành phần dinh dưỡng và kích hoạt Trợ lý AI **Zero** để phân tích sâu, chấm điểm thực phẩm và đưa ra lời khuyên cá nhân hóa.
* **Phong cách thiết kế UI/UX:** Tối giản, hiện đại, chuẩn thẩm mỹ Health-tech cao cấp (lấy cảm hứng từ Bevel Health, Apple Health và Whoop).
* **Điểm nhấn nhận diện trung tâm:** Một **vòng tròn chấm điểm lớn (140px)** nằm chính giữa màn hình với hiệu ứng phát sáng đổi màu theo 3 cấp độ:
  * 🟢 **Xanh lá (70 - 100 điểm):** Tốt cho sức khỏe, giàu dinh dưỡng tự nhiên.
  * 🟡 **Vàng (40 - 69 điểm):** Mức độ trung bình, chứa một số phụ gia hoặc đường/muối vừa phải.
  * 🔴 **Đỏ (0 - 39 điểm):** Siêu chế biến, nhiều chất béo bão hòa, natri cao, cần hạn chế.

---

## II. HỆ THỐNG TÀI NGUYÊN & HẠ TẦNG ĐÃ TRIỂN KHAI

| Thành phần | Công nghệ / Dịch vụ | Địa chỉ / Trạng thái | Ghi chú |
| :--- | :--- | :--- | :--- |
| **Kho lưu trữ (Git)** | GitHub | `https://github.com/Fluw13/Fluwwwwww` | Nhánh `main`, đã commit toàn bộ code mới nhất |
| **Backend API** | Node.js + Express | `C:\BarcodeApp\backend` | Hoạt động trơn tru |
| **Cloud Server** | Render Cloud (Free 24/7) | `https://fluw.onrender.com` | Hoạt động online toàn cầu 24/7 |
| **Trí tuệ nhân tạo** | Google Gemini Generative AI | Model `@google/genai` | Persona chuyên gia "Zero", phân tích JSON |
| **Dữ liệu thực phẩm** | OpenFoodFacts Database | Global Barcode Database | Tra cứu thông số macro, thành phần dinh dưỡng |
| **Frontend Mobile** | Flutter 3.47.8 / Dart 3.7+ | `C:\BarcodeApp\frontend` | Material 3, Clean Architecture |
| **File cài đặt test** | Android APK (Debug) | `frontend\build\app\outputs\flutter-apk\app-debug.apk` | Cài trực tiếp vào điện thoại Android |
| **Gói phát hành CH Play** | Android App Bundle (.aab) | `frontend\build\app\outputs\bundle\release\app-release.aab` | Đã ký bảo mật, sẵn sàng nộp lên Google Play |
| **Khóa ký bảo mật** | Java Keystore (JKS) | `frontend\android\app\upload-keystore.jks` | Alias: `upload`. Mật khẩu lưu trong `frontend\android\key.properties` (không đưa lên git) |

---

## III. CHI TIẾT NHỮNG GÌ ĐÃ CODE & XÂY DỰNG

### 1. Phần Backend (`C:\BarcodeApp\backend`)
* **`src/index.js`**:
  * Thiết lập Express server với Middleware `cors`, `dotenv`, `express.json()`.
  * Cung cấp endpoint kiểm tra máy chủ `GET /` và route chính `/api/product`.
* **`src/services/foodApiService.js`**:
  * Kết nối thư viện `axios` vào OpenFoodFacts API để truy vấn sản phẩm dựa theo mã barcode.
  * Chuẩn hóa và làm sạch dữ liệu dinh dưỡng (Calo, Đạm, Béo, Tinh bột, Thành phần nguyên liệu).
* **`src/services/geminiService.js`**:
  * Tích hợp Google Gemini AI với System Prompt độc quyền cho Persona **Zero**.
  * Ép định dạng đầu ra thành JSON chuẩn xác gồm:
    * `score`: Điểm số dinh dưỡng (0 - 100).
    * `verdict`: Tóm tắt nhận định trong 1 câu sắc bén.
    * `deepThink`: 3 bước suy luận chi tiết của Zero.
    * `dietaryAdvice`: Lời khuyên chế độ ăn uống thực tế.
    * `allergens`: Danh sách các cảnh báo dị ứng tiềm ẩn.
    * `healthyAlternatives`: Gợi ý thực phẩm thay thế lành mạnh hơn.
* **`src/controllers/productController.js`**:
  * Nhận mã barcode từ Frontend, gọi đồng thời dịch vụ dữ liệu và AI, phản hồi dữ liệu hoàn chỉnh về ứng dụng.

---

### 2. Phần Frontend Flutter (`C:\BarcodeApp\frontend`)
* **`lib/models/product_model.dart`**:
  * Định nghĩa cấu trúc dữ liệu `ProductModel`, `MacroNutrients`, `ZeroAnalysis`, `ThinkingStep`.
  * Xử lý parse JSON an toàn tuyệt đối với Null-Safety, fallback dữ liệu thông minh khi quét sản phẩm chưa có tên hoặc thiếu chỉ số.
* **`lib/services/api_service.dart`**:
  * Gọi API trực tiếp đến máy chủ Render Live: `https://fluw.onrender.com/api/product`.
  * Xử lý timeout và trả về thông báo lỗi thân thiện cho người dùng.
* **`lib/widgets/circular_score_ring.dart`**:
  * Vòng tròn điểm số trung tâm kích thước 140px.
  * Tự động tính toán góc quét cung tròn (`CustomPainter`) và chuyển màu động:
    * Xanh lá (`#00E676`) khi điểm >= 70.
    * Vàng cam (`#FFC107`) khi điểm từ 40 - 69.
    * Đỏ ruby (`#FF5252`) khi điểm < 40.
  * Hiệu ứng hào quang đổ bóng (ambient glow shadow) tạo cảm giác công nghệ cao cấp.
* **`lib/widgets/macro_bar.dart`**:
  * 4 thẻ chỉ số Macro dinh dưỡng với biểu tượng sinh động:
    * 🔥 Calo (Kcal)
    * 🥩 Đạm (Protein - g)
    * 🥑 Chất béo (Fat - g)
    * 🌾 Tinh bột (Carb - g)
* **`lib/screens/home_screen.dart`**:
  * Giao diện phong cách Bevel / Apple Health.
  * Thẻ tìm kiếm thông minh *"Bạn đang ăn món gì?"* hỗ trợ gõ tên hoặc mã vạch.
  * Nút camera tròn quét mã vạch trực quan.
  * Danh sách thực phẩm phổ biến gợi ý kèm nhãn Verified và điểm số trực quan.
* **`lib/screens/scanner_screen.dart`**:
  * Sử dụng thư viện `mobile_scanner: ^7.4.2`.
  * Mở camera quét mã vạch siêu nhanh, có khung căn chỉnh mã vạch và hiệu ứng quét quét.
  * Tự động điều hướng sang màn hình chi tiết ngay khi nhận diện được barcode.
* **`lib/screens/product_detail_screen.dart`**:
  * Màn hình chi tiết thực phẩm (Log Food UI):
    * Ảnh sản phẩm bo góc lớn kèm nhãn danh mục.
    * **Vòng tròn điểm số dinh dưỡng nổi bật ở giữa màn hình**.
    * Thanh Macro 4 chỉ số cân đối.
    * Khung tư duy **"Zero Deep Think"**: Hiển thị các bước suy luận phân tích sâu của AI Zero với hiệu ứng mượt mà.
    * Thẻ cảnh báo dị ứng (Allergens) dạng capsule tag.
    * Lời khuyên dinh dưỡng từ Zero và danh sách thực phẩm thay thế lành mạnh hơn.
    * Nút đen bo tròn cố định dưới đáy màn hình *"Thêm vào nhật ký (Add to log)"*.
* **`lib/main.dart`**:
  * Cấu hình Theme Material 3 hiện đại, nền sáng `#F8F9FA`, màu nhấn đen `#141414`, font chữ chuẩn công nghệ.

---

### 3. Cấu hình Android & Đóng gói phát hành
* **`android/app/build.gradle.kts`**:
  * Đã cấu hình `minSdk = 21`, tích hợp NDK phiên bản mới nhất trên máy.
  * Tích hợp trực tiếp cấu hình ký chứng chỉ `upload-keystore.jks` vào bản `release`.
  * Đã build thành công file **`app-release.aab`** đạt chuẩn 100% chính sách Google Play Store.

---

## IV. LỘ TRÌNH & NHỮNG PHẦN CÒN THIẾU CẦN PHÁT TRIỂN TIẾP

Khi bắt đầu phiên làm việc tiếp theo, chúng ta sẽ bắt tay vào thực hiện các hạng mục sau:

### 1. Cơ sở dữ liệu & Quản lý người dùng (Database & Auth)
* [ ] Tích hợp **Supabase** (hoặc Firebase) gói miễn phí trọn đời:
  * Tạo bảng `users` (đăng ký/đăng nhập bằng Google hoặc Email).
  * Tạo bảng `food_logs` để lưu trữ lịch sử các món ăn người dùng đã quét và chọn "Thêm vào nhật ký".
  * Tạo bảng `favorites` để lưu các món ăn yêu thích.

### 2. Tính năng Theo dõi Dinh dưỡng Cá nhân (Nutrition Tracking)
* [ ] Thiết lập mục tiêu calo hàng ngày (TDEE) theo cân nặng, chiều cao, mục tiêu (giảm mỡ, tăng cơ, giữ cân).
* [ ] Tính tổng Calo và tỷ lệ Macro (Đạm / Béo / Tinh bột) đã nạp trong ngày từ các món đã "Add to log".
* [ ] Biểu đồ theo dõi tiến độ tuần / tháng.

### 3. Đưa ứng dụng lên Google Play Store (CH Play)
* [ ] Đăng ký tài khoản Google Play Console (phí $25 một lần duy nhất của Google).
* [ ] Tạo bộ ảnh giới thiệu ứng dụng (App Screenshots & Feature Graphic) thể hiện vòng tròn điểm số và AI Zero.
* [ ] Tạo icon đại diện Fluw chính thức (1024x1024px).
* [ ] Viết chính sách bảo mật (Privacy Policy).
* [ ] Tải file `app-release.aab` đã tạo sẵn lên Google Play Console để duyệt và phát hành.

### 4. Tinh chỉnh & Nâng cấp Trải nghiệm Người dùng
* [ ] Bật tính năng quét offline (lưu cache các sản phẩm đã quét trong máy để khi mất mạng vẫn xem lại được).
* [ ] Cho phép người dùng chụp ảnh món ăn (chưa có mã vạch) để AI Zero nhận diện bằng hình ảnh.

---

## V. HƯỚNG DẪN KHỞI ĐỘNG NHANH CHO LẦN SAU

Khi mở lại dự án để làm việc tiếp, bạn chỉ cần mở VS Code và chạy các lệnh tương ứng:

1. **Khởi động Backend cục bộ (nếu cần test code máy chủ mới):**
   ```powershell
   cd C:\BarcodeApp\backend
   npm run dev
   ```
   *(Backend online trên Render `https://fluw.onrender.com` vẫn đang chạy 24/7 tự động).*

2. **Chạy ứng dụng Fluw trên máy tính (chế độ điện thoại Chrome):**
   ```powershell
   cd C:\BarcodeApp\frontend
   flutter run -d chrome
   ```
   *(Nhấn `F12` hoặc `Ctrl + Shift + M` để thấy giao diện điện thoại).*

3. **Cài file APK trực tiếp vào điện thoại thật:**
   * Lấy file `C:\BarcodeApp\frontend\build\app\outputs\flutter-apk\app-debug.apk`.
   * Gửi qua Zalo/Drive sang điện thoại và bấm Cài đặt.

---
*Tài liệu này được tạo tự động để đảm bảo tính liên tục 100% cho các phiên phát triển tiếp theo của dự án Fluw.*
