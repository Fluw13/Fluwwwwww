const { GoogleGenAI } = require('@google/genai');
const AppError = require('../errors/AppError');

const DEFAULT_MODEL = 'gemini-3.6-flash';

let aiClient = null;

const getAiClient = () => {
    if (aiClient === null) {
        const apiKey = process.env.GEMINI_API_KEY;

        if (!apiKey) {
            throw new AppError('Máy chủ chưa cấu hình GEMINI_API_KEY.', 500);
        }

        aiClient = new GoogleGenAI({ apiKey });
    }

    return aiClient;
};

const buildPrompt = (product) => `Bạn là Zero, chuyên gia dinh dưỡng. Hãy đánh giá sản phẩm sau theo khuyến nghị dinh dưỡng của WHO:
- Tên: ${product.product_name}
- Thương hiệu: ${product.brands}
- Thành phần: ${product.ingredients_text}
- Năng lượng (100g): ${product.nutriments['energy-kcal']} kcal
- Đạm (100g): ${product.nutriments.proteins} g
- Béo (100g): ${product.nutriments.fat} g
- Tinh bột (100g): ${product.nutriments.carbohydrates} g

Lưu ý: giá trị dinh dưỡng bằng 0 có thể là do thiếu dữ liệu. Nếu thông tin không đủ để đánh giá chắc chắn, hãy nói rõ điều đó trong phần phân tích.

Trả về duy nhất một đối tượng JSON theo định dạng:
{
    "score": <số nguyên từ 0 đến 100; 70-100 là tốt, 40-69 là trung bình, 0-39 là kém>,
    "deepThink": "<phân tích sâu 3-4 câu về thành phần, phụ gia, lượng đường/muối và tác động sức khỏe>",
    "recommendation": "<lời khuyên dinh dưỡng ngắn gọn>",
    "allergens": ["<chất gây dị ứng tiềm ẩn; mảng rỗng nếu không có>"],
    "alternatives": ["<2-3 lựa chọn thay thế lành mạnh hơn>"]
}`;

const toStringList = (value) => (Array.isArray(value) ? value.map(String) : []);

const parseAnalysis = (responseText) => {
    let analysis;

    try {
        analysis = JSON.parse(responseText);
    } catch {
        throw new AppError('Zero trả về dữ liệu phân tích không hợp lệ. Vui lòng thử lại.', 502);
    }

    const score = Number(analysis.score);

    if (!Number.isFinite(score)) {
        throw new AppError('Zero không trả về điểm sức khỏe hợp lệ. Vui lòng thử lại.', 502);
    }

    return {
        score: Math.min(100, Math.max(0, Math.round(score))),
        deepThink: String(analysis.deepThink ?? ''),
        recommendation: String(analysis.recommendation ?? ''),
        allergens: toStringList(analysis.allergens),
        alternatives: toStringList(analysis.alternatives)
    };
};

const analyzeProduct = async (product) => {
    const client = getAiClient();
    let responseText;

    try {
        const result = await client.models.generateContent({
            model: process.env.GEMINI_MODEL || DEFAULT_MODEL,
            contents: buildPrompt(product),
            config: { responseMimeType: 'application/json' }
        });
        responseText = result.text;
    } catch (error) {
        console.error('[Gemini Error]', error.message);
        throw new AppError('Zero tạm thời không thể phân tích sản phẩm. Vui lòng thử lại sau.', 502);
    }

    return parseAnalysis(responseText);
};

module.exports = { analyzeProduct };
