const fs = require('node:fs');
const path = require('node:path');
const { LIMITS_FOR_CAPTURE } = require('./captureContractFixtures');

Object.assign(process.env, LIMITS_FOR_CAPTURE);

const { captureFixtures } = require('./captureContractFixtures');
const app = require('../../src/app');
const openFoodFactsClient = require('../../src/services/openFoodFacts/openFoodFactsClient');

const OUTPUT_DIR = path.join(__dirname, '..', '..', '..', 'contracts', 'fixtures');

const main = async () => {
    const fixtures = await captureFixtures({ app, openFoodFactsClient });
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });

    for (const [name, fixture] of Object.entries(fixtures)) {
        fs.writeFileSync(path.join(OUTPUT_DIR, name + '.json'), JSON.stringify(fixture, null, 2) + '\n');
    }

    console.log('Wrote ' + Object.keys(fixtures).length + ' contract fixtures to ' + path.relative(process.cwd(), OUTPUT_DIR));
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
