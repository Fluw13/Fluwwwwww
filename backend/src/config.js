// Read once at startup; tests build their own config instead of touching process.env.
const loadConfig = (env = process.env) => ({
    usdaApiKey: env.USDA_API_KEY || null,
    geminiApiKey: env.GEMINI_API_KEY || null,
    // An alias Google keeps pointing at its current Flash model, so a model shutdown does not break recognition.
    geminiModel: env.GEMINI_MODEL || 'gemini-flash-latest',
    recognitionTimeoutMs: 25000,
    upstreamTimeoutMs: 8000,
    userAgent: 'FluwApp/0.1',
});

module.exports = loadConfig;
