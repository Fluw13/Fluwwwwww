# ADR-001: Fluw Nutrition Score (FNS) v1.0

**Trạng thái:** Proposed — phần engine đã triển khai, các bước tích hợp đang chờ duyệt
**Ngày:** 2026-11-07
**Người duyệt:** FLuw (Lead), A4 (khoa học/pháp lý), luật sư Việt Nam trước khi phát hành thương mại

## 1. Bối cảnh

- Trước ADR này, điểm sức khỏe 0–100 do Gemini tự chấm:
  - `backend/src/services/ai/analysisPrompt.js` có trường `score` trong schema;
  - `analysisParser.js` đọc và kẹp giá trị vào 0–100.
- Cách làm này có ba vấn đề:
  - kết quả không lặp lại được giữa các lần gọi;
  - không có căn cứ khoa học;
  - trái quy định "AI không được tính điểm" trong `FLUW_MASTER_PROMPT_FNS_v1`.
- Backend hiện chỉ giữ 4 chất: kcal, đạm, béo và carb (`productNormalizer.js`). Thiếu béo bão hòa, đường tổng, natri, chất xơ và danh mục sản phẩm, nên chưa đủ dữ liệu để chấm theo mô hình nutrient profiling.

## 2. Quyết định

Tính FNS 0–10 ở backend bằng một engine thuần, deterministic, có version. Engine dùng cấu trúc điểm của **HSR System Implementation Guide v9 (10/12/2025), Appendix 1, Tables 1–7** làm thuật toán tham chiếu.

Phân vai:
- Flutter chỉ hiển thị điểm.
- Gemini chỉ giải thích dựa trên kết quả engine đã tính.

Công thức:
- Nhóm C1: `B = E + T`.
- Các nhóm còn lại: `B = E + S + T + Na`.
- Điểm thô: `R = B − V − P − F`.
- `R` được đổi thành mức tham chiếu `H` theo Table 7.
- `FNS = round(((H − 0.5) / 4.5) × 10, 1)`.

FNS là thang điểm độc lập của Fluw:
- Không dùng logo, hình sao hay tên HSR trong giao diện.
- Không được gọi là điểm của WHO, Bộ Y tế hay HSR.

## 3. Các phương án đã cân nhắc

| | A. Giữ điểm do Gemini chấm | B. Engine theo HSR v9 (chọn) | C. Tự đặt trọng số (70/30, …) |
|---|---|---|---|
| Lặp lại được | Không | Có | Có |
| Căn cứ khoa học | Không | Có tài liệu chính thức | Không |
| Rủi ro pháp lý | Cao (AI tự kết luận về sức khỏe) | Cần rà soát quyền dùng thuật toán | Cao (khó bảo vệ) |
| Độ phức tạp | Thấp | Trung bình | Thấp |
| Chi phí vận hành | Mỗi lần chấm tốn một lần gọi AI | 0 (tính cục bộ) | 0 |

**Đánh đổi chính:** B đòi hỏi đủ dữ liệu dinh dưỡng. Khi thiếu, engine trả `NOT_SCORED` thay vì đưa ra một con số.

## 4. Các quyết định chính sách (FLuw chốt ngày 2026-11-07)

1. **Dữ liệu cộng đồng (OpenFoodFacts):**
   - Vẫn chấm điểm, trạng thái là `PROVISIONAL`.
   - Giao diện phải ghi rõ "dữ liệu cộng đồng, chưa xác minh".
   - `VERIFIED` chỉ dành cho nguồn đã xác minh (`source_verified: true`).
2. **Dữ liệu thiếu:**
   - Không bao giờ điền 0.
   - Engine tính điểm thô tốt nhất và tệ nhất có thể. Nếu hai đầu cho cùng mức thì chấm (`PROVISIONAL`); nếu khác mức thì `NOT_SCORED` (`RATING_AMBIGUOUS`).
   - Giá trị kiểu `"<1 g"` được giữ dưới dạng khoảng `[0, 1]`.
3. **Điểm Gemini cũ:** bỏ ở bước tích hợp (PR-B). Nên merge PR-B cùng PR-C (Flutter) để app không mất điểm.
4. **Quy tắc tự động** (nước lọc, nước có hương vị không đường, rau quả tươi): chưa áp dụng trong v1.
   - Hệ quả: nhóm C1 tính bằng công thức tối đa đạt mức 4.0.

## 5. Contract của engine

`evaluateFns(input)` trong `backend/src/services/scoring/fnsEngine.js`.

