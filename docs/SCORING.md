# Điểm Fluw — đặc tả `fluw-score-1.0`

Tài liệu chính thức về cách Fluw tính điểm. Code nằm ở `backend/src/scoring/`. Mọi thay đổi về ngưỡng, dải, trọng số hoặc quy tắc dữ liệu phải **tăng phiên bản** trong `backend/src/scoring/scoreVersion.js` và ghi vào mục "Lịch sử phiên bản" cuối file này.

- Điểm do **backend** tính bằng quy tắc xác định. AI (Zero) chỉ giải thích, không chấm và không sửa điểm.
- App hiển thị đúng số backend trả về, không tự tính lại.
- Dữ liệu: Open Food Facts (ODbL; ảnh CC BY-SA).

## 1. Công thức tổng

```
Điểm Fluw = làm_tròn( Điểm dinh dưỡng × 0,7 + Điểm phụ gia × 0,3 )
```

- Làm tròn đến số nguyên gần nhất; phần .5 làm tròn lên.
- **Chỉ có điểm tổng khi có đủ cả hai điểm thành phần.** Thiếu một trong hai thì điểm tổng = "Chưa đủ dữ liệu". App vẫn hiện điểm thành phần còn lại, ghi rõ là điểm riêng phần.
- Mức đánh giá (backend tính, app chỉ hiển thị):
  - ≥ 70: Tốt
  - 40–69: Trung bình
  - < 40: Nên hạn chế
- Ví dụ: 80 × 0,7 + 60 × 0,3 = 56 + 18 = **74/100 → Tốt**.

---

## 2. Điểm dinh dưỡng (trọng số 70%)

### 2.1. Phương pháp
- Dùng thuật toán công khai **Nutri-Score bản cập nhật 2022 (thực phẩm) và 2023 (đồ uống)** của Ủy ban khoa học Nutri-Score để tính **điểm thô**, sau đó quy đổi sang thang 0–100 (mục 2.5).
- Các ngưỡng bên dưới đã **đối chiếu từng con số** với `lib/ProductOpener/Nutriscore.pm`, bản cài đặt đang chạy của Open Food Facts (commit `d67e1ce`, 29/10/2026).
- Fluw **tự viết code** theo các ngưỡng đã công bố, không sao chép code của Open Food Facts (code đó theo giấy phép AGPL; nếu sao chép sẽ buộc toàn bộ backend Fluw phải theo AGPL).
- So sánh dùng dấu ">" nghiêm ngặt: giá trị **bằng** ngưỡng thì chưa bị tính thêm điểm. Riêng tỷ lệ béo bão hòa dùng "≥".
- Giá trị được làm tròn **đúng như app hiển thị** trước khi so ngưỡng (kJ đến 0,1; gam và % đến 0,01). Nhờ vậy sai số tính toán (ví dụ muối 1,4000000000000001 g khi quy đổi từ natri) không tạo ra điểm mà người dùng không thấy.

### 2.2. Loại sản phẩm (quyết định dùng bảng nào)
Lấy theo danh mục Open Food Facts (các cờ `is_beverage`, `is_water`, `is_cheese`, `is_fat_oil_nuts_seeds`, `is_red_meat_product` do OFF tính từ danh mục):

| Loại | Khác biệt |
|---|---|
| Thực phẩm chung | Bảng chuẩn |
| Đồ uống (gồm sữa và đồ uống từ sữa) | Bảng năng lượng, đường, đạm, rau củ riêng; có thêm điểm trừ chất tạo ngọt không đường |
| Nước | Luôn 100 điểm dinh dưỡng |
| Dầu, mỡ, hạt | Năng lượng tính theo "năng lượng từ béo bão hòa"; béo bão hòa tính theo tỷ lệ béo bão hòa / béo tổng |
| Phô mai | Luôn tính điểm đạm |
| Thịt đỏ | Điểm đạm tối đa 2 |

**Khi OFF không có danh mục** (rất phổ biến với hàng Việt): "Chưa đủ dữ liệu: chưa xác định được loại sản phẩm". **Không chấm** (quyết định của chủ dự án, giống cách Open Food Facts làm).

### 2.3. Bảng ngưỡng điểm trừ (trên 100 g hoặc 100 ml)
Mỗi lần vượt **qua** một ngưỡng được +1 điểm trừ.

