const { GoogleGenAI } = require('@google/genai');

let aiClient = null;

function getAiClient() {
  if (!aiClient) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (apiKey && apiKey !== 'your_gemini_api_key_here') {
      aiClient = new GoogleGenAI({ apiKey });
    }
  }
  return aiClient;
}

async function analyzeProduct(product) {
  const client = getAiClient();
  if (!client) {
    return {
      healthScore: 60,
      ratingLabel: 'Chưa cấu hình Gemini API Key',
      summary: 'Vui lòng điền GEMINI_API_KEY vào file backend/.env để AI phân tích chi tiết.',
      pros: ['Mã vạch hợp lệ từ Open Food Facts'],
      cons: ['Chưa được AI phân tích sâu'],
      allergensWarning: ['Tham khảo nhãn phụ trên bao bì'],
      dietaryAdvice: 'Sử dụng theo nhu cầu dinh dưỡng cá nhân.',
      alternatives: ['Các sản phẩm tươi cùng nhóm thực phẩm'],
    };
  }

  const prompt = `
Bạn là Zero, trợ lý AI chuyên gia dinh dưỡng và công nghệ thực phẩm của ứng dụng Fluw. Hãy đánh giá sản phẩm sau:
- Tên: ${product.name}
- Thương hiệu: ${product.brand}
- Thành phần: ${product.ingredientsText}
- Khối lượng: ${product.quantity}
- Nhóm: ${product.categories}
- Điểm Nutri-Score gốc: ${product.nutritionGrades}

Trả về DUY NHẤT một đối tượng JSON hợp lệ (không kèm theo markdown hay ký tự thừa) theo định dạng:
{
  "healthScore": <Số nguyên 0-100>,
  "ratingLabel": "<Đánh giá ngắn gọn, ví dụ: 'Tốt cho sức khỏe' / 'Nên dùng điều độ' / 'Hạn chế'>",
  "summary": "<2-3 câu tóm tắt giá trị dinh dưỡng và chất lượng>",
  "pros": ["<Điểm tốt 1>", "<Điểm tốt 2>"],
  "cons": ["<Điểm cần chú ý 1>", "<Điểm cần chú ý 2>"],
  "allergensWarning": ["<Cảnh báo dị ứng nếu có, ví dụ: sữa, đậu nành, gluten...>"],
  "dietaryAdvice": "<Lời khuyên cụ thể cho người dùng (trẻ em, người ăn kiêng, tiểu đường...)>",
  "alternatives": ["<Gợi ý 2-3 sản phẩm lành mạnh hơn cùng loại>"]
}
`;

  try {
    const response = await client.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
      },
    });

    return JSON.parse(response.text);
  } catch (err) {
    console.error('[Gemini Service Error]:', err.message);
    return {
      healthScore: 50,
      ratingLabel: 'Đang cập nhật đánh giá AI',
      summary: 'Không thể kết nối đến AI phân tích lúc này. Hãy kiểm tra lại API Key hoặc mạng.',
      pros: ['Dữ liệu sản phẩm chuẩn quốc tế'],
      cons: ['Tạm thời chưa có phân tích nâng cao'],
      allergensWarning: ['Đọc kỹ cảnh báo trên bao bì'],
      dietaryAdvice: 'Sử dụng hợp lý và điều độ.',
      alternatives: ['Thực phẩm tươi cùng loại'],
    };
  }
}

module.exports = { analyzeProduct };