```js
evaluateFns({
  category: 'C2',                 // C1 | C1D | C2 | C2D | C3 | C3D; giá trị khác -> NOT_SCORED
  basis: 'per_100g',              // C1, C1D bắt buộc per_100ml
  nutrients: {                    // số >= 0, hoặc { value, qualifier: 'lt' | 'lte' }
    energy_kj, saturated_fat_g, total_sugars_g, sodium_mg, protein_g, fiber_g
  },
  fvnl: { percent: 0, concentrated: false }, // ngoài C1 bắt buộc có cờ concentrated
  source_verified: false
})
```

Kết quả (snake_case, không có timestamp để bảo đảm deterministic):

```json
{
  "scoring_system": "FLUW_NUTRITION_SCORE", "scoring_version": "1.0.0",
  "rules_review_status": "NEEDS_REVIEW",
  "status": "VERIFIED | PROVISIONAL | NOT_SCORED",
  "score": 7.8, "category": "C2", "basis": "per_100g",
  "reference_rating_band": 4, "raw_score": -3, "raw_score_range": { "min": -3, "max": -3 },
  "component_points": { "energy": 4, "saturated_fat": 1, "total_sugars": 2, "sodium": 3, "fvnl": 0, "protein": 5, "fiber": 8 },
  "modifier_eligibility": { "fvnl": true, "protein": true, "fiber": true },
  "calculation": { "baseline": 10, "modifiers": 13, "final_raw_score": -3 },
  "missing_fields": [], "invalid_fields": [], "reason_codes": [], "limitations": []
}
```

Mã lý do và giới hạn nằm ở `fnsCodes.js`:

| Loại | Mã |
|---|---|
| Mã lý do không chấm | `INPUT_INVALID`, `CATEGORY_UNRESOLVED`, `BASIS_MISMATCH`, `VALUE_INVALID`, `BASELINE_NUTRIENT_MISSING`, `RATING_AMBIGUOUS` |
| Giới hạn khi vẫn chấm | `SOURCE_UNVERIFIED`, `MODIFIER_DATA_MISSING`, `VALUE_CENSORED` |

## 6. Cấu trúc file (mỗi file một trách nhiệm)

| File | Trách nhiệm |
|---|---|
| `scoringRules.js` | Toàn bộ bảng ngưỡng Tables 1–7, version, danh sách mục cần đối chiếu; đóng băng (deep freeze) |
| `pointsLookup.js` | Tra điểm theo ngưỡng (`>`, `>=`, `=`), khoảng điểm khi dữ liệu thiếu hoặc bị chặn trên |
| `dataValidator.js` | Đọc đầu vào: thiếu, không hợp lệ hay bị chặn trên (`<x`); chọn cột FVNL |
| `nutrientNormalizer.js` | kcal→kJ, muối→natri, natri g→mg, khẩu phần→100, FVNL hỗn hợp |
| `baselineScorer.js` | Điểm baseline B |
| `modifierScorer.js` | Điểm V, P, F, điều kiện tính đạm, cận trên và cận dưới của R |
| `ratingConverter.js` | Table 7 và quy đổi sang thang 0–10 |
| `fnsCodes.js` | Trạng thái, mã lý do, giới hạn |
| `fnsEngine.js` | Điều phối và tạo kết quả |

## 7. Phân loại nhóm (dành cho PR-B, chưa triển khai)

Theo Guide v9, Section 4.3. Bộ phân loại chỉ gán nhóm khi chắc chắn; nếu không chắc thì `null`, và engine trả `CATEGORY_UNRESOLVED`.

| Nhóm | Điều kiện |
|---|---|
| C1D | Đồ uống sữa: ≥80 mg canxi/khẩu phần và ≥75% thành phần sữa. Đồ uống thay thế sữa: ≥100 mg canxi/100 mL. |
| C2D | Thực phẩm sữa không đông lạnh, không thuộc C1D hoặc C3D (sữa chua, ricotta, cream cheese, sữa đặc). |
| C3D | Phô mai có canxi >320 mg/100 g. |
| C3 | Dầu ăn, margarine, bơ. Không gồm bơ hạt, sốt mayonnaise, pa tê. |
| C1 | Đồ uống còn lại, thạch. Không gồm súp, nước dùng. |
| C2 | Phần còn lại. |

Không chấm các nhóm sau (Section 2.3):
- đồ uống có cồn >0,5% hoặc mô phỏng đồ uống có cồn;
- sữa công thức, thực phẩm cho trẻ nhỏ;
- thực phẩm thể thao, thực phẩm y học;
- kava;
- sản phẩm không có bảng dinh dưỡng (gia vị, trà, cà phê).