| Chỉ số | Thực phẩm (ngưỡng) | Tối đa | Đồ uống (ngưỡng) | Tối đa |
|---|---|---|---|---|
| Năng lượng (kJ) | 335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350 | 10 | 30, 90, 150, 210, 240, 270, 300, 330, 360, 390 | 10 |
| Đường (g) | 3,4 · 6,8 · 10 · 14 · 17 · 20 · 24 · 27 · 31 · 34 · 37 · 41 · 44 · 48 · 51 | 15 | 0,5 · 2 · 3,5 · 5 · 6 · 7 · 8 · 9 · 10 · 11 | 10 |
| Chất béo bão hòa (g) | 1 · 2 · 3 · 4 · 5 · 6 · 7 · 8 · 9 · 10 | 10 | như thực phẩm | 10 |
| Muối (g) | 0,2 · 0,4 · … · 4,0 (bước 0,2) | 20 | như thực phẩm | 20 |
| Chất tạo ngọt không đường | — | — | có ít nhất 1 chất thì +4 | 4 |
| *Dầu/mỡ/hạt:* năng lượng từ béo bão hòa (kJ) | 120 · 240 · … · 1200 (bước 120) | 10 | | |
| *Dầu/mỡ/hạt:* tỷ lệ béo bão hòa/béo (%, dùng ≥) | 10 · 16 · 22 · 28 · 34 · 40 · 46 · 52 · 58 · 64 | 10 | | |

### 2.4. Bảng ngưỡng điểm cộng

| Chỉ số | Thực phẩm (ngưỡng) | Tối đa | Đồ uống (ngưỡng) | Tối đa |
|---|---|---|---|---|
| Đạm (g) | 2,4 · 4,8 · 7,2 · 9,6 · 12 · 14 · 17 | 7 | 1,2 · 1,5 · 1,8 · 2,1 · 2,4 · 2,7 · 3,0 | 7 |
| Chất xơ (g) | 3,0 · 4,1 · 5,2 · 6,3 · 7,4 | 5 | như thực phẩm | 5 |
| Rau củ, quả, đậu (%) | >40 → 1; >60 → 2; >80 → 5 | 5 | >40 → 2; >60 → 4; >80 → 6 | 6 |

**Quy tắc tính đạm:**
- Đồ uống và phô mai: luôn tính.
- Dầu/mỡ/hạt: chỉ tính khi tổng điểm trừ < 7.
- Thực phẩm khác: chỉ tính khi tổng điểm trừ < 11.
- Khi không được tính, chỉ số đạm vẫn hiện trong bảng với trạng thái "Không tính theo quy tắc", kèm lý do.

**Điểm thô = tổng điểm trừ − tổng điểm cộng.**

### 2.5. Quy đổi điểm thô sang thang 0–100 (công thức riêng của Fluw)
Mỗi dải điểm thô tương ứng một dải 0–100. Bên trong mỗi dải, quy đổi tuyến tính:
`điểm = điểm_cao − (điểm_thô − thô_đầu) × (điểm_cao − điểm_thấp) / (thô_cuối − thô_đầu)`

| Dải | Thực phẩm (điểm thô) | Dầu/mỡ/hạt | Đồ uống | → Điểm dinh dưỡng |
|---|---|---|---|---|
| 1 | −17 … 0 | −17 … −6 | chỉ nước (= 100) | 80–100 |
| 2 | 1 … 2 | −5 … 2 | −18 … 2 | 70–79 |
| 3 | 3 … 10 | 3 … 10 | 3 … 6 | 40–69 |
| 4 | 11 … 18 | 11 … 18 | 7 … 9 | 20–39 |
| 5 | 19 … 55 | 19 … 55 | 10 … 54 | 0–19 |

- Ranh giới dải trùng ranh giới hạng A–E của Nutri-Score 2023. Vì vậy, khi chỉ có điểm dinh dưỡng, màu ≥70 / 40–69 / <40 khớp với các hạng A–B / C / D–E.
- Fluw **không hiển thị chữ A–E, không dùng logo hay màu nhãn Nutri-Score** (nhãn hiệu đã đăng ký). App chỉ ghi "tham khảo thuật toán công khai Nutri-Score (cập nhật 2022–2023)".

