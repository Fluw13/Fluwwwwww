const geminiClient = require('./ai/geminiClient');
const { SYSTEM_INSTRUCTION, ANALYSIS_SCHEMA, buildPrompt } = require('./ai/analysisPrompt');
const { parseAnalysis } = require('./ai/analysisParser');

// The legacy route keeps its 40 s budget: the current app waits up to 120 s for product data and analysis together.
const LEGACY_TIMEOUT_MS = 40000;

const analyzeProduct = async (product) => {
    const responseText = await geminiClient.generateJson({
        systemInstruction: SYSTEM_INSTRUCTION,
        prompt: buildPrompt(product),
        schema: ANALYSIS_SCHEMA,
        timeoutMs: LEGACY_TIMEOUT_MS
    });

    return parseAnalysis(responseText);
};

module.exports = { analyzeProduct };