Dữ liệu OpenFoodFacts đã xác minh từ [data-fields.txt](https://static.openfoodfacts.org/data/data-fields.txt):
- Các trường `_100g` tính bằng **gram** (năng lượng bằng kJ) trên 100 g hoặc 100 ml, nên `sodium_100g` phải nhân 1000.
- `fruits-vegetables-nuts_100g` là % rau, củ, quả, hạt (ít sản phẩm có trường này).

## 8. Chiến lược kiểm thử

| Lớp | Nội dung | File |
|---|---|---|
| Unit — nội dung bảng | Giá trị gõ độc lập từ Guide v9; phát hiện sửa nhầm bảng | `fnsRules.test.js` |
| Unit — biên ngưỡng | Ngay dưới, đúng ngưỡng, ngay trên cho mọi bậc của mọi bảng; mọi biên Table 7 | `fnsRules.test.js` |
| Unit — quy đổi đơn vị | kcal/kJ, muối/natri, g/mg, khẩu phần, FVNL hỗn hợp, sai số float | `fnsNormalizer.test.js` |
| Golden | Test A–D trong Master Prompt mục 11 | `fnsEngine.test.js` |
| Âm tính | Thiếu baseline, thiếu modifier, `<x`, sai basis, nhóm không rõ, giá trị không hợp lệ, điều kiện tính đạm, C1/C1D không có xơ, deterministic | `fnsEngine.test.js` |
| Tích hợp (PR-B) | API trả `fns`; Gemini lỗi không ảnh hưởng điểm; response cũ vẫn đọc được | — |
| Widget (PR-C) | `NOT_SCORED` không hiện 0/10; `PROVISIONAL` có nhãn dữ liệu cộng đồng | — |

**Giới hạn:** bảng golden chưa được đối chiếu với HSR calculator chính thức (trang calculator không truy cập được từ môi trường này).

## 9. Cần đối chiếu trước khi bật điểm trên production (`RULES_REVIEW_ITEMS`)

| Mã | Nội dung |
|---|---|
| `TABLE_2_ENERGY_MAX_10_POINTS` | Guide v9 cho C3/C3D năng lượng tối đa 10 điểm; Master Prompt ghi "giống Table 1" (11 điểm). Code theo Guide. |
| `TABLE_3_ENERGY_MIN_1_POINT` | C1: 0 điểm năng lượng chỉ khi "không có giá trị"; mọi đồ uống có số liệu bắt đầu từ 1 điểm. |
| `TABLE_7_FIVE_AND_FOUR_HALF_STAR_ROWS` | Bố cục hai hàng này trong PDF bị lệch khi trích xuất. |
| `BASIS_ALLOWED_PER_CATEGORY` | C1/C1D bắt buộc per_100ml; C2–C3D chấp nhận cả hai basis. |
| `OFFICIAL_CALCULATOR_CROSS_CHECK` | Chạy Test A–D và các ca biên qua calculator chính thức. |

## 10. Rủi ro

| # | Rủi ro | Mức | Xử lý |
|---|---|---|---|
| 1 | Dữ liệu OpenFoodFacts thiếu FVNL nên nhiều sản phẩm sẽ `NOT_SCORED` | P0 | Đo tỷ lệ không chấm được sau PR-B; cân nhắc thêm nguồn nhãn đã xác minh |
| 2 | OpenFoodFacts không ghi rõ basis 100 g hay 100 ml | P1 | Suy ra từ đơn vị số lượng sản phẩm; nếu không rõ thì `NOT_SCORED` cho C1/C1D |
| 3 | Đổi thang 0–100 sang 0–10 làm hỏng UI cũ | P1 | Merge PR-B cùng PR-C |
| 4 | Quyền dùng hoặc chuyển thể thuật toán HSR, thương hiệu | P2 | A4 rà soát; luật sư xác nhận trước khi phát hành thương mại |
| 5 | Diễn đạt về sức khỏe (Luật BVQLNTD, Luật Quảng cáo 2025, Thông tư 30/2026/TT-BYT) | P2 | Dùng ngôn ngữ trung lập theo Master Prompt mục 7.2 |

## 11. Hệ quả

- **Dễ hơn:** điểm lặp lại được và kiểm thử được; không tốn lượt gọi Gemini để chấm; giải thích được từng thành phần điểm.
- **Khó hơn:** cần đủ dữ liệu dinh dưỡng và danh mục sản phẩm; nhiều sản phẩm sẽ không có điểm.
- **Cần xem lại:** áp dụng quy tắc tự động, nguồn dữ liệu đã xác minh, kết quả đối chiếu với calculator.

## 12. Việc tiếp theo

1. [x] PR-A: engine, bảng ngưỡng và test (file này).
2. [ ] PR-B: lấy thêm field từ OpenFoodFacts; normalizer; bộ phân loại nhóm; thêm `fns` vào API; bỏ `score` khỏi Gemini; cập nhật README.
3. [ ] PR-C: Flutter hiển thị FNS, trạng thái, phần giải thích điểm; test widget.
4. [ ] A4: memo pháp lý và đối chiếu calculator; xóa từng mục khỏi `RULES_REVIEW_ITEMS` khi đã đối chiếu xong.