### 2.6. Dữ liệu thiếu
| Trường hợp | Xử lý | Lý do |
|---|---|---|
| Thiếu năng lượng, béo, béo bão hòa, đường, muối/natri hoặc đạm | Điểm dinh dưỡng = "Chưa đủ dữ liệu", liệt kê chỉ số thiếu | Giống Open Food Facts; thiếu chỉ số trừ thì điểm sẽ đẹp giả |
| Không xác định được loại sản phẩm (OFF chưa có danh mục) | "Chưa đủ dữ liệu", không chấm | Quyết định của chủ dự án |
| Béo = 0 mà thiếu béo bão hòa · Carb = 0 mà thiếu đường | Béo bão hòa = 0 · Đường = 0 | Suy ra trực tiếp từ nhãn (giống OFF), ghi chú rõ |
| Chỉ có natri | Muối = natri × 2,5 | Quy đổi chuẩn |
| Chỉ có kcal | kJ = kcal × 4,184 | Quy đổi chuẩn |
| Thiếu chất xơ hoặc % rau củ quả | "Chưa đủ dữ liệu", **không chấm** | Quyết định của chủ dự án: không suy diễn thành điểm tốt hay xấu. (OFF thì tính 0 điểm cộng.) % rau củ quả do OFF ước tính (từ danh sách thành phần hoặc theo danh mục sản phẩm) được dùng, kèm ghi chú "ước tính" và nguồn ước tính |
| Đồ uống không có danh sách thành phần, hoặc hơn một nửa thành phần chưa nhận diện | "Chưa đủ dữ liệu" (không biết có chất tạo ngọt hay không; OFF đếm chất tạo ngọt từ chính danh sách thành phần đã nhận diện) | **Chặt hơn OFF** (OFF giả định là không có), theo nguyên tắc "không suy diễn thành điểm tốt". Cùng điều kiện tin cậy với điểm phụ gia (mục 3.1) |
| Sản phẩm cần pha (mì gói, bột pha uống, siro…) mà chỉ có số liệu dạng khô | "Chưa đủ dữ liệu: cần số liệu sau khi pha" | Giống OFF. Chấm dạng khô sẽ sai (ví dụ mì Hảo Hảo 450 kcal/100 g dạng khô) |
| Loại sản phẩm mà OFF đánh dấu "không áp dụng" (đồ uống có cồn, thực phẩm trẻ nhỏ…) | "Phương pháp không áp dụng cho loại sản phẩm này" | Giống OFF |

---

## 3. Điểm phụ gia (trọng số 30%)

### 3.1. Khi nào dữ liệu phụ gia được coi là kiểm chứng được
- Open Food Facts đã phân tích danh sách thành phần (`ingredients_n > 0`), **và**
- Không quá 50% thành phần là "không nhận diện được" (`unknown_ingredients_n ≤ ingredients_n / 2`). Đây là tiêu chí chính OFF dùng để quyết định có xếp nhóm NOVA hay không.

Không thỏa một trong hai điều kiện → "Chưa đủ dữ liệu phụ gia". **Không coi là 0 phụ gia.**

### 3.2. Đếm phụ gia
- Đếm số phụ gia **khác nhau** trong `additives_tags`. Mã cha (chỉ gồm số) và mã con chỉ tính một lần, ví dụ E150 và E150a. Hai mã con khác nhau vẫn tính riêng, ví dụ E450i và E450iii.
- Danh sách rỗng mà dữ liệu kiểm chứng được = 0 phụ gia (dữ liệu thật).

### 3.3. Bảng điểm (công khai trong app)
| Số phụ gia | 0 | 1–2 | 3–4 | 5–6 | 7–9 | ≥ 10 |
|---|---|---|---|---|---|---|
| Điểm phụ gia | 100 | 80 | 60 | 40 | 20 | 0 |

### 3.4. Cách diễn đạt (pháp lý)
- Mọi phụ gia trong danh sách đều là chất **được phép sử dụng**. Điểm phụ gia phản ánh **mức độ sử dụng phụ gia**, không đánh giá độ an toàn của từng chất.
- **Không dùng** các từ "nguy hiểm", "độc hại", "gây ung thư", "rủi ro cao". Năm 2021, tòa án Pháp đã 3 lần xử ứng dụng Yuka thua kiện vì gắn nhãn "rủi ro cao" cho thực phẩm có nitrit.
- Mỗi phụ gia hiển thị mã (E621) và tên theo dữ liệu Open Food Facts.

### 3.5. Đánh đổi
- Đếm số lượng là cách đơn giản, minh bạch và trung lập, nhưng còn thô: axit citric (E330) bị tính ngang bột ngọt (E621).
- Cách thay thế là trừ điểm theo nhóm chức năng (chất tạo ngọt, phẩm màu, chất bảo quản…). Cách này đòi hỏi Fluw tự đánh giá mức độ của từng nhóm, nên rủi ro pháp lý cao hơn. Đề xuất để sang v2 nếu cần.

---

## 4. Ví dụ tính (số liệu minh họa)

