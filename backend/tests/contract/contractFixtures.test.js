const { LIMITS_FOR_CAPTURE } = require('../../scripts/contractFixtures/captureContractFixtures');

Object.assign(process.env, LIMITS_FOR_CAPTURE);

const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { captureFixtures } = require('../../scripts/contractFixtures/captureContractFixtures');
const app = require('../../src/app');
const openFoodFactsClient = require('../../src/services/openFoodFacts/openFoodFactsClient');
const geminiClient = require('../../src/services/ai/geminiClient');

const FIXTURES_DIR = path.join(__dirname, '..', '..', '..', 'contracts', 'fixtures');

test('contracts/fixtures khớp đúng phản hồi thật của API v1 (chạy npm run contract:fixtures khi contract đổi)', async (t) => {
    t.mock.method(console, 'info', () => {});
    t.mock.method(console, 'warn', () => {});
    const captured = await captureFixtures({ app, openFoodFactsClient, geminiClient });
    const onDisk = fs.readdirSync(FIXTURES_DIR).filter((file) => file.endsWith('.json')).map((file) => file.slice(0, -5)).sort();

    assert.deepEqual(onDisk, Object.keys(captured).sort());

    for (const [name, fixture] of Object.entries(captured)) {
        const saved = JSON.parse(fs.readFileSync(path.join(FIXTURES_DIR, name + '.json'), 'utf8'));
        assert.deepEqual(saved, fixture, name);
    }
});

test('mọi phản hồi lỗi có success:false, error là chuỗi và code', () => {
    for (const file of fs.readdirSync(FIXTURES_DIR).filter((name) => name.startsWith('error-'))) {
        const { body, status } = JSON.parse(fs.readFileSync(path.join(FIXTURES_DIR, file), 'utf8'));
        assert.ok(status >= 400, file);
        assert.equal(body.success, false, file);
        assert.equal(typeof body.error, 'string', file);
        assert.equal(typeof body.code, 'string', file);
    }
});
