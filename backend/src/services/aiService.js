const geminiClient = require('./ai/geminiClient');
const { SYSTEM_INSTRUCTION, ANALYSIS_SCHEMA, buildPrompt } = require('./ai/analysisPrompt');
const { parseAnalysis } = require('./ai/analysisParser');

const analyzeProduct = async (product) => {
    const responseText = await geminiClient.generateJson({
        systemInstruction: SYSTEM_INSTRUCTION,
        prompt: buildPrompt(product),
        schema: ANALYSIS_SCHEMA
    });

    return parseAnalysis(responseText);
};

module.exports = { analyzeProduct };
