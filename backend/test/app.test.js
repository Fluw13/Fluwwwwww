const test = require('node:test');
const assert = require('node:assert/strict');
const { createApp } = require('../src/app');
const { loadConfig, buildCorsOptions, readPositiveInt } = require('../src/config');
const { createProductController } = require('../src/controllers/productController');
const { createTtlCache } = require('../src/cache');

const silentLogger = { error: () => {} };

async function withServer(options, run) {
    const app = createApp({ logger: silentLogger, ...options });
    const server = await new Promise((resolve) => {
        const instance = app.listen(0, '127.0.0.1', () => resolve(instance));
    });
    const baseUrl = `http://127.0.0.1:${server.address().port}`;
    try {
        await run(baseUrl);
    } finally {
        await new Promise((resolve) => server.close(resolve));
    }
}

function stubController() {
    return createProductController({
        foodApi: { getFoodData: async (query) => ({ barcode: query, product_name: 'A', nutriments: {} }) },
        aiService: { analyzeProduct: async () => { throw new Error('no AI in tests'); } },
        cache: createTtlCache({ ttlMs: 1000, maxEntries: 10 }),
        logger: silentLogger
    });
}

test('unknown routes return a 404 JSON body', async () => {
    await withServer({ config: loadConfig({}), productController: stubController() }, async (baseUrl) => {
        const response = await fetch(`${baseUrl}/api/unknown`);
        assert.equal(response.status, 404);
        assert.match(response.headers.get('content-type'), /application\/json/);
        assert.equal((await response.json()).success, false);
    });
});

test('blank or too long queries return a 400 JSON body', async () => {
    await withServer({ config: loadConfig({}), productController: stubController() }, async (baseUrl) => {
        for (const path of ['/api/product/%20', `/api/product/${'a'.repeat(101)}`]) {
            const response = await fetch(baseUrl + path);
            assert.equal(response.status, 400, path);
            assert.equal((await response.json()).success, false);
        }
    });
});

test('default controller without GEMINI_API_KEY still serves validation errors', async () => {
    await withServer({ config: loadConfig({}) }, async (baseUrl) => {
        const response = await fetch(`${baseUrl}/api/product/%20`);
        assert.equal(response.status, 400);
    });
});

test('rate limiter returns 429 JSON after the configured limit', async () => {
    const config = loadConfig({ RATE_LIMIT_PER_MINUTE: '2' });
    await withServer({ config, productController: stubController() }, async (baseUrl) => {
        const statuses = [];
        for (let index = 0; index < 3; index += 1) {
            const response = await fetch(`${baseUrl}/api/product/12345678`);
            statuses.push(response.status);
            if (response.status === 429) {
                const body = await response.json();
                assert.equal(body.success, false);
                assert.equal(typeof body.error, 'string');
            } else {
                await response.arrayBuffer();
            }
        }
        assert.deepEqual(statuses, [200, 200, 429]);
    });
});

test('helmet headers are applied', async () => {
    await withServer({ config: loadConfig({}), productController: stubController() }, async (baseUrl) => {
        const response = await fetch(`${baseUrl}/api/unknown`);
        await response.arrayBuffer();
        assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
        assert.equal(response.headers.get('x-powered-by'), null);
    });
});

test('CORS allows every origin unless ALLOWED_ORIGINS is set', async () => {
    assert.deepEqual(buildCorsOptions(undefined), {});
    assert.deepEqual(buildCorsOptions(' , '), {});
    assert.deepEqual(buildCorsOptions('https://a.test, https://b.test'), { origin: ['https://a.test', 'https://b.test'] });

    const config = loadConfig({ ALLOWED_ORIGINS: 'https://a.test' });
    await withServer({ config, productController: stubController() }, async (baseUrl) => {
        const allowed = await fetch(`${baseUrl}/api/unknown`, { headers: { Origin: 'https://a.test' } });
        await allowed.arrayBuffer();
        assert.equal(allowed.headers.get('access-control-allow-origin'), 'https://a.test');

        const blocked = await fetch(`${baseUrl}/api/unknown`, { headers: { Origin: 'https://evil.test' } });
        await blocked.arrayBuffer();
        assert.equal(blocked.headers.get('access-control-allow-origin'), null);
    });
});

test('numeric env values fall back to defaults when invalid', () => {
    assert.equal(readPositiveInt('45', 30), 45);
    assert.equal(readPositiveInt('0', 30), 30);
    assert.equal(readPositiveInt('-3', 30), 30);
    assert.equal(readPositiveInt('abc', 30), 30);
    assert.equal(readPositiveInt(undefined, 30), 30);

    const config = loadConfig({});
    assert.equal(config.rateLimitPerMinute, 30);
    assert.equal(config.cacheTtlSeconds, 86400);
    assert.equal(config.cacheMaxEntries, 500);
    assert.equal(config.geminiModel, 'gemini-3.6-flash');
    assert.equal(config.geminiTimeoutMs, 25000);
    assert.equal(loadConfig({ GEMINI_TIMEOUT_MS: 'abc' }).geminiTimeoutMs, 25000);
    assert.equal(loadConfig({ GEMINI_TIMEOUT_MS: '8000' }).geminiTimeoutMs, 8000);
});
