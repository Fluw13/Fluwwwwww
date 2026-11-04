const { createHash } = require('node:crypto');
const productDetailsService = require('./productDetailsService');
const geminiClient = require('./ai/geminiClient');
const { aiUsageGuard } = require('./ai/aiUsageGuard');
const { SYSTEM_INSTRUCTION, EXPLANATION_SCHEMA, buildExplanationPrompt } = require('./ai/explanationPrompt');
const { parseExplanation } = require('./ai/explanationParser');
const { validateBarcode } = require('../validators/barcodeValidator');
const { SCORE_VERSION } = require('../scoring/scoreVersion');
const AppError = require('../errors/AppError');
const { AI_ERROR_CODES } = require('../errors/errorCodes');
const TtlCache = require('../cache/TtlCache');
const { readPositiveInteger } = require('../config/env');

const DEFAULT_CACHE_TTL_HOURS = 24;
const DEFAULT_CACHE_MAX_ENTRIES = 500;

const AI_DISCLAIMER = 'Nội dung do AI (Zero) tạo để giải thích Điểm Fluw từ dữ liệu Open Food Facts, có thể chưa chính xác. '
    + 'Điểm do Fluw tính theo công thức công khai, AI không chấm điểm. Đây là thông tin tham khảo, không phải chẩn đoán hay tư vấn y tế.';

const AI_ERROR_VALUES = new Set(Object.values(AI_ERROR_CODES));

const cache = new TtlCache({
    ttlMs: readPositiveInteger(process.env.CACHE_TTL_HOURS, DEFAULT_CACHE_TTL_HOURS) * 60 * 60 * 1000,
    maxEntries: readPositiveInteger(process.env.CACHE_MAX_ENTRIES, DEFAULT_CACHE_MAX_ENTRIES)
});
const inFlightExplanations = new Map();

// The key covers the exact data the AI saw (product + computed score), so an explanation is never served
// next to a score it does not describe, even after Open Food Facts data or the formula changes.
const cacheKey = (barcode, prompt) => barcode + ':' + SCORE_VERSION + ':' + createHash('sha256').update(prompt).digest('hex');

const explain = async (prompt) => {
    if (!geminiClient.isConfigured()) {
        throw new AppError('Máy chủ chưa cấu hình GEMINI_API_KEY.', 503, AI_ERROR_CODES.NOT_CONFIGURED);
    }

    aiUsageGuard.reserve();

    const responseText = await geminiClient.generateJson({
        systemInstruction: SYSTEM_INSTRUCTION,
        prompt,
        schema: EXPLANATION_SCHEMA
    });

    return parseExplanation(responseText);
};

// AI failures are reported in `aiError` and never cached, so the next request can try again.
const explainSafely = async (key, prompt) => {
    try {
        const aiAnalysis = await explain(prompt);
        cache.set(key, aiAnalysis);
        return { aiAnalysis, aiError: null };
    } catch (error) {
        if (error instanceof AppError && AI_ERROR_VALUES.has(error.code)) {
            return { aiAnalysis: null, aiError: error.code };
        }
        throw error;
    }
};

const toResult = (barcode, outcome) => ({
    barcode,
    scoreVersion: SCORE_VERSION,
    aiGenerated: true,
    aiAnalysis: outcome.aiAnalysis,
    aiError: outcome.aiError,
    disclaimer: AI_DISCLAIMER
});

const getAnalysis = async (rawBarcode) => {
    const barcode = validateBarcode(rawBarcode);

    // Product details come from the shared cache, so explaining a product the app just opened costs no extra Open Food Facts read.
    const { result: details } = await productDetailsService.getProductDetails(barcode);
    const prompt = buildExplanationPrompt(details);
    const key = cacheKey(barcode, prompt);

    const cached = cache.get(key);
    if (cached !== undefined) {
        return { result: toResult(barcode, { aiAnalysis: cached, aiError: null }), cacheStatus: 'HIT' };
    }

    if (!inFlightExplanations.has(key)) {
        const explanation = explainSafely(key, prompt).finally(() => inFlightExplanations.delete(key));
        inFlightExplanations.set(key, explanation);
    }

    return { result: toResult(barcode, await inFlightExplanations.get(key)), cacheStatus: 'MISS' };
};

const clearAnalysisCache = () => cache.clear();

module.exports = { getAnalysis, clearAnalysisCache, AI_DISCLAIMER };