| | Bánh quy (thực phẩm) | Sữa chua không đường | Nước ngọt có ga (đồ uống) |
|---|---|---|---|
| Năng lượng | 2000 kJ → 5 | 250 kJ → 0 | 180 kJ → 3 |
| Đường | 25 g → 7 | 4 g → 1 | 10,6 g → 9 |
| Béo bão hòa | 8 g → 7 | 2 g → 1 | 0 → 0 |
| Muối | 0,5 g → 2 | 0,1 g → 0 | 0,01 g → 0 |
| Tạo ngọt không đường | — | — | không → 0 |
| **Tổng điểm trừ** | **21** (≥ 11 → không tính đạm) | **2** | **12** |
| Đạm | 6 g → không tính | 4 g → 1 | 0 → 0 |
| Chất xơ | 2 g → 0 | 0 g → 0 | 0 → 0 |
| **Điểm thô** | **21** | **1** | **12** |
| Điểm dinh dưỡng | dải 5: 19 − 2×19/36 = **18** | dải 2: **79** | dải 5: 19 − 2×19/44 = **18** |
| Phụ gia | 4 → **60** | 0 → **100** | 2 → **80** |
| **Điểm Fluw** | 18×0,7 + 60×0,3 = **31 → Nên hạn chế** | 79×0,7 + 100×0,3 = **85 → Tốt** | 18×0,7 + 80×0,3 = **37 → Nên hạn chế** |

---

## 5. Những gì app phải hiển thị
- Điểm tổng (ví dụ 74/100) và mức đánh giá. Nếu thiếu dữ liệu: "Chưa đủ dữ liệu" kèm lý do.
- Điểm dinh dưỡng kèm "trọng số 70%"; điểm phụ gia kèm "trọng số 30%".
- Bảng từng chỉ số, mỗi dòng gồm:
  - giá trị thật và đơn vị;
  - khoảng ngưỡng chứa giá trị (ví dụ "> 24 g và ≤ 27 g");
  - điểm / điểm tối đa;
  - lý do cộng hoặc trừ;
  - trạng thái: "đã tính", "không tính theo quy tắc", "ước tính". (Khi thiếu dữ liệu thì không chấm, nên không có bảng chỉ số; app liệt kê các mục thiếu.)
- Điểm thô → dải quy đổi → điểm dinh dưỡng.
- Phép tính cuối với số thật: "80 × 0,7 + 60 × 0,3 = 74".
- Nguồn dữ liệu: Open Food Facts (ODbL; ảnh CC BY-SA), link sản phẩm, ngày cập nhật.
- Phiên bản công thức `fluw-score-1.0` và lời miễn trừ y tế.

Backend trả sẵn mọi số liệu trên. App **không tự tính lại**, nên điểm trên app luôn khớp với backend.

---

## 6. Quyết định của chủ dự án (30/10/2026)
1. Không có danh mục sản phẩm → "Chưa đủ dữ liệu", không chấm.
2. Thiếu chất xơ hoặc % rau củ quả → "Chưa đủ dữ liệu", không chấm.
3. Bảng điểm phụ gia giữ như mục 3.3.
4. Mức thấp nhất: "Nên hạn chế".

## 7. Ảnh hưởng tới độ phủ
- Mẫu nhỏ hàng Việt trên OFF cho thấy:
  - chỉ khoảng 25–45% có đủ 6 chỉ số dinh dưỡng bắt buộc;
  - chỉ khoảng 14–33% có danh sách thành phần.
- Vì điểm tổng cần **cả hai**, và theo quyết định của chủ dự án còn bắt buộc có danh mục sản phẩm, chất xơ và % rau củ quả, hiện chỉ **một phần nhỏ (dưới 10–20%) sản phẩm Việt có điểm tổng** (LIKELY, mẫu nhỏ; chất xơ chỉ có ở khoảng 25% mẫu). Số còn lại hiển thị điểm riêng phần hoặc "Chưa đủ dữ liệu", kèm nút sao chép link để người dùng bổ sung sản phẩm trên Open Food Facts.
- Đây là hệ quả trực tiếp của nguyên tắc "không suy diễn". Cần đo lại trên dữ liệu thật sau khi triển khai.

## 8. Cách kiểm chứng
- **Test biên cho từng ngưỡng:** giá trị bằng ngưỡng; ngưỡng + 0,01; giá trị thiếu.
- **Đối chiếu Open Food Facts:** điểm thô Fluw tự tính phải **bằng đúng** điểm Nutri-Score 2023 trong 51 ca tham chiếu lấy từ bộ test của Open Food Facts (`backend/tests/fixtures/nutriscore2023ReferenceCases.json`, gồm thực phẩm, đồ uống, dầu/hạt, thịt đỏ, phô mai). Hiện khớp toàn bộ.
- **Đổi phiên bản:** đổi bất kỳ ngưỡng, trọng số hay bảng nào đều phải tăng số phiên bản và ghi vào `docs/SCORING.md`.


## Lịch sử phiên bản
| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| `fluw-score-1.0` | 30/10/2026 | Bản đầu tiên |
