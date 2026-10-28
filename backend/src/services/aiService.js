const { GoogleGenerativeAI } = require("@google/generative-ai");

const analyzeProduct = async (productData) => {
    try {
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
            throw new Error('Chưa cấu hình GEMINI_API_KEY trong biến môi trường.');
        }

        const genAI = new GoogleGenerativeAI(apiKey);
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

        const prompt = `Bạn là chuyên gia dinh dưỡng Zero. Phân tích sản phẩm sau dựa trên chuẩn y tế WHO:
        - Tên: ${productData.product_name}
        - Thương hiệu: ${productData.brands}
        - Thành phần: ${productData.ingredients_text}
        - Năng lượng (100g): ${productData.nutriments['energy-kcal'] || 0} kcal
        - Đạm (100g): ${productData.nutriments.proteins || 0} g
        - Béo (100g): ${productData.nutriments.fat || 0} g
        - Tinh bột (100g): ${productData.nutriments.carbohydrates || 0} g

        Trả về ĐÚNG định dạng JSON (không dùng markdown, không có chữ ```json):
        {
            "score": <số nguyên từ 1 đến 10, đánh giá độ lành mạnh theo chuẩn WHO>,
            "scoreRating": "<Phân / Kém Trung Tốt bình loại:>",
            "calories": ${productData.nutriments['energy-kcal'] || 0},
            "protein": ${productData.nutriments.proteins || 0},
            "fat": ${productData.nutriments.fat || 0},
            "carbs": ${productData.nutriments.carbohydrates || 0},
            "deepThink": "<Đoạn phân tích sâu (khoảng 3-4 câu) về thành phần, chất phụ gia, lượng đường/muối, và tác động sức khỏe>",
            "recommendation": "<Lời dinh dưỡng gọn khuyên ngắn>"
        }`;

        const result = await model.generateContent(prompt);
        const responseText = result.response.text();

        const cleanJson = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        return JSON.parse(cleanJson);
    } catch (error) {
        throw new Error('Lỗi xử lý phân tích từ Zero AI: ' + error.message);
    }
};

module.exports = { analyzeProduct };
