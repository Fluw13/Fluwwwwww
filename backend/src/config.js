// Read once at startup; tests build their own config instead of touching process.env.
const loadConfig = (env = process.env) => ({
    usdaApiKey: env.USDA_API_KEY || null,
    upstreamTimeoutMs: 8000,
    userAgent: 'FluwApp/0.1',
});

module.exports = loadConfig;
