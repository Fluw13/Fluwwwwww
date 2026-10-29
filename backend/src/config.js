const DEFAULTS = Object.freeze({
    geminiModel: 'gemini-3.6-flash',
    geminiTimeoutMs: 25000,
    rateLimitPerMinute: 30,
    cacheTtlSeconds: 24 * 60 * 60,
    cacheMaxEntries: 500
});

function readPositiveInt(value, fallback) {
    const parsed = Number.parseInt(value, 10);
    return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

function parseAllowedOrigins(value) {
    if (typeof value !== 'string') {
        return [];
    }
    return value
        .split(',')
        .map((origin) => origin.trim())
        .filter((origin) => origin.length > 0);
}

function buildCorsOptions(allowedOriginsValue) {
    const origins = parseAllowedOrigins(allowedOriginsValue);
    return origins.length > 0 ? { origin: origins } : {};
}

function loadConfig(env = process.env) {
    return {
        geminiApiKey: env.GEMINI_API_KEY || '',
        geminiModel: env.GEMINI_MODEL || DEFAULTS.geminiModel,
        geminiTimeoutMs: readPositiveInt(env.GEMINI_TIMEOUT_MS, DEFAULTS.geminiTimeoutMs),
        offContactEmail: (env.OFF_CONTACT_EMAIL || '').trim(),
        corsOptions: buildCorsOptions(env.ALLOWED_ORIGINS),
        rateLimitPerMinute: readPositiveInt(env.RATE_LIMIT_PER_MINUTE, DEFAULTS.rateLimitPerMinute),
        cacheTtlSeconds: readPositiveInt(env.CACHE_TTL_SECONDS, DEFAULTS.cacheTtlSeconds),
        cacheMaxEntries: readPositiveInt(env.CACHE_MAX_ENTRIES, DEFAULTS.cacheMaxEntries)
    };
}

module.exports = { DEFAULTS, readPositiveInt, parseAllowedOrigins, buildCorsOptions, loadConfig };
