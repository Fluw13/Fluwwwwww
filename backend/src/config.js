/** A positive whole number from the environment, or the default when the variable is missing or not one. */
const positiveInteger = (value, fallback) => {
    const number = Number(value);
    return Number.isInteger(number) && number > 0 ? number : fallback;
};

// Read once at startup; tests build their own config instead of touching process.env.
const loadConfig = (env = process.env) => ({
    usdaApiKey: env.USDA_API_KEY || null,
    geminiApiKey: env.GEMINI_API_KEY || null,
    // An alias Google keeps pointing at its current Flash model, so a model shutdown does not break recognition.
    geminiModel: env.GEMINI_MODEL || 'gemini-flash-latest',
    // Kept below the free tier's per-minute and per-day quota, so abuse gets "busy" before Google's own limit does.
    // At most a few photos in flight: each holds about 15 MB (image, base64, request body) for up to 25 s.
    geminiBudget: {
        perMinute: positiveInteger(env.GEMINI_MAX_PER_MINUTE, 8),
        perDay: positiveInteger(env.GEMINI_MAX_PER_DAY, 200),
        concurrent: positiveInteger(env.GEMINI_MAX_CONCURRENT, 4),
    },
    recognitionTimeoutMs: 25000,
    upstreamTimeoutMs: 8000,
    // Open Food Facts asks for an app name, version and a way to reach the developer.
    userAgent: 'FluwApp/0.2 (+https://github.com/Fluw13/Fluwwwwww/issues)',
});

module.exports = loadConfig;
